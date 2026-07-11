extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []

	_check_save_system(failures)
	_check_interaction_features(failures)
	_check_level_slice_nodes(failures)
	_check_level_clear_contract(failures)

	if failures.is_empty():
		print("PASS: Pass 5 smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_save_system(failures: Array[String]) -> void:
	if not ProjectSettings.has_setting("autoload/SaveSystem"):
		failures.append("SaveSystem autoload is not configured")

	var save_script := load("res://scripts/core/save_system.gd")
	var save_system = save_script.new()
	for method in ["save_game", "load_game", "clear_save"]:
		if not save_system.has_method(method):
			failures.append("SaveSystem missing method: %s" % method)
	if save_system is Node:
		save_system.free()


func _check_interaction_features(failures: Array[String]) -> void:
	var interaction_script := load("res://scripts/overworld/interaction_area.gd")
	var interaction = interaction_script.new()
	for property_name in ["required_flags", "locked_message", "save_on_interact", "level_id", "spawn_point"]:
		var found := false
		for item in interaction.get_property_list():
			if item.get("name") == property_name:
				found = true
				break
		if not found:
			failures.append("InteractionArea missing exported property: %s" % property_name)
	interaction.free()


func _check_level_slice_nodes(failures: Array[String]) -> void:
	var scene := load("res://scenes/levels/level_01.tscn")
	if scene == null:
		failures.append("level_01.tscn did not load")
		return
	var level: Node = scene.instantiate()
	if level.get_script() == null:
		failures.append("Level01 needs a controller script")

	for node_path in [
		"World/TagFlour",
		"World/TagCups",
		"World/TagBroom",
		"World/SavePoint",
		"World/TransitionDoor",
		"World/PantryShelves",
		"World/Crates"
	]:
		_require_node(level, node_path, failures)

	var exit_door: Node = level.get_node_or_null("World/TransitionDoor")
	if exit_door != null:
		var required = exit_door.get("required_flags")
		if required == null:
			failures.append("TransitionDoor missing required_flags")
		else:
			for flag_name in ["met_marn", "marn_practice_cleared", "pantry_tags_sorted"]:
				if not required.has(flag_name):
					failures.append("TransitionDoor missing required flag: %s" % flag_name)

	level.free()


func _check_level_clear_contract(failures: Array[String]) -> void:
	var level_script := load("res://scripts/levels/level_01_controller.gd")
	if level_script == null:
		failures.append("Level 1 controller script does not exist")
		return
	var level_controller = level_script.new()
	for method in ["can_clear_level", "collect_tag", "get_collected_tag_count"]:
		if not level_controller.has_method(method):
			failures.append("Level 1 controller missing method: %s" % method)

	var game_state: Node = root.get_node_or_null("GameState")
	var created_game_state := false
	if game_state == null:
		game_state = load("res://scripts/core/game_state.gd").new()
		game_state.name = "GameState"
		root.add_child(game_state)
		created_game_state = true
	root.add_child(level_controller)

	game_state.clear_flags()
	level_controller.collect_tag("tag_flour")
	level_controller.collect_tag("tag_cups")
	if level_controller.can_clear_level():
		failures.append("Level 1 should not clear before all tags, Marn, and battle are complete")
	level_controller.collect_tag("tag_broom")
	if not game_state.get_flag("pantry_tags_sorted"):
		failures.append("Collecting three tags should set pantry_tags_sorted")
	game_state.set_flag("met_marn")
	game_state.set_flag("marn_practice_cleared")
	if not level_controller.can_clear_level():
		failures.append("Level 1 should clear after tags, Marn, and practice battle")

	level_controller.free()
	if created_game_state:
		game_state.free()


func _require_node(root_node: Node, path: NodePath, failures: Array[String]) -> void:
	if root_node.get_node_or_null(path) == null:
		failures.append("Missing node: %s" % path)
