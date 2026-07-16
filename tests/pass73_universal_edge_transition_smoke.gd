extends SceneTree

const CANONICAL_ROUTES := {
	"level_01": ["arrival", "harbour_square", "residences_docks", "records_alley", "satyaki_waterfront"],
	"level_02": ["suburb", "monkey_plaza", "laboratory", "lab_approach", "mayor_complex"],
	"level_03": ["forest_entrance", "berry_paths", "chef_hut", "sharing_clearing", "ankit_gate"],
	"level_04": ["pun_street", "hospital_reception", "serum_ward", "festival_plaza", "mayor_stage"],
	"level_05": ["ruined_boulevard", "gummies_pub", "hooligan_alley", "bike_route", "mansion_foyer", "clue_chambers", "ruined_court"]
}

var failures: Array[String] = []
var _game_state
var _save_system
var _original_save_paths: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_game_state = root.get_node_or_null("GameState")
	_save_system = root.get_node_or_null("SaveSystem")
	_prepare_temporary_save()
	_test_transition_contract()
	await _test_every_room_threshold()
	_cleanup_temporary_save()
	_finish("Pass 73 universal far-right threshold across every district room")


func _test_transition_contract() -> void:
	var district_source := FileAccess.get_file_as_string("res://scripts/world/district_level.gd")
	var room_source := FileAccess.get_file_as_string("res://scripts/world/world_room.gd")
	var transition_source := FileAccess.get_file_as_string("res://scripts/world/room_transition.gd")
	var menu_source := FileAccess.get_file_as_string("res://scripts/core/main_menu.gd")
	var electron_source := FileAccess.get_file_as_string("res://electron/main.cjs")
	var release_source := FileAccess.get_file_as_string("res://.github/workflows/release.yml")
	_assert(district_source.contains("EDGE_MARGIN := 40.0"), "Districts must activate exits before collision can stop the player")
	_assert(district_source.contains("request_edge_transition(side, player)"), "Districts must centrally activate directional edge exits")
	_assert(room_source.contains("func try_edge_exit"), "Every room must expose a shared edge-exit API")
	_assert(transition_source.contains("func try_transition"), "Area and threshold transitions must share one implementation")
	_assert(menu_source.contains("right_edge_harbour_square"), "The reported Harbour Square save state must have a runtime probe")
	_assert(electron_source.contains("current_room === \"residences_docks\""), "Electron must verify the Harbour Square destination")
	_assert(release_source.contains("smoke --prefix electron -- right_edge_harbour_square"), "Tagged releases must run the Harbour Square probe")


func _test_every_room_threshold() -> void:
	_assert(_game_state != null and _save_system != null, "Game state and save system must be available")
	if _game_state == null or _save_system == null:
		return
	for level_id in CANONICAL_ROUTES:
		_game_state.reset_progression()
		_game_state.clear_flags()
		_game_state.current_level_id = level_id
		_game_state.current_room_id = str(CANONICAL_ROUTES[level_id][0])
		_game_state.spawn_point = "start"
		_game_state.set_flag("tutorial_overworld_completed", true)
		_game_state.set_flag("tutorial_battle_completed", true)
		var room_data := _load_json("res://data/rooms/%s_rooms.json" % level_id)
		var rooms: Dictionary = room_data.get("rooms", {})
		for cutscene_value in room_data.get("post_battle_cutscenes", []):
			var cutscene_data: Dictionary = cutscene_value
			var unless_flag := str(cutscene_data.get("unless_flag", ""))
			if not unless_flag.is_empty():
				_game_state.set_flag(unless_flag, true)
		for room_id in rooms:
			for exit_value in (rooms[room_id] as Dictionary).get("exits", []):
				var exit_data: Dictionary = exit_value
				for required_flag in exit_data.get("required_flags", []):
					_game_state.set_flag(str(required_flag), true)
		var packed := load("res://scenes/levels/districts/%s.tscn" % level_id) as PackedScene
		_assert(packed != null, "%s district scene must load" % level_id)
		if packed == null:
			continue
		var district = packed.instantiate()
		root.add_child(district)
		await process_frame
		var route: Array = CANONICAL_ROUTES[level_id]
		for index in range(route.size() - 1):
			var source_room := str(route[index])
			var target_room := str(route[index + 1])
			if district.get_current_room_id() != source_room:
				district.switch_room(source_room, "default", false)
			district.player.global_position = Vector2(601.0, 280.0)
			Input.action_release("move_left")
			Input.action_release("move_right")
			district.call("_physics_process", 0.0)
			Input.action_press("move_right")
			district.call("_physics_process", 0.0)
			_assert(district.get_current_room_id() == target_room, "%s/%s must move to %s at x=600 without Area2D overlap" % [level_id, source_room, target_room])
			Input.action_release("move_right")
			district.call("_physics_process", 0.0)
		district.queue_free()
		await process_frame


func _prepare_temporary_save() -> void:
	if _save_system == null:
		return
	_original_save_paths = [_save_system.save_path, _save_system.backup_path, _save_system.temporary_path]
	_save_system.save_path = "user://pass73_save.json"
	_save_system.backup_path = "user://pass73_save.backup.json"
	_save_system.temporary_path = "user://pass73_save.tmp.json"
	_save_system.clear_save()


func _cleanup_temporary_save() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	if _save_system == null:
		return
	_save_system.clear_save()
	_save_system.save_path = _original_save_paths[0]
	_save_system.backup_path = _original_save_paths[1]
	_save_system.temporary_path = _original_save_paths[2]
	paused = false


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
