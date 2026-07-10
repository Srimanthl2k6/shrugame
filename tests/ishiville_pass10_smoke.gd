extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_level_config(failures)
	_check_level_scene(failures)
	_check_dialogue(failures)
	_check_encounters_and_final_gate(failures)
	_check_ending(failures)

	if failures.is_empty():
		print("PASS: Ishiville Pass 10 smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_level_config(failures: Array[String]) -> void:
	var config := _load_dict("res://data/levels/level_05_config.json", failures)
	if config.get("area_name", "") != "Area 111":
		failures.append("Level 5 config area must be Area 111")
	if config.get("mini_boss_id", "") != "suhas":
		failures.append("Level 5 config mini boss must be Suhas")
	if config.get("main_boss_id", "") != "srmt":
		failures.append("Level 5 config main boss must be SRMT")
	if config.get("reward_gear_id", "") != "musical_guitar":
		failures.append("Level 5 config reward gear must be musical_guitar")
	if not Array(config.get("clue_ids", [])).has("mansion_court_clues"):
		failures.append("Level 5 config must include mansion_court_clues")


func _check_level_scene(failures: Array[String]) -> void:
	var scene := load("res://scenes/levels/level_05.tscn")
	if scene == null:
		failures.append("Level 5 scene failed to load")
		return
	var level: Node = scene.instantiate()
	root.add_child(level)
	for node_path in [
		"World/PinkRuins",
		"World/GummiesPub",
		"World/SuhasBarFight",
		"World/BikeReward",
		"World/GuitarReward",
		"World/FallenMansion",
		"World/MansionCourtClues",
		"World/RuinedCourt",
		"World/SRMTBoss",
		"World/KfcDungeon",
		"World/IshiYogaCell",
		"World/TransitionDoor",
		"World/Nulla",
		"World/Objective",
		"World/PracticeEncounter",
		"UiLayer/ObjectiveTracker",
		"UiLayer/ClueJournal"
	]:
		if level.get_node_or_null(node_path) == null:
			failures.append("Level 5 scene missing %s" % node_path)
	var guitar = level.get_node_or_null("World/GuitarReward")
	if guitar != null and guitar.get("gear_id") != "musical_guitar":
		failures.append("GuitarReward must unlock musical_guitar")
	var clues = level.get_node_or_null("World/MansionCourtClues")
	if clues != null and clues.get("clue_id") != "mansion_court_clues":
		failures.append("MansionCourtClues must collect mansion_court_clues")
	var srmt = level.get_node_or_null("World/SRMTBoss")
	if srmt != null:
		var required_flags: PackedStringArray = srmt.get("required_flags")
		for flag_name in ["suhas_defeated", "musical_guitar_unlocked", "mansion_court_clues_collected"]:
			if not required_flags.has(flag_name):
				failures.append("SRMTBoss missing required flag %s" % flag_name)
	level.queue_free()


func _check_dialogue(failures: Array[String]) -> void:
	var dialogue := _load_dict("res://data/dialogue/level_05_dialogue.json", failures)
	for dialogue_id in ["nulla_intro", "nulla_after_battle", "pub_gummies", "suhas_intro", "guitar_reward", "mansion_court_clues", "srmt_intro", "srmt_defeat", "ishiyoga_rescue"]:
		if not dialogue.has(dialogue_id):
			failures.append("Level 5 dialogue missing %s" % dialogue_id)
	var text := JSON.stringify(dialogue)
	for phrase in ["Shrububu", "Area 111", "Gummies", "Suhas", "musical guitar", "SRMT", "IshiYoga", "KFC"]:
		if not text.contains(phrase):
			failures.append("Level 5 dialogue missing canon phrase %s" % phrase)


func _check_encounters_and_final_gate(failures: Array[String]) -> void:
	var encounters := _load_dict("res://data/encounters/level_05_encounters.json", failures)
	for encounter_id in ["suhas_bar_fight", "srmt_final_boss"]:
		if not encounters.has(encounter_id):
			failures.append("Level 5 encounters missing %s" % encounter_id)
	if not encounters.has("suhas_bar_fight") or not encounters.has("srmt_final_boss"):
		return
	var suhas: Dictionary = encounters["suhas_bar_fight"]
	if suhas.get("boss_type", "") != "mini_boss":
		failures.append("Suhas encounter must be mini_boss")
	if suhas.get("reward_gear", "") != "musical_guitar":
		failures.append("Suhas encounter must reward musical_guitar")
	var srmt: Dictionary = encounters["srmt_final_boss"]
	if srmt.get("boss_type", "") != "final_boss":
		failures.append("SRMT encounter must be final_boss")
	if srmt.get("required_weapon", "") != "musical_guitar":
		failures.append("SRMT encounter must require musical_guitar")
	if srmt.get("defeated_flag", "") != "srmt_defeated":
		failures.append("SRMT encounter must set srmt_defeated")

	var scene := load("res://scenes/battle/battle_scene.tscn")
	var battle: Node = scene.instantiate()
	root.add_child(battle)
	var game_state: Node = root.get_node_or_null("GameState")
	if game_state != null:
		game_state.reset_progression()
	if battle.start_encounter("srmt_final_boss"):
		failures.append("SRMT final boss should not start without musical_guitar")
	if game_state != null:
		game_state.unlock_gear("musical_guitar")
		game_state.equip_weapon("musical_guitar")
	if battle.start_encounter("srmt_final_boss"):
		battle.enemy_hp = 1
		battle.choose_command("act")
		if game_state != null and not game_state.get_flag("srmt_defeated"):
			failures.append("SRMT defeat did not set srmt_defeated")
	else:
		failures.append("BattleManager could not start SRMT after musical_guitar")
	battle.queue_free()


func _check_ending(failures: Array[String]) -> void:
	var text := FileAccess.get_file_as_string("res://scenes/ending.tscn")
	for phrase in ["IshiYoga", "KFC", "Ishiville"]:
		if not text.contains(phrase):
			failures.append("Ending scene missing %s" % phrase)


func _load_dict(path: String, failures: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(path):
		failures.append("missing data file %s" % path)
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		failures.append("%s must parse as a dictionary" % path)
		return {}
	return data
