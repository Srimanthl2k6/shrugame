extends Node


func run() -> void:
	var game_state := get_node_or_null("/root/GameState")
	var save_system := get_node_or_null("/root/SaveSystem")
	var level_manager := get_node_or_null("/root/LevelManager")
	var visited_levels: Array[String] = ["level_01"]
	var saves_verified := 0
	var failures: Array[String] = []
	if game_state == null or save_system == null or level_manager == null:
		_report(false, visited_levels, saves_verified, ["Required progression autoloads are missing."])
		queue_free()
		return
	save_system.new_game("shrububu")
	game_state.set_flag("tutorial_overworld_completed", true)
	game_state.set_flag("tutorial_battle_completed", true)
	var chain := [
		{"source": "level_01", "room": "satyaki_waterfront", "flag": "satyaki_tirumal_defeated", "target": "level_02", "target_room": "suburb"},
		{"source": "level_02", "room": "mayor_complex", "flag": "deepak_reddy_defeated", "target": "level_03", "target_room": "forest_entrance"},
		{"source": "level_03", "room": "ankit_gate", "flag": "ankit_defeated", "target": "level_04", "target_room": "pun_street"},
		{"source": "level_04", "room": "mayor_stage", "flag": "mitta_defeated", "target": "level_05", "target_room": "ruined_boulevard"}
	]
	for step_value in chain:
		var step: Dictionary = step_value
		game_state.current_level_id = str(step.get("source", ""))
		game_state.current_room_id = str(step.get("room", ""))
		game_state.spawn_point = "from_boss"
		game_state.set_flag(str(step.get("flag", "")), true)
		if not save_system.save_game(game_state.current_level_id, game_state.spawn_point, game_state.current_room_id):
			failures.append("Could not save %s." % game_state.current_level_id)
			break
		var error: Error = level_manager.transition_to_level(str(step.get("target", "")))
		if error != OK:
			failures.append("Transition to %s failed with %d." % [step.get("target", ""), error])
			break
		await get_tree().process_frame
		await get_tree().process_frame
		var loaded: Dictionary = save_system.load_game()
		if str(loaded.get("level_id", "")) != str(step.get("target", "")) or str(loaded.get("room_id", "")) != str(step.get("target_room", "")):
			failures.append("Continue did not restore %s/%s." % [step.get("target", ""), step.get("target_room", "")])
			break
		saves_verified += 1
		visited_levels.append(str(step.get("target", "")))
	_report(failures.is_empty() and game_state.current_level_id == "level_05", visited_levels, saves_verified, failures)
	queue_free()


func _report(complete: bool, visited_levels: Array[String], saves_verified: int, failures: Array[String]) -> void:
	if not OS.has_feature("web"):
		return
	var game_state := get_node_or_null("/root/GameState")
	var payload := {
		"complete": complete,
		"visited_levels": visited_levels,
		"saves_verified": saves_verified,
		"final_level": str(game_state.current_level_id) if game_state != null else "",
		"failures": failures
	}
	JavaScriptBridge.eval("window.__shrugameFullProgressionDiagnostics = %s" % JSON.stringify(payload), true)
