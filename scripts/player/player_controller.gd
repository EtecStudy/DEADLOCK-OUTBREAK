extends CharacterBody3D

signal movement_state_changed(state: int)

enum MovementState { IDLE, WALKING, RUNNING, AIRBORNE }

@export_group("Movement")
@export_range(0.1, 20.0, 0.1) var walk_speed: float = 4.5
@export_range(0.1, 25.0, 0.1) var sprint_speed: float = 7.0
@export_range(0.1, 100.0, 0.1) var acceleration: float = 18.0
@export_range(0.1, 100.0, 0.1) var deceleration: float = 22.0
@export_range(1.0, 60.0, 0.5) var gravity: float = 24.0
@export_range(0.0, 1.0, 0.05) var air_control_scale: float = 0.35
@export_range(0.0, 1.0, 0.01) var idle_speed_threshold: float = 0.15
@export_range(0.0, 1.0, 0.01) var floor_snap_distance: float = 0.25
@export_group("Camera")
@export_range(0.5, 10.0, 0.1) var camera_distance: float = 4.2
@export_range(-89.0, 89.0, 1.0) var initial_camera_pitch_degrees: float = -5.0
@export_range(0.0005, 0.01, 0.0001) var mouse_sensitivity: float = 0.0022
@export_range(-89.0, 0.0, 1.0) var min_camera_pitch_degrees: float = -45.0
@export_range(0.0, 89.0, 1.0) var max_camera_pitch_degrees: float = 55.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
var _camera_pitch: float = 0.0
var _mouse_captured: bool = false
var movement_state: MovementState = MovementState.IDLE


func _ready() -> void:
	floor_snap_length = floor_snap_distance
	_camera_pitch = deg_to_rad(initial_camera_pitch_degrees)
	camera_pivot.rotation.x = _camera_pitch
	spring_arm.spring_length = camera_distance
	spring_arm.add_excluded_object(get_rid())
	if DisplayServer.get_name() != "headless":
		_set_mouse_captured(true)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _mouse_captured:
		var mouse_motion := event as InputEventMouseMotion
		rotate_y(-mouse_motion.relative.x * mouse_sensitivity)
		var min_pitch := deg_to_rad(min_camera_pitch_degrees)
		var max_pitch := deg_to_rad(max_camera_pitch_degrees)
		_camera_pitch = clampf(
			_camera_pitch - mouse_motion.relative.y * mouse_sensitivity,
			min_pitch,
			max_pitch,
		)
		camera_pivot.rotation.x = _camera_pitch
	elif event.is_action_pressed("pause") and not (event is InputEventKey and event.echo):
		_toggle_mouse_capture()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if not _mouse_captured:
				_set_mouse_captured(true)
				get_viewport().set_input_as_handled()


func _toggle_mouse_capture() -> void:
	_set_mouse_captured(not _mouse_captured)


func _set_mouse_captured(captured: bool) -> void:
	_mouse_captured = captured
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE


func is_mouse_captured() -> bool:
	return _mouse_captured


func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward",
	)
	var local_direction := Vector3(input_vector.x, 0.0, input_vector.y)
	var world_direction := global_basis * local_direction
	if world_direction.length_squared() > 1.0:
		world_direction = world_direction.normalized()

	var sprint_requested := input_vector != Vector2.ZERO and Input.is_action_pressed("sprint")
	var target_speed := sprint_speed if sprint_requested else walk_speed
	var target_velocity := world_direction * target_speed
	var control_scale := 1.0 if is_on_floor() else air_control_scale
	var change_rate := acceleration if world_direction != Vector3.ZERO else deceleration
	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	horizontal_velocity = horizontal_velocity.move_toward(
		target_velocity,
		change_rate * control_scale * delta,
	)
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

	if is_on_floor():
		if velocity.y < 0.0:
			velocity.y = 0.0
	else:
		velocity.y -= gravity * delta

	move_and_slide()
	_update_movement_state(sprint_requested)


func _update_movement_state(sprint_requested: bool) -> void:
	var next_state: MovementState
	if not is_on_floor():
		next_state = MovementState.AIRBORNE
	elif Vector2(velocity.x, velocity.z).length() < idle_speed_threshold:
		next_state = MovementState.IDLE
	elif sprint_requested:
		next_state = MovementState.RUNNING
	else:
		next_state = MovementState.WALKING

	if next_state != movement_state:
		movement_state = next_state
		movement_state_changed.emit(movement_state)


func get_movement_state_name() -> String:
	return MovementState.keys()[movement_state].to_lower()
