extends RefCounted

const TUNING_PATH := "res://data/tuning/gameplay_tuning.json"


static func load_data() -> Dictionary:
	var text := FileAccess.get_file_as_string(TUNING_PATH)
	if text.is_empty():
		return {}
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data


static func get_value(path: Array, fallback):
	var current = load_data()
	for key in path:
		if typeof(current) != TYPE_DICTIONARY or not current.has(key):
			return fallback
		current = current[key]
	return current


static func get_vector2(path: Array, fallback: Vector2) -> Vector2:
	var value = get_value(path, [])
	if typeof(value) != TYPE_ARRAY or value.size() < 2:
		return fallback
	return Vector2(float(value[0]), float(value[1]))
