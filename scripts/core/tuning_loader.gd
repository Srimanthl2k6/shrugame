extends RefCounted

const TUNING_PATH := "res://data/tuning/gameplay_tuning.json"
const DIFFICULTY_PATH := "res://data/difficulty/difficulty_modes.json"


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


static func load_difficulty_modes() -> Dictionary:
	var text := FileAccess.get_file_as_string(DIFFICULTY_PATH)
	if text.is_empty():
		return {}
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data


static func get_difficulty(difficulty_id: String) -> Dictionary:
	var modes := load_difficulty_modes()
	var difficulty: Dictionary = modes.get(difficulty_id, modes.get("shrububu", {}))
	return difficulty.duplicate(true)


static func get_difficulty_value(difficulty_id: String, key: String, fallback):
	return get_difficulty(difficulty_id).get(key, fallback)


static func scale_int(value: int, multiplier: float, minimum: int = 1) -> int:
	return max(minimum, int(round(float(value) * multiplier)))


static func scale_float(value: float, multiplier: float, minimum: float = 0.0) -> float:
	return max(minimum, value * multiplier)
