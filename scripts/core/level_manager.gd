extends Node

signal transition_failed(message: String)
signal transition_started(source_level_id: String, target_level_id: String)

var _transitioning := false


func transition_to_level(target_level_id: String, target_room_id: String = "", target_spawn_id: String = "start") -> Error:
	if _transitioning:
		return ERR_BUSY
	var config := _load_level_config(target_level_id)
	if config.is_empty() or str(config.get("level_id", "")) != target_level_id:
		return _fail_transition("The road ahead could not be found.", ERR_FILE_NOT_FOUND)
	var save_system := get_node_or_null("/root/SaveSystem")
	var game_state := get_node_or_null("/root/GameState")
	if save_system == null or game_state == null:
		return _fail_transition("Ishiville could not update the journey.", ERR_UNCONFIGURED)
	var packed := save_system.get_level_scene(target_level_id) as PackedScene
	if packed == null:
		return _fail_transition("The next district failed to load.", ERR_CANT_OPEN)

	var resolved_room_id := target_room_id
	if resolved_room_id.is_empty():
		resolved_room_id = str(config.get("start_room_id", ""))
	if resolved_room_id.is_empty():
		return _fail_transition("The next district has no valid entrance.", ERR_INVALID_DATA)

	_transitioning = true
	var snapshot := _snapshot_state(game_state)
	var source_level_id := str(game_state.current_level_id)
	transition_started.emit(source_level_id, target_level_id)
	_mark_source_complete(game_state, source_level_id, target_level_id)
	game_state.current_level_id = target_level_id
	game_state.current_room_id = resolved_room_id
	game_state.spawn_point = target_spawn_id
	game_state.pending_encounter_id = ""
	game_state.update_objective_from_level(target_level_id)

	if not save_system.save_game(target_level_id, target_spawn_id, resolved_room_id):
		_restore_state(game_state, snapshot)
		_transitioning = false
		return _fail_transition("The journey could not be saved. The road remains open.", ERR_CANT_CREATE)

	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.play_sfx("transition_wipe")
	var error := get_tree().change_scene_to_packed(packed)
	if error != OK:
		_restore_state(game_state, snapshot)
		save_system.save_game(str(game_state.current_level_id), str(game_state.spawn_point), str(game_state.current_room_id))
		_transitioning = false
		return _fail_transition("The next district failed to open. Progress was restored.", error)
	call_deferred("_finish_transition")
	return OK


func is_transitioning() -> bool:
	return _transitioning


func _finish_transition() -> void:
	_transitioning = false


func _mark_source_complete(game_state: Node, source_level_id: String, target_level_id: String) -> void:
	if source_level_id.is_empty() or source_level_id == target_level_id:
		return
	var source_config := _load_level_config(source_level_id)
	if str(source_config.get("next_level_id", "")) == target_level_id:
		game_state.set_flag("%s_completed" % source_level_id, true)


func _snapshot_state(game_state: Node) -> Dictionary:
	return {
		"level": str(game_state.current_level_id),
		"room": str(game_state.current_room_id),
		"spawn": str(game_state.spawn_point),
		"pending": str(game_state.pending_encounter_id),
		"objective": str(game_state.current_objective),
		"flags": game_state.story_flags.duplicate(true)
	}


func _restore_state(game_state: Node, snapshot: Dictionary) -> void:
	game_state.current_level_id = str(snapshot.get("level", "level_01"))
	game_state.current_room_id = str(snapshot.get("room", "arrival"))
	game_state.spawn_point = str(snapshot.get("spawn", "start"))
	game_state.pending_encounter_id = str(snapshot.get("pending", ""))
	game_state.current_objective = str(snapshot.get("objective", ""))
	game_state.story_flags = snapshot.get("flags", {}).duplicate(true)
	game_state.rebuild_defeated_bosses_from_flags()


func _load_level_config(level_id: String) -> Dictionary:
	var path := "res://data/levels/%s_config.json" % level_id
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _fail_transition(message: String, error: Error) -> Error:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.set_current_objective(message)
	var current_scene := get_tree().current_scene if is_inside_tree() else null
	if current_scene != null:
		for node in current_scene.find_children("ObjectiveTracker", "", true, false):
			if node.has_method("refresh"):
				node.refresh()
	transition_failed.emit(message)
	push_error(message)
	return error
