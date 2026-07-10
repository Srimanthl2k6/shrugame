extends Node2D

@export var objective_flag := ""
@export var clear_flags: PackedStringArray = []


func _ready() -> void:
	_refresh_exit_hint()


func complete_objective() -> void:
	var game_state := _get_game_state()
	if game_state == null or objective_flag.is_empty():
		return
	game_state.set_flag(objective_flag, true)
	_refresh_exit_hint()


func collect_objective(_flag_name: String = "") -> void:
	complete_objective()


func can_clear_level() -> bool:
	var game_state := _get_game_state()
	if game_state == null:
		return false
	for flag_name in clear_flags:
		if not game_state.get_flag(flag_name):
			return false
	return true


func _refresh_exit_hint() -> void:
	var exit_door := get_node_or_null("World/TransitionDoor")
	if exit_door == null:
		return
	if can_clear_level():
		exit_door.interaction_message = "The way forward opens."


func _get_game_state() -> Node:
	if is_inside_tree():
		return get_tree().root.get_node_or_null("GameState")
	return null
