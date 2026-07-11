extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_save_system(failures)
	_check_main_title_flow(failures)
	_check_audio_manager(failures)
	_check_ending_scene(failures)
	_check_export_preset(failures)
	_check_readme_status(failures)

	if failures.is_empty():
		print("PASS: Pass 10 smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_save_system(failures: Array[String]) -> void:
	var game_state: Node = root.get_node_or_null("GameState")
	if game_state == null:
		failures.append("GameState autoload is required")
		return
	var save_system: Node = root.get_node_or_null("SaveSystem")
	if save_system == null:
		failures.append("SaveSystem autoload is required")
		return

	if not save_system.has_method("has_save"):
		failures.append("SaveSystem must expose has_save()")
	if not save_system.has_method("new_game"):
		failures.append("SaveSystem must expose new_game()")
	if not save_system.has_method("get_level_scene_path"):
		failures.append("SaveSystem must expose get_level_scene_path(level_id)")
		return

	save_system.save_path = "user://pass10_smoke_save.json"
	save_system.clear_save()
	game_state.clear_flags()
	game_state.set_flag("pass10_flag", true)
	var saved: bool = save_system.save_game("level_03", "save_point")
	if not saved:
		failures.append("SaveSystem must write a single local save file")
	if not save_system.has_save():
		failures.append("SaveSystem has_save() should be true after save")
	game_state.current_level_id = "level_01"
	game_state.spawn_point = "start"
	game_state.clear_flags()
	var data: Dictionary = save_system.load_game()
	if data.get("level_id", "") != "level_03":
		failures.append("SaveSystem must load saved level_id")
	if game_state.current_level_id != "level_03" or game_state.spawn_point != "save_point":
		failures.append("SaveSystem must restore GameState current level and spawn point")
	if not game_state.get_flag("pass10_flag"):
		failures.append("SaveSystem must restore story flags")
	if save_system.get_level_scene_path("level_04") != "res://scenes/levels/level_04.tscn":
		failures.append("SaveSystem must map level ids to scene paths")
	save_system.clear_save()


func _check_main_title_flow(failures: Array[String]) -> void:
	var scene := load("res://scenes/main.tscn")
	if scene == null:
		failures.append("Main scene must load")
		return
	var main: Node = scene.instantiate()
	root.add_child(main)
	await process_frame

	if not main.has_method("start_new_game"):
		failures.append("Main scene must expose start_new_game()")
	if not main.has_method("continue_game"):
		failures.append("Main scene must expose continue_game()")
	if main.get_node_or_null("TitleLayer") == null:
		failures.append("Main scene must include a title layer")
	if main.get_node_or_null("TitleLayer/Panel/NewGameButton") == null:
		failures.append("Title screen must include a New Game button")
	if main.get_node_or_null("TitleLayer/Panel/ContinueButton") == null:
		failures.append("Title screen must include a Continue button")

	main.free()


func _check_audio_manager(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://project.godot")
	if not source.contains("AudioManager"):
		failures.append("AudioManager must be registered as an autoload")
	var audio_manager: Node = root.get_node_or_null("AudioManager")
	if audio_manager == null:
		failures.append("AudioManager autoload is required")
		return
	for method_name in ["play_sfx", "play_ui_select", "play_save_chime", "play_encounter_start"]:
		if not audio_manager.has_method(method_name):
			failures.append("AudioManager missing %s()" % method_name)
	if not audio_manager.play_sfx("ui_select"):
		failures.append("AudioManager should play known SFX ids")


func _check_ending_scene(failures: Array[String]) -> void:
	if load("res://scenes/ending.tscn") == null:
		failures.append("Ending scene must exist")
	var level_scene := load("res://scenes/levels/level_05.tscn")
	if level_scene == null:
		failures.append("Level 5 scene must load")
		return
	var level: Node = level_scene.instantiate()
	var door: Node = level.get_node_or_null("World/TransitionDoor")
	if door == null:
		failures.append("Level 5 needs a transition door")
	elif door.get("target_scene_path") != "res://scenes/ending.tscn":
		failures.append("Level 5 transition door must target the ending scene")
	level.free()


func _check_export_preset(failures: Array[String]) -> void:
	if not FileAccess.file_exists("res://export_presets.cfg"):
		failures.append("Windows export preset file is required")
		return
	var text := FileAccess.get_file_as_string("res://export_presets.cfg")
	if not text.contains('name="Windows Desktop"'):
		failures.append("Export preset must include Windows Desktop")
	if not text.contains('platform="Windows Desktop"'):
		failures.append("Export preset must target Windows Desktop")
	if not text.contains("builds/windows/Shrugame.exe"):
		failures.append("Export preset must point at builds/windows/Shrugame.exe")


func _check_readme_status(failures: Array[String]) -> void:
	var readme := FileAccess.get_file_as_string("res://README.md")
	if readme.contains("structure-only skeleton") or readme.contains("intentionally not implemented"):
		failures.append("README must reflect the current playable prototype status")
	if not readme.contains("Pass 10"):
		failures.append("README must mention Pass 10 status")
