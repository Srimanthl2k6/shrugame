class_name RoomTransition
extends Area2D

@export var transition_id := "exit"
@export var target_room_id := ""
@export var target_spawn_id := "default"
@export var required_flags: PackedStringArray = []
@export var locked_objective := ""

var enabled := true


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not enabled or not body.is_in_group("player"):
		return
	if not _requirements_met():
		var game_state := get_node_or_null("/root/GameState")
		if game_state != null and not locked_objective.is_empty():
			game_state.set_current_objective(locked_objective)
		return
	var district := _find_district()
	if district != null:
		district.request_room_change(target_room_id, target_spawn_id)


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
