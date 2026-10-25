extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const EXPECTED_ACTIONS := [
	"move_forward",
	"move_backward",
	"move_left",
	"move_right",
	"interact",
	"primary_action",
	"secondary_action",
	"reload",
	"pause",
	"toggle_fullscreen",
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	var configured_scene: String = str(ProjectSettings.get_setting("application/run/main_scene", ""))
	if configured_scene != MAIN_SCENE_PATH:
		errors.append("Unexpected main scene: %s" % configured_scene)

	var project_name: String = str(ProjectSettings.get_setting("application/config/name", ""))
	if project_name != "Deadlock Outbreak":
		errors.append("Unexpected project name: %s" % project_name)

	if int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)) != 1280:
		errors.append("Initial viewport width is not 1280")
	if int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)) != 720:
		errors.append("Initial viewport height is not 720")
	if int(ProjectSettings.get_setting("display/window/size/window_width_override", 0)) != 1280:
		errors.append("Initial window width override is not 1280")
	if int(ProjectSettings.get_setting("display/window/size/window_height_override", 0)) != 720:
		errors.append("Initial window height override is not 720")
	if int(ProjectSettings.get_setting("display/window/size/mode", -1)) != 0:
		errors.append("Initial window mode is not windowed")
	if not bool(ProjectSettings.get_setting("display/window/size/resizable", false)):
		errors.append("Initial window is not resizable")
	if str(ProjectSettings.get_setting("display/window/stretch/mode", "")) != "disabled":
		errors.append("Unexpected initial stretch mode")
	if str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "")) != "gl_compatibility":
		errors.append("Renderer is not configured for GL Compatibility")

	for action in EXPECTED_ACTIONS:
		if not InputMap.has_action(action):
			errors.append("Missing input action: %s" % action)
		elif InputMap.action_get_events(action).is_empty():
			errors.append("Input action has no bound event: %s" % action)

	var packed_scene: PackedScene = load(MAIN_SCENE_PATH) as PackedScene
	if packed_scene == null:
		errors.append("Main scene did not load as a PackedScene")
		_finish(errors, {})
		return

	var main_node: Node = packed_scene.instantiate()
	if not (main_node is Node3D):
		errors.append("Main scene root is not Node3D")
	if main_node.get_script() == null:
		errors.append("Main scene has no foundation script")
	elif main_node.get_script().resource_path != "res://scripts/core/window_controller.gd":
		errors.append("Main scene script reference is unexpected")
	var controller_window_size: Vector2i = main_node.call("_get_windowed_resolution")
	if controller_window_size != Vector2i(1280, 720):
		errors.append("Window controller did not read the shared 1280x720 ProjectSettings")

	var player_node := main_node.get_node_or_null("PrisonCellBlockout/Player") as CharacterBody3D
	if player_node == null:
		errors.append("Prison cell does not instance the reusable Player CharacterBody3D")
	else:
		if player_node.scene_file_path != "res://scenes/player/player.tscn":
			errors.append("Prison cell Player instance does not come from the reusable player scene")
		if player_node.get_node_or_null("CollisionShape3D") == null:
			errors.append("Prison cell Player has no collision shape")
		var player_camera := player_node.get_node_or_null("EyePivot/Camera3D") as Camera3D
		if player_camera == null or not player_camera.current:
			errors.append("Main scene Player eye-level first-person camera is missing or not current")
		if player_node.get_node_or_null("EyePivot/SpringArm3D") != null:
			errors.append("First-person Player must not contain a third-person SpringArm3D")
	if main_node.get_node_or_null("PrisonCellBlockout/CellFloor") is not MeshInstance3D:
		errors.append("Prison cell blockout has no visible floor mesh")
	if main_node.get_node_or_null("PrisonCellBlockout/CellDoor") == null:
		errors.append("Prison cell blockout has no barred cell door")
	if main_node.get_node_or_null("PrisonCellBlockout/CorridorLeftWall") is not MeshInstance3D:
		errors.append("Prison cell blockout has no visible adjoining corridor")

	get_root().add_child(main_node)
	await process_frame
	if not main_node.is_inside_tree():
		errors.append("Main scene did not enter the SceneTree")
	if player_node != null and not player_node.is_inside_tree():
		errors.append("Main scene Player did not enter the SceneTree")

	var details := {
		"project_name": project_name,
		"main_scene": configured_scene,
		"root_type": main_node.get_class(),
		"viewport": [
			ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height"),
		],
		"window_size_override": [
			ProjectSettings.get_setting("display/window/size/window_width_override"),
			ProjectSettings.get_setting("display/window/size/window_height_override"),
		],
		"window_mode": ProjectSettings.get_setting("display/window/size/mode"),
		"resizable": ProjectSettings.get_setting("display/window/size/resizable"),
		"stretch_mode": ProjectSettings.get_setting("display/window/stretch/mode"),
		"renderer": ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		"input_actions": EXPECTED_ACTIONS,
		"player_scene": player_node.scene_file_path if player_node != null else "",
		"player_entered_scene_tree": player_node != null and player_node.is_inside_tree(),
		"entered_scene_tree": main_node.is_inside_tree(),
	}
	main_node.queue_free()
	_finish(errors, details)


func _finish(errors: Array[String], details: Dictionary) -> void:
	if not errors.is_empty():
		printerr("DEADLOCK_PROJECT_SMOKE_RESULT=" + JSON.stringify({"ok": false, "errors": errors, "details": details}))
		quit(1)
		return
	print("DEADLOCK_PROJECT_SMOKE_RESULT=" + JSON.stringify({
		"ok": true,
		"engine": Engine.get_version_info().string,
		"details": details,
	}))
	quit(0)
