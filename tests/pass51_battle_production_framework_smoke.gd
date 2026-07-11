extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_weapon_timing()
	await process_frame
	await _test_battle_flow()
	if failures.is_empty():
		print("PASS: Pass 51 active weapons, choice menus, pattern timelines, Resonance, and difficulty recovery")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _test_weapon_timing() -> void:
	var scene := load("res://scenes/battle/weapon_timing_controller.tscn") as PackedScene
	_assert(scene != null, "Weapon timing scene must load")
	if scene == null:
		return
	var timing = scene.instantiate()
	root.add_child(timing)
	var result := {"multiplier": 0.0, "grade": ""}
	timing.timing_resolved.connect(func(multiplier: float, grade: String): result.multiplier = multiplier; result.grade = grade)
	timing.start_attack("precision", "Poojan's Revolver")
	timing.resolve_at(0.5)
	_assert(float(result.multiplier) >= 1.7, "Centered precision input must score near-perfect damage")
	_assert(str(result.grade) == "PERFECT", "Centered precision input must receive PERFECT")
	timing.queue_free()


func _test_battle_flow() -> void:
	var game_state := root.get_node_or_null("GameState")
	var save_system := root.get_node_or_null("SaveSystem")
	_assert(game_state != null and save_system != null, "Battle test requires state and save autoloads")
	if game_state == null or save_system == null:
		return
	save_system.new_game("shrububu")
	game_state.unlock_gear("revolver")
	game_state.equip_weapon("revolver")
	game_state.pending_encounter_id = "poojan_strength_test"
	var battle_scene := load("res://scenes/battle/battle_scene.tscn") as PackedScene
	var battle = battle_scene.instantiate()
	root.add_child(battle)
	await process_frame
	_assert(battle.phase == "player_command", "Poojan must begin in command phase")
	_assert(battle.get_node_or_null("HudLayer/BattleHud/ChoicePanel") != null, "Battle HUD must contain a real choice panel")
	_assert(battle.get_node_or_null("HudLayer/WeaponTiming") != null, "Battle must contain active weapon timing UI")
	var pattern = battle.get_node("Arena/BulletPattern")
	for pattern_id in ["arcs", "ricochets", "environmental_hazards", "rhythm_notes"]:
		_assert(pattern.get_supported_pattern_types().has(pattern_id), "Missing production pattern: %s" % pattern_id)
	battle.enemy_hp = 20
	battle.enemy_max_hp = 20
	battle._enemy_actor.setup("Sheriff Poojan", 20)
	var enemy_before: int = battle.enemy_hp
	_assert(battle.choose_command("act", {"timing_multiplier": 1.75}), "Timed revolver Act must resolve")
	_assert(battle.enemy_hp < enemy_before and battle.resonance >= 2, "Strong timing must deal damage and build extra Resonance")
	_assert(battle.phase == "enemy_phase", "Completed active attack must enter dodge phase")
	battle.finish_enemy_phase()
	battle._player_actor.hp = 1
	battle.player_hp = 1
	battle.phase = "enemy_phase"
	battle._state_machine.set_state("enemy_phase")
	battle._on_soul_hit()
	_assert(battle.phase == "player_command" and battle.player_hp > 0, "Shrububu mode must provide one automatic phase recovery")
	battle.queue_free()
	await process_frame

	save_system.new_game("srmt")
	game_state.pending_encounter_id = "poojan_strength_test"
	var hard_battle = battle_scene.instantiate()
	root.add_child(hard_battle)
	await process_frame
	hard_battle._player_actor.hp = 1
	hard_battle.player_hp = 1
	hard_battle.phase = "enemy_phase"
	hard_battle._state_machine.set_state("enemy_phase")
	hard_battle._on_soul_hit()
	_assert(hard_battle.phase == "defeated", "SRMT mode must not grant automatic recovery")
	hard_battle.queue_free()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
