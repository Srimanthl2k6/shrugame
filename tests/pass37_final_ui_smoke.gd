extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_theme(failures)
	_check_main_menu(failures)
	_check_pause_menu(failures)
	_check_presentation_overlay(failures)
	_check_dialogue_box(failures)
	_finish(failures)


func _check_theme(failures: Array[String]) -> void:
	var theme := load("res://assets/shared/ui/shrugame_theme.tres") as Theme
	if theme == null:
		failures.append("Final UI theme failed to load")
	elif theme.default_font == null:
		failures.append("Final UI theme has no pixel font")
	if not ProjectSettings.has_setting("autoload/SettingsManager"):
		failures.append("SettingsManager is not an autoload")


func _check_main_menu(failures: Array[String]) -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	if scene == null:
		failures.append("Main scene failed to load")
		return
	var main := scene.instantiate()
	for path in [
		"TitleLayer/MenuPanel/OptionsButton",
		"TitleLayer/MenuPanel/CreditsButton",
		"TitleLayer/SettingsPanel",
		"TitleLayer/CreditsLayer"
	]:
		if main.get_node_or_null(path) == null:
			failures.append("Main menu is missing %s" % path)
	main.free()


func _check_pause_menu(failures: Array[String]) -> void:
	var scene := load("res://scenes/ui/pause_menu.tscn") as PackedScene
	if scene == null:
		failures.append("Pause menu failed to load")
		return
	var pause := scene.instantiate()
	for path in [
		"Root/Shell/Left/ResumeButton",
		"Root/Shell/Left/JournalButton",
		"Root/Shell/Left/ItemsButton",
		"Root/Shell/Left/OptionsButton",
		"Root/Shell/Left/SaveButton",
		"Root/Shell/Left/TitleButton",
		"Root/SettingsPanel"
	]:
		if pause.get_node_or_null(path) == null:
			failures.append("Pause menu is missing %s" % path)
	pause.free()


func _check_presentation_overlay(failures: Array[String]) -> void:
	var guide: Node = load("res://scripts/visual/presentation_guide.gd").new()
	var overlay: Control = guide.build_pc_overlay()
	for hidden_panel in ["RouteStepsPanel", "LegendPanel", "PromptPanel"]:
		var panel := overlay.get_node_or_null(hidden_panel) as Control
		if panel == null:
			failures.append("Compatibility overlay node missing: %s" % hidden_panel)
		elif panel.visible:
			failures.append("Debug overlay panel should be hidden by default: %s" % hidden_panel)
	overlay.free()
	guide.free()


func _check_dialogue_box(failures: Array[String]) -> void:
	var scene := load("res://scenes/ui/dialogue_box.tscn") as PackedScene
	if scene == null:
		failures.append("Dialogue box failed to load")
		return
	var dialogue := scene.instantiate()
	if dialogue.get_node_or_null("Panel/ContinueLabel") == null:
		failures.append("Dialogue box lacks a continue indicator")
	dialogue.free()


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("PASS: Premium final UI smoke test")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
