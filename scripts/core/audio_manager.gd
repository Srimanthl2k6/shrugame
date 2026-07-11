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
var _music_player: AudioStreamPlayer
var _catalog: Dictionary = {}
var _stream_cache: Dictionary = {}
var current_music_id: String = ""
var last_sfx_id: String = ""
var _music_tween: Tween


func _ready() -> void:
	_load_catalog()
	_ensure_players()


func get_audio_catalog() -> Dictionary:
	if _catalog.is_empty():
		_load_catalog()
	return _catalog.duplicate(true)


func play_music(music_id: String, fade_seconds: float = 0.35) -> bool:
	if not _is_known_audio_id(music_id, "music"):
		return false
	if music_id == current_music_id and _music_player != null and _music_player.playing:
		return true
	current_music_id = music_id
	if DisplayServer.get_name() == "headless":
		return true
	_ensure_players()
	var stream := _load_stream(music_id)
	if stream == null:
		return false
	_configure_loop(stream, music_id)
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	if _music_player.playing and fade_seconds > 0.0:
		_music_tween = create_tween()
		_music_tween.tween_property(_music_player, "volume_db", -36.0, fade_seconds * 0.5)
		_music_tween.tween_callback(_start_music_stream.bind(stream))
		_music_tween.tween_property(_music_player, "volume_db", 0.0, fade_seconds * 0.5)
	else:
		_start_music_stream(stream)
	return true


func stop_music() -> void:
	current_music_id = ""
	if _music_player != null:
		_music_player.stop()


func duck_music(duration: float = 0.35, amount_db: float = -8.0) -> void:
	if _music_player == null or not _music_player.playing:
		return
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", amount_db, 0.06)
	_music_tween.tween_interval(maxf(duration, 0.05))
	_music_tween.tween_property(_music_player, "volume_db", 0.0, 0.18)


func play_sfx(sfx_id: String) -> bool:
	if not _is_known_audio_id(sfx_id, "sfx"):
		return false
	last_sfx_id = sfx_id
	if DisplayServer.get_name() == "headless":
		return true
	_ensure_players()
	var stream := _load_stream(sfx_id)
	if stream == null:
		return false
	var player := _get_available_player()
	if player == null:
		return false
	player.stream = stream
	player.play()
	if sfx_id in ["building_break", "boss_defeat", "growth_transform"]:
		duck_music(0.4, -10.0)
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


func _load_catalog() -> void:
	_catalog.clear()
	for id in LEGACY_SFX_PATHS.keys():
		_catalog[id] = {
			"type": "sfx",
			"path": LEGACY_SFX_PATHS[id],
			"loop": false,
			"description": "Legacy shared SFX."
		}
	if FileAccess.file_exists(AUDIO_CATALOG_PATH):
		var data = JSON.parse_string(FileAccess.get_file_as_string(AUDIO_CATALOG_PATH))
		if typeof(data) == TYPE_DICTIONARY:
			for id in data.keys():
				_catalog[id] = data[id]


func _ensure_players() -> void:
	if _music_player == null:
		_music_player = AudioStreamPlayer.new()
		_music_player.name = "MusicPlayer"
		_music_player.bus = "Music"
		add_child(_music_player)
	if not _players.is_empty():
		return
	for index in range(8):
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%s" % index
		player.bus = "SFX"
		add_child(player)
		_players.append(player)


func _is_known_audio_id(audio_id: String, expected_type: String) -> bool:
	if _catalog.is_empty():
		_load_catalog()
	if not _catalog.has(audio_id):
		return false
	if expected_type.is_empty():
		return true
	var entry: Dictionary = _catalog[audio_id]
	return str(entry.get("type", "")) == expected_type


func _load_stream(audio_id: String) -> AudioStream:
	if _stream_cache.has(audio_id):
		return _stream_cache[audio_id]
	if not _catalog.has(audio_id):
		return null
	var entry: Dictionary = _catalog[audio_id]
	var path := str(entry.get("path", ""))
	if path.is_empty():
		return null
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = ResourceLoader.load(path) as AudioStream
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


func _start_music_stream(stream: AudioStream) -> void:
	_music_player.stream = stream
	_music_player.volume_db = -36.0 if _music_player.playing else 0.0
	_music_player.play()


func _configure_loop(stream: AudioStream, music_id: String) -> void:
	if not bool(_catalog.get(music_id, {}).get("loop", false)):
		return
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = maxi(1, int(wav.get_length() * wav.mix_rate))
