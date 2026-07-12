extends SceneTree

const CANONICAL_ROUTES := {
	"level_01": ["arrival", "harbour_square", "residences_docks", "records_alley", "satyaki_waterfront"],
	"level_02": ["suburb", "monkey_plaza", "laboratory", "lab_approach", "mayor_complex"],
	"level_03": ["forest_entrance", "berry_paths", "chef_hut", "sharing_clearing", "ankit_gate"],
	"level_04": ["pun_street", "hospital_reception", "serum_ward", "festival_plaza", "mayor_stage"],
	"level_05": ["ruined_boulevard", "gummies_pub", "hooligan_alley", "bike_route", "mansion_foyer", "clue_chambers", "ruined_court"]
}

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_canonical_routes()
	_test_banana_burbs_is_linear()
	_test_packaged_navigation_probe()
	await _test_runtime_edge_geometry()
	_finish("Pass 72 far-right navigation and linear Banana-burbs route")


func _test_canonical_routes() -> void:
	for level_id in CANONICAL_ROUTES:
		var data := _load_json("res://data/rooms/%s_rooms.json" % level_id)
		var rooms: Dictionary = data.get("rooms", {})
		var route: Array = CANONICAL_ROUTES[level_id]
		for index in range(route.size() - 1):
			var source_id := str(route[index])
			var target_id := str(route[index + 1])
			_assert(rooms.has(source_id), "%s is missing canonical room %s" % [level_id, source_id])
			if not rooms.has(source_id):
				continue
			var forward_exit := _find_room_exit(rooms[source_id], target_id, "")
			_assert(not forward_exit.is_empty(), "%s/%s must continue east to %s" % [level_id, source_id, target_id])
			_assert(str(forward_exit.get("id", "")).begins_with("east_to_"), "%s/%s forward route must be eastbound" % [level_id, source_id])
			_assert(_array_number(forward_exit.get("position", []), 0) == 636.0, "%s/%s forward trigger must sit at the far-right edge" % [level_id, source_id])
			_assert(_array_number(forward_exit.get("size", []), 0) == 16.0, "%s/%s forward trigger must use the narrow edge strip" % [level_id, source_id])
		for room_id in rooms:
			for exit_value in (rooms[room_id] as Dictionary).get("exits", []):
				var exit_data: Dictionary = exit_value
				var exit_id := str(exit_data.get("id", ""))
				_assert(not exit_id.begins_with("north_to_") and not exit_id.begins_with("south_to_"), "%s/%s must not hide required navigation above or below the screen" % [level_id, room_id])
		if level_id != "level_05":
			var final_room: Dictionary = rooms[str(route.back())]
			var next_level := "level_%02d" % (int(level_id.right(2)) + 1)
			var district_exit := _find_room_exit(final_room, "", next_level)
			_assert(not district_exit.is_empty(), "%s final room must continue to %s" % [level_id, next_level])
			_assert(str(district_exit.get("id", "")).begins_with("east_to_"), "%s district road must be eastbound" % level_id)
			_assert(_array_number(district_exit.get("position", []), 0) == 636.0, "%s district road must sit at the far-right edge" % level_id)


func _test_banana_burbs_is_linear() -> void:
	var data := _load_json("res://data/rooms/level_02_rooms.json")
	var rooms: Dictionary = data.get("rooms", {})
	var plaza: Dictionary = rooms.get("monkey_plaza", {})
	var laboratory: Dictionary = rooms.get("laboratory", {})
	var approach: Dictionary = rooms.get("lab_approach", {})
	_assert(not _find_room_exit(plaza, "laboratory", "").is_empty(), "Monkey Plaza must lead directly east to the laboratory")
	var lab_exit := _find_room_exit(laboratory, "lab_approach", "")
	_assert((lab_exit.get("required_flags", []) as Array).has("165_files_collected"), "Laboratory east edge must gate on the 165-files")
	var mayor_exit := _find_room_exit(approach, "mayor_complex", "")
	_assert((mayor_exit.get("required_flags", []) as Array).has("monkeys_spell_broken"), "Lab approach east edge must gate the mayor route on the popcorn event")
	var has_popcorn := false
	for interaction_value in approach.get("interactions", []):
		var interaction: Dictionary = interaction_value
		has_popcorn = has_popcorn or str(interaction.get("id", "")) == "PopcornBreak"
	_assert(has_popcorn, "The popcorn event must sit on the forward route beside Nitin")
	var config := _load_json("res://data/levels/level_02_config.json")
	var paths: Array = config.get("room_scene_paths", [])
	_assert(paths.size() == 5 and str(paths[2]).ends_with("laboratory.tscn") and str(paths[3]).ends_with("lab_approach.tscn"), "Level 2 config must document the new linear room order")


func _test_packaged_navigation_probe() -> void:
	var menu_source := FileAccess.get_file_as_string("res://scripts/core/main_menu.gd")
	var electron_source := FileAccess.get_file_as_string("res://electron/main.cjs")
	var release_source := FileAccess.get_file_as_string("res://.github/workflows/release.yml")
	_assert(menu_source.contains("right_edge_level_02"), "Godot must expose the Level 2 edge-transition smoke state")
	_assert(electron_source.contains("current_room === \"lab_approach\""), "Electron must verify the destination room")
	_assert(electron_source.contains("app.exit(passed ? 0 : 1)"), "Electron smoke failures must propagate as process failures")
	_assert(release_source.contains("smoke --prefix electron -- right_edge_level_02"), "Tagged releases must run the right-edge navigation probe")


func _test_runtime_edge_geometry() -> void:
	var packed := load("res://scenes/levels/rooms/level_01/arrival.tscn") as PackedScene
	_assert(packed != null, "Arrival room must load for runtime edge verification")
	if packed == null:
		return
	var room = packed.instantiate()
	root.add_child(room)
	await process_frame
	var exit_area := room.get_node_or_null("Exits/east_to_square") as Area2D
	_assert(exit_area != null, "Arrival must instantiate its east edge trigger")
	if exit_area != null:
		_assert(is_equal_approx(exit_area.position.x, 636.0), "Runtime must align east triggers to x=636")
		var collision := exit_area.get_child(0) as CollisionShape2D if exit_area.get_child_count() > 0 else null
		var rectangle := collision.shape as RectangleShape2D if collision != null else null
		_assert(rectangle != null and is_equal_approx(rectangle.size.x, 16.0), "Runtime east trigger must be a 16px edge strip")
	var right_wall_body := room.get_node_or_null("BoundaryWalls/RightWall") as StaticBody2D
	var right_wall := right_wall_body.get_child(0) as CollisionShape2D if right_wall_body != null and right_wall_body.get_child_count() > 0 else null
	var wall_rectangle := right_wall.shape as RectangleShape2D if right_wall != null else null
	_assert(wall_rectangle != null and is_equal_approx(wall_rectangle.size.x, 4.0), "Right boundary must allow the player to reach the edge trigger")
	room.queue_free()
	await process_frame


func _find_room_exit(room: Dictionary, target_room: String, target_level: String) -> Dictionary:
	for exit_value in room.get("exits", []):
		var exit_data: Dictionary = exit_value
		if not target_room.is_empty() and str(exit_data.get("target_room_id", "")) == target_room:
			return exit_data
		if not target_level.is_empty() and str(exit_data.get("target_level_id", "")) == target_level:
			return exit_data
	return {}


func _array_number(value, index: int) -> float:
	if typeof(value) == TYPE_ARRAY and value.size() > index:
		return float(value[index])
	return -1.0


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
