extends Control

@onready var clue_label: Label = $Panel/ClueLabel

var last_rendered_text := ""


func _ready() -> void:
	refresh()


func refresh() -> String:
	last_rendered_text = _build_clue_text()
	if clue_label != null:
		clue_label.text = last_rendered_text
	return last_rendered_text


func _build_clue_text() -> String:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or not game_state.has_method("get_collected_clue_ids"):
		return "No clues yet."

	var clue_ids: Array = game_state.get_collected_clue_ids()
	if clue_ids.is_empty():
		return "No clues yet."

	var clue_data := _load_json_dict("res://data/clues/clues.json")
	var lines: Array[String] = []
	for clue_id in clue_ids:
		var entry: Dictionary = clue_data.get(str(clue_id), {})
		var display_name := str(entry.get("display_name", clue_id))
		var summary := str(entry.get("summary", ""))
		if summary.is_empty():
			lines.append(display_name)
		else:
			lines.append("%s: %s" % [display_name, summary])
	return "\n".join(lines)


func _load_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data
