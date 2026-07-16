extends SceneTree

const STORY_MUSIC_PATH := "res://assets/shared/audio/music/literally_my_life.mp3"
const BIRTHDAY_CHEER_PATH := "res://assets/shared/audio/sfx/children_yay.mp3"
const BIRTHDAY_PHOTO_PATH := "res://assets/shared/ending/shrubudday.jpeg"

var failures: Array[String] = []
var _save_system
var _game_state
var _audio_manager
var _original_save_paths: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_save_system = root.get_node_or_null("SaveSystem")
	_game_state = root.get_node_or_null("GameState")
	_audio_manager = root.get_node_or_null("AudioManager")
	_prepare_temporary_save()
	_test_media_contract()
	await _test_music_lifecycle_and_battle_outcomes()
	_test_ending_controls_and_photo()
	_test_electron_quit_contract()
	_cleanup_temporary_save()
	_finish("Pass 78 final media, ending controls, and desktop Quit")


func _test_media_contract() -> void:
	for path in [STORY_MUSIC_PATH, BIRTHDAY_CHEER_PATH, BIRTHDAY_PHOTO_PATH]:
		_assert(FileAccess.file_exists(path), "%s must exist in its normalized runtime path" % path)
	_assert(load(STORY_MUSIC_PATH) is AudioStreamMP3, "Story music MP3 must import")
	_assert(load(BIRTHDAY_CHEER_PATH) is AudioStreamMP3, "Birthday cheer MP3 must import")
	var photo := load(BIRTHDAY_PHOTO_PATH) as Texture2D
	_assert(photo != null and photo.get_width() == 1194 and photo.get_height() == 1600, "Birthday photo must import at 1194x1600")
	var catalog := _load_json("res://data/audio/audio_catalog.json")
	var music: Dictionary = catalog.get("literally_my_life", {})
	var cheer: Dictionary = catalog.get("children_yay", {})
	_assert(str(music.get("type", "")) == "music" and bool(music.get("loop", false)), "The Nightcore track must be the one looping music entry")
	_assert(str(cheer.get("type", "")) == "sfx" and not bool(cheer.get("loop", true)), "Children Yay must be a one-shot SFX")
	var manifest := FileAccess.get_file_as_string("res://scripts/core/runtime_resource_manifest.gd")
	for path in [STORY_MUSIC_PATH, BIRTHDAY_CHEER_PATH, BIRTHDAY_PHOTO_PATH]:
		_assert(manifest.contains(path), "%s must be strongly referenced for Web export" % path)
	var site_files := _read_tree_text("res://site")
	_assert(not site_files.to_lower().contains("shrubudday"), "The private birthday photo must not appear in website media")


func _test_music_lifecycle_and_battle_outcomes() -> void:
	_assert(_audio_manager != null and _game_state != null and _save_system != null, "Audio, state, and save autoloads must exist")
	if _audio_manager == null or _game_state == null or _save_system == null:
		return
	_game_state.reset_progression()
	_game_state.clear_flags()
	_game_state.unlock_gear("musical_guitar")
	_game_state.equip_weapon("musical_guitar")
	_audio_manager.sync_story_music()
	_assert(_audio_manager.is_story_music_playing(), "Story music must begin before SRMT is defeated")

	var battle_scene := load("res://scenes/battle/battle_scene.tscn") as PackedScene
	_assert(battle_scene != null, "Battle scene must load for both SRMT outcomes")
	if battle_scene != null:
		for route in ["strength", "resonance"]:
			_game_state.set_flag("srmt_defeated", false)
			_audio_manager.sync_story_music()
			_game_state.pending_encounter_id = "srmt_final_boss"
			var battle = battle_scene.instantiate()
			root.add_child(battle)
			await process_frame
			_assert(battle.active_encounter_id == "srmt_final_boss", "SRMT encounter must start for the %s route" % route)
			battle.battle_resolution = route
			battle.resolve_battle(false)
			_assert(_game_state.get_flag("srmt_defeated"), "The %s route must set srmt_defeated" % route)
			_assert(not _audio_manager.is_story_music_playing(), "The %s route must stop story music immediately" % route)
			battle.queue_free()
			await process_frame

	_assert(_save_system.save_game("level_05", "from_mansion", "ruined_court"), "Completed state must save")
	_game_state.set_flag("srmt_defeated", false)
	_audio_manager.sync_story_music()
	_assert(_save_system.has_saved_flag("srmt_defeated"), "Read-only saved-flag query must find SRMT completion")
	_assert(not _audio_manager.is_story_music_playing(), "Completed saves must launch without story music")
	_save_system.new_game("shrububu")
	_assert(_audio_manager.is_story_music_playing(), "New Game must clear completion and restart the track")


func _test_ending_controls_and_photo() -> void:
	var packed := load("res://scenes/ending.tscn") as PackedScene
	_assert(packed != null, "Ending scene must load")
	if packed == null:
		return
	var ending = packed.instantiate()
	var photo := ending.get_node_or_null("BirthdayPhoto") as TextureRect
	var hint := ending.get_node_or_null("ContinueHint") as Label
	_assert(photo != null and photo.texture != null, "Ending must show Shrubudday.jpeg")
	_assert(photo != null and photo.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "Birthday photo must remain completely visible without cropping")
	_assert(photo != null and photo.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "Birthday photo must use linear filtering")
	_assert(hint != null and hint.text == "ENTER / ESC: TITLE", "Ending hint must describe the repaired navigation")
	for action in ["interact", "ui_accept", "ui_cancel"]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = true
		_assert(ending.call("_is_title_return_event", event), "%s must return from the birthday scene" % action)
	var unrelated := InputEventAction.new()
	unrelated.action = "move_left"
	unrelated.pressed = true
	_assert(not ending.call("_is_title_return_event", unrelated), "Movement must not dismiss the birthday scene")
	var controller_text := FileAccess.get_file_as_string("res://scripts/core/ending_controller.gd")
	_assert(not controller_text.contains("create_timer(1.2)"), "Ending input must use a release latch, not a fixed delay")
	_assert(controller_text.contains('change_scene_to_file("res://scenes/main.tscn")'), "All ending actions must route to the title")
	ending.free()


func _test_electron_quit_contract() -> void:
	var menu := FileAccess.get_file_as_string("res://scripts/core/main_menu.gd")
	var preload_text := FileAccess.get_file_as_string("res://electron/preload.cjs")
	var main := FileAccess.get_file_as_string("res://electron/main.cjs")
	_assert(menu.contains("window.parent.shrugameDesktop"), "Web Quit must call the Electron preload API")
	_assert(menu.contains("desktop.quit()"), "Web Quit must invoke the secure quit command")
	_assert(menu.contains("get_tree().quit()"), "Native Godot Quit fallback must remain")
	_assert(preload_text.contains('quit: () => ipcRenderer.send("app:quit")'), "Preload must expose only the quit IPC command")
	_assert(main.contains('ipcMain.on("app:quit"') and main.contains("app.quit()"), "Electron main must terminate on app:quit")


func _prepare_temporary_save() -> void:
	if _save_system == null:
		return
	_original_save_paths = [_save_system.save_path, _save_system.backup_path, _save_system.temporary_path]
	_save_system.save_path = "user://pass78_save.json"
	_save_system.backup_path = "user://pass78_save.backup.json"
	_save_system.temporary_path = "user://pass78_save.tmp.json"
	_save_system.clear_save()


func _cleanup_temporary_save() -> void:
	if _save_system == null:
		return
	_audio_manager.stop_story_music()
	_save_system.clear_save()
	_save_system.save_path = _original_save_paths[0]
	_save_system.backup_path = _original_save_paths[1]
	_save_system.temporary_path = _original_save_paths[2]
	paused = false


func _read_tree_text(root_path: String) -> String:
	var result := ""
	var paths: Array[String] = [root_path]
	while not paths.is_empty():
		var current: String = paths.pop_back()
		var directory: DirAccess = DirAccess.open(current)
		if directory == null:
			continue
		directory.list_dir_begin()
		var entry: String = directory.get_next()
		while not entry.is_empty():
			var child: String = current.path_join(entry)
			if directory.current_is_dir():
				paths.append(child)
			elif entry.get_extension().to_lower() in ["html", "css", "js", "ts", "json", "txt", "md"]:
				result += FileAccess.get_file_as_string(child)
			entry = directory.get_next()
		directory.list_dir_end()
	return result


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
