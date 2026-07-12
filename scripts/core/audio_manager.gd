extends Node

const AUDIO_CATALOG_PATH := "res://data/audio/audio_catalog.json"

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
var _catalog: Dictionary = {}
var _stream_cache: Dictionary = {}
var last_sfx_id := ""


func _ready() -> void:
	_load_catalog()
	_ensure_players()
	_publish_web_diagnostics()


func get_audio_catalog() -> Dictionary:
	if _catalog.is_empty():
		_load_catalog()
	return _catalog.duplicate(true)


func play_sfx(sfx_id: String) -> bool:
	if not _is_known_sfx(sfx_id):
		return false
	last_sfx_id = sfx_id
	if DisplayServer.get_name() == "headless":
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
	return true


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
	for child in get_children():
		if child is AudioStreamPlayer and (child as AudioStreamPlayer).playing:
			var stream := (child as AudioStreamPlayer).stream
			if stream is AudioStreamWAV and (stream as AudioStreamWAV).loop_mode != AudioStreamWAV.LOOP_DISABLED:
				return true
	return false


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
		if str(entry.get("type", "")) != "sfx":
			continue
		entry = entry.duplicate(true)
		entry["loop"] = false
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


func _publish_web_diagnostics() -> void:
	if not OS.has_feature("web"):
		return
	var payload := JSON.stringify({
		"mode": "sfx-only",
		"continuousPlayers": 0,
		"sfxEntries": _catalog.size()
	})
	JavaScriptBridge.eval("window.__shrugameAudioDiagnostics = %s" % payload, true)
