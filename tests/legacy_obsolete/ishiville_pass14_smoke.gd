extends SceneTree

const LEVEL_FLOW := [
	{
		"level_id": "level_01",
		"scene": "res://scenes/levels/level_01.tscn",
		"clues": ["divorce_records"],
		"pre_flags": ["building_broken"],
		"mid_flags": [],
		"post_flags": [],
		"mini_encounter": "poojan_strength_test",
		"mini_defeated": "poojan_defeated",
		"main_encounter": "satyaki_tirumal_boss",
		"main_defeated": "satyaki_tirumal_defeated",
		"reward_gear": "revolver",
		"growth": 2,
		"next_scene": "res://scenes/levels/level_02.tscn"
	},
	{
		"level_id": "level_02",
		"scene": "res://scenes/levels/level_02.tscn",
		"clues": ["165_files"],
		"pre_flags": [],
		"mid_flags": ["monkeys_spell_broken"],
		"post_flags": [],
		"mini_encounter": "nitin_janitor_boss",
		"mini_defeated": "nitin_defeated",
		"main_encounter": "deepak_reddy_boss",
		"main_defeated": "deepak_reddy_defeated",
		"reward_gear": "banana_gun",
		"growth": 3,
		"next_scene": "res://scenes/levels/level_03.tscn"
	},
	{
		"level_id": "level_03",
		"scene": "res://scenes/levels/level_03.tscn",
		"clues": ["berry_contract"],
		"pre_flags": ["berries_collected"],
		"mid_flags": ["berries_shared"],
		"post_flags": [],
		"mini_encounter": "niggesh_nishal_boss",
		"mini_defeated": "niggesh_nishal_defeated",
		"main_encounter": "ankit_boss",
		"main_defeated": "ankit_defeated",
		"reward_gear": "berry_potions",
		"growth": 4,
		"next_scene": "res://scenes/levels/level_04.tscn"
	},
	{
		"level_id": "level_04",
		"scene": "res://scenes/levels/level_04.tscn",
		"clues": ["hospital_records"],
		"pre_flags": [],
		"mid_flags": ["aeon_festival_started"],
		"post_flags": [],
		"mini_encounter": "doctor_sushan_boss",
		"mini_defeated": "doctor_sushan_defeated",
		"main_encounter": "mitta_boss",
		"main_defeated": "mitta_defeated",
		"reward_gear": "festival_clearance",
		"growth": 5,
		"next_scene": "res://scenes/levels/level_05.tscn"
	},
	{
		"level_id": "level_05",
		"scene": "res://scenes/levels/level_05.tscn",
		"clues": ["mansion_court_clues"],
		"pre_flags": ["pub_gummies_seen"],
		"mid_flags": ["bike_unlocked", "musical_guitar_unlocked"],
		"post_flags": ["ishiyoga_rescued"],
		"mini_encounter": "suhas_bar_fight",
		"mini_defeated": "suhas_defeated",
		"main_encounter": "srmt_final_boss",
		"main_defeated": "srmt_defeated",
		"reward_gear": "musical_guitar",
		"growth": 5,
		"next_scene": "res://scenes/ending.tscn"
	}
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var game_state: Node = root.get_node_or_null("GameState")
	var save_system: Node = root.get_node_or_null("SaveSystem")
	if game_state == null:
		failures.append("GameState autoload missing")
	if save_system == null:
		failures.append("SaveSystem autoload missing")
	if game_state != null and save_system != null:
		_check_new_game_baseline(game_state, save_system, failures)
		_simulate_full_playthrough(game_state, save_system, failures)
		_check_balance_ranges(failures)

	if failures.is_empty():
		print("PASS: Ishiville Pass 14 smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_new_game_baseline(game_state: Node, save_system: Node, failures: Array[String]) -> void:
	save_system.save_path = "user://ishiville_pass14_new_game.json"
	save_system.clear_save()
	save_system.new_game()
	if game_state.current_level_id != "level_01":
		failures.append("New game must start at level_01")
	if game_state.get_growth_stage() != 1:
		failures.append("New game must start at growth stage 1")
	if game_state.get_item_count("kfc_popcorn_box") < 1:
		failures.append("New game should include Shrububu's backup KFC popcorn box")
	save_system.clear_save()


func _simulate_full_playthrough(game_state: Node, save_system: Node, failures: Array[String]) -> void:
	save_system.save_path = "user://ishiville_pass14_full_flow.json"
	save_system.clear_save()
	save_system.new_game()
	for spec in LEVEL_FLOW:
		_apply_story_setup(game_state, spec)
		_run_encounter(str(spec["mini_encounter"]), game_state, failures)
		_check_defeat_state(game_state, str(spec["mini_defeated"]), failures)
		for flag_name in spec["mid_flags"]:
			game_state.set_flag(str(flag_name), true)
		_sync_level_scene(spec, game_state, failures)
		_run_encounter(str(spec["main_encounter"]), game_state, failures)
		_check_defeat_state(game_state, str(spec["main_defeated"]), failures)
		for flag_name in spec["post_flags"]:
			game_state.set_flag(str(flag_name), true)
		_sync_level_scene(spec, game_state, failures)
		_check_level_rewards(game_state, spec, failures)
		_check_transition_gate(spec, failures)
		_check_save_restore_checkpoint(game_state, save_system, spec, failures)
	save_system.clear_save()


func _apply_story_setup(game_state: Node, spec: Dictionary) -> void:
	game_state.current_level_id = str(spec["level_id"])
	for flag_name in spec["pre_flags"]:
		game_state.set_flag(str(flag_name), true)
	for clue_id in spec["clues"]:
		game_state.collect_clue(str(clue_id))


func _run_encounter(encounter_id: String, game_state: Node, failures: Array[String]) -> void:
	var battle_scene := load("res://scenes/battle/battle_scene.tscn")
	var battle: Node = battle_scene.instantiate()
	root.add_child(battle)
	if not battle.start_encounter(encounter_id):
		failures.append("Could not start required encounter %s" % encounter_id)
		battle.queue_free()
		return
	var turns := 0
	while str(battle.get("phase")) != "resolved" and turns < 32:
		match str(battle.get("phase")):
			"player_command":
				battle.choose_command("act")
			"enemy_phase":
				battle.finish_enemy_phase()
			_:
				failures.append("%s reached unexpected battle phase %s" % [encounter_id, battle.get("phase")])
				break
		turns += 1
	if str(battle.get("phase")) != "resolved":
		failures.append("%s did not resolve within balanced turn budget" % encounter_id)
	if game_state.get_growth_stage() < 1 or game_state.get_growth_stage() > 5:
		failures.append("%s left growth stage outside valid range" % encounter_id)
	battle.queue_free()


func _check_defeat_state(game_state: Node, defeated_flag: String, failures: Array[String]) -> void:
	if not game_state.get_flag(defeated_flag):
		failures.append("Missing story defeat flag %s" % defeated_flag)
	if not bool(game_state.defeated_bosses.get(defeated_flag, false)):
		failures.append("Missing persisted defeated_bosses entry %s" % defeated_flag)


func _sync_level_scene(spec: Dictionary, _game_state: Node, failures: Array[String]) -> void:
	var scene := load(str(spec["scene"]))
	if scene == null:
		failures.append("Could not load %s" % spec["scene"])
		return
	var level: Node = scene.instantiate()
	root.add_child(level)
	level.queue_free()


func _check_level_rewards(game_state: Node, spec: Dictionary, failures: Array[String]) -> void:
	var reward_gear := str(spec["reward_gear"])
	if not reward_gear.is_empty() and not game_state.has_gear(reward_gear):
		failures.append("%s did not unlock reward gear %s" % [spec["level_id"], reward_gear])
	if game_state.get_growth_stage() < int(spec["growth"]):
		failures.append("%s did not reach growth stage %d" % [spec["level_id"], spec["growth"]])


func _check_transition_gate(spec: Dictionary, failures: Array[String]) -> void:
	var scene := load(str(spec["scene"]))
	var level: Node = scene.instantiate()
	root.add_child(level)
	var transition = level.get_node_or_null("World/TransitionDoor")
	if transition == null:
		failures.append("%s missing TransitionDoor" % spec["level_id"])
	else:
		if transition.get("target_scene_path") != spec["next_scene"]:
			failures.append("%s transition target mismatch" % spec["level_id"])
		var required_flags: PackedStringArray = transition.get("required_flags")
		var game_state: Node = root.get_node_or_null("GameState")
		for flag_name in required_flags:
			if game_state != null and not game_state.get_flag(flag_name):
				failures.append("%s transition still blocked by %s after clear sync" % [spec["level_id"], flag_name])
	level.queue_free()


func _check_save_restore_checkpoint(game_state: Node, save_system: Node, spec: Dictionary, failures: Array[String]) -> void:
	var expected_stage: int = game_state.get_growth_stage()
	var expected_weapon: String = str(game_state.current_weapon)
	var expected_flags: Dictionary = game_state.story_flags.duplicate(true)
	var expected_gear: Dictionary = game_state.gear.duplicate(true)
	var expected_clues: Dictionary = game_state.clues.duplicate(true)
	var expected_defeated: Dictionary = game_state.defeated_bosses.duplicate(true)
	var expected_inventory: Dictionary = game_state.inventory.duplicate(true)
	if not save_system.save_game(str(spec["level_id"]), "checkpoint_%s" % spec["level_id"]):
		failures.append("Save failed at %s" % spec["level_id"])
		return
	game_state.clear_flags()
	game_state.reset_progression()
	game_state.current_level_id = "wrong"
	save_system.load_game()
	if game_state.current_level_id != spec["level_id"]:
		failures.append("Save restore level mismatch at %s" % spec["level_id"])
	if game_state.get_growth_stage() != expected_stage:
		failures.append("Save restore growth mismatch at %s" % spec["level_id"])
	if game_state.current_weapon != expected_weapon:
		failures.append("Save restore current weapon mismatch at %s" % spec["level_id"])
	if not _dict_contains_state(game_state.story_flags, expected_flags):
		failures.append("Save restore story flags mismatch at %s" % spec["level_id"])
	if not _dict_contains_state(game_state.gear, expected_gear):
		failures.append("Save restore gear mismatch at %s" % spec["level_id"])
	if not _dict_contains_state(game_state.clues, expected_clues):
		failures.append("Save restore clues mismatch at %s" % spec["level_id"])
	if not _dict_contains_state(game_state.defeated_bosses, expected_defeated):
		failures.append("Save restore defeated bosses mismatch at %s" % spec["level_id"])
	if not _dict_contains_state(game_state.inventory, expected_inventory):
		failures.append("Save restore inventory mismatch at %s" % spec["level_id"])


func _dict_contains_state(actual: Dictionary, expected: Dictionary) -> bool:
	for key in expected.keys():
		if actual.get(key) != expected[key]:
			return false
	return true


func _check_balance_ranges(failures: Array[String]) -> void:
	var tuning := _load_dict("res://data/tuning/gameplay_tuning.json", failures)
	var overworld: Dictionary = tuning.get("overworld", {})
	var battle: Dictionary = tuning.get("battle", {})
	var speed: float = float(overworld.get("player_speed", 0.0))
	if speed < 82.0 or speed > 96.0:
		failures.append("Player speed should be tuned into the responsive 82-96 range")
	var damage: int = int(battle.get("enemy_phase_damage", 0))
	if damage < 1 or damage > 2:
		failures.append("Enemy phase damage should stay fair at 1-2")
	var bullet_radius: float = float(battle.get("bullet_radius", 0.0))
	if bullet_radius < 2.0 or bullet_radius > 3.0:
		failures.append("Bullet radius should stay readable/fair between 2 and 3")


func _load_dict(path: String, failures: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(path):
		failures.append("missing data file %s" % path)
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		failures.append("%s must parse as a dictionary" % path)
		return {}
	return data
