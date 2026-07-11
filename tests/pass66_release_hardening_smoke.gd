extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_save_recovery_and_migration()
	_test_input_and_settings_recovery()
	_test_electron_security_contract()
	_finish("Pass 66 save and Electron hardening")


func _test_save_recovery_and_migration() -> void:
	var save_system = root.get_node_or_null("SaveSystem")
	var game_state = root.get_node_or_null("GameState")
	_assert(save_system != null and game_state != null, "Save hardening requires autoloads")
	if save_system == null or game_state == null:
		return
	var original_paths := [save_system.save_path, save_system.backup_path, save_system.temporary_path]
	save_system.save_path = "user://pass66_save.json"
	save_system.backup_path = "user://pass66_save.backup.json"
	save_system.temporary_path = "user://pass66_save.tmp.json"
	save_system.clear_save()
	save_system.new_game("shrububu")
	_assert(game_state.difficulty_locked, "Difficulty must lock when a save starts")
	_assert(not game_state.set_difficulty("srmt"), "Difficulty must not change after save creation")
	game_state.current_room_id = "records_alley"
	game_state.playtime_seconds = 321.5
	game_state.collect_clue("divorce_records")
	game_state.unlock_gear("revolver")
	game_state.equip_weapon("revolver")
	game_state.add_item("berry_potion", 2)
	_assert(save_system.save_game("level_01", "from_docks", "records_alley"), "First progression save must commit")
	_assert(save_system.save_game("level_01", "from_docks", "records_alley"), "Second progression save must produce a backup")
	var corrupt := FileAccess.open(save_system.save_path, FileAccess.WRITE)
	corrupt.store_string("{ definitely not valid json")
	corrupt = null
	game_state.reset_progression()
	var recovered: Dictionary = save_system.load_game()
	_assert(not recovered.is_empty(), "Corrupt primary save must recover from backup")
	_assert(game_state.current_room_id == "records_alley", "Recovered save must restore room")
	_assert(game_state.has_clue("divorce_records") and game_state.has_gear("revolver"), "Recovered save must restore clue and gear")
	_assert(game_state.playtime_seconds >= 321.0, "Recovered save must restore playtime")

	save_system.clear_save()
	var legacy := FileAccess.open(save_system.save_path, FileAccess.WRITE)
	legacy.store_string(JSON.stringify({"level_id": "level_03", "spawn_point": "default", "story_flags": {}, "difficulty_id": "shrububu"}))
	legacy = null
	var migrated: Dictionary = save_system.load_game()
	_assert(int(migrated.get("schema_version", 0)) == 3, "Legacy save must migrate to schema 3")
	_assert(str(migrated.get("room_id", "")) == "forest_entrance", "Legacy save must recover a valid default room")
	save_system.clear_save()
	save_system.save_path = original_paths[0]
	save_system.backup_path = original_paths[1]
	save_system.temporary_path = original_paths[2]
	await process_frame


func _test_input_and_settings_recovery() -> void:
	var input_manager = root.get_node_or_null("InputManager")
	var settings_manager = root.get_node_or_null("SettingsManager")
	_assert(input_manager != null and settings_manager != null, "Input/settings hardening requires autoloads")
	if input_manager == null or settings_manager == null:
		return
	var input_paths := [input_manager.bindings_path, input_manager.bindings_temporary_path, input_manager.bindings_backup_path]
	input_manager.bindings_path = "user://pass66_input.json"
	input_manager.bindings_temporary_path = "user://pass66_input.tmp.json"
	input_manager.bindings_backup_path = "user://pass66_input.backup.json"
	input_manager.reset_bindings()
	_assert(input_manager.save_bindings(), "Input bindings must save atomically")
	_assert(input_manager.rebind_key("interact", KEY_F), "Interact key must be remappable")
	var bad_input := FileAccess.open(input_manager.bindings_path, FileAccess.WRITE)
	bad_input.store_string("invalid")
	bad_input = null
	_assert(input_manager.load_bindings(), "Input bindings must recover from backup")
	input_manager.reset_bindings()
	input_manager.bindings_path = input_paths[0]
	input_manager.bindings_temporary_path = input_paths[1]
	input_manager.bindings_backup_path = input_paths[2]

	var setting_paths := [settings_manager.settings_path, settings_manager.settings_temporary_path, settings_manager.settings_backup_path]
	settings_manager.settings_path = "user://pass66_settings.json"
	settings_manager.settings_temporary_path = "user://pass66_settings.tmp.json"
	settings_manager.settings_backup_path = "user://pass66_settings.backup.json"
	for path in [settings_manager.settings_path, settings_manager.settings_temporary_path, settings_manager.settings_backup_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	settings_manager.settings = settings_manager.DEFAULTS.duplicate(true)
	_assert(settings_manager.save_settings(), "Settings must save atomically")
	settings_manager.set_setting("flash_reduction", true)
	var bad_settings := FileAccess.open(settings_manager.settings_path, FileAccess.WRITE)
	bad_settings.store_string("invalid")
	bad_settings = null
	_assert(settings_manager.load_settings(), "Settings must recover from backup")
	_assert(not bool(settings_manager.get_setting("flash_reduction")), "Settings recovery must restore last valid backup")
	for path in [settings_manager.settings_path, settings_manager.settings_temporary_path, settings_manager.settings_backup_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	settings_manager.settings_path = setting_paths[0]
	settings_manager.settings_temporary_path = setting_paths[1]
	settings_manager.settings_backup_path = setting_paths[2]


func _test_electron_security_contract() -> void:
	var main_text := FileAccess.get_file_as_string("res://electron/main.cjs")
	var preload_text := FileAccess.get_file_as_string("res://electron/preload.cjs")
	var renderer_text := FileAccess.get_file_as_string("res://electron/renderer/index.html")
	for requirement in ["contextIsolation: true", "nodeIntegration: false", "sandbox: true", "setPermissionRequestHandler", "onBeforeRequest"]:
		_assert(main_text.contains(requirement), "Electron security contract is missing %s" % requirement)
	_assert(renderer_text.contains("Content-Security-Policy"), "Electron renderer needs a strict CSP")
	for api_name in ["getVersion", "getPlatform", "isFullscreen", "toggleFullscreen", "openExternal", "quit"]:
		_assert(preload_text.contains(api_name), "Safe preload API is missing %s" % api_name)
	_assert(not preload_text.contains("require: "), "Preload must not expose require")
	_assert(not preload_text.contains("readFile"), "Preload must not expose filesystem access")


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
