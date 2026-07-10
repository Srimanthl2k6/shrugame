extends SceneTree

const LEVELS := {
	"level_01": {
		"scene": "res://scenes/levels/level_01.tscn",
		"dialogue_file": "res://data/dialogue/level_01_dialogue.json",
		"npc": "Marn",
		"intro_dialogue": "marn_intro",
		"post_dialogue": "marn_after_battle",
		"clear_flag": "marn_practice_cleared"
	},
	"level_02": {
		"scene": "res://scenes/levels/level_02.tscn",
		"dialogue_file": "res://data/dialogue/level_02_dialogue.json",
		"npc": "Vela",
		"intro_dialogue": "vela_intro",
		"post_dialogue": "vela_after_battle",
		"clear_flag": "vela_practice_cleared"
	},
	"level_03": {
		"scene": "res://scenes/levels/level_03.tscn",
		"dialogue_file": "res://data/dialogue/level_03_dialogue.json",
		"npc": "Tickroot",
		"intro_dialogue": "tickroot_intro",
		"post_dialogue": "tickroot_after_battle",
		"clear_flag": "tickroot_practice_cleared"
	},
	"level_04": {
		"scene": "res://scenes/levels/level_04.tscn",
		"dialogue_file": "res://data/dialogue/level_04_dialogue.json",
		"npc": "JudgeLuma",
		"intro_dialogue": "luma_intro",
		"post_dialogue": "luma_after_battle",
		"clear_flag": "luma_practice_cleared"
	},
	"level_05": {
		"scene": "res://scenes/levels/level_05.tscn",
		"dialogue_file": "res://data/dialogue/level_05_dialogue.json",
		"npc": "Nulla",
		"intro_dialogue": "nulla_intro",
		"post_dialogue": "nulla_after_battle",
		"clear_flag": "nulla_practice_cleared"
	}
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_interaction_resolves_post_dialogue(failures)
	for level_id in LEVELS.keys():
		var spec: Dictionary = LEVELS[level_id]
		_check_dialogue_entries(level_id, spec, failures)
		_check_npc_scene_wiring(level_id, spec, failures)

	if failures.is_empty():
		print("PASS: Pass 8 smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_interaction_resolves_post_dialogue(failures: Array[String]) -> void:
	var game_state: Node = root.get_node_or_null("GameState")
	var created_game_state := false
	if game_state == null:
		game_state = load("res://scripts/core/game_state.gd").new()
		game_state.name = "GameState"
		root.add_child(game_state)
		created_game_state = true
	game_state.clear_flags()

	var area: Area2D = load("res://scripts/overworld/interaction_area.gd").new()
	if not area.has_method("resolve_dialogue_id"):
		failures.append("InteractionArea must expose resolve_dialogue_id()")
		area.free()
		game_state.free()
		return

	area.dialogue_id = "marn_intro"
	area.post_flag = "marn_practice_cleared"
	area.post_dialogue_id = "marn_after_battle"
	root.add_child(area)
	if area.resolve_dialogue_id() != "marn_intro":
		failures.append("InteractionArea should use intro dialogue before post flag is set")
	game_state.set_flag("marn_practice_cleared")
	if area.resolve_dialogue_id() != "marn_after_battle":
		failures.append("InteractionArea should switch to post dialogue after post flag is set")

	area.free()
	if created_game_state:
		game_state.free()


func _check_dialogue_entries(level_id: String, spec: Dictionary, failures: Array[String]) -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(spec["dialogue_file"]))
	if typeof(data) != TYPE_DICTIONARY:
		failures.append("%s dialogue file must parse as a dictionary" % level_id)
		return
	for dialogue_id in [spec["intro_dialogue"], spec["post_dialogue"]]:
		if not data.has(dialogue_id):
			failures.append("%s missing dialogue id %s" % [level_id, dialogue_id])
			continue
		var entry: Dictionary = data[dialogue_id]
		if entry.get("speaker", "") == "":
			failures.append("%s dialogue %s needs a speaker" % [level_id, dialogue_id])
		var lines = entry.get("lines", [])
		if typeof(lines) != TYPE_ARRAY or lines.size() < 2:
			failures.append("%s dialogue %s needs at least two lines" % [level_id, dialogue_id])
	if data.has(spec["post_dialogue"]):
		var post_entry: Dictionary = data[spec["post_dialogue"]]
		if post_entry.get("complete_flag", "") == "":
			failures.append("%s post dialogue needs a complete_flag" % level_id)


func _check_npc_scene_wiring(level_id: String, spec: Dictionary, failures: Array[String]) -> void:
	var scene := load(spec["scene"])
	if scene == null:
		failures.append("%s scene must load" % level_id)
		return
	var level: Node = scene.instantiate()
	var npc: Node = level.get_node_or_null("World/%s" % spec["npc"])
	if npc == null:
		failures.append("%s missing NPC %s" % [level_id, spec["npc"]])
		level.free()
		return
	if npc.get("dialogue_id") != spec["intro_dialogue"]:
		failures.append("%s NPC intro dialogue mismatch" % level_id)
	if npc.get("post_flag") != spec["clear_flag"]:
		failures.append("%s NPC post_flag mismatch" % level_id)
	if npc.get("post_dialogue_id") != spec["post_dialogue"]:
		failures.append("%s NPC post_dialogue_id mismatch" % level_id)
	level.free()
