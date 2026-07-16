extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := _load_json("res://data/audio/audio_catalog.json")
	_assert(catalog.size() >= 14, "Audio catalog must cover the story track, birthday cheer, and gameplay SFX")
	var music_entries := 0
	for audio_id in catalog:
		var entry: Dictionary = catalog[audio_id]
		var path := str(entry.get("path", ""))
		var entry_type := str(entry.get("type", ""))
		_assert(entry_type in ["sfx", "music"], "%s must use a supported audio type" % audio_id)
		if entry_type == "music":
			music_entries += 1
			_assert(str(audio_id) == "literally_my_life" and bool(entry.get("loop", false)), "Only literally_my_life may loop")
		else:
			_assert(not bool(entry.get("loop", true)), "%s SFX must never loop" % audio_id)
		_assert(load(path) is AudioStream, "%s audio resource must import" % audio_id)
	_assert(music_entries == 1, "Exactly one looping music entry must ship")
	var bus_layout_text := FileAccess.get_file_as_string("res://default_bus_layout.tres")
	_assert(bus_layout_text.contains("&\"Music\""), "The story track needs a Music bus routed to Master")
	_assert(bus_layout_text.contains("&\"SFX\""), "SFX bus must remain")
	var audio_manager := root.get_node_or_null("AudioManager")
	var save_system := root.get_node_or_null("SaveSystem")
	var game_state := root.get_node_or_null("GameState")
	var original_paths := [save_system.save_path, save_system.backup_path, save_system.temporary_path]
	save_system.save_path = "user://pass64_save.json"
	save_system.backup_path = "user://pass64_save.backup.json"
	save_system.temporary_path = "user://pass64_save.tmp.json"
	save_system.clear_save()
	game_state.set_flag("srmt_defeated", false)
	audio_manager.sync_story_music()
	_assert(audio_manager != null and audio_manager.is_story_music_playing(), "The single story track must play before SRMT is defeated")
	_assert(audio_manager.has_continuous_audio_player(), "The story track must be the one continuous player")
	_assert(audio_manager != null and audio_manager.play_ui_select(), "UI SFX must remain playable")
	_assert(audio_manager.play_birthday_cheer(), "Birthday cheer must remain a one-shot SFX")
	game_state.set_flag("srmt_defeated", true)
	_assert(not audio_manager.is_story_music_playing(), "SRMT's defeat must stop story music immediately")
	save_system.save_game("level_05", "from_mansion", "ruined_court")
	game_state.set_flag("srmt_defeated", false)
	audio_manager.sync_story_music()
	_assert(not audio_manager.is_story_music_playing(), "A completed saved game must keep story music stopped on launch")
	save_system.new_game("shrububu")
	_assert(audio_manager.is_story_music_playing(), "New Game must restart story music from the beginning")
	save_system.clear_save()
	save_system.save_path = original_paths[0]
	save_system.backup_path = original_paths[1]
	save_system.temporary_path = original_paths[2]
	var settings := root.get_node_or_null("SettingsManager")
	for key in ["master_volume", "sfx_volume", "flash_reduction", "screen_shake", "high_contrast_bullets"]:
		_assert(settings != null and settings.DEFAULTS.has(key), "Settings must expose %s" % key)
	_assert(settings != null and not settings.DEFAULTS.has("music_volume"), "Obsolete music setting must be ignored")
	_finish("Pass 64 single story track and SFX game-feel contract")


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
