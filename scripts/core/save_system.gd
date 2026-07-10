extends Node

const LEVEL_SCENES := {
	"level_01": "res://scenes/levels/level_01.tscn",
	"level_02": "res://scenes/levels/level_02.tscn",
	"level_03": "res://scenes/levels/level_03.tscn",
	"level_04": "res://scenes/levels/level_04.tscn",
	"level_05": "res://scenes/levels/level_05.tscn"
}

var save_path := "user://savegame.json"


func save_game(level_id: String, spawn_point: String = "default") -> bool:
	var flags := {}
	var growth_stage := 1
	var inventory := {}
	var gear := {}
	var clues := {}
	var defeated_bosses := {}
	var current_weapon := ""
	var current_objective := ""
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

	var data := {
		"level_id": level_id,
		"spawn_point": spawn_point,
		"story_flags": flags,
		"growth_stage": growth_stage,
		"inventory": inventory,
		"gear": gear,
		"clues": clues,
		"defeated_bosses": defeated_bosses,
		"current_weapon": current_weapon,
		"current_objective": current_objective
	}

	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


func load_game() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {}

	var data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if typeof(data) != TYPE_DICTIONARY:
		return {}

	var game_state := _get_game_state()
	if game_state != null:
		game_state.current_level_id = str(data.get("level_id", game_state.current_level_id))
		game_state.spawn_point = str(data.get("spawn_point", game_state.spawn_point))
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
		if game_state.has_method("rebuild_defeated_bosses_from_flags"):
			game_state.rebuild_defeated_bosses_from_flags()
	return data


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func new_game() -> void:
	clear_save()
	var game_state := _get_game_state()
	if game_state == null:
		return
	game_state.current_level_id = "level_01"
	game_state.spawn_point = "start"
	game_state.pending_encounter_id = "marn_practice"
	game_state.clear_flags()
	game_state.reset_progression()
	game_state.add_item("kfc_popcorn_box", 1)
	game_state.set_current_objective("Find KFC in Divorcee Harbour.")


func get_level_scene_path(level_id: String) -> String:
	return str(LEVEL_SCENES.get(level_id, LEVEL_SCENES["level_01"]))


func clear_save() -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


func _get_game_state() -> Node:
	if is_inside_tree():
		return get_tree().root.get_node_or_null("GameState")
	return null
