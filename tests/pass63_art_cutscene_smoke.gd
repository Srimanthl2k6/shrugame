extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var required_actions := ["idle_down", "idle_up", "idle_left", "idle_right", "walk_down", "walk_up", "walk_left", "walk_right", "interact", "door_slam", "battle_idle", "hurt", "victory", "growth_transform"]
	for form_number in range(1, 6):
		var form_id := "form_%02d" % form_number
		for action in required_actions:
			var path := "res://assets/shared/sprites/shrububu/%s/%s.png" % [form_id, action]
			_assert(ResourceLoader.exists(path), "%s is missing" % path)
			var texture := load(path) as Texture2D
			_assert(texture != null and texture.get_width() > 0 and texture.get_height() > 0, "%s must import as visible art" % path)

	for level_number in range(1, 6):
		var room_data := _load_json("res://data/rooms/level_%02d_rooms.json" % level_number)
		for room_value in (room_data.get("rooms", {}) as Dictionary).values():
			var room: Dictionary = room_value
			var background_path := str(room.get("background", ""))
			var texture := load(background_path) as Texture2D
			_assert(texture != null, "%s must load" % background_path)
			if texture != null:
				_assert(texture.get_size() == Vector2(640, 360), "%s must be 640x360" % background_path)

	var cutscene_catalog := _load_json("res://data/cutscenes/index.json")
	var used_step_types: Dictionary = {}
	for path_value in cutscene_catalog.values():
		var data := _load_json(str(path_value))
		for step_value in data.get("steps", []):
			if typeof(step_value) == TYPE_DICTIONARY:
				used_step_types[str((step_value as Dictionary).get("type", ""))] = true
	for required_type in ["camera_pan", "camera_zoom", "actor_animation", "music_state", "checkpoint", "cut_in", "dialogue", "start_battle"]:
		_assert(used_step_types.has(required_type), "Cutscene catalog must exercise %s" % required_type)

	var production_text := ""
	for path in ["res://scenes/main.tscn", "res://scripts/core/runtime_resource_manifest.gd"]:
		production_text += FileAccess.get_file_as_string(path)
	for forbidden in ["Pink NPC", "Red boss", "Yellow clue", "Route: door", "SHRUBUBU BODY"]:
		_assert(not production_text.contains(forbidden), "Production presentation still contains debug label: %s" % forbidden)
	for private_reference in ["shrububu- child", "shrububu- older"]:
		_assert(not production_text.contains(private_reference), "Private reference leaked into runtime manifest")
	_finish("Pass 63 final art and cutscene contract")


func _load_json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish(label: String) -> void:
	if failures.is_empty():
		print("PASS: %s" % label)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
