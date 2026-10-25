extends SceneTree

const WINDOW_CONTROLLER_PATH := "res://scripts/core/window_controller.gd"
const MISSING_SCENE_PATH := "res://tests/__missing_scene_for_error_test__.tscn"
const MAIN_SCENE_PATH := "res://scenes/main.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	if not ResourceLoader.exists(MAIN_SCENE_PATH):
		errors.append("Required scene check failed for existing main scene")
	var missing_resource_message := _required_resource_error(MISSING_SCENE_PATH)
	if missing_resource_message.is_empty() or not missing_resource_message.contains(MISSING_SCENE_PATH):
		errors.append("Missing resource was not reported with its path")

	var controller_script := load(WINDOW_CONTROLLER_PATH) as Script
	if controller_script == null:
		errors.append("Window controller script could not be loaded")
		_finish(errors)
		return
	var controller := Node.new()
	controller.set_script(controller_script)
	get_root().add_child(controller)
	await process_frame

	var width_key := "display/window/size/window_width_override"
	var height_key := "display/window/size/window_height_override"
	var original_width: Variant = ProjectSettings.get_setting(width_key)
	var original_height: Variant = ProjectSettings.get_setting(height_key)
	ProjectSettings.set_setting(width_key, 0)
	ProjectSettings.set_setting(height_key, -1)
	var fallback_size: Vector2i = controller.call("_get_windowed_resolution")
	ProjectSettings.set_setting(width_key, original_width)
	ProjectSettings.set_setting(height_key, original_height)
	if fallback_size != Vector2i(1280, 720):
		errors.append("Invalid window overrides did not fall back to the valid viewport size")

	controller.queue_free()
	_finish(errors)


func _required_resource_error(resource_path: String) -> String:
	if ResourceLoader.exists(resource_path):
		return ""
	return "Required resource not found: %s" % resource_path


func _finish(errors: Array[String]) -> void:
	if not errors.is_empty():
		printerr("DEADLOCK_ERROR_TEST_RESULT=" + JSON.stringify({"ok": false, "errors": errors}))
		quit(1)
		return
	print("DEADLOCK_ERROR_TEST_RESULT=" + JSON.stringify({
		"ok": true,
		"missing_resource_message": _required_resource_error(MISSING_SCENE_PATH),
		"invalid_window_override_fallback": [1280, 720],
	}))
	quit(0)
