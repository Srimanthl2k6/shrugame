extends Node

const SAVE_SCHEMA_VERSION := 4

const LEVEL_SCENES := {
	"level_01": "res://scenes/levels/districts/level_01.tscn",
	"level_02": "res://scenes/levels/districts/level_02.tscn",
	"level_03": "res://scenes/levels/districts/level_03.tscn",
	"level_04": "res://scenes/levels/districts/level_04.tscn",
	"level_05": "res://scenes/levels/districts/level_05.tscn"
}

# Strong references keep string-selected district scenes available in Web exports.
const LEVEL_PACKED_SCENES := {
	"level_01": preload("res://scenes/levels/districts/level_01.tscn"),
	"level_02": preload("res://scenes/levels/districts/level_02.tscn"),
	"level_03": preload("res://scenes/levels/districts/level_03.tscn"),
	"level_04": preload("res://scenes/levels/districts/level_04.tscn"),
	"level_05": preload("res://scenes/levels/districts/level_05.tscn")
}

var save_path := "user://savegame.json"
var backup_path := "user://savegame.backup.json"
var temporary_path := "user://savegame.tmp.json"
var _migration_rewrite_required := false


func save_game(level_id: String, spawn_point: String = "default", room_id: String = "") -> bool:
	var flags := {}
	var growth_stage := 1
	var inventory := {}
	var gear := {}
	var clues := {}
	var defeated_bosses := {}
	var current_weapon := ""
	var current_objective := ""
	var difficulty_id := "shrububu"
	var resolved_room_id := room_id
	var playtime_seconds := 0.0
	var difficulty_locked := true
	var save_created_unix := int(Time.get_unix_time_from_system())
	var game_state := _get_game_state()
	if game_state != null:
		flags = game_state.story_flags.duplicate(true)
		growth_stage = game_state.growth_stage
		inventory = game_state.inventory.duplicate(true)
		gear = game_state.gear.duplicate(true)
		clues = game_state.clues.duplicate(true)
		defeated_bosses = game_state.defeated_bosses.duplicate(true)
		current_weapon = game_state.current_weapon
		current_objective = game_state.current_objective
		difficulty_id = game_state.difficulty_id
		if resolved_room_id.is_empty():
			resolved_room_id = str(game_state.current_room_id)
		playtime_seconds = float(game_state.playtime_seconds)
		difficulty_locked = bool(game_state.difficulty_locked)
		save_created_unix = int(game_state.save_created_unix)
	if resolved_room_id.is_empty():
		resolved_room_id = _default_room_for_level(level_id)

	var data := {
		"schema_version": SAVE_SCHEMA_VERSION,
		"level_id": level_id,
		"room_id": resolved_room_id,
		"spawn_point": spawn_point,
		"playtime_seconds": playtime_seconds,
		"story_flags": flags,
		"growth_stage": growth_stage,
		"inventory": inventory,
		"gear": gear,
		"clues": clues,
		"defeated_bosses": defeated_bosses,
		"current_weapon": current_weapon,
		"current_objective": current_objective,
		"difficulty_id": difficulty_id,
		"difficulty_locked": difficulty_locked,
		"save_created_unix": save_created_unix,
		"last_saved_unix": int(Time.get_unix_time_from_system())
	}

	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	file = null
	return _commit_temporary_save()


func load_game() -> Dictionary:
	_migration_rewrite_required = false
	var data = _read_save_candidate(save_path)
	if data.is_empty():
		data = _load_backup()
		if data.is_empty():
			return {}
	data = _migrate_save_data(data)
	if not _is_valid_save_data(data):
		return {}

	var game_state := _get_game_state()
	if game_state != null:
		game_state.current_level_id = str(data.get("level_id", game_state.current_level_id))
		game_state.current_room_id = str(data.get("room_id", _default_room_for_level(game_state.current_level_id)))
		game_state.spawn_point = str(data.get("spawn_point", game_state.spawn_point))
		game_state.schema_version = int(data.get("schema_version", SAVE_SCHEMA_VERSION))
		game_state.playtime_seconds = float(data.get("playtime_seconds", 0.0))
		if data.has("story_flags") and typeof(data["story_flags"]) == TYPE_DICTIONARY:
			game_state.story_flags = data["story_flags"].duplicate(true)
		game_state.growth_stage = int(data.get("growth_stage", game_state.growth_stage))
		if data.has("inventory") and typeof(data["inventory"]) == TYPE_DICTIONARY:
			game_state.inventory = data["inventory"].duplicate(true)
		if data.has("gear") and typeof(data["gear"]) == TYPE_DICTIONARY:
			game_state.gear = data["gear"].duplicate(true)
		if data.has("clues") and typeof(data["clues"]) == TYPE_DICTIONARY:
			game_state.clues = data["clues"].duplicate(true)
		if data.has("defeated_bosses") and typeof(data["defeated_bosses"]) == TYPE_DICTIONARY:
			game_state.defeated_bosses = data["defeated_bosses"].duplicate(true)
		game_state.current_weapon = str(data.get("current_weapon", game_state.current_weapon))
		game_state.current_objective = str(data.get("current_objective", game_state.current_objective))
		var loaded_difficulty := str(data.get("difficulty_id", "shrububu"))
		if game_state.has_method("set_difficulty"):
			game_state.set_difficulty(loaded_difficulty, true)
		else:
			game_state.difficulty_id = loaded_difficulty
		game_state.difficulty_locked = bool(data.get("difficulty_locked", true))
		game_state.save_created_unix = int(data.get("save_created_unix", 0))
		if game_state.has_method("rebuild_defeated_bosses_from_flags"):
			game_state.rebuild_defeated_bosses_from_flags()
	if _migration_rewrite_required:
		var migrated_level := str(data.get("level_id", "level_01"))
		var migrated_room := str(data.get("room_id", _default_room_for_level(migrated_level)))
		var migrated_spawn := str(data.get("spawn_point", "start"))
		if not save_game(migrated_level, migrated_spawn, migrated_room):
			push_warning("Loaded a migrated save, but could not rewrite it atomically.")
		_migration_rewrite_required = false
	return data


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func new_game(selected_difficulty_id: String = "shrububu") -> void:
	clear_save()
	var game_state := _get_game_state()
	if game_state == null:
		return
	game_state.reset_progression()
	game_state.current_level_id = "level_01"
	game_state.current_room_id = "arrival"
	game_state.spawn_point = "start"
	game_state.pending_encounter_id = "marn_practice"
	if game_state.has_method("set_difficulty"):
		game_state.set_difficulty(selected_difficulty_id, true)
	else:
		game_state.difficulty_id = selected_difficulty_id
	game_state.clear_flags()
	game_state.add_item("kfc_popcorn_box", 1)
	game_state.set_current_objective("Find KFC in Divorcee Harbour.")
	game_state.lock_difficulty()
	save_game("level_01", "start", "arrival")


func get_level_scene_path(level_id: String) -> String:
	return str(LEVEL_SCENES.get(level_id, LEVEL_SCENES["level_01"]))


func get_level_scene(level_id: String) -> PackedScene:
	return LEVEL_PACKED_SCENES.get(level_id, LEVEL_PACKED_SCENES["level_01"]) as PackedScene


func clear_save() -> void:
	for path in [save_path, backup_path, temporary_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _commit_temporary_save() -> bool:
	var absolute_save := ProjectSettings.globalize_path(save_path)
	var absolute_backup := ProjectSettings.globalize_path(backup_path)
	var absolute_temporary := ProjectSettings.globalize_path(temporary_path)
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(absolute_backup)
	if FileAccess.file_exists(save_path):
		if DirAccess.rename_absolute(absolute_save, absolute_backup) != OK:
			return false
	var error := DirAccess.rename_absolute(absolute_temporary, absolute_save)
	if error != OK:
		if FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(absolute_backup, absolute_save)
		return false
	return true


func _load_backup() -> Dictionary:
	return _read_save_candidate(backup_path)


func _read_save_candidate(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var parsed = parser.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var candidate: Dictionary = parsed
	return candidate if _is_valid_save_data(candidate, true) else {}


func _is_valid_save_data(data: Dictionary, allow_legacy: bool = false) -> bool:
	var level_id := str(data.get("level_id", ""))
	if not LEVEL_SCENES.has(level_id):
		return false
	if not allow_legacy and int(data.get("schema_version", 0)) != SAVE_SCHEMA_VERSION:
		return false
	for key in ["story_flags", "inventory", "gear", "clues", "defeated_bosses"]:
		if data.has(key) and typeof(data[key]) != TYPE_DICTIONARY:
			return false
	var difficulty_id := str(data.get("difficulty_id", "shrububu"))
	return difficulty_id in ["shrububu", "srmt"]


func _migrate_save_data(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	var original_schema := int(migrated.get("schema_version", 0))
	var level_id := str(migrated.get("level_id", "level_01"))
	if not migrated.has("schema_version"):
		migrated["schema_version"] = SAVE_SCHEMA_VERSION
	if not migrated.has("room_id") or str(migrated["room_id"]).is_empty():
		migrated["room_id"] = _default_room_for_level(level_id)
	if not migrated.has("playtime_seconds"):
		migrated["playtime_seconds"] = 0.0
	migrated["schema_version"] = SAVE_SCHEMA_VERSION
	if not migrated.has("difficulty_locked"):
		migrated["difficulty_locked"] = true
	if not migrated.has("save_created_unix"):
		migrated["save_created_unix"] = int(Time.get_unix_time_from_system())
	if not migrated.has("last_saved_unix"):
		migrated["last_saved_unix"] = migrated["save_created_unix"]
	for dictionary_key in ["story_flags", "inventory", "gear", "clues", "defeated_bosses"]:
		if not migrated.has(dictionary_key) or typeof(migrated[dictionary_key]) != TYPE_DICTIONARY:
			migrated[dictionary_key] = {}
	var flags: Dictionary = migrated["story_flags"]
	var clues: Dictionary = migrated["clues"]
	var read_legacy_hospital_map := bool(flags.get("hospital_map_collected", false)) \
		or bool(flags.get("clue_hospital_map_seen", false)) \
		or bool(clues.get("hospital_map", false))
	if read_legacy_hospital_map and not bool(flags.get("hospital_records_collected", false)):
		flags["hospital_records_collected"] = true
		clues["hospital_records"] = true
		if level_id == "level_04" and not bool(flags.get("doctor_sushan_defeated", false)):
			migrated["current_objective"] = "Walk right into the Pattern Serum ward and confront Doctor Sushan."
		_migration_rewrite_required = true
	if original_schema != SAVE_SCHEMA_VERSION:
		_migration_rewrite_required = true
	return migrated


func _default_room_for_level(level_id: String) -> String:
	var defaults := {
		"level_01": "arrival",
		"level_02": "suburb",
		"level_03": "forest_entrance",
		"level_04": "pun_street",
		"level_05": "ruined_boulevard"
	}
	return str(defaults.get(level_id, "arrival"))


func _get_game_state() -> Node:
	if is_inside_tree():
		return get_tree().root.get_node_or_null("GameState")
	return null
