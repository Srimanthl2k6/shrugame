extends RefCounted

var _state := "idle"


func start() -> void:
	_state = "player_command"


func set_state(next_state: String) -> void:
	_state = next_state


func get_state() -> String:
	return _state
