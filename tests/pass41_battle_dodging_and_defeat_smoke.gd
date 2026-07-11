extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node_or_null("GameState")
	_assert(game_state != null, "GameState autoload must exist")
	var save_system := root.get_node_or_null("SaveSystem")
	_assert(save_system != null, "SaveSystem autoload must exist")
	save_system.new_game("srmt")
	game_state.pending_encounter_id = "poojan_strength_test"

	var battle_scene := load("res://scenes/battle/battle_scene.tscn") as PackedScene
	var battle = battle_scene.instantiate()
	root.add_child(battle)
	await process_frame
	_assert(battle.phase == "player_command", "Battle must begin in player command phase")

	var soul = battle.get_node("Arena/SoulCursor")
	_assert(soul.has_method("set_active"), "Soul cursor must have movement/collision behavior")
	_assert(not soul.active, "Soul cursor must be inactive during command phase")
	_assert(battle.choose_command("guard"), "Guard command must start an enemy phase")
	_assert(battle.phase == "enemy_phase" and soul.active, "Soul cursor must activate during enemy phase")

	var pattern = battle.get_node("Arena/BulletPattern")
	pattern.clear_pattern()
	pattern.start_pattern({"type": "straight_lanes", "count": 3, "telegraph_seconds": 0.0})
	var bullets := pattern.get_children().filter(func(child): return child is Area2D)
	_assert(bullets.size() == 3, "Pattern must create collidable bullets")
	_assert(bullets.all(func(bullet): return bullet.is_in_group("battle_bullet")), "Every bullet must use the battle_bullet collision group")

	battle._player_actor.hp = 1
	battle.player_hp = 1
	battle.guarding = false
	battle._on_soul_hit()
	_assert(battle.phase == "defeated", "Zero HP must enter defeat state, not victory")
	_assert(not game_state.get_flag("poojan_defeated"), "Defeat must never award the boss-cleared flag")

	_assert(battle.start_encounter("poojan_strength_test"), "Retry must restart the encounter")
	_assert(battle.phase == "player_command" and battle.player_hp == battle.player_max_hp, "Retry must restore battle state and HP")
	print("PASS: battle dodging, bullet collision contract, and defeat flow")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
