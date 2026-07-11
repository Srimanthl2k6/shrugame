extends Node

signal setting_changed(key: String, value)

const DEFAULT_SETTINGS_PATH := "user://settings.json"
const DEFAULT_SETTINGS_TEMP_PATH := "user://settings.tmp.json"
const DEFAULT_SETTINGS_BACKUP_PATH := "user://settings.backup.json"
const DEFAULTS := {
	"master_volume": 0.85,
	"music_volume": 0.72,
	"sfx_volume": 0.9,
	"fullscreen": false,
	"screen_shake": true,
	"flash_reduction": false,
	"text_speed": 1.0,
	"show_objectives": true,
	"high_contrast_bullets": false,
	"hold_to_skip": true
}

var settings: Dictionary = DEFAULTS.duplicate(true)
var settings_path := DEFAULT_SETTINGS_PATH
var settings_temporary_path := DEFAULT_SETTINGS_TEMP_PATH
var settings_backup_path := DEFAULT_SETTINGS_BACKUP_PATH


func _ready() -> void:
	load_settings()
	apply_all()


func get_setting(key: String, fallback = null):
	if settings.has(key):
		return settings[key]
	if DEFAULTS.has(key):
		return DEFAULTS[key]
	return fallback


func set_setting(key: String, value, persist: bool = true) -> bool:
	if not DEFAULTS.has(key):
		return false
	settings[key] = value
	_apply_setting(key, value)
	setting_changed.emit(key, value)
	if persist:
		save_settings()
	return true


func reset_defaults() -> void:
	settings = DEFAULTS.duplicate(true)
	apply_all()
	save_settings()
	for key in settings.keys():
		setting_changed.emit(str(key), settings[key])


func load_settings() -> bool:
	settings = DEFAULTS.duplicate(true)
	var data = _load_settings_dictionary(settings_path)
	if data.is_empty():
		data = _load_settings_dictionary(settings_backup_path)
	if data.is_empty():
		return false
	for key in DEFAULTS.keys():
		if data.has(key):
			settings[key] = data[key]
	return true


func save_settings() -> bool:
	var file := FileAccess.open(settings_temporary_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(settings, "\t"))
	file.flush()
	file = null
	return _commit_settings()


func _commit_settings() -> bool:
	var target := ProjectSettings.globalize_path(settings_path)
	var temporary := ProjectSettings.globalize_path(settings_temporary_path)
	var backup := ProjectSettings.globalize_path(settings_backup_path)
	if FileAccess.file_exists(settings_backup_path):
		DirAccess.remove_absolute(backup)
	if FileAccess.file_exists(settings_path) and DirAccess.rename_absolute(target, backup) != OK:
		return false
	if DirAccess.rename_absolute(temporary, target) == OK:
		return true
	if FileAccess.file_exists(settings_backup_path):
		DirAccess.rename_absolute(backup, target)
	return false


func _load_settings_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var parsed = parser.data
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func apply_all() -> void:
	for key in settings.keys():
		_apply_setting(str(key), settings[key])


func _apply_setting(key: String, value) -> void:
	match key:
		"master_volume":
			_set_bus_volume("Master", float(value))
		"music_volume":
			_set_bus_volume("Music", float(value))
		"sfx_volume":
			_set_bus_volume("SFX", float(value))
		"fullscreen":
			_apply_fullscreen(bool(value))


func _set_bus_volume(bus_name: String, linear_volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var safe_volume := clampf(linear_volume, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_index, safe_volume <= 0.001)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(safe_volume, 0.001)))


func _apply_fullscreen(enabled: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var target_mode := DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != target_mode:
		DisplayServer.window_set_mode(target_mode)
