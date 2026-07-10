extends Node

var story_flags: Dictionary = {}
var current_level_id := "level_01"
var spawn_point := "start"
var pending_encounter_id := "marn_practice"
var growth_stage := 1
var inventory: Dictionary = {}
var gear: Dictionary = {}
var clues: Dictionary = {}
var defeated_bosses: Dictionary = {}
var current_weapon := ""
var current_objective := ""


func set_flag(flag_name: String, value: bool = true) -> void:
	if flag_name.is_empty():
		return
	story_flags[flag_name] = value
	if flag_name.ends_with("_defeated"):
		if value:
			defeated_bosses[flag_name] = true
		else:
			defeated_bosses.erase(flag_name)


func get_flag(flag_name: String, default_value: bool = false) -> bool:
	return story_flags.get(flag_name, default_value)


func clear_flags() -> void:
	story_flags.clear()
	defeated_bosses.clear()


func reset_progression() -> void:
	growth_stage = 1
	inventory.clear()
	gear.clear()
	clues.clear()
	defeated_bosses.clear()
	current_weapon = ""
	current_objective = ""


func add_item(item_id: String, amount: int = 1) -> int:
	if item_id.is_empty() or amount <= 0:
		return get_item_count(item_id)
	inventory[item_id] = get_item_count(item_id) + amount
	return int(inventory[item_id])


func consume_item(item_id: String, amount: int = 1) -> bool:
	if item_id.is_empty() or amount <= 0:
		return false
	var count := get_item_count(item_id)
	if count < amount:
		return false
	var next_count := count - amount
	if next_count <= 0:
		inventory.erase(item_id)
	else:
		inventory[item_id] = next_count
	return true


func get_item_count(item_id: String) -> int:
	return int(inventory.get(item_id, 0))


func unlock_gear(gear_id: String, equip_if_empty: bool = true) -> bool:
	if gear_id.is_empty():
		return false
	gear[gear_id] = true
	if equip_if_empty and current_weapon.is_empty():
		current_weapon = gear_id
	return true


func has_gear(gear_id: String) -> bool:
	return bool(gear.get(gear_id, false))


func equip_weapon(gear_id: String) -> bool:
	if not has_gear(gear_id):
		return false
	current_weapon = gear_id
	return true


func collect_clue(clue_id: String) -> bool:
	if clue_id.is_empty():
		return false
	clues[clue_id] = true
	set_flag("%s_collected" % clue_id, true)
	return true


func has_clue(clue_id: String) -> bool:
	return bool(clues.get(clue_id, false))


func mark_boss_defeated(defeated_flag: String) -> void:
	set_flag(defeated_flag, true)


func is_boss_defeated(defeated_flag: String) -> bool:
	return bool(defeated_bosses.get(defeated_flag, false))


func rebuild_defeated_bosses_from_flags() -> void:
	for flag_name in story_flags.keys():
		if str(flag_name).ends_with("_defeated") and bool(story_flags[flag_name]):
			defeated_bosses[str(flag_name)] = true


func get_collected_clue_ids() -> Array[String]:
	var ids: Array[String] = []
	for clue_id in clues.keys():
		if bool(clues[clue_id]):
			ids.append(str(clue_id))
	ids.sort()
	return ids


func set_growth_stage(stage: int) -> void:
	growth_stage = int(clamp(stage, 1, 5))


func get_growth_stage() -> int:
	return growth_stage


func get_growth_scale() -> float:
	var scales := {
		1: 1.0,
		2: 1.08,
		3: 1.16,
		4: 1.28,
		5: 1.4
	}
	return float(scales.get(growth_stage, 1.0))


func apply_growth_to_node(node: Node) -> void:
	node.set_meta("growth_stage", growth_stage)
	if node is Node2D:
		var node_2d := node as Node2D
		node_2d.scale = Vector2.ONE * get_growth_scale()


func set_current_objective(objective_text: String) -> void:
	current_objective = objective_text.strip_edges()


func get_current_objective() -> String:
	return current_objective


func update_objective_from_level(level_id: String = "") -> String:
	if not level_id.is_empty():
		current_level_id = level_id
	var config := _load_json_dict("res://data/levels/%s_config.json" % current_level_id)
	if config.is_empty():
		set_current_objective("Find KFC.")
		return current_objective

	var area_name := str(config.get("area_name", current_level_id))
	var clue_ids: Array = config.get("clue_ids", [])
	var missing_clue := ""
	for clue_id in clue_ids:
		if not has_clue(str(clue_id)):
			missing_clue = str(clue_id)
			break
	var reward_gear_id := str(config.get("reward_gear_id", ""))

	if not missing_clue.is_empty():
		set_current_objective("Explore %s and find the next clue." % area_name)
	elif not reward_gear_id.is_empty() and not has_gear(reward_gear_id):
		set_current_objective("Challenge the boss of %s." % area_name)
	else:
		set_current_objective("Leave %s and keep searching for KFC." % area_name)
	return current_objective


func _load_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data
