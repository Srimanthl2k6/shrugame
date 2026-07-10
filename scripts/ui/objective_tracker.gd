extends Control

@onready var objective_label: Label = $Panel/ObjectiveLabel

var last_rendered_text := ""


func _ready() -> void:
	refresh()


func refresh() -> String:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		last_rendered_text = "Find KFC."
	elif game_state.has_method("get_current_objective") and not game_state.get_current_objective().is_empty():
		last_rendered_text = game_state.get_current_objective()
	elif game_state.has_method("update_objective_from_level"):
		last_rendered_text = game_state.update_objective_from_level(str(game_state.get("current_level_id")))
	else:
		last_rendered_text = "Find KFC."

	if objective_label != null:
		objective_label.text = last_rendered_text
	return last_rendered_text


func set_objective(objective_text: String) -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and game_state.has_method("set_current_objective"):
		game_state.set_current_objective(objective_text)
	refresh()
