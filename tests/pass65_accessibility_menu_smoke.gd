extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert(ProjectSettings.get_setting("display/window/size/viewport_width") == 640, "Viewport width must be 640")
	_assert(ProjectSettings.get_setting("display/window/size/viewport_height") == 360, "Viewport height must be 360")
	_assert(ProjectSettings.get_setting("display/window/size/window_width_override") == 1280, "Default window width must be 1280")
	_assert(ProjectSettings.get_setting("display/window/size/min_width") == 960, "Minimum window width must be 960")
	for action in ["move_left", "move_right", "move_up", "move_down", "interact", "ui_accept", "ui_cancel"]:
		_assert(InputMap.has_action(action), "%s input action is missing" % action)
		var has_keyboard := false
		var has_controller := false
		for event in InputMap.action_get_events(action):
			has_keyboard = has_keyboard or event is InputEventKey
			has_controller = has_controller or event is InputEventJoypadButton or event is InputEventJoypadMotion
		_assert(has_keyboard, "%s needs a keyboard binding" % action)
		_assert(has_controller, "%s needs a controller binding" % action)

	var main_text := FileAccess.get_file_as_string("res://scenes/main.tscn")
	for node_name in ["NewGameButton", "ContinueButton", "OptionsButton", "ControlsButton", "CreditsButton", "QuitButton", "OverwriteDialog"]:
		_assert(main_text.contains(node_name), "Title screen is missing %s" % node_name)
	var settings_text := FileAccess.get_file_as_string("res://scenes/ui/settings_panel.tscn")
	for control in ["MasterSlider", "SfxSlider", "FlashToggle", "ShakeToggle", "ObjectivesToggle", "ContrastToggle", "TextSpeedSlider"]:
		_assert(settings_text.contains(control), "Settings panel is missing %s" % control)
	_assert(not settings_text.contains("MusicSlider"), "SFX-only settings must not expose a music slider")
	var controls_text := FileAccess.get_file_as_string("res://scenes/ui/controls_panel.tscn")
	_assert(controls_text.contains("ReplayButton"), "In-game controls must offer tutorial replay")
	_assert(root.get_node_or_null("TutorialManager") != null, "First-play tutorial manager must be registered")
	var modes := _load_json("res://data/difficulty/difficulty_modes.json")
	_assert(str((modes.get("shrububu", {}) as Dictionary).get("description", "")).contains("Extremely easy"), "Shrububu difficulty must be explicit")
	_assert(str((modes.get("srmt", {}) as Dictionary).get("description", "")).contains("Extremely hard"), "SRMT difficulty must be explicit")
	_finish("Pass 65 menu, onboarding, and accessibility contract")


func _load_json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish(label: String) -> void:
	if failures.is_empty():
		print("PASS: %s" % label)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
