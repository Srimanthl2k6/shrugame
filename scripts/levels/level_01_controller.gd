extends Node2D

const CLEAR_FLAGS := ["poojan_defeated", "divorce_records_collected", "satyaki_tirumal_defeated"]
const TAG_FLAGS := ["tag_flour", "tag_cups", "tag_broom"]
const LEGACY_CLEAR_FLAGS := ["met_marn", "marn_practice_cleared", "pantry_tags_sorted"]
const ROUTE_SUMMARY := [
	"1. Slam the fake KFC door.",
	"2. Beat Sheriff Poojan.",
	"3. Collect the divorce records.",
	"4. Confront Satyaki Tirumal.",
	"5. Exit to Banana-burbs."
]


func _ready() -> void:
	var game_state := _get_game_state()
	if game_state != null:
		game_state.current_level_id = "level_01"
		if game_state.has_method("get_current_objective") and game_state.get_current_objective().is_empty():
			game_state.set_current_objective("Find KFC in Divorcee Harbour.")
	_sync_progression_rewards()
	_refresh_exit_hint()


func collect_objective(_flag_name: String = "") -> void:
	_sync_progression_rewards()
	_refresh_exit_hint()


func collect_tag(flag_name: String) -> void:
	var game_state := _get_game_state()
	if game_state == null or not TAG_FLAGS.has(flag_name):
		return
	game_state.set_flag(flag_name, true)
	if get_collected_tag_count() >= TAG_FLAGS.size():
		game_state.set_flag("pantry_tags_sorted", true)
	_refresh_exit_hint()


func get_collected_tag_count() -> int:
	var game_state := _get_game_state()
	if game_state == null:
		return 0
	var count := 0
	for flag_name in TAG_FLAGS:
		if game_state.get_flag(flag_name):
			count += 1
	return count


func can_clear_level() -> bool:
	var game_state := _get_game_state()
	if game_state == null:
		return false
	if _has_flags(game_state, LEGACY_CLEAR_FLAGS):
		return true
	return _has_flags(game_state, CLEAR_FLAGS)


func get_level01_route_summary() -> Array[String]:
	return ROUTE_SUMMARY.duplicate()


func _has_flags(game_state: Node, flag_names: Array) -> bool:
	for flag_name in flag_names:
		if not game_state.get_flag(flag_name):
			return false
	return true


func _sync_progression_rewards() -> void:
	var game_state := _get_game_state()
	if game_state == null:
		return
	if game_state.get_flag("poojan_defeated") and game_state.has_method("unlock_gear"):
		game_state.unlock_gear("revolver")
	if game_state.get_flag("satyaki_tirumal_defeated") and game_state.has_method("set_growth_stage"):
		game_state.set_growth_stage(2)
		game_state.set_current_objective("Divorcee Harbour is free. Leave for Banana-burbs.")
		game_state.set_flag("met_marn", true)
		game_state.set_flag("marn_practice_cleared", true)
		game_state.set_flag("pantry_tags_sorted", true)


func _refresh_exit_hint() -> void:
	var exit_door := get_node_or_null("World/TransitionDoor")
	if exit_door == null:
		return
	if can_clear_level():
		exit_door.interaction_message = "Divorcee Harbour is free. Banana-burbs waits inland."
	else:
		exit_door.locked_message = "Divorcee Harbour is not free yet: beat Poojan, collect the divorce records, and defeat Satyaki."


func _get_game_state() -> Node:
	if is_inside_tree():
		return get_tree().root.get_node_or_null("GameState")
	return null
