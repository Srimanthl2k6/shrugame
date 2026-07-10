extends SceneTree

const REQUIRED_LEVELS := ["level_01", "level_02", "level_03", "level_04", "level_05"]
const REQUIRED_GEAR := ["revolver", "banana_gun", "berry_potions", "musical_guitar"]
const REQUIRED_CLUES := ["divorce_records", "165_files", "berry_contract", "hospital_records", "mansion_court_clues"]
const REQUIRED_BOSSES := ["poojan", "satyaki_tirumal", "nitin", "deepak_reddy", "niggesh_nishal", "ankit", "doctor_sushan", "mitta", "suhas", "srmt"]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_characters(failures)
	_check_items(failures)
	_check_gear(failures)
	_check_clues(failures)
	_check_level_configs(failures)
	_check_game_state_fields(failures)
	_check_save_fields(failures)

	if failures.is_empty():
		print("PASS: Ishiville Pass 3 smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_characters(failures: Array[String]) -> void:
	var data := _load_dict("res://data/characters/characters.json", failures)
	if data.is_empty():
		return
	for character_id in ["shrububu", "ishiyoga", "srmt"] + REQUIRED_BOSSES:
		if not data.has(character_id):
			failures.append("characters.json missing %s" % character_id)
			continue
		var entry: Dictionary = data[character_id]
		for key in ["display_name", "role", "level_id", "dialogue_state_ids"]:
			if not entry.has(key):
				failures.append("character %s missing %s" % [character_id, key])


func _check_items(failures: Array[String]) -> void:
	var data := _load_dict("res://data/items/items.json", failures)
	if data.is_empty():
		return
	for item_id in ["kfc_popcorn_box", "gummies", "kfc_bucket"]:
		if not data.has(item_id):
			failures.append("items.json missing %s" % item_id)
			continue
		var item: Dictionary = data[item_id]
		for key in ["display_name", "type", "description"]:
			if not item.has(key):
				failures.append("item %s missing %s" % [item_id, key])


func _check_gear(failures: Array[String]) -> void:
	var data := _load_dict("res://data/gear/gear.json", failures)
	if data.is_empty():
		return
	for gear_id in REQUIRED_GEAR:
		if not data.has(gear_id):
			failures.append("gear.json missing %s" % gear_id)
			continue
		var gear: Dictionary = data[gear_id]
		for key in ["display_name", "weapon_type", "unlock_level", "battle_use", "story_use"]:
			if not gear.has(key):
				failures.append("gear %s missing %s" % [gear_id, key])


func _check_clues(failures: Array[String]) -> void:
	var data := _load_dict("res://data/clues/clues.json", failures)
	if data.is_empty():
		return
	for clue_id in REQUIRED_CLUES:
		if not data.has(clue_id):
			failures.append("clues.json missing %s" % clue_id)
			continue
		var clue: Dictionary = data[clue_id]
		for key in ["display_name", "level_id", "summary", "unlocks"]:
			if not clue.has(key):
				failures.append("clue %s missing %s" % [clue_id, key])


func _check_level_configs(failures: Array[String]) -> void:
	for level_id in REQUIRED_LEVELS:
		var data := _load_dict("res://data/levels/%s_config.json" % level_id, failures)
		if data.is_empty():
			continue
		for key in ["area_name", "intro_event", "mini_boss_id", "main_boss_id", "reward_gear_id", "clue_ids", "growth_stage_unlock", "town_state_after_defeat"]:
			if not data.has(key):
				failures.append("%s config missing %s" % [level_id, key])


func _check_game_state_fields(failures: Array[String]) -> void:
	var game_state: Node = root.get_node_or_null("GameState")
	if game_state == null:
		failures.append("GameState autoload missing")
		return
	for field_name in ["growth_stage", "inventory", "gear", "clues", "defeated_bosses", "current_weapon"]:
		if game_state.get(field_name) == null:
			failures.append("GameState missing field %s" % field_name)


func _check_save_fields(failures: Array[String]) -> void:
	var game_state: Node = root.get_node_or_null("GameState")
	var save_system: Node = root.get_node_or_null("SaveSystem")
	if game_state == null or save_system == null:
		return
	for field_name in ["growth_stage", "inventory", "gear", "clues", "defeated_bosses", "current_weapon"]:
		if game_state.get(field_name) == null:
			return

	save_system.save_path = "user://ishiville_pass3_save.json"
	save_system.clear_save()
	game_state.growth_stage = 3
	game_state.inventory = {"kfc_popcorn_box": 1}
	game_state.gear = {"revolver": true, "banana_gun": true}
	game_state.clues = {"165_files": true}
	game_state.defeated_bosses = {"deepak_reddy": true}
	game_state.current_weapon = "banana_gun"

	if not save_system.save_game("level_02", "lab_exit"):
		failures.append("SaveSystem failed to write pass 3 progression save")
		return

	game_state.growth_stage = 1
	game_state.inventory = {}
	game_state.gear = {}
	game_state.clues = {}
	game_state.defeated_bosses = {}
	game_state.current_weapon = ""
	save_system.load_game()

	if game_state.growth_stage != 3:
		failures.append("SaveSystem did not restore growth_stage")
	if game_state.inventory.get("kfc_popcorn_box", 0) != 1:
		failures.append("SaveSystem did not restore inventory")
	if not game_state.gear.get("banana_gun", false):
		failures.append("SaveSystem did not restore gear")
	if not game_state.clues.get("165_files", false):
		failures.append("SaveSystem did not restore clues")
	if not game_state.defeated_bosses.get("deepak_reddy", false):
		failures.append("SaveSystem did not restore defeated_bosses")
	if game_state.current_weapon != "banana_gun":
		failures.append("SaveSystem did not restore current_weapon")
	save_system.clear_save()


func _load_dict(path: String, failures: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(path):
		failures.append("missing data file %s" % path)
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		failures.append("%s must parse as a dictionary" % path)
		return {}
	return data
