extends SceneTree

const PLAYER_SCENE_PATH := "res://scenes/player/player.tscn"
const MOVE_ACTIONS := ["move_forward", "move_backward", "move_left", "move_right"]
const ALL_TEST_ACTIONS := ["move_forward", "move_backward", "move_left", "move_right", "sprint"]
const FIXED_STEP_COUNT := 36


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	var packed_scene := load(PLAYER_SCENE_PATH) as PackedScene
	if packed_scene == null:
		_finish(["Player PackedScene failed to load"])
		return

	var floor_body := StaticBody3D.new()
	floor_body.name = "PhysicsTestFloor"
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(40.0, 1.0, 40.0)
	var floor_collider := CollisionShape3D.new()
	floor_collider.shape = floor_shape
	floor_body.add_child(floor_collider)
	get_root().add_child(floor_body)

	var player := packed_scene.instantiate() as CharacterBody3D
	if player == null:
		_finish(["Player root is not CharacterBody3D"])
		return
	player.name = "PlayerUnderTest"
	player.position = Vector3(0.0, 0.1, 8.0)
	get_root().add_child(player)

	var player_collider := player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	var camera := player.get_node_or_null("CameraPivot/SpringArm3D/Camera3D") as Camera3D
	var spring_arm := player.get_node_or_null("CameraPivot/SpringArm3D") as SpringArm3D
	if player_collider == null or player_collider.shape is not CapsuleShape3D:
		errors.append("Player has no capsule collision shape")
	if camera == null or not camera.current:
		errors.append("Player camera is missing or not current")
	if spring_arm == null:
		errors.append("Player third-person spring arm is missing")

	_release_actions()
	await _wait_physics_frames(6)
	if not player.is_on_floor():
		errors.append("Player did not settle onto the test floor")
	if camera != null:
		if player.to_local(camera.global_position).z <= 0.0:
			errors.append("Third-person camera is not positioned behind the player")
		if camera.global_position.y <= player.global_position.y + 1.8:
			errors.append("Third-person camera is not positioned slightly above the player")
		if (-camera.global_basis.z).z >= 0.0:
			errors.append("Third-person camera is not looking toward the player's forward direction")
	if player.get_movement_state_name() != "idle":
		errors.append("Player did not begin in the IDLE state")

	for action in MOVE_ACTIONS:
		var displacement := await _measure_direction(player, action)
		match action:
			"move_forward":
				if displacement.z >= -0.5:
					errors.append("Forward input did not move toward -Z")
			"move_backward":
				if displacement.z <= 0.5:
					errors.append("Backward input did not move toward +Z")
			"move_left":
				if displacement.x >= -0.5:
					errors.append("Left input did not move toward -X")
			"move_right":
				if displacement.x <= 0.5:
					errors.append("Right input did not move toward +X")

	await _reset_player(player, Vector3(0.0, 0.0, 8.0))
	Input.action_press("move_forward")
	Input.action_press("move_right")
	await _wait_physics_frames(FIXED_STEP_COUNT)
	var diagonal_speed := Vector2(player.velocity.x, player.velocity.z).length()
	if diagonal_speed > player.walk_speed + 0.05:
		errors.append("Diagonal movement exceeded the configured walking speed")
	var axial_acceleration_speed := await _measure_initial_acceleration(player, false)
	var diagonal_acceleration_speed := await _measure_initial_acceleration(player, true)
	if absf(axial_acceleration_speed - diagonal_acceleration_speed) > 0.05:
		errors.append("Diagonal input accelerated faster than axial input")

	var normal_speed := await _measure_speed(player, false)
	var sprint_speed := await _measure_speed(player, true)
	if normal_speed < player.walk_speed * 0.9:
		errors.append("Normal movement did not reach its configured speed")
	if sprint_speed <= normal_speed * 1.2 or sprint_speed < player.sprint_speed * 0.9:
		errors.append("Sprint did not produce a meaningful speed increase")

	_release_actions()
	await _reset_player(player, Vector3(0.0, 0.0, 8.0))
	var state_transitions: Array[int] = []
	player.movement_state_changed.connect(func(state: int) -> void: state_transitions.append(state))
	Input.action_press("move_forward")
	await _wait_physics_frames(4)
	if player.get_movement_state_name() != "walking":
		errors.append("Walking input did not set the WALKING state")
	Input.action_press("sprint")
	await _wait_physics_frames(4)
	if player.get_movement_state_name() != "running":
		errors.append("Shift/sprint input did not set the RUNNING state")
	_release_actions()
	await _wait_physics_frames(40)
	if player.get_movement_state_name() != "idle":
		errors.append("Releasing movement did not return to the IDLE state")
	if state_transitions.size() < 3:
		errors.append("Movement state transition signal did not report the state changes")

	await _reset_player(player, Vector3(0.0, 4.0, 8.0))
	var start_height := player.global_position.y
	await _wait_physics_frames(12)
	if player.global_position.y >= start_height - 0.1 or player.get_movement_state_name() != "airborne":
		errors.append("Gravity did not move the player into the AIRBORNE state")
	await _wait_physics_frames(150)
	if not player.is_on_floor() or absf(player.global_position.y) > 0.08:
		errors.append("Player did not land and remain on the floor")

	await _reset_player(player, Vector3(0.0, 0.0, 0.0))
	var wall := StaticBody3D.new()
	wall.position = Vector3(0.0, 1.5, -2.5)
	var wall_shape := BoxShape3D.new()
	wall_shape.size = Vector3(6.0, 3.0, 0.5)
	var wall_collider := CollisionShape3D.new()
	wall_collider.shape = wall_shape
	wall.add_child(wall_collider)
	get_root().add_child(wall)
	Input.action_press("move_forward")
	await _wait_physics_frames(90)
	_release_actions()
	if player.global_position.z < -2.2:
		errors.append("Player moved through the solid test wall")
	wall.position = Vector3(0.0, 1.5, 0.0)
	await _wait_physics_frames(4)
	if spring_arm != null and spring_arm.get_hit_length() >= player.camera_distance - 0.1:
		errors.append("Spring arm did not retract when a wall obstructed the camera")

	var yaw_before := player.rotation.y
	player._set_mouse_captured(true)
	var mouse_motion := InputEventMouseMotion.new()
	mouse_motion.relative = Vector2(80.0, -10000.0)
	get_root().push_input(mouse_motion)
	await process_frame
	if is_equal_approx(player.rotation.y, yaw_before):
		errors.append("Mouse motion did not rotate the player horizontally")
	var max_pitch := deg_to_rad(player.max_camera_pitch_degrees)
	if not is_equal_approx(player.camera_pivot.rotation.x, max_pitch):
		errors.append("Camera pitch exceeded or missed the configured upper limit")
	var mouse_motion_down := InputEventMouseMotion.new()
	mouse_motion_down.relative = Vector2(0.0, 20000.0)
	get_root().push_input(mouse_motion_down)
	await process_frame
	var min_pitch := deg_to_rad(player.min_camera_pitch_degrees)
	if not is_equal_approx(player.camera_pivot.rotation.x, min_pitch):
		errors.append("Camera pitch exceeded or missed the configured lower limit")

	player._set_mouse_captured(false)
	var escape_event := InputEventKey.new()
	escape_event.physical_keycode = KEY_ESCAPE
	escape_event.pressed = true
	get_root().push_input(escape_event.duplicate())
	await process_frame
	if not player.is_mouse_captured():
		errors.append("Escape did not capture a released mouse")
	get_root().push_input(escape_event.duplicate())
	await process_frame
	if player.is_mouse_captured():
		errors.append("Escape did not release a captured mouse")
	var recapture_click := InputEventMouseButton.new()
	recapture_click.button_index = MOUSE_BUTTON_LEFT
	recapture_click.pressed = true
	get_root().push_input(recapture_click)
	await process_frame
	if not player.is_mouse_captured():
		errors.append("Left click did not recapture the released mouse")

	_release_actions()
	player.queue_free()
	floor_body.queue_free()
	wall.queue_free()
	_finish(errors)


func _measure_direction(player: CharacterBody3D, action: String) -> Vector3:
	await _reset_player(player, Vector3(0.0, 0.0, 8.0))
	var start_position := player.global_position
	Input.action_press(action)
	await _wait_physics_frames(FIXED_STEP_COUNT)
	Input.action_release(action)
	return player.global_position - start_position


func _measure_initial_acceleration(player: CharacterBody3D, diagonal: bool) -> float:
	await _reset_player(player, Vector3(0.0, 0.0, 8.0))
	Input.action_press("move_forward")
	if diagonal:
		Input.action_press("move_right")
	await _wait_physics_frames(4)
	var speed := Vector2(player.velocity.x, player.velocity.z).length()
	_release_actions()
	return speed


func _measure_speed(player: CharacterBody3D, sprint: bool) -> float:
	await _reset_player(player, Vector3(0.0, 0.0, 8.0))
	Input.action_press("move_forward")
	if sprint:
		Input.action_press("sprint")
	await _wait_physics_frames(FIXED_STEP_COUNT)
	var speed := Vector2(player.velocity.x, player.velocity.z).length()
	_release_actions()
	return speed


func _reset_player(player: CharacterBody3D, position: Vector3) -> void:
	_release_actions()
	player.velocity = Vector3.ZERO
	player.global_position = position
	await _wait_physics_frames(4)


func _release_actions() -> void:
	for action in ALL_TEST_ACTIONS:
		Input.action_release(action)


func _wait_physics_frames(frame_count: int) -> void:
	for _frame_index in range(frame_count):
		await physics_frame


func _finish(errors: Array[String]) -> void:
	if not errors.is_empty():
		printerr("DEADLOCK_PLAYER_PHYSICS_RESULT=" + JSON.stringify({"ok": false, "errors": errors}))
		quit(1)
		return
	print("DEADLOCK_PLAYER_PHYSICS_RESULT=" + JSON.stringify({"ok": true}))
	quit(0)
