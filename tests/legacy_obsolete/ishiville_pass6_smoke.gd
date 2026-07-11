extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_level_config(failures)
	_check_level_scene(failures)
	_check_dialogue(failures)
	_check_encounters_and_rewards(failures)
	_check_interaction_progression_fields(failures)

	if failures.is_empty():
		print("PASS: Ishiville Pass 6 smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_level_config(failures: Array[String]) -> void:
	var config := _load_dict("res://data/levels/level_01_config.json", failures)
	if config.get("area_name", "") != "Divorcee Harbour":
		failures.append("Level 1 config area must be Divorcee Harbour")
	if config.get("mini_boss_id", "") != "poojan":
		failures.append("Level 1 config mini boss must be Poojan")
	if config.get("main_boss_id", "") != "satyaki_tirumal":
		failures.append("Level 1 config main boss must be Satyaki Tirumal")
	if config.get("reward_gear_id", "") != "revolver":
		failures.append("Level 1 config reward gear must be revolver")
	if int(config.get("growth_stage_unlock", 0)) != 2:
		failures.append("Level 1 config must unlock growth stage 2")


func _check_level_scene(failures: Array[String]) -> void:
	var scene := load("res://scenes/levels/level_01.tscn")
	if scene == null:
		failures.append("Level 1 scene failed to load")
		return
	var level: Node = scene.instantiate()
	root.add_child(level)
	for node_path in [
		"World/KfcDoor",
		"World/BrokenChickenBuilding",
		"World/SheriffPoojan",
		"World/DivorceRecords",
		"World/SatyakiApproach",
		"World/SatyakiBoss",
		"World/TransitionDoor",
		"UiLayer/ObjectiveTracker",
		"UiLayer/ClueJournal"
	]:
		if level.get_node_or_null(node_path) == null:
			failures.append("Level 1 scene missing %s" % node_path)
	var transition = level.get_node_or_null("World/TransitionDoor")
	if transition != null:
		var required_flags: PackedStringArray = transition.get("required_flags")
		for flag_name in ["poojan_defeated", "divorce_records_collected", "satyaki_tirumal_defeated"]:
			if not required_flags.has(flag_name):
				failures.append("Level 1 transition missing required flag %s" % flag_name)
	level.queue_free()


func _check_dialogue(failures: Array[String]) -> void:
	var dialogue := _load_dict("res://data/dialogue/level_01_dialogue.json", failures)
	for dialogue_id in ["opening_not_kfc", "resident_satyaki_clue", "poojan_intro", "poojan_after", "satyaki_intro", "satyaki_defeat"]:
		if not dialogue.has(dialogue_id):
			failures.append("Level 1 dialogue missing %s" % dialogue_id)
	var text := JSON.stringify(dialogue)
	for required_word in ["Shrububu", "KFC", "Poojan", "Satyaki"]:
		if not text.contains(required_word):
			failures.append("Level 1 dialogue missing canon word %s" % required_word)


func _check_encounters_and_rewards(failures: Array[String]) -> void:
	var encounters := _load_dict("res://data/encounters/level_01_encounters.json", failures)
	for encounter_id in ["poojan_strength_test", "satyaki_tirumal_boss"]:
		if not encounters.has(encounter_id):
			failures.append("Level 1 encounters missing %s" % encounter_id)
	if not encounters.has("poojan_strength_test") or not encounters.has("satyaki_tirumal_boss"):
		return
	var poojan: Dictionary = encounters["poojan_strength_test"]
	if poojan.get("boss_type", "") != "mini_boss":
		failures.append("Poojan encounter must be mini_boss")
	if poojan.get("reward_gear", "") != "revolver":
		failures.append("Poojan encounter must reward revolver")
	if poojan.get("defeated_flag", "") != "poojan_defeated":
		failures.append("Poojan encounter must set poojan_defeated")
	var satyaki: Dictionary = encounters["satyaki_tirumal_boss"]
	if satyaki.get("boss_type", "") != "main_boss":
		failures.append("Satyaki encounter must be main_boss")
	if int(satyaki.get("growth_stage_reward", 0)) != 2:
		failures.append("Satyaki encounter must reward growth stage 2")
	if satyaki.get("defeated_flag", "") != "satyaki_tirumal_defeated":
		failures.append("Satyaki encounter must set satyaki_tirumal_defeated")

	var scene := load("res://scenes/battle/battle_scene.tscn")
	var battle: Node = scene.instantiate()
	root.add_child(battle)
	var game_state: Node = root.get_node_or_null("GameState")
	if game_state != null:
		game_state.reset_progression()
		game_state.unlock_gear("revolver")
	if battle.start_encounter("satyaki_tirumal_boss"):
		battle.enemy_hp = 1
		battle.choose_command("act")
		if game_state != null:
			if game_state.get_growth_stage() != 2:
				failures.append("Satyaki defeat did not apply growth stage 2")
			if not game_state.get_flag("satyaki_tirumal_defeated"):
				failures.append("Satyaki defeat did not set defeated flag")
	else:
		failures.append("BattleManager could not start satyaki_tirumal_boss")
	battle.queue_free()


func _check_interaction_progression_fields(failures: Array[String]) -> void:
	var interaction: Area2D = load("res://scripts/overworld/interaction_area.gd").new()
	for property_name in ["clue_id", "item_id", "item_amount", "gear_id", "growth_stage_on_interact", "objective_text"]:
		if interaction.get(property_name) == null:
			failures.append("InteractionArea missing progression field %s" % property_name)
	interaction.free()


func _load_dict(path: String, failures: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(path):
		failures.append("missing data file %s" % path)
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		failures.append("%s must parse as a dictionary" % path)
		return {}
	return data
