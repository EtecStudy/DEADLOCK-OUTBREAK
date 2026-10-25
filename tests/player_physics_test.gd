extends SceneTree

const PLAYER_SCENE_PATH := "res://scenes/player/player.tscn"
const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const EXPECTED_EYE_HEIGHT := 1.62
const EXPECTED_CAPSULE_HEIGHT := 1.8
const EXPECTED_CAPSULE_RADIUS := 0.32


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	var details: Dictionary = {
		"scope": "3.1 reusable first-person player scene; movement and mouse look are deferred",
	}
	var packed_player := load(PLAYER_SCENE_PATH) as PackedScene
	if packed_player == null:
		_finish(["Player scene did not load as a PackedScene"], details)
		return

	var player := packed_player.instantiate() as CharacterBody3D
	if player == null:
		_finish(["Reusable Player scene root is not CharacterBody3D"], details)
		return

	var collision := player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null:
		errors.append("Player scene is missing its CollisionShape3D")
	elif not (collision.shape is CapsuleShape3D):
		errors.append("Player collision shape is not a human-scale CapsuleShape3D")
	else:
		var capsule := collision.shape as CapsuleShape3D
		if not is_equal_approx(capsule.height, EXPECTED_CAPSULE_HEIGHT):
			errors.append("Player capsule height is not 1.8 m")
		if not is_equal_approx(capsule.radius, EXPECTED_CAPSULE_RADIUS):
			errors.append("Player capsule radius is not 0.32 m")
		if not is_equal_approx(collision.position.y, EXPECTED_CAPSULE_HEIGHT / 2.0):
			errors.append("Player capsule is not centered at floor level")
		details["capsule_height_m"] = capsule.height
		details["capsule_radius_m"] = capsule.radius

	var eye_pivot := player.get_node_or_null("EyePivot") as Node3D
	if eye_pivot == null:
		errors.append("Player scene is missing its EyePivot")
	elif not is_equal_approx(eye_pivot.position.y, EXPECTED_EYE_HEIGHT):
		errors.append("EyePivot is not at the 1.62 m human eye height")

	var camera := player.get_node_or_null("EyePivot/Camera3D") as Camera3D
	if camera == null:
		errors.append("Player camera is not parented directly to EyePivot")
	else:
		if not camera.current:
			errors.append("First-person Camera3D is not the current scene camera")
		if camera.position.length() > 0.001:
			errors.append("First-person Camera3D must sit at the eye pivot, not behind the player")
		if not is_equal_approx(camera.fov, 75.0):
			errors.append("First-person camera FOV is not 75 degrees")

	if not player.find_children("*", "SpringArm3D", true, false).is_empty():
		errors.append("Player scene contains a third-person SpringArm3D")
	if not player.find_children("*", "MeshInstance3D", true, false).is_empty():
		errors.append("Player scene contains a visible full-body mesh instead of a first-person view")
	for required_path in [
		"WorldModelRoot",
		"EyePivot/ViewModelRoot",
		"EyePivot/ViewModelRoot/HandsAnchor",
		"EyePivot/ViewModelRoot/WeaponAnchor",
	]:
		if player.get_node_or_null(required_path) == null:
			errors.append("Player scene is missing prepared first-person node: %s" % required_path)

	if player.get_script() == null or player.get_script().resource_path != "res://scripts/player/player_controller.gd":
		errors.append("Player scene is not connected to its reusable first-person scene script")

	get_root().add_child(player)
	await process_frame
	if not player.is_inside_tree():
		errors.append("Reusable Player did not enter the SceneTree")
	if camera != null and not camera.current:
		errors.append("Player scene script did not activate the first-person camera")
	if eye_pivot != null and not is_equal_approx(eye_pivot.position.y, EXPECTED_EYE_HEIGHT):
		errors.append("Player scene script moved the eye pivot away from the configured eye height")
	details["spring_arm_count"] = player.find_children("*", "SpringArm3D", true, false).size()
	details["player_mesh_count"] = player.find_children("*", "MeshInstance3D", true, false).size()
	details["eye_height_m"] = EXPECTED_EYE_HEIGHT
	details["camera_at_eye_pivot"] = camera != null and camera.position.length() <= 0.001
	player.queue_free()
	await process_frame

	var packed_main := load(MAIN_SCENE_PATH) as PackedScene
	if packed_main == null:
		errors.append("Main scene did not load for first-person integration check")
	else:
		var main := packed_main.instantiate()
		var integrated_player := main.get_node_or_null("PrisonCellBlockout/Player") as CharacterBody3D
		if integrated_player == null:
			errors.append("Main scene does not place the reusable Player in the prison cell blockout")
		elif integrated_player.scene_file_path != PLAYER_SCENE_PATH:
			errors.append("Main scene player is not an instance of the reusable first-person scene")
		if main.get_node_or_null("PrisonCellBlockout/CellDoor") == null:
			errors.append("First-person scene is not integrated with the prison-cell setting")
		details["main_scene"] = MAIN_SCENE_PATH
		details["player_scene"] = PLAYER_SCENE_PATH
		details["prison_cell_integration"] = integrated_player != null
		main.free()

	_finish(errors, details)


func _finish(errors: Array[String], details: Dictionary) -> void:
	if not errors.is_empty():
		printerr("DEADLOCK_PLAYER_SCENE_RESULT=" + JSON.stringify({"ok": false, "errors": errors, "details": details}))
		quit(1)
		return
	print("DEADLOCK_PLAYER_SCENE_RESULT=" + JSON.stringify({
		"ok": true,
		"engine": Engine.get_version_info().string,
		"details": details,
	}))
	quit(0)
