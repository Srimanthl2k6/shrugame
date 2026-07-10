extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []

	_check_encounter_data(failures)
	_check_battle_scripts(failures)
	_check_battle_scene(failures)
	_check_hud_scene(failures)
	_check_soul_scene(failures)
	_check_level_trigger(failures)
	_check_battle_flow(failures)

	if failures.is_empty():
		print("PASS: Pass 4 smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_encounter_data(failures: Array[String]) -> void:
	var text := FileAccess.get_file_as_string("res://data/encounters/level_01_encounters.json")
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		failures.append("Level 1 encounter JSON is not an object")
		return
	if not data.has("marn_practice"):
		failures.append("Level 1 encounters missing marn_practice")
		return
	var encounter = data["marn_practice"]
	if typeof(encounter) != TYPE_DICTIONARY:
		failures.append("marn_practice is not an encounter object")
		return
	for key in ["enemy_name", "enemy_hp", "player_hp", "resonance_goal", "return_scene"]:
		if not encounter.has(key):
			failures.append("marn_practice missing key: %s" % key)


func _check_battle_scripts(failures: Array[String]) -> void:
	_require_methods("res://scripts/battle/battle_manager.gd", ["start_encounter", "choose_act", "finish_enemy_phase", "resolve_battle"], failures)
	_require_methods("res://scripts/battle/encounter_state_machine.gd", ["start", "set_state", "get_state"], failures)
	_require_methods("res://scripts/battle/battle_actor.gd", ["setup", "take_damage", "is_defeated"], failures)
	_require_methods("res://scripts/battle/bullet_pattern_base.gd", ["start_pattern", "clear_pattern"], failures)
	_require_methods("res://scripts/ui/battle_hud.gd", ["update_hud", "show_message"], failures)


func _check_battle_scene(failures: Array[String]) -> void:
	var scene := load("res://scenes/battle/battle_scene.tscn")
	if scene == null:
		failures.append("battle_scene.tscn did not load")
		return
	var battle: Node = scene.instantiate()
	if battle.get_script() == null:
		failures.append("BattleScene has no battle manager script")
	_require_node(battle, "Arena", failures)
	_require_node(battle, "Arena/SoulCursor", failures)
	_require_node(battle, "Arena/BulletPattern", failures)
	_require_node(battle, "HudLayer/BattleHud", failures)
	battle.free()


func _check_hud_scene(failures: Array[String]) -> void:
	var scene := load("res://scenes/ui/battle_hud.tscn")
	if scene == null:
		failures.append("battle_hud.tscn did not load")
		return
	var hud: Node = scene.instantiate()
	if hud.get_script() == null:
		failures.append("BattleHud has no script")
	_require_node(hud, "Panel/EnemyLabel", failures)
	_require_node(hud, "Panel/HpLabel", failures)
	_require_node(hud, "Panel/PhaseLabel", failures)
	_require_node(hud, "Panel/CommandLabel", failures)
	hud.free()


func _check_soul_scene(failures: Array[String]) -> void:
	var scene := load("res://scenes/battle/soul_cursor.tscn")
	if scene == null:
		failures.append("soul_cursor.tscn did not load")
		return
	var soul: Node = scene.instantiate()
	_require_node(soul, "CollisionShape2D", failures)
	_require_node(soul, "Visual", failures)
	soul.free()


func _check_level_trigger(failures: Array[String]) -> void:
	var scene := load("res://scenes/levels/level_01.tscn")
	if scene == null:
		failures.append("level_01.tscn did not load")
		return
	var level: Node = scene.instantiate()
	_require_node(level, "World/PracticeEncounter", failures)
	var trigger: Node = level.get_node_or_null("World/PracticeEncounter")
	if trigger != null and trigger.get("target_scene_path") != "res://scenes/battle/battle_scene.tscn":
		failures.append("PracticeEncounter must transition to battle_scene.tscn")
	level.free()


func _check_battle_flow(failures: Array[String]) -> void:
	var scene := load("res://scenes/battle/battle_scene.tscn")
	if scene == null:
		return
	var battle: Node = scene.instantiate()
	root.add_child(battle)
	if not battle.has_method("start_encounter"):
		failures.append("BattleManager cannot be flow-tested without start_encounter")
	elif not battle.start_encounter("marn_practice"):
		failures.append("BattleManager could not start marn_practice")
	elif battle.get("phase") != "player_command":
		failures.append("Battle must start in player_command phase")
	else:
		battle.set("enemy_phase_seconds", 0.01)
		battle.choose_act()
		if battle.get("phase") != "enemy_phase":
			failures.append("choose_act must enter enemy_phase")
		await create_timer(0.03).timeout
		if battle.get("player_hp") >= battle.get("player_max_hp"):
			failures.append("finish_enemy_phase must damage player in prototype")
		battle.resolve_battle(false)
		if battle.get("phase") != "resolved":
			failures.append("resolve_battle(false) must mark battle resolved")
	battle.free()


func _require_methods(script_path: String, methods: Array[String], failures: Array[String]) -> void:
	var script := load(script_path)
	if script == null:
		failures.append("Could not load script: %s" % script_path)
		return
	if not script.has_method("new"):
		failures.append("Script cannot be instantiated: %s" % script_path)
		return
	var instance = script.new()
	for method in methods:
		if not instance.has_method(method):
			failures.append("%s missing method: %s" % [script_path, method])
	if instance is Node:
		instance.free()


func _require_node(root_node: Node, path: NodePath, failures: Array[String]) -> void:
	if root_node.get_node_or_null(path) == null:
		failures.append("Missing node: %s" % path)
