extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := _load_json("res://data/audio/audio_catalog.json")
	_assert(catalog.size() >= 12, "SFX catalog must cover UI, weapons, bosses, clues, and transitions")
	for audio_id in catalog:
		var entry: Dictionary = catalog[audio_id]
		var path := str(entry.get("path", ""))
		_assert(str(entry.get("type", "")) == "sfx", "%s must be an SFX entry" % audio_id)
		_assert(not bool(entry.get("loop", true)), "%s must never loop" % audio_id)
		_assert(load(path) is AudioStream, "%s SFX must import" % audio_id)
	_assert(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("res://assets/shared/audio/music")), "Continuous music assets must not ship")
	var bus_layout_text := FileAccess.get_file_as_string("res://default_bus_layout.tres")
	_assert(not bus_layout_text.contains("&\"Music\""), "Music bus must be removed")
	_assert(bus_layout_text.contains("&\"SFX\""), "SFX bus must remain")
	var audio_manager := root.get_node_or_null("AudioManager")
	_assert(audio_manager != null and not audio_manager.has_continuous_audio_player(), "Audio manager must have no continuous player")
	_assert(audio_manager != null and audio_manager.play_ui_select(), "UI SFX must remain playable")
	var settings := root.get_node_or_null("SettingsManager")
	for key in ["master_volume", "sfx_volume", "flash_reduction", "screen_shake", "high_contrast_bullets"]:
		_assert(settings != null and settings.DEFAULTS.has(key), "Settings must expose %s" % key)
	_assert(settings != null and not settings.DEFAULTS.has("music_volume"), "Obsolete music setting must be ignored")
	_finish("Pass 64 SFX-only audio and game-feel contract")


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
