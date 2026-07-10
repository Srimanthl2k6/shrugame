extends SceneTree

const LEVELS := {
	"level_02": {
		"scene": "res://scenes/levels/level_02.tscn",
		"dialogue_file": "res://data/dialogue/level_02_dialogue.json",
		"dialogue_id": "vela_intro",
		"encounter_file": "res://data/encounters/level_02_encounters.json",
		"encounter_id": "vela_practice",
		"npc": "Vela",
		"objective_flag": "level_02_objective_done",
		"clear_flag": "vela_practice_cleared",
		"next_scene": "res://scenes/levels/level_03.tscn"
	},
	"level_03": {
		"scene": "res://scenes/levels/level_03.tscn",
		"dialogue_file": "res://data/dialogue/level_03_dialogue.json",
		"dialogue_id": "tickroot_intro",
		"encounter_file": "res://data/encounters/level_03_encounters.json",
		"encounter_id": "tickroot_practice",
		"npc": "Tickroot",
		"objective_flag": "level_03_objective_done",
		"clear_flag": "tickroot_practice_cleared",
		"next_scene": "res://scenes/levels/level_04.tscn"
	},
	"level_04": {
		"scene": "res://scenes/levels/level_04.tscn",
		"dialogue_file": "res://data/dialogue/level_04_dialogue.json",
		"dialogue_id": "luma_intro",
		"encounter_file": "res://data/encounters/level_04_encounters.json",
		"encounter_id": "luma_practice",
		"npc": "JudgeLuma",
		"objective_flag": "level_04_objective_done",
		"clear_flag": "luma_practice_cleared",
		"next_scene": "res://scenes/levels/level_05.tscn"
	},
	"level_05": {
		"scene": "res://scenes/levels/level_05.tscn",
		"dialogue_file": "res://data/dialogue/level_05_dialogue.json",
		"dialogue_id": "nulla_intro",
		"encounter_file": "res://data/encounters/level_05_encounters.json",
		"encounter_id": "nulla_practice",
		"npc": "Nulla",
		"objective_flag": "level_05_objective_done",
		"clear_flag": "nulla_practice_cleared",
		"next_scene": "res://scenes/ending.tscn"
	}
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []

	_check_battle_manager_support(failures)
	for level_id in LEVELS.keys():
		var spec: Dictionary = LEVELS[level_id]
		_check_dialogue_data(level_id, spec, failures)
		_check_encounter_data(level_id, spec, failures)
		_check_level_scene(level_id, spec, failures)
		_check_level_controller(level_id, spec, failures)
		_check_battle_start(spec, failures)

	if failures.is_empty():
		print("PASS: Pass 7 smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_battle_manager_support(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/battle/battle_manager.gd")
	if not source.contains("level_05_encounters.json"):
		failures.append("BattleManager must search all level encounter files")
	if not source.contains("pending_encounter_id"):
		failures.append("BattleManager must support pending_encounter_id")


func _check_dialogue_data(level_id: String, spec: Dictionary, failures: Array[String]) -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(spec["dialogue_file"]))
	if typeof(data) != TYPE_DICTIONARY or not data.has(spec["dialogue_id"]):
		failures.append("%s missing dialogue id %s" % [level_id, spec["dialogue_id"]])
		return
	var entry: Dictionary = data[spec["dialogue_id"]]
	if entry.get("speaker", "") == "" or typeof(entry.get("lines", null)) != TYPE_ARRAY or entry["lines"].is_empty():
		failures.append("%s dialogue must include speaker and lines" % level_id)


func _check_encounter_data(level_id: String, spec: Dictionary, failures: Array[String]) -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(spec["encounter_file"]))
	if typeof(data) != TYPE_DICTIONARY or not data.has(spec["encounter_id"]):
		failures.append("%s missing encounter id %s" % [level_id, spec["encounter_id"]])
		return
	var encounter: Dictionary = data[spec["encounter_id"]]
	for key in ["enemy_name", "enemy_hp", "player_hp", "resonance_goal", "return_scene"]:
		if not encounter.has(key):
			failures.append("%s encounter missing %s" % [level_id, key])


func _check_level_scene(level_id: String, spec: Dictionary, failures: Array[String]) -> void:
	var scene := load(spec["scene"])
	if scene == null:
		failures.append("%s scene did not load" % level_id)
		return
	var level: Node = scene.instantiate()
	if level.get_script() == null:
		failures.append("%s needs a controller script" % level_id)
	for node_path in [
		"World/Player",
		"World/%s" % spec["npc"],
		"World/Objective",
		"World/PracticeEncounter",
		"World/SavePoint",
		"World/TransitionDoor",
		"DialogueLayer/DialogueBox"
	]:
		if level.get_node_or_null(node_path) == null:
			failures.append("%s missing node %s" % [level_id, node_path])

	var npc: Node = level.get_node_or_null("World/%s" % spec["npc"])
	if npc != null and npc.get("dialogue_id") != spec["dialogue_id"]:
		failures.append("%s NPC dialogue_id mismatch" % level_id)

	var encounter: Node = level.get_node_or_null("World/PracticeEncounter")
	if encounter != null and encounter.get("encounter_id") != spec["encounter_id"]:
		failures.append("%s PracticeEncounter encounter_id mismatch" % level_id)

	var exit_door: Node = level.get_node_or_null("World/TransitionDoor")
	if exit_door != null:
		if exit_door.get("target_scene_path") != spec["next_scene"]:
			failures.append("%s TransitionDoor target mismatch" % level_id)
		var required = exit_door.get("required_flags")
		for flag_name in [spec["objective_flag"], spec["clear_flag"]]:
			if required == null or not required.has(flag_name):
				failures.append("%s TransitionDoor missing required flag %s" % [level_id, flag_name])
	level.free()


func _check_level_controller(level_id: String, spec: Dictionary, failures: Array[String]) -> void:
	var scene := load(spec["scene"])
	if scene == null:
		return
	var level: Node = scene.instantiate()
	var game_state: Node = root.get_node_or_null("GameState")
	var created_game_state := false
	if game_state == null:
		game_state = load("res://scripts/core/game_state.gd").new()
		game_state.name = "GameState"
		root.add_child(game_state)
		created_game_state = true
	root.add_child(level)
	game_state.clear_flags()
	if not level.has_method("complete_objective") or not level.has_method("can_clear_level"):
		failures.append("%s controller missing objective/clear methods" % level_id)
	else:
		level.complete_objective()
		if not game_state.get_flag(spec["objective_flag"]):
			failures.append("%s complete_objective did not set objective flag" % level_id)
		if level.can_clear_level():
			failures.append("%s should not clear before encounter flag" % level_id)
		game_state.set_flag(spec["clear_flag"])
		if not level.can_clear_level():
			failures.append("%s should clear after objective and encounter flags" % level_id)
	level.free()
	if created_game_state:
		game_state.free()


func _check_battle_start(spec: Dictionary, failures: Array[String]) -> void:
	var scene := load("res://scenes/battle/battle_scene.tscn")
	if scene == null:
		return
	var battle: Node = scene.instantiate()
	root.add_child(battle)
	if not battle.start_encounter(spec["encounter_id"]):
		failures.append("BattleManager could not start %s" % spec["encounter_id"])
	battle.free()
