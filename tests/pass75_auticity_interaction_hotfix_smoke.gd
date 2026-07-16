extends SceneTree

var failures: Array[String] = []
var _game_state
var _save_system
var _interaction_manager
var _original_save_paths: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_game_state = root.get_node_or_null("GameState")
	_save_system = root.get_node_or_null("SaveSystem")
	_interaction_manager = root.get_node_or_null("InteractionManager")
	_prepare_temporary_save()
	_test_data_contract()
	_test_legacy_map_migration()
	await _test_hospital_runtime_progression()
	await _test_focus_selection_and_padding()
	_cleanup()
	_finish("Pass 75 Auticity recovery and centralized interaction targeting")


func _test_data_contract() -> void:
	var rooms := _load_json("res://data/rooms/level_04_rooms.json")
	var reception: Dictionary = rooms.get("rooms", {}).get("hospital_reception", {})
	var records := _find_interaction(reception, "HospitalRecords")
	_assert(not records.is_empty(), "Auticity must expose one required hospital records terminal")
	_assert(_find_interaction(reception, "HospitalMap").is_empty(), "The ambiguous hospital map must not remain interactive")
	_assert(str(records.get("clue_id", "")) == "hospital_records", "The visible terminal must grant hospital_records")
	_assert(bool(records.get("persist_progress_on_activate", false)), "Hospital records must persist atomically")
	_assert(str(records.get("objective_text", "")) == "Walk right into the Pattern Serum ward and confront Doctor Sushan.", "Hospital records must direct the player right")
	var east := _find_exit(reception, "east_to_ward")
	_assert((east.get("required_flags", []) as Array).has("hospital_records_collected"), "The ward exit must use the terminal's flag")
	_assert(str(east.get("locked_objective", "")).contains("glowing hospital records terminal"), "The locked exit must identify the terminal")
	var dialogue := _load_json("res://data/dialogue/level_04_dialogue.json")
	var records_lines: Array = dialogue.get("hospital_records", {}).get("lines", [])
	_assert("SRMT wants lab results by midnight." in " ".join(PackedStringArray(records_lines)), "The midnight note must be part of the required records")
	var tuning := _load_json("res://data/tuning/gameplay_tuning.json")
	_assert(not tuning.get("overworld", {}).has("interaction_size"), "Global tuning must not overwrite authored interaction sizes")
	_assert(tuning.get("overworld", {}).get("interaction_padding", []) == [24.0, 20.0], "Shared interaction padding must be 24x20 per side")
	var presentation := FileAccess.get_file_as_string("res://scripts/visual/presentation_guide.gd")
	_assert(presentation.contains("InteractionManager"), "The bottom prompt must use centralized focus")
	_assert(presentation.contains("top_bar.visible = show_objectives"), "Objective visibility must not hide interaction prompts")
	var menu_source := FileAccess.get_file_as_string("res://scripts/core/main_menu.gd")
	var electron_source := FileAccess.get_file_as_string("res://electron/main.cjs")
	var release_source := FileAccess.get_file_as_string("res://.github/workflows/release.yml")
	_assert(menu_source.contains("level_04_hospital_progression") and menu_source.contains("full_progression"), "Godot must expose both packaged 1.0.5 probes")
	_assert(electron_source.contains('encounter_id === "doctor_sushan_boss"'), "Electron must verify the Auticity records-to-Sushan route")
	_assert(electron_source.contains("fullProgressionDiagnostics?.saves_verified === 4"), "Electron must verify all four district saves")
	_assert(release_source.contains("level_04_hospital_progression") and release_source.contains("full_progression"), "Tagged releases must run both 1.0.5 packaged probes")


func _test_legacy_map_migration() -> void:
	_assert(_save_system != null and _game_state != null, "Migration requires SaveSystem and GameState")
	if _save_system == null or _game_state == null:
		return
	_save_system.clear_save()
	var legacy := {
		"schema_version": 3,
		"level_id": "level_04",
		"room_id": "hospital_reception",
		"spawn_point": "from_street",
		"story_flags": {"hospital_map_collected": true, "clue_hospital_map_seen": true},
		"clues": {"hospital_map": true},
		"inventory": {},
		"gear": {},
		"defeated_bosses": {},
		"difficulty_id": "shrububu",
		"current_objective": "Explore the hospital map."
	}
	var file := FileAccess.open(_save_system.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy, "\t"))
	file = null
	var loaded: Dictionary = _save_system.load_game()
	_assert(int(loaded.get("schema_version", 0)) == 4, "Legacy Auticity saves must migrate to schema 4")
	_assert(_game_state.get_flag("hospital_records_collected"), "Reading the old map must grant the new records flag")
	_assert(_game_state.has_clue("hospital_records"), "Reading the old map must grant the new records clue")
	_assert(_game_state.get_current_objective() == "Walk right into the Pattern Serum ward and confront Doctor Sushan.", "Migrated saves must receive the repaired objective")
	var rewritten := _load_user_json(_save_system.save_path)
	_assert(int(rewritten.get("schema_version", 0)) == 4, "Migrated saves must be rewritten atomically")
	_assert(bool(rewritten.get("story_flags", {}).get("hospital_records_collected", false)), "The rewritten save must persist recovered progression")


func _test_hospital_runtime_progression() -> void:
	_save_system.clear_save()
	_game_state.reset_progression()
	_game_state.clear_flags()
	_game_state.current_level_id = "level_04"
	_game_state.current_room_id = "hospital_reception"
	_game_state.spawn_point = "from_street"
	_game_state.set_flag("tutorial_overworld_completed", true)
	_game_state.set_flag("tutorial_battle_completed", true)
	_save_system.save_game("level_04", "from_street", "hospital_reception")
	var packed := load("res://scenes/levels/districts/level_04.tscn") as PackedScene
	var district = packed.instantiate() if packed != null else null
	_assert(district != null, "Auticity district must instantiate")
	if district == null:
		return
	root.add_child(district)
	await process_frame
	var records := district.current_room.get_node_or_null("Interactions/HospitalRecords") as InteractionArea
	_assert(records != null and records.get_node_or_null("Visual") != null, "The records terminal must be a visible runtime interaction")
	if records == null:
		district.queue_free()
		return
	var shape := records.get_node("CollisionShape2D").shape as RectangleShape2D
	_assert(shape.size == records.interaction_size + records.interaction_padding * 2.0, "Runtime interaction geometry must preserve authored size plus padding")
	district.player.global_position = records.global_position + Vector2(-records.interaction_size.x * 0.5 - 12.0, 0.0)
	records.call("_on_body_entered", district.player)
	_interaction_manager.call("_process", 0.0)
	_assert(_interaction_manager.get_focused_interaction() == records, "Approaching the terminal must select it")
	_activate_focused()
	_assert(_game_state.get_flag("hospital_records_collected"), "Activating the terminal must grant hospital_records_collected")
	_assert(_game_state.has_clue("hospital_records"), "Activating the terminal must collect the hospital records")
	_assert(_game_state.get_current_objective() == "Walk right into the Pattern Serum ward and confront Doctor Sushan.", "The terminal must update the objective immediately")
	var saved := _load_user_json(_save_system.save_path)
	_assert(str(saved.get("room_id", "")) == "hospital_reception", "The terminal must save the current room")
	_assert(bool(saved.get("story_flags", {}).get("hospital_records_collected", false)), "The terminal must atomically save its flag")
	_drain_dialogue()
	Input.action_release("move_right")
	district.call("_physics_process", 0.0)
	district.player.global_position = Vector2(601.0, 280.0)
	Input.action_press("move_right")
	district.call("_physics_process", 0.0)
	Input.action_release("move_right")
	district.call("_physics_process", 0.0)
	_assert(district.get_current_room_id() == "serum_ward", "Walking right after the records must enter the Pattern Serum ward")
	var sushan: Node = district.current_room.get_node_or_null("Interactions/DoctorSushan")
	_assert(sushan != null, "Doctor Sushan must be reachable in the next room")
	if sushan != null:
		district.player.global_position = Vector2(360.0, 284.0)
		_assert((sushan as InteractionArea).is_player_candidate(district.player), "Sushan's padded authored bounds must include the main walking lane (size=%s padding=%s delta=%s)" % [(sushan as InteractionArea).interaction_size, (sushan as InteractionArea).interaction_padding, ((sushan as InteractionArea).global_position - district.player.global_position).abs()])
		_interaction_manager.call("_process", 0.0)
		_assert(_interaction_manager.get_focused_interaction() == sushan, "Doctor Sushan must focus from the main walking lane")
	district.queue_free()
	await process_frame


func _test_focus_selection_and_padding() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var player := (load("res://scenes/overworld/player.tscn") as PackedScene).instantiate()
	host.add_child(player)
	await process_frame
	var center := Vector2(320, 180)
	var area := _make_test_area(host, "FourWayTarget", center, 0)
	var approaches := [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	for direction in approaches:
		var offset := Vector2(
			direction.x * (area.interaction_size.x * 0.5 + 12.0),
			direction.y * (area.interaction_size.y * 0.5 + 10.0)
		)
		player.global_position = area.global_position + offset
		area.call("_on_body_entered", player)
		_interaction_manager.call("_process", 0.0)
		_assert(_interaction_manager.get_focused_interaction() == area, "Interaction must focus from %s without sprite overlap" % direction)
		_assert(not Rect2(area.global_position - area.interaction_size * 0.5, area.interaction_size).has_point(player.global_position), "Approach point must remain outside the authored sprite footprint")
		area.call("_on_body_exited", player)
	area.queue_free()
	await process_frame

	var left := _make_test_area(host, "LeftTarget", center + Vector2(-24, 0), 0)
	var right := _make_test_area(host, "RightTarget", center + Vector2(24, 0), 0)
	player.global_position = center
	player.set_facing_direction("right")
	left.call("_on_body_entered", player)
	right.call("_on_body_entered", player)
	_interaction_manager.call("_process", 0.0)
	_assert(_interaction_manager.get_focused_interaction() == right, "Facing direction must resolve close distance ties")
	_assert(right.get_node("InteractionButtonMarker").visible and not left.get_node("InteractionButtonMarker").visible, "Exactly one nearby object may display the button marker")
	right.position = left.position
	left.focus_priority = 2
	right.focus_priority = 8
	_interaction_manager.call("_process", 0.0)
	_assert(_interaction_manager.get_focused_interaction() == right, "Focus priority must resolve exact ties deterministically")

	var dialogue_manager := root.get_node_or_null("DialogueManager")
	dialogue_manager.start_inline_dialogue("Test", ["Busy."])
	_interaction_manager.call("_process", 0.0)
	_assert(_interaction_manager.get_focused_interaction() == null, "Dialogue must suppress interaction focus")
	dialogue_manager.cancel_dialogue(false)
	paused = true
	_interaction_manager.call("_process", 0.0)
	_assert(_interaction_manager.get_focused_interaction() == null, "Pause must suppress interaction focus")
	paused = false

	left.call("_on_body_exited", player)
	right.call("_on_body_exited", player)
	host.queue_free()
	await process_frame


func _make_test_area(parent: Node2D, node_name: String, at: Vector2, priority: int) -> InteractionArea:
	var area := InteractionArea.new()
	area.name = node_name
	area.position = at
	area.display_name = node_name
	area.interaction_size = Vector2(24, 24)
	area.interaction_padding = Vector2(24, 20)
	area.focus_priority = priority
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = area.interaction_size + area.interaction_padding * 2.0
	collision.shape = shape
	area.add_child(collision)
	parent.add_child(area)
	return area


func _activate_focused() -> void:
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	_interaction_manager.call("_unhandled_input", event)


func _drain_dialogue() -> void:
	var manager := root.get_node_or_null("DialogueManager")
	while manager != null and manager.is_active():
		manager.advance()


func _find_interaction(room: Dictionary, interaction_id: String) -> Dictionary:
	for value in room.get("interactions", []):
		var interaction: Dictionary = value
		if str(interaction.get("id", "")) == interaction_id:
			return interaction
	return {}


func _find_exit(room: Dictionary, exit_id: String) -> Dictionary:
	for value in room.get("exits", []):
		var exit_data: Dictionary = value
		if str(exit_data.get("id", "")) == exit_id:
			return exit_data
	return {}


func _prepare_temporary_save() -> void:
	_assert(_save_system != null and _game_state != null and _interaction_manager != null, "Required hotfix autoloads must exist")
	if _save_system == null:
		return
	_original_save_paths = [_save_system.save_path, _save_system.backup_path, _save_system.temporary_path]
	_save_system.save_path = "user://pass75_save.json"
	_save_system.backup_path = "user://pass75_save.backup.json"
	_save_system.temporary_path = "user://pass75_save.tmp.json"
	_save_system.clear_save()


func _cleanup() -> void:
	Input.action_release("move_right")
	paused = false
	var dialogue_manager := root.get_node_or_null("DialogueManager")
	if dialogue_manager != null:
		dialogue_manager.cancel_dialogue(false)
	if _save_system != null:
		_save_system.clear_save()
		_save_system.save_path = _original_save_paths[0]
		_save_system.backup_path = _original_save_paths[1]
		_save_system.temporary_path = _original_save_paths[2]


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
