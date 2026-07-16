extends Node

const AUDIO_CATALOG_PATH := "res://data/audio/audio_catalog.json"
const STORY_MUSIC_ID := "literally_my_life"
const STORY_COMPLETE_FLAG := "srmt_defeated"

const LEGACY_SFX_PATHS := {
	"ui_select": "res://assets/shared/audio/ui_select.wav",
	"save_chime": "res://assets/shared/audio/save_chime.wav",
	"encounter_start": "res://assets/shared/audio/encounter_start.wav"
}

const WEAPON_SFX := {
	"": "ui_select",
	"revolver": "revolver",
	"banana_gun": "banana_gun",
	"berry_potions": "berry_potion",
	"musical_guitar": "guitar_note"
}

var _players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _catalog: Dictionary = {}
var _stream_cache: Dictionary = {}
var _story_music_active := false
var last_sfx_id := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_catalog()
	_ensure_players()
	_ensure_music_player()
	var game_state := get_tree().root.get_node_or_null("GameState")
	if game_state != null and game_state.has_signal("story_flag_changed"):
		var callback := Callable(self, "_on_story_flag_changed")
		if not game_state.is_connected("story_flag_changed", callback):
			game_state.connect("story_flag_changed", callback)
	_publish_web_diagnostics()
	call_deferred("sync_story_music")


func get_audio_catalog() -> Dictionary:
	if _catalog.is_empty():
		_load_catalog()
	return _catalog.duplicate(true)


func play_sfx(sfx_id: String) -> bool:
	if not _is_known_sfx(sfx_id):
		return false
	last_sfx_id = sfx_id
	if DisplayServer.get_name() == "headless":
		_publish_web_diagnostics()
		return true
	_ensure_players()
	var stream := _load_stream(sfx_id)
	if stream == null:
		return false
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
	var player := _get_available_player()
	if player == null:
		return false
	player.stream = stream
	player.play()
	_publish_web_diagnostics()
	return true


func play_story_music() -> bool:
	if _is_story_complete():
		stop_story_music()
		return false
	_story_music_active = true
	if DisplayServer.get_name() == "headless":
		_publish_web_diagnostics()
		return true
	_ensure_music_player()
	if _music_player == null:
		return false
	var stream := _load_stream(STORY_MUSIC_ID)
	if stream == null:
		return false
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	_music_player.stream = stream
	if not _music_player.playing:
		_music_player.play()
	_publish_web_diagnostics()
	return true


func stop_story_music() -> void:
	_story_music_active = false
	if _music_player != null:
		_music_player.stop()
	_publish_web_diagnostics()


func sync_story_music() -> void:
	if _is_story_complete():
		stop_story_music()
	else:
		play_story_music()


func is_story_music_playing() -> bool:
	if DisplayServer.get_name() == "headless":
		return _story_music_active
	return _story_music_active and _music_player != null and _music_player.playing


func play_birthday_cheer() -> bool:
	return play_sfx("children_yay")


func play_weapon_sfx(weapon_id: String) -> bool:
	return play_sfx(str(WEAPON_SFX.get(weapon_id, "ui_select")))


func play_boss_hurt() -> bool:
	return play_sfx("boss_hurt")


func play_boss_defeat() -> bool:
	return play_sfx("boss_defeat")


func play_clue_pickup() -> bool:
	return play_sfx("clue_pickup")


func play_growth_transform() -> bool:
	return play_sfx("growth_transform")


func play_ui_select() -> bool:
	return play_sfx("ui_select")


func play_save_chime() -> bool:
	return play_sfx("save_chime")


func play_encounter_start() -> bool:
	return play_sfx("encounter_start")


func has_continuous_audio_player() -> bool:
	return is_story_music_playing()


func _load_catalog() -> void:
	_catalog.clear()
	for id in LEGACY_SFX_PATHS:
		_catalog[id] = {
			"type": "sfx",
			"path": LEGACY_SFX_PATHS[id],
			"loop": false,
			"description": "Shared interface SFX."
		}
	if not FileAccess.file_exists(AUDIO_CATALOG_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(AUDIO_CATALOG_PATH))
	if typeof(data) != TYPE_DICTIONARY:
		return
	for id in data:
		var entry: Dictionary = data[id]
		var entry_type := str(entry.get("type", ""))
		if entry_type not in ["sfx", "music"]:
			continue
		entry = entry.duplicate(true)
		entry["loop"] = entry_type == "music" and str(id) == STORY_MUSIC_ID
		_catalog[id] = entry


func _ensure_players() -> void:
	if not _players.is_empty():
		return
	for index in range(8):
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%s" % index
		player.bus = "SFX"
		add_child(player)
		_players.append(player)


func _ensure_music_player() -> void:
	if _music_player != null and is_instance_valid(_music_player):
		return
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "StoryMusic"
	_music_player.bus = "Music"
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_player)


func _is_known_sfx(audio_id: String) -> bool:
	if _catalog.is_empty():
		_load_catalog()
	return _catalog.has(audio_id) and str(_catalog[audio_id].get("type", "")) == "sfx"


func _load_stream(audio_id: String) -> AudioStream:
	if _stream_cache.has(audio_id):
		return _stream_cache[audio_id]
	if not _catalog.has(audio_id):
		return null
	var path := str(_catalog[audio_id].get("path", ""))
	if path.is_empty():
		return null
	var stream: AudioStream = ResourceLoader.load(path) as AudioStream if ResourceLoader.exists(path) else null
	if stream == null and path.ends_with(".wav"):
		stream = AudioStreamWAV.load_from_file(path)
	if stream != null:
		_stream_cache[audio_id] = stream
	return stream


func _get_available_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	return _players[0] if not _players.is_empty() else null


func _is_story_complete() -> bool:
	var game_state := get_tree().root.get_node_or_null("GameState") if is_inside_tree() else null
	if game_state != null and game_state.has_method("get_flag") and game_state.get_flag(STORY_COMPLETE_FLAG):
		return true
	var save_system := get_tree().root.get_node_or_null("SaveSystem") if is_inside_tree() else null
	return save_system != null \
		and save_system.has_method("has_saved_flag") \
		and save_system.has_saved_flag(STORY_COMPLETE_FLAG)


func _on_story_flag_changed(flag_name: String, value: bool) -> void:
	if flag_name != STORY_COMPLETE_FLAG:
		return
	if value:
		stop_story_music()
	else:
		sync_story_music()


func _publish_web_diagnostics() -> void:
	if not OS.has_feature("web"):
		return
	var payload := JSON.stringify({
		"mode": "single-story-loop",
		"continuousPlayers": 1 if is_story_music_playing() else 0,
		"storyMusicPlaying": is_story_music_playing(),
		"lastSfxId": last_sfx_id,
		"sfxEntries": _count_catalog_entries("sfx"),
		"musicEntries": _count_catalog_entries("music")
	})
	JavaScriptBridge.eval("window.__shrugameAudioDiagnostics = %s" % payload, true)


func _count_catalog_entries(entry_type: String) -> int:
	var count := 0
	for entry in _catalog.values():
		if str((entry as Dictionary).get("type", "")) == entry_type:
			count += 1
	return count
