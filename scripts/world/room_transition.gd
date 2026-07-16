class_name RoomTransition
extends Area2D

@export var transition_id := "exit"
@export var target_level_id := ""
@export var target_room_id := ""
@export var target_spawn_id := "default"
@export var required_flags: PackedStringArray = []
@export var locked_objective := ""

var enabled := true


func _ready() -> void:
	# Edge exits are polled centrally by DistrictLevel so one held input cannot
	# activate multiple rooms. Non-edge transitions retain overlap behavior.
	if get_edge_side().is_empty():
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	try_transition(body)


func try_transition(body: Node2D) -> bool:
	if not enabled or not body.is_in_group("player"):
		return false
	if not _requirements_met():
		var game_state := get_node_or_null("/root/GameState")
		if game_state != null and not locked_objective.is_empty():
			game_state.set_current_objective(locked_objective)
		return false
	if not target_level_id.is_empty():
		enabled = false
		var level_manager := get_node_or_null("/root/LevelManager")
		if level_manager == null:
			enabled = true
			return false
		var error: Error = level_manager.transition_to_level(target_level_id, target_room_id, target_spawn_id)
		if error != OK:
			enabled = true
			return false
		return true
	var district := _find_district()
	if district != null:
		return bool(district.request_room_change(target_room_id, target_spawn_id))
	return false


func is_forward_exit() -> bool:
	return get_edge_side() == "right"


func get_edge_side() -> String:
	var normalized_id := transition_id.to_lower()
	if normalized_id.begins_with("east_to_"):
		return "right"
	if normalized_id.begins_with("west_to_"):
		return "left"
	return ""


func _requirements_met() -> bool:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return required_flags.is_empty()
	for flag_name in required_flags:
		if not game_state.get_flag(flag_name):
			return false
	return true


func _find_district() -> Node:
	var candidate: Node = self
	while candidate != null:
		if candidate.has_method("request_room_change"):
			return candidate
		candidate = candidate.get_parent()
	return null
