extends SceneTree

const FIXTURE_PATH := "res://tests/fixtures/full_walkthrough.json"
const BATTLE_SCENE := preload("res://scenes/battle/battle_scene.tscn")
const GRID_STEP := 8
const PLAYER_HALF_SIZE := Vector2(8, 12)

var failures: Array[String] = []
var _fixture: Dictionary = {}
var _game_state
var _save_system
var _interaction_manager
var _tutorial_manager
var _original_save_paths: Array[String] = []
var _battle_count := 0
var _visited_rooms: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_fixture = _load_json(FIXTURE_PATH)
	_game_state = root.get_node_or_null("GameState")
	_save_system = root.get_node_or_null("SaveSystem")
	_interaction_manager = root.get_node_or_null("InteractionManager")
	_tutorial_manager = root.get_node_or_null("TutorialManager")
	_prepare_temporary_save()
	Engine.set_meta("shrugame_deterministic_walkthrough", true)
	Engine.remove_meta("shrugame_walkthrough_requested_scene")
	_test_fixture_and_reachability()
	for difficulty_value in _fixture.get("difficulties", []):
		await _run_complete_route(str(difficulty_value))
	_cleanup()
	_finish("Pass 77 complete two-difficulty gameplay walkthrough")


func _run_complete_route(difficulty_id: String) -> void:
	_battle_count = 0
	_visited_rooms.clear()
	_save_system.new_game(difficulty_id)
	if _tutorial_manager != null:
		_tutorial_manager.begin_new_game_sequence()
		_tutorial_manager.call("_on_skipped")
	var change_error := change_scene_to_file("res://scenes/levels/districts/level_01.tscn")
	_assert(change_error == OK, "%s walkthrough must load Level 1" % difficulty_id)
	await process_frame
	await process_frame
	for level_value in _fixture.get("levels", []):
		var level_data: Dictionary = level_value
		var level_id := str(level_data.get("level_id", ""))
		var district := current_scene as DistrictLevel
		_assert(district != null, "%s must have a live district scene for %s" % [difficulty_id, level_id])
		if district == null:
			return
		_assert(str(district.level_id) == level_id, "%s walkthrough expected %s but loaded %s" % [difficulty_id, level_id, district.level_id])
		for step_value in level_data.get("steps", []):
			var step: Dictionary = step_value
			var expected_source_room := str(step.get("room", ""))
			_visited_rooms["%s/%s" % [level_id, district.get_current_room_id()]] = true
			_assert(district.get_current_room_id() == expected_source_room, "%s route expected %s/%s before %s" % [difficulty_id, level_id, expected_source_room, step.get("type", "step")])
			match str(step.get("type", "")):
				"interaction":
					await _activate_interaction(district, str(step.get("id", "")))
				"battle":
					await _activate_interaction(district, str(step.get("id", "")))
					await _resolve_pending_battle(district, str(step.get("encounter", "")), difficulty_id)
				"edge":
					_cross_right_edge(district)
					_assert(district.get_current_room_id() == str(step.get("expect_room", "")), "%s must move right from %s to %s" % [level_id, expected_source_room, step.get("expect_room", "")])
				"level_edge":
					_cross_right_edge(district)
					await process_frame
					await process_frame
					await process_frame
					var target_level := str(step.get("target_level", ""))
					_assert(_game_state.current_level_id == target_level, "%s must transition to %s" % [level_id, target_level])
					_assert(_game_state.current_room_id == str(step.get("expect_room", "")), "%s transition must use room %s" % [target_level, step.get("expect_room", "")])
					_assert(_game_state.get_flag("%s_completed" % level_id), "%s completion must persist at its east edge" % level_id)
					_restart_from_save(target_level, str(step.get("expect_room", "")), difficulty_id)
					district = current_scene as DistrictLevel
					_assert(district != null and district.level_id == target_level, "Continue state and live scene must agree on %s" % target_level)
					continue
				_:
					_assert(false, "Unknown walkthrough step: %s" % step.get("type", ""))
			_assert_expected_progress(step, difficulty_id)

	_assert(_battle_count == 10, "%s walkthrough must resolve all ten bosses" % difficulty_id)
	for flag_value in _fixture.get("final_flags", []):
		_assert(_game_state.get_flag(str(flag_value)), "%s walkthrough must finish with %s" % [difficulty_id, flag_value])
	for gear_value in _fixture.get("final_gear", []):
		_assert(_game_state.has_gear(str(gear_value)), "%s walkthrough must retain %s" % [difficulty_id, gear_value])
	_assert(_game_state.get_growth_stage() == int(_fixture.get("final_growth_stage", 5)), "%s walkthrough must finish at growth form 5" % difficulty_id)
	_assert(str(Engine.get_meta("shrugame_walkthrough_requested_scene", "")) == "res://scenes/ending.tscn", "%s walkthrough must request the ending scene" % difficulty_id)
	_assert(_visited_rooms.size() == 27, "%s walkthrough must visit all 27 production rooms, visited %d" % [difficulty_id, _visited_rooms.size()])
	_save_system.save_game("level_05", "from_clues", "ruined_court")
	_restart_from_save("level_05", "ruined_court", difficulty_id)
	_assert(_game_state.get_flag("birthday_card_seen"), "%s final save must retain the birthday ending" % difficulty_id)


func _activate_interaction(district: DistrictLevel, interaction_id: String) -> void:
	var area := district.current_room.get_node_or_null("Interactions/%s" % interaction_id) as InteractionArea
	_assert(area != null, "%s/%s must contain interaction %s" % [district.level_id, district.get_current_room_id(), interaction_id])
	if area == null:
		return
	var player := district.player as Node2D
	var approach_offset := Vector2(-area.interaction_size.x * 0.5 - minf(12.0, area.interaction_padding.x - 2.0), 0.0)
	player.global_position = area.global_position + approach_offset
	if player.has_method("set_facing_direction"):
		player.set_facing_direction("right")
	area.call("_on_body_entered", player)
	_interaction_manager.call("_process", 0.0)
	_assert(_interaction_manager.get_focused_interaction() == area, "%s must receive centralized focus" % interaction_id)
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	_interaction_manager.call("_unhandled_input", event)
	_drain_dialogue()
	if is_instance_valid(area):
		area.call("_on_body_exited", player)
	await process_frame


func _resolve_pending_battle(district: DistrictLevel, expected_encounter: String, difficulty_id: String) -> void:
	_assert(_game_state.pending_encounter_id == expected_encounter, "%s must launch encounter %s" % [district.get_current_room_id(), expected_encounter])
	var battle: Node = BATTLE_SCENE.instantiate()
	root.add_child(battle)
	await process_frame
	if paused and _tutorial_manager != null:
		_tutorial_manager.call("_on_skipped")
	_assert(str(battle.get("active_encounter_id")) == expected_encounter, "%s must initialize the real battle scene" % expected_encounter)
	_assert(str(battle.get("difficulty_id")) == difficulty_id, "%s must use %s difficulty tuning" % [expected_encounter, difficulty_id])
	battle.set("battle_resolution", "strength")
	battle.call("resolve_battle", false)
	_battle_count += 1
	battle.queue_free()
	await process_frame
	district.call("_run_pending_story_flow")
	await process_frame


func _cross_right_edge(district: DistrictLevel) -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	district.call("_physics_process", 0.0)
	district.player.global_position = district.current_room.to_global(Vector2(601.0, 280.0))
	Input.action_press("move_right")
	district.call("_physics_process", 0.0)
	Input.action_release("move_right")
	if is_instance_valid(district) and district.is_inside_tree():
		district.call("_physics_process", 0.0)


func _restart_from_save(expected_level: String, expected_room: String, difficulty_id: String) -> void:
	_game_state.reset_progression()
	_game_state.clear_flags()
	_game_state.current_level_id = "level_01"
	_game_state.current_room_id = "arrival"
	_game_state.spawn_point = "start"
	_game_state.pending_encounter_id = ""
	var loaded: Dictionary = _save_system.load_game()
	_assert(str(loaded.get("level_id", "")) == expected_level, "Continue must restore %s" % expected_level)
	_assert(_game_state.current_room_id == expected_room, "Continue must restore room %s" % expected_room)
	_assert(_game_state.difficulty_id == difficulty_id, "Continue must retain locked %s difficulty" % difficulty_id)


func _assert_expected_progress(step: Dictionary, difficulty_id: String) -> void:
	var expected_flag := str(step.get("expect_flag", ""))
	if not expected_flag.is_empty():
		_assert(_game_state.get_flag(expected_flag), "%s route must set %s" % [difficulty_id, expected_flag])
	var expected_clue := str(step.get("expect_clue", ""))
	if not expected_clue.is_empty():
		_assert(_game_state.has_clue(expected_clue), "%s route must collect clue %s" % [difficulty_id, expected_clue])
	var expected_scene := str(step.get("expect_scene", ""))
	if not expected_scene.is_empty():
		_assert(str(Engine.get_meta("shrugame_walkthrough_requested_scene", "")) == expected_scene, "%s route must request %s" % [difficulty_id, expected_scene])


func _test_fixture_and_reachability() -> void:
	_assert(not _fixture.is_empty(), "Full walkthrough fixture must load")
	var fixture_room_count := 0
	var fixture_battle_count := 0
	var required_by_room: Dictionary = {}
	for level_value in _fixture.get("levels", []):
		var level: Dictionary = level_value
		var level_id := str(level.get("level_id", ""))
		var rooms_data := _load_json("res://data/rooms/%s_rooms.json" % level_id)
		var rooms: Dictionary = rooms_data.get("rooms", {})
		fixture_room_count += rooms.size()
		for step_value in level.get("steps", []):
			var step: Dictionary = step_value
			if str(step.get("type", "")) == "battle":
				fixture_battle_count += 1
			if str(step.get("type", "")) in ["interaction", "battle"]:
				var key := "%s/%s" % [level_id, step.get("room", "")]
				if not required_by_room.has(key):
					required_by_room[key] = []
				required_by_room[key].append(str(step.get("id", "")))
		for room_id_value in rooms:
			var room_id := str(room_id_value)
			_audit_room_reachability(level_id, room_id, rooms[room_id], required_by_room.get("%s/%s" % [level_id, room_id], []))
	_assert(fixture_room_count == 27, "Walkthrough fixture must cover all 27 rooms")
	_assert(fixture_battle_count == 10, "Walkthrough fixture must cover all ten bosses")


func _audit_room_reachability(level_id: String, room_id: String, room: Dictionary, required_ids: Array) -> void:
	var spawns: Dictionary = room.get("spawn_points", {})
	var start := Vector2(88, 280)
	var leftmost_x := INF
	for spawn_value in spawns.values():
		if typeof(spawn_value) == TYPE_ARRAY and spawn_value.size() >= 2 and float(spawn_value[0]) < leftmost_x:
			leftmost_x = float(spawn_value[0])
			start = Vector2(float(spawn_value[0]), float(spawn_value[1]))
	var reachable := _reachable_grid(start, room.get("blockers", []))
	_assert(not reachable.is_empty(), "%s/%s must have a reachable spawn" % [level_id, room_id])
	for interaction_id_value in required_ids:
		var interaction_id := str(interaction_id_value)
		var interaction := _find_interaction(room, interaction_id)
		_assert(not interaction.is_empty(), "%s/%s is missing required interaction %s" % [level_id, room_id, interaction_id])
		if interaction.is_empty():
			continue
		var position := _to_vector2(interaction.get("position", []), Vector2.ZERO)
		var authored := _to_vector2(interaction.get("interaction_size", [44, 36]), Vector2(44, 36))
		var padding := _to_vector2(interaction.get("interaction_padding", [24, 20]), Vector2(24, 20))
		var activation_rect := Rect2(position - authored * 0.5 - padding - PLAYER_HALF_SIZE, authored + (padding + PLAYER_HALF_SIZE) * 2.0)
		_assert(_grid_reaches_rect(reachable, activation_rect), "%s/%s interaction %s needs a reachable activation position" % [level_id, room_id, interaction_id])
	for exit_value in room.get("exits", []):
		var exit_data: Dictionary = exit_value
		if str(exit_data.get("id", "")).begins_with("east_to_"):
			var exit_position := _to_vector2(exit_data.get("position", [636, 280]), Vector2(636, 280))
			var exit_size := _to_vector2(exit_data.get("size", [16, 108]), Vector2(16, 108))
			var target := Rect2(Vector2(592, exit_position.y - exit_size.y * 0.5), Vector2(48, exit_size.y))
			_assert(_grid_reaches_rect(reachable, target), "%s/%s east exit must be physically reachable" % [level_id, room_id])


func _reachable_grid(start: Vector2, blocker_values: Array) -> Dictionary:
	var blockers: Array[Rect2] = []
	for blocker_value in blocker_values:
		var value: Array = blocker_value
		if value.size() >= 4:
			blockers.append(Rect2(float(value[0]) - PLAYER_HALF_SIZE.x, float(value[1]) - PLAYER_HALF_SIZE.y, float(value[2]) + PLAYER_HALF_SIZE.x * 2.0, float(value[3]) + PLAYER_HALF_SIZE.y * 2.0))
	var start_cell := Vector2i(int(round(start.x / GRID_STEP)), int(round(start.y / GRID_STEP)))
	var queue: Array[Vector2i] = [start_cell]
	var visited: Dictionary = {start_cell: true}
	var cursor := 0
	while cursor < queue.size():
		var cell: Vector2i = queue[cursor]
		cursor += 1
		for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + offset
			if visited.has(next):
				continue
			var point := Vector2(next.x * GRID_STEP, next.y * GRID_STEP)
			if point.x < PLAYER_HALF_SIZE.x + 4.0 or point.x > 640.0 - PLAYER_HALF_SIZE.x - 4.0 or point.y < 20.0 + PLAYER_HALF_SIZE.y or point.y > 340.0 - PLAYER_HALF_SIZE.y:
				continue
			var blocked := false
			for blocker in blockers:
				if blocker.has_point(point):
					blocked = true
					break
			if blocked:
				continue
			visited[next] = true
			queue.append(next)
	return visited


func _grid_reaches_rect(reachable: Dictionary, target: Rect2) -> bool:
	for cell_value in reachable.keys():
		var cell: Vector2i = cell_value
		if target.has_point(Vector2(cell.x * GRID_STEP, cell.y * GRID_STEP)):
			return true
	return false


func _drain_dialogue() -> void:
	var dialogue_manager := root.get_node_or_null("DialogueManager")
	while dialogue_manager != null and dialogue_manager.is_active():
		dialogue_manager.advance()


func _find_interaction(room: Dictionary, interaction_id: String) -> Dictionary:
	for interaction_value in room.get("interactions", []):
		var interaction: Dictionary = interaction_value
		if str(interaction.get("id", "")) == interaction_id:
			return interaction
	return {}


func _to_vector2(value, fallback: Vector2) -> Vector2:
	if typeof(value) == TYPE_ARRAY and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return fallback


func _prepare_temporary_save() -> void:
	_assert(_save_system != null and _game_state != null and _interaction_manager != null, "Walkthrough requires progression and interaction autoloads")
	if _save_system == null:
		return
	_original_save_paths = [_save_system.save_path, _save_system.backup_path, _save_system.temporary_path]
	_save_system.save_path = "user://pass77_save.json"
	_save_system.backup_path = "user://pass77_save.backup.json"
	_save_system.temporary_path = "user://pass77_save.tmp.json"
	_save_system.clear_save()


func _cleanup() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	paused = false
	Engine.remove_meta("shrugame_deterministic_walkthrough")
	Engine.remove_meta("shrugame_walkthrough_requested_scene")
	if _save_system != null:
		_save_system.clear_save()
		_save_system.save_path = _original_save_paths[0]
		_save_system.backup_path = _original_save_paths[1]
		_save_system.temporary_path = _original_save_paths[2]


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
