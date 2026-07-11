extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []

	_check_project_autoloads(failures)
	_check_dialogue_data(failures)
	_check_dialogue_scripts(failures)
	_check_dialogue_flow(failures)
	_check_dialogue_scene(failures)
	_check_level_npc(failures)

	if failures.is_empty():
		print("PASS: Pass 3 smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_project_autoloads(failures: Array[String]) -> void:
	if not ProjectSettings.has_setting("autoload/GameState"):
		failures.append("GameState autoload is not configured")
	if not ProjectSettings.has_setting("autoload/DialogueManager"):
		failures.append("DialogueManager autoload is not configured")


func _check_dialogue_data(failures: Array[String]) -> void:
	var text := FileAccess.get_file_as_string("res://data/dialogue/level_01_dialogue.json")
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		failures.append("Level 1 dialogue JSON is not an object")
		return
	if not data.has("marn_intro"):
		failures.append("Level 1 dialogue missing marn_intro")
		return
	var entry = data["marn_intro"]
	if typeof(entry) != TYPE_DICTIONARY:
		failures.append("marn_intro is not a dialogue entry object")
		return
	if not entry.has("speaker") or entry["speaker"] != "Marn":
		failures.append("marn_intro speaker must be Marn")
	if not entry.has("lines") or typeof(entry["lines"]) != TYPE_ARRAY or entry["lines"].is_empty():
		failures.append("marn_intro must contain at least one line")
	if not entry.has("complete_flag") or entry["complete_flag"] != "met_marn":
		failures.append("marn_intro must set met_marn when completed")


func _check_dialogue_scripts(failures: Array[String]) -> void:
	var game_state_script := load("res://scripts/core/game_state.gd")
	var game_state = game_state_script.new()
	for method in ["set_flag", "get_flag", "clear_flags"]:
		if not game_state.has_method(method):
			failures.append("GameState missing method: %s" % method)
	game_state.free()

	var dialogue_manager_script := load("res://scripts/dialogue/dialogue_manager.gd")
	var dialogue_manager = dialogue_manager_script.new()
	for method in ["load_dialogue_file", "start_dialogue", "advance", "is_active"]:
		if not dialogue_manager.has_method(method):
			failures.append("DialogueManager missing method: %s" % method)
	dialogue_manager.free()


func _check_dialogue_flow(failures: Array[String]) -> void:
	var game_state: Node = root.get_node_or_null("GameState")
	var dialogue_manager: Node = root.get_node_or_null("DialogueManager")
	var created_game_state := false
	var created_dialogue_manager := false

	if game_state == null:
		game_state = load("res://scripts/core/game_state.gd").new()
		game_state.name = "GameState"
		root.add_child(game_state)
		created_game_state = true
	if dialogue_manager == null:
		dialogue_manager = load("res://scripts/dialogue/dialogue_manager.gd").new()
		dialogue_manager.name = "DialogueManager"
		root.add_child(dialogue_manager)
		created_dialogue_manager = true

	game_state.clear_flags()
	if not dialogue_manager.load_dialogue_file("res://data/dialogue/level_01_dialogue.json"):
		failures.append("DialogueManager could not load Level 1 dialogue")
	elif not dialogue_manager.start_dialogue("marn_intro"):
		failures.append("DialogueManager could not start marn_intro")
	else:
		while dialogue_manager.is_active():
			dialogue_manager.advance()
		if not game_state.get_flag("met_marn"):
			failures.append("Completing marn_intro did not set met_marn")

	if created_dialogue_manager:
		dialogue_manager.free()
	if created_game_state:
		game_state.free()


func _check_dialogue_scene(failures: Array[String]) -> void:
	var scene := load("res://scenes/ui/dialogue_box.tscn")
	if scene == null:
		failures.append("dialogue_box.tscn did not load")
		return
	var box: Node = scene.instantiate()
	if box.get_script() == null:
		failures.append("DialogueBox has no script")
	_require_node(box, "Panel", failures)
	_require_node(box, "Panel/SpeakerLabel", failures)
	_require_node(box, "Panel/LineLabel", failures)
	box.free()


func _check_level_npc(failures: Array[String]) -> void:
	var scene := load("res://scenes/levels/level_01.tscn")
	if scene == null:
		failures.append("level_01.tscn did not load")
		return
	var level: Node = scene.instantiate()
	_require_node(level, "World/Marn", failures)
	_require_node(level, "DialogueLayer/DialogueBox", failures)

	var marn: Node = level.get_node_or_null("World/Marn")
	if marn != null:
		if marn.get("dialogue_id") != "marn_intro":
			failures.append("Marn dialogue_id must be marn_intro")
		if marn.get("flag_on_interact") != "met_marn":
			failures.append("Marn flag_on_interact must be met_marn")
	level.free()


func _require_node(root: Node, path: NodePath, failures: Array[String]) -> void:
	if root.get_node_or_null(path) == null:
		failures.append("Missing node: %s" % path)
