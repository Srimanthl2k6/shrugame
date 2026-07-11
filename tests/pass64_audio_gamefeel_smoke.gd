extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := _load_json("res://data/audio/audio_catalog.json")
	_assert(catalog.size() >= 20, "Audio catalog must cover music, UI, weapons, bosses, clues, and transitions")
	var music_count := 0
	for audio_id in catalog:
		var entry: Dictionary = catalog[audio_id]
		var path := str(entry.get("path", ""))
		var stream := load(path) as AudioStream
		_assert(stream != null, "%s audio must import" % audio_id)
		if str(entry.get("type", "")) == "music":
			music_count += 1
			_assert(bool(entry.get("loop", false)), "%s music must loop" % audio_id)
			if stream != null:
				_assert(stream.get_length() >= 10.0, "%s music loop is too short" % audio_id)
	_assert(music_count >= 9, "Release requires title, five districts, boss, SRMT, and ending music")
	_assert(ResourceLoader.exists("res://default_bus_layout.tres"), "Audio bus layout is missing")
	var settings := root.get_node_or_null("SettingsManager")
	for key in ["master_volume", "music_volume", "sfx_volume", "flash_reduction", "screen_shake", "high_contrast_bullets"]:
		_assert(settings != null and settings.DEFAULTS.has(key), "Settings must expose %s" % key)
	_finish("Pass 64 audio and game-feel contract")


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
