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
		print("PASS: Ishiville Pass 9 smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_level_config(failures: Array[String]) -> void:
	var config := _load_dict("res://data/levels/level_04_config.json", failures)
	if config.get("area_name", "") != "Auticity":
		failures.append("Level 4 config area must be Auticity")
	if config.get("mini_boss_id", "") != "doctor_sushan":
		failures.append("Level 4 config mini boss must be Doctor Sushan")
	if config.get("main_boss_id", "") != "mitta":
		failures.append("Level 4 config main boss must be Mitta")
	if int(config.get("growth_stage_unlock", 0)) != 5:
		failures.append("Level 4 config must unlock growth stage 5")
	if not Array(config.get("clue_ids", [])).has("hospital_records"):
		failures.append("Level 4 config must include hospital_records clue")


func _check_level_scene(failures: Array[String]) -> void:
	var scene := load("res://scenes/levels/level_04.tscn")
	if scene == null:
		failures.append("Level 4 scene failed to load")
		return
	var level: Node = scene.instantiate()
	root.add_child(level)
	for node_path in [
		"World/PunStreet",
		"World/Hospital",
		"World/HospitalRecords",
		"World/PatternSerumLab",
		"World/DoctorSushan",
		"World/AeonFestival",
		"World/MittaBoss",
		"World/TransitionDoor",
		"World/JudgeLuma",
		"World/Objective",
		"World/PracticeEncounter",
		"UiLayer/ObjectiveTracker",
		"UiLayer/ClueJournal"
	]:
		if level.get_node_or_null(node_path) == null:
			failures.append("Level 4 scene missing %s" % node_path)
	var records = level.get_node_or_null("World/HospitalRecords")
	if records != null and records.get("clue_id") != "hospital_records":
		failures.append("HospitalRecords must collect hospital_records clue")
	var festival = level.get_node_or_null("World/AeonFestival")
	if festival != null and festival.get("flag_on_interact") != "aeon_festival_started":
		failures.append("AeonFestival must set aeon_festival_started")
	var mitta = level.get_node_or_null("World/MittaBoss")
	if mitta != null:
		var required_flags: PackedStringArray = mitta.get("required_flags")
		for flag_name in ["hospital_records_collected", "doctor_sushan_defeated", "aeon_festival_started"]:
			if not required_flags.has(flag_name):
				failures.append("MittaBoss missing required flag %s" % flag_name)
	level.queue_free()


func _check_dialogue(failures: Array[String]) -> void:
	var dialogue := _load_dict("res://data/dialogue/level_04_dialogue.json", failures)
	for dialogue_id in ["luma_intro", "luma_after_battle", "pun_loop", "hospital_records", "sushan_intro", "sushan_defeat", "aeon_festival", "mitta_intro", "mitta_defeat"]:
		if not dialogue.has(dialogue_id):
			failures.append("Level 4 dialogue missing %s" % dialogue_id)
	var text := JSON.stringify(dialogue)
	for phrase in ["Shrububu", "Auticity", "Pattern Serum", "Doctor Sushan", "Aeon Festival", "Mitta"]:
		if not text.contains(phrase):
			failures.append("Level 4 dialogue missing canon phrase %s" % phrase)


func _check_encounters_and_rewards(failures: Array[String]) -> void:
	var encounters := _load_dict("res://data/encounters/level_04_encounters.json", failures)
	for encounter_id in ["doctor_sushan_boss", "mitta_boss"]:
		if not encounters.has(encounter_id):
			failures.append("Level 4 encounters missing %s" % encounter_id)
	if not encounters.has("doctor_sushan_boss") or not encounters.has("mitta_boss"):
		return
	var sushan: Dictionary = encounters["doctor_sushan_boss"]
	if sushan.get("boss_type", "") != "mini_boss":
		failures.append("Doctor Sushan encounter must be mini_boss")
	if sushan.get("defeated_flag", "") != "doctor_sushan_defeated":
		failures.append("Doctor Sushan encounter must set doctor_sushan_defeated")
	var mitta: Dictionary = encounters["mitta_boss"]
	if mitta.get("boss_type", "") != "main_boss":
		failures.append("Mitta encounter must be main_boss")
	if int(mitta.get("growth_stage_reward", 0)) != 5:
		failures.append("Mitta encounter must reward growth stage 5")
	if mitta.get("defeated_flag", "") != "mitta_defeated":
		failures.append("Mitta encounter must set mitta_defeated")

	var scene := load("res://scenes/battle/battle_scene.tscn")
	var battle: Node = scene.instantiate()
	root.add_child(battle)
	var game_state: Node = root.get_node_or_null("GameState")
	if game_state != null:
		game_state.reset_progression()
		game_state.unlock_gear("berry_potions")
	if battle.start_encounter("mitta_boss"):
		battle.enemy_hp = 1
		battle.choose_command("act")
		if game_state != null:
			if game_state.get_growth_stage() != 5:
				failures.append("Mitta defeat did not apply growth stage 5")
			if not game_state.get_flag("mitta_defeated"):
				failures.append("Mitta defeat did not set defeated flag")
	else:
		failures.append("BattleManager could not start mitta_boss")
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
