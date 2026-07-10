extends Node2D

const CLEAR_FLAGS := ["hospital_records_collected", "doctor_sushan_defeated", "aeon_festival_started", "mitta_defeated"]
const LEGACY_CLEAR_FLAGS := ["level_04_objective_done", "luma_practice_cleared"]
const ROUTE_SUMMARY := [
	"1. Follow the puns to Auticity hospital.",
	"2. Collect the hospital records.",
	"3. Beat Doctor Sushan in the Pattern Serum lab.",
	"4. Start the Aeon festival.",
	"5. Defeat Mitta at the festival stage.",
	"6. Exit to Area 111."
]


func _ready() -> void:
	var game_state := _get_game_state()
	if game_state != null:
		game_state.current_level_id = "level_04"
		if game_state.has_method("get_current_objective") and game_state.get_current_objective().is_empty():
			game_state.set_current_objective("Follow the puns to Auticity hospital.")
	_sync_progression_rewards()
	_refresh_exit_hint()


func complete_objective() -> void:
	var game_state := _get_game_state()
	if game_state == null:
		return
	game_state.set_flag("level_04_objective_done", true)
	_refresh_exit_hint()


func collect_objective(flag_name: String = "") -> void:
	var game_state := _get_game_state()
	if game_state != null and not flag_name.is_empty():
		game_state.set_flag(flag_name, true)
	if flag_name == "aeon_festival_started":
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


func get_level04_route_summary() -> Array:
	return ROUTE_SUMMARY.duplicate()


func _sync_progression_rewards() -> void:
	var game_state := _get_game_state()
	if game_state == null:
		return
	if game_state.get_flag("mitta_defeated"):
		if game_state.has_method("set_growth_stage"):
			game_state.set_growth_stage(5)
		if game_state.has_method("unlock_gear"):
			game_state.unlock_gear("festival_clearance")
		game_state.set_flag("level_04_objective_done", true)
		game_state.set_flag("luma_practice_cleared", true)
		if game_state.has_method("set_current_objective"):
			game_state.set_current_objective("Auticity is free. Leave for Area 111.")


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
		exit_door.interaction_message = "Auticity is free. Area 111 flashes pink in the distance."
	else:
		exit_door.locked_message = "Auticity is not free yet: find records, beat Sushan, start Aeon Festival, and defeat Mitta."


func _get_game_state() -> Node:
	if is_inside_tree():
		return get_tree().root.get_node_or_null("GameState")
	return null
