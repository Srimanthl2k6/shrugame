extends SceneTree

const REQUIRED_COMMANDS := ["act", "item", "gear", "guard"]
const REQUIRED_PATTERNS := ["straight_lanes", "rings", "falling_objects", "sweeping_beams", "musical_notes", "callback_mix"]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_encounter_data(failures)
	_check_pattern_base(failures)
	_check_battle_manager(failures)

	if failures.is_empty():
		print("PASS: Ishiville Pass 5 smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_encounter_data(failures: Array[String]) -> void:
	var encounters := _load_dict("res://data/encounters/level_01_encounters.json", failures)
	if encounters.is_empty():
		return
	if not encounters.has("framework_test_boss"):
		failures.append("level_01_encounters missing framework_test_boss")
		return
	var encounter: Dictionary = encounters["framework_test_boss"]
	for key in ["boss_type", "phases", "reward_gear", "return_scene", "defeated_flag", "commands"]:
		if not encounter.has(key):
			failures.append("framework_test_boss missing %s" % key)
	for command in REQUIRED_COMMANDS:
		if not Array(encounter.get("commands", [])).has(command):
			failures.append("framework_test_boss command list missing %s" % command)
	var phases: Array = encounter.get("phases", [])
	if phases.size() < 2:
		failures.append("framework_test_boss needs at least two phases")
		return
	for phase in phases:
		if typeof(phase) != TYPE_DICTIONARY:
			failures.append("framework_test_boss phase must be a dictionary")
			continue
		for key in ["id", "intro_dialogue", "patterns", "clear_threshold"]:
			if not phase.has(key):
				failures.append("framework_test_boss phase missing %s" % key)


func _check_pattern_base(failures: Array[String]) -> void:
	var pattern: Node = load("res://scripts/battle/bullet_pattern_base.gd").new()
	if not _has_methods(pattern, ["get_supported_pattern_types", "start_pattern"], failures):
		return
	var types: Array = pattern.get_supported_pattern_types()
	for pattern_type in REQUIRED_PATTERNS:
		if not types.has(pattern_type):
			failures.append("BulletPatternBase missing pattern type %s" % pattern_type)
	pattern.start_pattern({"type": "rings", "count": 4})
	if pattern.get_child_count() != 4:
		failures.append("BulletPatternBase did not spawn requested ring bullets")
	pattern.clear_pattern()
	pattern.free()


func _check_battle_manager(failures: Array[String]) -> void:
	var scene := load("res://scenes/battle/battle_scene.tscn")
	if scene == null:
		failures.append("Battle scene failed to load")
		return
	var battle: Node = scene.instantiate()
	root.add_child(battle)
	if not _has_methods(battle, ["get_available_commands", "choose_command", "get_current_phase_id", "get_weapon_behavior", "use_item", "equip_weapon"], failures):
		battle.queue_free()
		return

	var game_state: Node = root.get_node_or_null("GameState")
	if game_state != null:
		game_state.reset_progression()
		game_state.add_item("kfc_popcorn_box", 1)
		game_state.unlock_gear("revolver")
		game_state.unlock_gear("banana_gun")
		game_state.current_weapon = "revolver"

	if not battle.start_encounter("framework_test_boss"):
		failures.append("BattleManager could not start framework_test_boss")
	else:
		for command in REQUIRED_COMMANDS:
			if not battle.get_available_commands().has(command):
				failures.append("BattleManager available commands missing %s" % command)
		if battle.get_current_phase_id() != "opening":
			failures.append("BattleManager did not enter opening phase")
		var revolver: Dictionary = battle.get_weapon_behavior("revolver")
		if revolver.get("weapon_type", "") != "precision":
			failures.append("BattleManager did not expose revolver behavior")
		if not battle.equip_weapon("banana_gun"):
			failures.append("BattleManager did not equip unlocked banana gun")
		if not battle.choose_command("gear", {"weapon_id": "revolver"}):
			failures.append("BattleManager gear command failed")
		battle.finish_enemy_phase()
		battle.player_hp = 10
		if not battle.use_item("kfc_popcorn_box"):
			failures.append("BattleManager item command failed")
		if battle.player_hp <= 10:
			failures.append("BattleManager item command did not heal")
		if not battle.choose_command("guard"):
			failures.append("BattleManager guard command failed")
		if battle.phase != "enemy_phase":
			failures.append("BattleManager guard command did not advance to enemy phase")
		battle.finish_enemy_phase()
		battle.enemy_hp = 1
		if not battle.choose_command("act"):
			failures.append("BattleManager act command failed")
		if battle.phase != "resolved":
			failures.append("BattleManager did not resolve after enemy defeat")
		if game_state != null:
			if not game_state.has_gear("revolver"):
				failures.append("BattleManager did not preserve reward gear")
			if not game_state.get_flag("framework_test_boss_defeated"):
				failures.append("BattleManager did not set defeated flag")
	battle.queue_free()


func _has_methods(node: Object, method_names: Array[String], failures: Array[String]) -> bool:
	var ok := true
	for method_name in method_names:
		if not node.has_method(method_name):
			failures.append("%s missing method %s" % [node.get_class(), method_name])
			ok = false
	return ok


func _load_dict(path: String, failures: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(path):
		failures.append("missing data file %s" % path)
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		failures.append("%s must parse as a dictionary" % path)
		return {}
	return data
