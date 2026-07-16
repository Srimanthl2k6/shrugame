extends SceneTree

var failures: Array[String] = []
var _save_system
var _game_state
var _original_save_paths: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_save_system = root.get_node_or_null("SaveSystem")
	_game_state = root.get_node_or_null("GameState")
	_prepare_temporary_save()
	_test_readable_native_ui()
	_test_device_aware_prompts()
	_test_tutorial_flow()
	await _test_satyaki_resolution_routes()
	await _test_complete_level_chain()
	_cleanup_temporary_save()
	_finish("Pass 71 readable UI, tutorials, persistent audio, and level transitions")


func _test_readable_native_ui() -> void:
	var theme_text := FileAccess.get_file_as_string("res://assets/shared/ui/shrugame_theme.tres")
	_assert(theme_text.contains("AtkinsonHyperlegible-Regular.ttf"), "Functional UI must use Atkinson Hyperlegible")
	_assert(theme_text.contains("default_font_size = 16"), "Default UI text must be 16px")
	for path in [
		"res://scenes/main.tscn",
		"res://scenes/ending.tscn",
		"res://scenes/ui/dialogue_box.tscn",
		"res://scenes/ui/pause_menu.tscn",
		"res://scenes/ui/settings_panel.tscn",
		"res://scenes/ui/controls_panel.tscn",
		"res://scenes/ui/battle_hud.tscn",
		"res://scenes/ui/tutorial_overlay.tscn"
	]:
		var text := FileAccess.get_file_as_string(path)
		_assert(not text.contains("Transform2D(2, 0, 0, 2, 0, 0)"), "%s must not enlarge a 320px UI" % path)
		_assert(text.contains("offset_right = 640") or text.contains("offset_right = 640.0") or path.ends_with("pause_menu.tscn"), "%s needs a native 640px root" % path)
		var regex := RegEx.new()
		regex.compile("theme_override_font_sizes/(?:normal_)?font_size = ([0-9]+)")
		for result in regex.search_all(text):
			_assert(int(result.get_string(1)) >= 13, "%s contains unreadably small functional text" % path)
	var district_text := ""
	for level_number in range(1, 6):
		district_text += FileAccess.get_file_as_string("res://scenes/levels/districts/level_%02d.tscn" % level_number)
	_assert(not district_text.contains("Transform2D(2, 0, 0, 2, 0, 0)"), "District UI layers must render natively")
	var presentation_text := FileAccess.get_file_as_string("res://scripts/visual/presentation_guide.gd")
	_assert(presentation_text.contains("Vector2(640.0, 360.0)"), "Objective and interaction overlay must use the native viewport")
	_assert(not presentation_text.contains("root.scale = Vector2(2.0, 2.0)"), "Objective overlay must not enlarge tiny text")
	var director_text := FileAccess.get_file_as_string("res://scripts/cutscenes/cutscene_director.gd")
	_assert(not director_text.contains("_overlay.scale = Vector2(2.0, 2.0)"), "Cutscene overlay must not be scaled beyond the viewport")


func _test_device_aware_prompts() -> void:
	var input_manager = root.get_node_or_null("InputManager")
	_assert(input_manager != null, "Input manager must be available")
	if input_manager == null:
		return
	input_manager.last_device_id = "keyboard"
	_assert(not str(input_manager.get_action_prompt("interact")).is_empty(), "Keyboard interact prompt must resolve")
	_assert(str(input_manager.get_movement_prompt()).contains("WASD"), "Default keyboard movement prompt must be recognizable")
	input_manager.last_device_id = "controller"
	_assert(str(input_manager.get_action_prompt("interact")) == "A", "Controller interact prompt must use A")
	_assert(str(input_manager.get_movement_prompt()).contains("STICK"), "Controller movement prompt must identify the stick")
	input_manager.last_device_id = "keyboard"


func _test_tutorial_flow() -> void:
	var tutorial = root.get_node_or_null("TutorialManager")
	_assert(tutorial != null, "Tutorial manager must be registered")
	if tutorial == null:
		return
	_game_state.reset_progression()
	_game_state.clear_flags()
	_game_state.current_level_id = "level_01"
	_game_state.current_room_id = "arrival"
	_game_state.spawn_point = "start"
	tutorial.begin_new_game_sequence()
	_assert(tutorial.mode == "intro_card" and paused, "New game must pause on the controls card")
	tutorial.call("_on_confirmed")
	_assert(tutorial.mode == "waiting_opening" and not paused, "Controls confirmation must release the opening cutscene")
	tutorial.call("_on_cutscene_completed", "opening_arrival", false)
	_assert(tutorial.mode == "overworld_movement", "Opening completion must begin movement training")
	var actor := Node2D.new()
	root.add_child(actor)
	tutorial.set("_tracked_node", actor)
	tutorial.set("_tracked_start", Vector2.ZERO)
	actor.position = Vector2(25, 0)
	tutorial.call("_process", 0.016)
	_assert(tutorial.mode == "overworld_interaction", "Movement training must require actual displacement")
	tutorial.notify_interaction_completed(actor)
	_assert(_game_state.get_flag("tutorial_overworld_completed"), "First interaction must persist overworld tutorial completion")
	actor.queue_free()

	_game_state.set_flag("tutorial_battle_completed", false)
	tutorial.begin_battle_command_tutorial("poojan_strength_test")
	_assert(tutorial.mode == "battle_commands" and paused, "Poojan must pause for command instruction")
	tutorial.call("_on_confirmed")
	var soul := Node2D.new()
	root.add_child(soul)
	tutorial.begin_battle_enemy_tutorial("poojan_strength_test", soul)
	_assert(tutorial.mode == "battle_enemy" and paused, "Poojan's first enemy phase must pause for dodge instruction")
	tutorial.call("_on_confirmed")
	soul.position = Vector2(9, 0)
	tutorial.call("_process", 0.016)
	_assert(_game_state.get_flag("tutorial_battle_completed") and not paused, "Soul movement must persist battle tutorial completion")
	soul.queue_free()


func _test_satyaki_resolution_routes() -> void:
	var packed := load("res://scenes/battle/battle_scene.tscn") as PackedScene
	_assert(packed != null, "Battle scene must load for Satyaki regression")
	if packed == null:
		return
	for route in ["strength", "resonance"]:
		_game_state.set_flag("satyaki_tirumal_defeated", false)
		_game_state.pending_encounter_id = "satyaki_tirumal_boss"
		var battle = packed.instantiate()
		root.add_child(battle)
		await process_frame
		_assert(battle.active_encounter_id == "satyaki_tirumal_boss", "Satyaki encounter must start for %s route" % route)
		battle.battle_resolution = route
		battle.resolve_battle(false)
		_assert(_game_state.get_flag("satyaki_tirumal_defeated"), "Satyaki %s route must unlock progression" % route)
		battle.queue_free()
		await process_frame


func _test_complete_level_chain() -> void:
	_game_state.reset_progression()
	_game_state.clear_flags()
	_game_state.set_flag("tutorial_overworld_completed", true)
	_game_state.set_flag("tutorial_battle_completed", true)
	var transitions := [
		{"source": "level_01", "room": "satyaki_waterfront", "boss": "satyaki_tirumal_defeated", "target": "level_02", "target_room": "suburb"},
		{"source": "level_02", "room": "mayor_complex", "boss": "deepak_reddy_defeated", "target": "level_03", "target_room": "forest_entrance"},
		{"source": "level_03", "room": "ankit_gate", "boss": "ankit_defeated", "target": "level_04", "target_room": "pun_street"},
		{"source": "level_04", "room": "mayor_stage", "boss": "mitta_defeated", "target": "level_05", "target_room": "ruined_boulevard"}
	]
	var level_manager = root.get_node_or_null("LevelManager")
	_assert(level_manager != null, "Central level manager must be registered")
	if level_manager == null:
		return
	for transition in transitions:
		_game_state.current_level_id = str(transition.source)
		_game_state.current_room_id = str(transition.room)
		_game_state.spawn_point = "from_boss"
		_game_state.set_flag(str(transition.boss), true)
		_save_system.save_game(str(transition.source), "from_boss", str(transition.room))
		var error: Error = level_manager.transition_to_level(str(transition.target))
		_assert(error == OK, "%s to %s transition must succeed" % [transition.source, transition.target])
		await process_frame
		await process_frame
		_assert(_game_state.current_level_id == transition.target, "Transition must update current level to %s" % transition.target)
		_assert(_game_state.current_room_id == transition.target_room, "Transition must use %s start room" % transition.target)
		_assert(_game_state.spawn_point == "start", "Transition must use the canonical start spawn")
		_assert(_game_state.get_flag("%s_completed" % transition.source), "%s completion flag must persist" % transition.source)
		var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(_save_system.save_path))
		_assert(typeof(saved) == TYPE_DICTIONARY and str(saved.get("level_id", "")) == transition.target, "Save must commit %s before scene change" % transition.target)
	_game_state.current_level_id = "level_01"
	_game_state.current_room_id = "arrival"
	var loaded: Dictionary = _save_system.load_game()
	_assert(str(loaded.get("level_id", "")) == "level_05" and _game_state.current_level_id == "level_05", "Continue must restore Level 5 after the complete chain")
	var level_one_rooms := _load_json("res://data/rooms/level_01_rooms.json")
	var waterfront: Dictionary = (level_one_rooms.get("rooms", {}) as Dictionary).get("satyaki_waterfront", {})
	var has_legacy_safe_exit := false
	for exit_value in waterfront.get("exits", []):
		var exit_data: Dictionary = exit_value
		has_legacy_safe_exit = has_legacy_safe_exit or (str(exit_data.get("target_level_id", "")) == "level_02" and (exit_data.get("required_flags", []) as Array).has("satyaki_tirumal_defeated"))
	_assert(has_legacy_safe_exit, "Existing post-Satyaki saves must expose the automatic Level 2 exit")


func _prepare_temporary_save() -> void:
	_assert(_save_system != null and _game_state != null, "Save and game state autoloads must exist")
	if _save_system == null:
		return
	_original_save_paths = [_save_system.save_path, _save_system.backup_path, _save_system.temporary_path]
	_save_system.save_path = "user://pass71_save.json"
	_save_system.backup_path = "user://pass71_save.backup.json"
	_save_system.temporary_path = "user://pass71_save.tmp.json"
	_save_system.clear_save()


func _cleanup_temporary_save() -> void:
	if _save_system == null:
		return
	_save_system.clear_save()
	_save_system.save_path = _original_save_paths[0]
	_save_system.backup_path = _original_save_paths[1]
	_save_system.temporary_path = _original_save_paths[2]
	paused = false


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
