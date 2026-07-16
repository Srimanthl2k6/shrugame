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
var _director
var _original_save_paths: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_game_state = root.get_node_or_null("GameState")
	_save_system = root.get_node_or_null("SaveSystem")
	_director = root.get_node_or_null("CutsceneDirector")
	_prepare_temporary_save()
	_test_route_data_contract()
	await _test_bidirectional_runtime()
	await _test_controller_edge_latch()
	await _test_laboratory_progression()
	_cleanup_temporary_save()
	_finish("Pass 74 Level 2 progression and single-step bidirectional navigation")


func _test_route_data_contract() -> void:
	for level_id in CANONICAL_ROUTES:
		var data := _load_json("res://data/rooms/%s_rooms.json" % level_id)
		var rooms: Dictionary = data.get("rooms", {})
		var route: Array = CANONICAL_ROUTES[level_id]
		for index in range(1, route.size()):
			var room_id := str(route[index])
			var previous_id := str(route[index - 1])
			var west := _find_exit(rooms.get(room_id, {}), "west_to_")
			_assert(str(west.get("target_room_id", "")) == previous_id, "%s/%s west exit must target immediate predecessor %s" % [level_id, room_id, previous_id])
			_assert(_array_number(west.get("position", []), 0) == 4.0, "%s/%s west exit must be anchored at x=4" % [level_id, room_id])
			_assert(_array_number(west.get("size", []), 0) == 16.0, "%s/%s west exit must use a 16px strip" % [level_id, room_id])
			var target_room: Dictionary = rooms.get(previous_id, {})
			var spawn_id := str(west.get("target_spawn_id", ""))
			var spawn: Array = target_room.get("spawn_points", {}).get(spawn_id, [])
			_assert(_array_number(spawn, 0) >= 500.0, "%s/%s west return spawn must be on the target room's right side" % [level_id, room_id])

	var level_two := _load_json("res://data/rooms/level_02_rooms.json")
	var lab: Dictionary = level_two.get("rooms", {}).get("laboratory", {})
	var records := _find_interaction(lab, "LabRecords")
	_assert(str(records.get("visual", "")).ends_with("prop_165_files.png"), "The canonical 165-files must be visible")
	_assert(bool(records.get("auto_activate_on_body_enter", false)), "The canonical 165-files must auto-activate")
	_assert(str(records.get("flag_on_interact", "")) == "165_files_collected", "The visible files must set the progression flag")
	_assert(str(records.get("clue_id", "")) == "165_files", "The visible files must collect the canonical clue")
	_assert(_array_number(records.get("position", []), 1) > 254.0, "The files must sit below the laboratory's central blocker")
	_assert(_find_interaction(lab, "BananaGunCase").is_empty(), "The misleading optional file-like interaction must be removed")
	for required_id in ["NitinBoss", "PopcornBreak"]:
		var interaction := _find_interaction(level_two.get("rooms", {}).get("lab_approach", {}), required_id)
		_assert(bool(interaction.get("auto_activate_on_body_enter", false)), "%s must auto-activate on the required route" % required_id)
	var deepak := _find_interaction(level_two.get("rooms", {}).get("mayor_complex", {}), "DeepakBoss")
	_assert(bool(deepak.get("auto_activate_on_body_enter", false)), "Deepak must auto-activate on the required route")
	var menu_source := FileAccess.get_file_as_string("res://scripts/core/main_menu.gd")
	var electron_source := FileAccess.get_file_as_string("res://electron/main.cjs")
	var release_source := FileAccess.get_file_as_string("res://.github/workflows/release.yml")
	_assert(menu_source.contains("level_02_lab_progression"), "Godot must expose the clean laboratory smoke state")
	_assert(electron_source.contains('encounter_id === "nitin_janitor_boss"'), "Electron must verify that the Nitin encounter starts")
	_assert(release_source.contains("smoke --prefix electron -- level_02_lab_progression"), "Tagged releases must run the laboratory-to-Nitin probe")


func _test_bidirectional_runtime() -> void:
	_assert(_game_state != null and _save_system != null, "Navigation test requires GameState and SaveSystem")
	if _game_state == null or _save_system == null:
		return
	for level_id in CANONICAL_ROUTES:
		_prepare_level_state(level_id)
		var packed := load("res://scenes/levels/districts/%s.tscn" % level_id) as PackedScene
		var district = packed.instantiate() if packed != null else null
		_assert(district != null, "%s district must instantiate" % level_id)
		if district == null:
			continue
		root.add_child(district)
		await process_frame
		var route: Array = CANONICAL_ROUTES[level_id]
		for index in range(route.size() - 1, 0, -1):
			var source := str(route[index])
			var target := str(route[index - 1])
			district.switch_room(source, "default", false)
			_neutralize_edge_input(district)
			district.player.global_position = Vector2(39.0, 280.0)
			Input.action_press("move_left")
			district.call("_physics_process", 0.0)
			_assert(district.get_current_room_id() == target, "%s/%s must move west once to %s" % [level_id, source, target])
			if index > 1:
				district.player.global_position = Vector2(39.0, 280.0)
				district.call("_physics_process", 0.0)
				_assert(district.get_current_room_id() == target, "%s held-left input must not skip west past %s" % [level_id, target])
			Input.action_release("move_left")
			district.call("_physics_process", 0.0)
		district.queue_free()
		await process_frame


func _test_controller_edge_latch() -> void:
	_assert(_has_controller_axis("move_left", -1.0), "Controller left-stick input must be bound to move_left")
	_assert(_has_controller_axis("move_right", 1.0), "Controller left-stick input must be bound to move_right")
	_prepare_level_state("level_01")
	var packed := load("res://scenes/levels/districts/level_01.tscn") as PackedScene
	var district = packed.instantiate() if packed != null else null
	_assert(district != null, "Controller navigation district must instantiate")
	if district == null:
		return
	root.add_child(district)
	await process_frame
	district.switch_room("records_alley", "default", false)
	_neutralize_edge_input(district)
	district.player.global_position = Vector2(39.0, 280.0)
	Input.action_press("move_left")
	district.call("_physics_process", 0.0)
	_assert(district.get_current_room_id() == "residences_docks", "Controller left input must move back exactly one room")
	district.player.global_position = Vector2(39.0, 280.0)
	district.call("_physics_process", 0.0)
	_assert(district.get_current_room_id() == "residences_docks", "Held controller input must not skip a second room")
	Input.action_release("move_left")
	district.call("_physics_process", 0.0)
	Input.action_press("move_left")
	district.call("_physics_process", 0.0)
	_assert(district.get_current_room_id() == "harbour_square", "A released and repeated controller input must allow one more room")
	Input.action_release("move_left")
	district.queue_free()
	await process_frame


func _test_laboratory_progression() -> void:
	_assert(_game_state != null and _save_system != null and _director != null, "Laboratory test requires progression autoloads")
	if _game_state == null or _save_system == null or _director == null:
		return
	_prepare_level_state("level_02")
	_game_state.current_room_id = "laboratory"
	_game_state.spawn_point = "from_plaza"
	var packed := load("res://scenes/levels/districts/level_02.tscn") as PackedScene
	var district = packed.instantiate() if packed != null else null
	_assert(district != null, "Level 2 district must instantiate for laboratory progression")
	if district == null:
		return
	root.add_child(district)
	await process_frame
	_assert(district.get_current_room_id() == "laboratory", "Existing laboratory saves must reopen in the laboratory")
	var records = district.current_room.get_node_or_null("Interactions/LabRecords")
	_assert(records != null and records.get_node_or_null("Visual") != null, "The reachable laboratory files must have a visible runtime sprite")
	if records == null:
		district.queue_free()
		return
	district.player.global_position = records.global_position
	records.call("_on_body_entered", district.player)
	await process_frame
	await process_frame
	_assert(_game_state.get_flag("165_files_collected"), "Activating the visible files must immediately set 165_files_collected")
	_assert(_game_state.has_clue("165_files"), "Activating the visible files must collect the 165-files clue")
	_assert(_game_state.get_current_objective() == "Walk right and confront Nitin.", "The laboratory objective must explicitly direct the player right")
	var saved := _load_user_json(_save_system.save_path)
	_assert(str(saved.get("room_id", "")) == "laboratory", "The laboratory interaction must persist the current room")
	_assert(bool(saved.get("story_flags", {}).get("165_files_collected", false)), "The laboratory interaction must atomically persist its progression flag")
	if _director.is_playing:
		_director.skip_current()
	for _frame in range(8):
		await process_frame
		if not _director.is_playing:
			break
	_game_state.set_flag("nitin_defeat_seen", true)
	_neutralize_edge_input(district)
	district.player.global_position = Vector2(601.0, 280.0)
	Input.action_press("move_right")
	district.call("_physics_process", 0.0)
	Input.action_release("move_right")
	_assert(district.get_current_room_id() == "lab_approach", "Walking right after the files must enter the lab approach")
	district.call("_physics_process", 0.0)
	var nitin = district.current_room.get_node_or_null("Interactions/NitinBoss")
	_assert(nitin != null, "Nitin must exist on the laboratory exit route")
	if nitin != null:
		district.player.global_position = nitin.global_position
		nitin.call("_on_body_entered", district.player)
		await process_frame
		await process_frame
		_assert(_director.is_playing and _director.active_cutscene_id == "nitin_confrontation", "Reaching Nitin must automatically start his confrontation")
		if _director.is_playing:
			_director.skip_current()
		for _frame in range(8):
			await process_frame
		_assert(_game_state.pending_encounter_id == "nitin_janitor_boss", "Nitin's automatic confrontation must launch the correct battle")
	district.queue_free()
	await process_frame


func _prepare_level_state(level_id: String) -> void:
	_game_state.reset_progression()
	_game_state.clear_flags()
	_game_state.current_level_id = level_id
	_game_state.current_room_id = str(CANONICAL_ROUTES[level_id][0])
	_game_state.spawn_point = "start"
	_game_state.pending_encounter_id = ""
	_game_state.set_flag("tutorial_overworld_completed", true)
	_game_state.set_flag("tutorial_battle_completed", true)
	var room_data := _load_json("res://data/rooms/%s_rooms.json" % level_id)
	for cutscene_value in room_data.get("post_battle_cutscenes", []):
		var unless_flag := str((cutscene_value as Dictionary).get("unless_flag", ""))
		if not unless_flag.is_empty():
			_game_state.set_flag(unless_flag, true)
	for room_value in room_data.get("rooms", {}).values():
		for exit_value in (room_value as Dictionary).get("exits", []):
			for flag_name in (exit_value as Dictionary).get("required_flags", []):
				_game_state.set_flag(str(flag_name), true)
	if level_id == "level_02":
		for flag_name in ["165_files_collected", "nitin_defeated", "monkeys_spell_broken", "deepak_reddy_defeated"]:
			_game_state.set_flag(flag_name, false)


func _neutralize_edge_input(district) -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	district.call("_physics_process", 0.0)


func _has_controller_axis(action: String, expected_value: float) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion:
			var motion := event as InputEventJoypadMotion
			if motion.axis == JOY_AXIS_LEFT_X and is_equal_approx(motion.axis_value, expected_value):
				return true
	return false


func _find_exit(room: Dictionary, prefix: String) -> Dictionary:
	for exit_value in room.get("exits", []):
		var exit_data: Dictionary = exit_value
		if str(exit_data.get("id", "")).begins_with(prefix):
			return exit_data
	return {}


func _find_interaction(room: Dictionary, interaction_id: String) -> Dictionary:
	for interaction_value in room.get("interactions", []):
		var interaction: Dictionary = interaction_value
		if str(interaction.get("id", "")) == interaction_id:
			return interaction
	return {}


func _array_number(value, index: int) -> float:
	if typeof(value) == TYPE_ARRAY and value.size() > index:
		return float(value[index])
	return -1.0


func _prepare_temporary_save() -> void:
	if _save_system == null:
		return
	_original_save_paths = [_save_system.save_path, _save_system.backup_path, _save_system.temporary_path]
	_save_system.save_path = "user://pass74_save.json"
	_save_system.backup_path = "user://pass74_save.backup.json"
	_save_system.temporary_path = "user://pass74_save.tmp.json"
	_save_system.clear_save()


func _cleanup_temporary_save() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	if _save_system != null:
		_save_system.clear_save()
		_save_system.save_path = _original_save_paths[0]
		_save_system.backup_path = _original_save_paths[1]
		_save_system.temporary_path = _original_save_paths[2]
	paused = false


func _load_json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _load_user_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
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
