extends Node


func _ready() -> void:
	if not InputMap.has_action("toggle_fullscreen"):
		push_error("WindowController requires the 'toggle_fullscreen' action in project.godot.")


func _get_windowed_resolution() -> Vector2i:
	var viewport_size := Vector2i(
		int(ProjectSettings.get_setting("display/window/size/viewport_width", 1280)),
		int(ProjectSettings.get_setting("display/window/size/viewport_height", 720)),
	)
	var windowed_size := Vector2i(
		int(ProjectSettings.get_setting("display/window/size/window_width_override", viewport_size.x)),
		int(ProjectSettings.get_setting("display/window/size/window_height_override", viewport_size.y)),
	)
	if windowed_size.x > 0 and windowed_size.y > 0:
		return windowed_size
	if viewport_size.x > 0 and viewport_size.y > 0:
		push_warning("Invalid window override; restoring the window to the configured viewport size.")
		return viewport_size
	push_error("Window and viewport sizes are invalid; falling back to 1280x720.")
	return Vector2i(1280, 720)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("toggle_fullscreen"):
		return

	var key_event := event as InputEventKey
	if key_event != null and key_event.echo:
		return

	_toggle_fullscreen()
	get_viewport().set_input_as_handled()


func _toggle_fullscreen() -> void:
	var current_mode := DisplayServer.window_get_mode()
	var is_fullscreen := (
		current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN
		or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)

	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(_get_windowed_resolution())
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
