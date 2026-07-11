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
		print("PASS: Ishiville Pass 8 smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_level_config(failures: Array[String]) -> void:
	var config := _load_dict("res://data/levels/level_03_config.json", failures)
	if config.get("area_name", "") != "Berry Barks":
		failures.append("Level 3 config area must be Berry Barks")
	if config.get("mini_boss_id", "") != "niggesh_nishal":
		failures.append("Level 3 config mini boss must be Niggesh Nishal")
	if config.get("main_boss_id", "") != "ankit":
		failures.append("Level 3 config main boss must be Ankit")
	if config.get("reward_gear_id", "") != "berry_potions":
		failures.append("Level 3 config reward gear must be berry_potions")
	if int(config.get("growth_stage_unlock", 0)) != 4:
		failures.append("Level 3 config must unlock growth stage 4")
	if not Array(config.get("clue_ids", [])).has("berry_contract"):
		failures.append("Level 3 config must include berry_contract clue")


func _check_level_scene(failures: Array[String]) -> void:
	var scene := load("res://scenes/levels/level_03.tscn")
	if scene == null:
		failures.append("Level 3 scene failed to load")
		return
	var level: Node = scene.instantiate()
	root.add_child(level)
	for node_path in [
		"World/DouglasFirTown",
		"World/BerryClusters",
		"World/BerryContract",
		"World/ChefNishal",
		"World/BerryShare",
		"World/AnkitBoss",
		"World/TransitionDoor",
		"World/Tickroot",
		"World/Objective",
		"World/PracticeEncounter",
		"UiLayer/ObjectiveTracker",
		"UiLayer/ClueJournal"
	]:
		if level.get_node_or_null(node_path) == null:
			failures.append("Level 3 scene missing %s" % node_path)
	var berries = level.get_node_or_null("World/BerryClusters")
	if berries != null and berries.get("flag_on_interact") != "berry_cluster_01":
		failures.append("BerryClusters must be the first 250-berry cluster")
	for cluster_path in ["World/BerryClusters", "World/BerryCluster02", "World/BerryCluster03", "World/BerryCluster04"]:
		var cluster = level.get_node_or_null(cluster_path)
		if cluster == null or int(cluster.get("item_amount")) != 250:
			failures.append("%s must award one 250-berry cluster" % cluster_path)
	var contract = level.get_node_or_null("World/BerryContract")
	if contract != null and contract.get("clue_id") != "berry_contract":
		failures.append("BerryContract must collect berry_contract clue")
	var share = level.get_node_or_null("World/BerryShare")
	if share != null and share.get("gear_id") != "berry_potions":
		failures.append("BerryShare must unlock berry_potions")
	var ankit = level.get_node_or_null("World/AnkitBoss")
	if ankit != null:
		var required_flags: PackedStringArray = ankit.get("required_flags")
		for flag_name in ["berry_contract_collected", "niggesh_nishal_defeated", "berries_shared"]:
			if not required_flags.has(flag_name):
				failures.append("AnkitBoss missing required flag %s" % flag_name)
	level.queue_free()


func _check_dialogue(failures: Array[String]) -> void:
	var dialogue := _load_dict("res://data/dialogue/level_03_dialogue.json", failures)
	for dialogue_id in ["tickroot_intro", "tickroot_after_battle", "nishal_intro", "berry_contract", "nishal_defeat", "berry_share", "ankit_intro", "ankit_defeat"]:
		if not dialogue.has(dialogue_id):
			failures.append("Level 3 dialogue missing %s" % dialogue_id)
	var text := JSON.stringify(dialogue)
	for phrase in ["Shrububu", "KFC", "1000 berries", "Niggesh Nishal", "Ankit", "berry potions"]:
		if not text.contains(phrase):
			failures.append("Level 3 dialogue missing canon phrase %s" % phrase)


func _check_encounters_and_rewards(failures: Array[String]) -> void:
	var encounters := _load_dict("res://data/encounters/level_03_encounters.json", failures)
	for encounter_id in ["niggesh_nishal_boss", "ankit_boss"]:
		if not encounters.has(encounter_id):
			failures.append("Level 3 encounters missing %s" % encounter_id)
	if not encounters.has("niggesh_nishal_boss") or not encounters.has("ankit_boss"):
		return
	var nishal: Dictionary = encounters["niggesh_nishal_boss"]
	if nishal.get("boss_type", "") != "mini_boss":
		failures.append("Niggesh Nishal encounter must be mini_boss")
	if nishal.get("defeated_flag", "") != "niggesh_nishal_defeated":
		failures.append("Niggesh Nishal encounter must set niggesh_nishal_defeated")
	var ankit: Dictionary = encounters["ankit_boss"]
	if ankit.get("boss_type", "") != "main_boss":
		failures.append("Ankit encounter must be main_boss")
	if int(ankit.get("growth_stage_reward", 0)) != 4:
		failures.append("Ankit encounter must reward growth stage 4")
	if ankit.get("defeated_flag", "") != "ankit_defeated":
		failures.append("Ankit encounter must set ankit_defeated")

	var scene := load("res://scenes/battle/battle_scene.tscn")
	var battle: Node = scene.instantiate()
	root.add_child(battle)
	var game_state: Node = root.get_node_or_null("GameState")
	if game_state != null:
		game_state.reset_progression()
		game_state.unlock_gear("berry_potions")
	if battle.start_encounter("ankit_boss"):
		battle.enemy_hp = 1
		battle.choose_command("act")
		if game_state != null:
			if game_state.get_growth_stage() != 4:
				failures.append("Ankit defeat did not apply growth stage 4")
			if not game_state.get_flag("ankit_defeated"):
				failures.append("Ankit defeat did not set defeated flag")
	else:
		failures.append("BattleManager could not start ankit_boss")
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
