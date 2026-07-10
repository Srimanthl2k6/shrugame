extends Node2D

const CLEAR_FLAGS := ["berry_contract_collected", "niggesh_nishal_defeated", "berries_shared", "ankit_defeated"]
const LEGACY_CLEAR_FLAGS := ["level_03_objective_done", "tickroot_practice_cleared"]
const ROUTE_SUMMARY := [
	"1. Collect the 1000 berries as clusters.",
	"2. Read the berry contract.",
	"3. Beat Nishal over the fake chicken promise.",
	"4. share berries with the town.",
	"5. Defeat Ankit near the forest route.",
	"6. Exit to Auticity."
]


func _ready() -> void:
	var game_state := _get_game_state()
	if game_state != null:
		game_state.current_level_id = "level_03"
		if game_state.has_method("get_current_objective") and game_state.get_current_objective().is_empty():
			game_state.set_current_objective("Collect 1000 berries as clusters in Berry Barks.")
	_sync_progression_rewards()
	_refresh_exit_hint()


func complete_objective() -> void:
	var game_state := _get_game_state()
	if game_state == null:
		return
	game_state.set_flag("level_03_objective_done", true)
	_refresh_exit_hint()


func collect_objective(flag_name: String = "") -> void:
	var game_state := _get_game_state()
	if game_state != null and not flag_name.is_empty():
		game_state.set_flag(flag_name, true)
	if flag_name == "berries_shared":
		complete_objective()
	_sync_progression_rewards()
	_refresh_exit_hint()


func can_clear_level() -> bool:
	var game_state := _get_game_state()
	if game_state == null:
		return false
	if _has_flags(game_state, LEGACY_CLEAR_FLAGS):
		return true
	return _has_flags(game_state, CLEAR_FLAGS)


func get_level03_route_summary() -> Array[String]:
	return ROUTE_SUMMARY.duplicate()


func _sync_progression_rewards() -> void:
	var game_state := _get_game_state()
	if game_state == null:
		return
	if game_state.get_flag("berries_shared") and game_state.has_method("unlock_gear"):
		game_state.unlock_gear("berry_potions")
	if game_state.get_flag("ankit_defeated"):
		if game_state.has_method("set_growth_stage"):
			game_state.set_growth_stage(4)
		game_state.set_flag("level_03_objective_done", true)
		game_state.set_flag("tickroot_practice_cleared", true)
		if game_state.has_method("set_current_objective"):
			game_state.set_current_objective("Berry Barks is fed. Leave for Auticity.")


func _has_flags(game_state: Node, flag_names: Array) -> bool:
	for flag_name in flag_names:
		if not game_state.get_flag(flag_name):
			return false
	return true


func _refresh_exit_hint() -> void:
	var exit_door := get_node_or_null("World/TransitionDoor")
	if exit_door == null:
		return
	if can_clear_level():
		exit_door.interaction_message = "Berry Barks is fed. Auticity waits past the mist."
	else:
		exit_door.locked_message = "Berry Barks is not free yet: collect the contract, beat Nishal, share berries, and defeat Ankit."


func _get_game_state() -> Node:
	if is_inside_tree():
		return get_tree().root.get_node_or_null("GameState")
	return null
