class_name WorldRoom
extends Node2D

@export var room_id := "room"
@export var display_name := "Room"
@export var room_size := Vector2(640.0, 360.0)
@export var ambience_id := ""


func _ready() -> void:
	pass


func get_spawn_position(spawn_id: String) -> Vector2:
	var spawn_root := get_node_or_null("SpawnPoints")
	if spawn_root != null:
		var marker := spawn_root.get_node_or_null(spawn_id) as Marker2D
		if marker != null:
			return marker.global_position
		var default_marker := spawn_root.get_node_or_null("default") as Marker2D
		if default_marker != null:
			return default_marker.global_position
	return room_size * 0.5


func get_room_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, room_size)


func configure_player_camera(player: Node) -> void:
	if player != null and player.has_method("configure_room_bounds"):
		player.configure_room_bounds(get_room_bounds())


func try_forward_exit(body: Node2D) -> bool:
	var exits := get_node_or_null("Exits")
	if exits == null:
		return false
	for candidate in exits.get_children():
		if candidate.has_method("is_forward_exit") and candidate.call("is_forward_exit"):
			return bool(candidate.call("try_transition", body))
	return false
