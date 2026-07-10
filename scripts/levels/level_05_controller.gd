extends Node2D

const CLEAR_FLAGS := ["mansion_court_clues_collected", "suhas_defeated", "srmt_defeated", "ishiyoga_rescued"]
const LEGACY_CLEAR_FLAGS := ["level_05_objective_done", "nulla_practice_cleared"]
const ROUTE_SUMMARY := [
	"1. Visit the Gummies pub and ask about chicken.",
	"2. Beat Suhas in the bar fight.",
	"3. Take the bike and guitar rewards.",
	"4. Solve the fallen mansion and court clues.",
	"5. Defeat SRMT on the ruined throne.",
	"6. Rescue IshiYoga in the KFC dungeon.",
	"7. Take the ending route back through Ishiville."
]


func _ready() -> void:
	var game_state := _get_game_state()
	if game_state != null:
		game_state.current_level_id = "level_05"
		if game_state.has_method("get_current_objective") and game_state.get_current_objective().is_empty():
			game_state.set_current_objective("Find KFC in Area 111.")
	_sync_progression_rewards()
	_refresh_exit_hint()


func complete_objective() -> void:
	var game_state := _get_game_state()
	if game_state == null:
		return
	game_state.set_flag("level_05_objective_done", true)
	_refresh_exit_hint()


func collect_objective(flag_name: String = "") -> void:
	var game_state := _get_game_state()
	if game_state != null and not flag_name.is_empty():
		game_state.set_flag(flag_name, true)
	if flag_name == "ishiyoga_rescued":
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


func get_level05_route_summary() -> Array:
	return ROUTE_SUMMARY.duplicate()


func _sync_progression_rewards() -> void:
	var game_state := _get_game_state()
	if game_state == null:
		return
	if game_state.get_flag("suhas_defeated"):
		game_state.set_flag("bike_unlocked", true)
		game_state.set_flag("musical_guitar_unlocked", true)
		if game_state.has_method("unlock_gear"):
			game_state.unlock_gear("musical_guitar")
	if game_state.get_flag("srmt_defeated") and game_state.has_method("set_growth_stage"):
		game_state.set_growth_stage(5)
	if game_state.get_flag("ishiyoga_rescued"):
		game_state.set_flag("level_05_objective_done", true)
		game_state.set_flag("nulla_practice_cleared", true)
		if game_state.has_method("set_current_objective"):
			game_state.set_current_objective("IshiYoga is free. Ishiville gets KFC.")


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
		exit_door.interaction_message = "IshiYoga is free. Ishiville gets KFC."
	else:
		exit_door.locked_message = "The ending needs Suhas beaten, SRMT defeated, and IshiYoga rescued."


func _get_game_state() -> Node:
	if is_inside_tree():
		return get_tree().root.get_node_or_null("GameState")
	return null
