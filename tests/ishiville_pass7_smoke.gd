extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_level_config(failures)
	_check_level_scene(failures)
	_check_dialogue(failures)
	_check_encounters_and_rewards(failures)

	if failures.is_empty():
		print("PASS: Ishiville Pass 7 smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_level_config(failures: Array[String]) -> void:
	var config := _load_dict("res://data/levels/level_02_config.json", failures)
	if config.get("area_name", "") != "Banana-burbs":
		failures.append("Level 2 config area must be Banana-burbs")
	if config.get("mini_boss_id", "") != "nitin":
		failures.append("Level 2 config mini boss must be Nitin")
	if config.get("main_boss_id", "") != "deepak_reddy":
		failures.append("Level 2 config main boss must be Deepak Reddy")
	if config.get("reward_gear_id", "") != "banana_gun":
		failures.append("Level 2 config reward gear must be banana_gun")
	if int(config.get("growth_stage_unlock", 0)) != 3:
		failures.append("Level 2 config must unlock growth stage 3")
	if not Array(config.get("clue_ids", [])).has("165_files"):
		failures.append("Level 2 config must require 165-files clue")


func _check_level_scene(failures: Array[String]) -> void:
	var scene := load("res://scenes/levels/level_02.tscn")
	if scene == null:
		failures.append("Level 2 scene failed to load")
		return
	var level: Node = scene.instantiate()
	root.add_child(level)
	for node_path in [
		"World/BananaHouses",
		"World/HappyMonkeyLoop",
		"World/LabRecords",
		"World/NitinJanitor",
		"World/PopcornShare",
		"World/MayorOffice",
		"World/DeepakBoss",
		"World/TransitionDoor",
		"UiLayer/ObjectiveTracker",
		"UiLayer/ClueJournal"
	]:
		if level.get_node_or_null(node_path) == null:
			failures.append("Level 2 scene missing %s" % node_path)
	var records = level.get_node_or_null("World/LabRecords")
	if records != null and records.get("clue_id") != "165_files":
		failures.append("LabRecords must collect 165_files")
	var popcorn = level.get_node_or_null("World/PopcornShare")
	if popcorn != null:
		if popcorn.get("gear_id") != "banana_gun":
			failures.append("PopcornShare must unlock banana_gun")
		if popcorn.get("flag_on_interact") != "monkeys_spell_broken":
			failures.append("PopcornShare must set monkeys_spell_broken")
	var deepak = level.get_node_or_null("World/DeepakBoss")
	if deepak != null:
		var required_flags: PackedStringArray = deepak.get("required_flags")
		for flag_name in ["165_files_collected", "nitin_defeated", "monkeys_spell_broken"]:
			if not required_flags.has(flag_name):
				failures.append("DeepakBoss missing required flag %s" % flag_name)
	level.queue_free()


func _check_dialogue(failures: Array[String]) -> void:
	var dialogue := _load_dict("res://data/dialogue/level_02_dialogue.json", failures)
	for dialogue_id in ["monkey_loop", "lab_165_files", "nitin_intro", "popcorn_reveal", "deepak_intro", "deepak_defeat"]:
		if not dialogue.has(dialogue_id):
			failures.append("Level 2 dialogue missing %s" % dialogue_id)
	var text := JSON.stringify(dialogue)
	for required_word in ["Shrububu", "KFC", "165-files", "Nitin", "Deepak", "outside world"]:
		if not text.contains(required_word):
			failures.append("Level 2 dialogue missing canon phrase %s" % required_word)


func _check_encounters_and_rewards(failures: Array[String]) -> void:
	var encounters := _load_dict("res://data/encounters/level_02_encounters.json", failures)
	for encounter_id in ["nitin_janitor_boss", "deepak_reddy_boss"]:
		if not encounters.has(encounter_id):
			failures.append("Level 2 encounters missing %s" % encounter_id)
	if not encounters.has("nitin_janitor_boss") or not encounters.has("deepak_reddy_boss"):
		return
	var nitin: Dictionary = encounters["nitin_janitor_boss"]
	if nitin.get("boss_type", "") != "mini_boss":
		failures.append("Nitin encounter must be mini_boss")
	if nitin.get("defeated_flag", "") != "nitin_defeated":
		failures.append("Nitin encounter must set nitin_defeated")
	var deepak: Dictionary = encounters["deepak_reddy_boss"]
	if deepak.get("boss_type", "") != "main_boss":
		failures.append("Deepak encounter must be main_boss")
	if int(deepak.get("growth_stage_reward", 0)) != 3:
		failures.append("Deepak encounter must reward growth stage 3")
	if deepak.get("defeated_flag", "") != "deepak_reddy_defeated":
		failures.append("Deepak encounter must set deepak_reddy_defeated")

	var scene := load("res://scenes/battle/battle_scene.tscn")
	var battle: Node = scene.instantiate()
	root.add_child(battle)
	var game_state: Node = root.get_node_or_null("GameState")
	if game_state != null:
		game_state.reset_progression()
		game_state.unlock_gear("banana_gun")
	if battle.start_encounter("deepak_reddy_boss"):
		battle.enemy_hp = 1
		battle.choose_command("act")
		if game_state != null:
			if game_state.get_growth_stage() != 3:
				failures.append("Deepak defeat did not apply growth stage 3")
			if not game_state.get_flag("deepak_reddy_defeated"):
				failures.append("Deepak defeat did not set defeated flag")
	else:
		failures.append("BattleManager could not start deepak_reddy_boss")
	battle.queue_free()


func _load_dict(path: String, failures: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(path):
		failures.append("missing data file %s" % path)
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		failures.append("%s must parse as a dictionary" % path)
		return {}
	return data
