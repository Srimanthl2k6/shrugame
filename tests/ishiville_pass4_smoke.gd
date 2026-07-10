extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var game_state: Node = root.get_node_or_null("GameState")
	var save_system: Node = root.get_node_or_null("SaveSystem")
	if game_state == null:
		failures.append("GameState autoload missing")
	else:
		_check_inventory(game_state, failures)
		_check_gear(game_state, failures)
		_check_clues(game_state, failures)
		_check_growth(game_state, failures)
		_check_objectives(game_state, failures)
		_check_ui_scenes(game_state, failures)
	if game_state != null and save_system != null:
		_check_pass4_save_restore(game_state, save_system, failures)

	if failures.is_empty():
		print("PASS: Ishiville Pass 4 smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_inventory(game_state: Node, failures: Array[String]) -> void:
	if not _has_methods(game_state, ["add_item", "consume_item", "get_item_count"], failures):
		return
	game_state.reset_progression()
	game_state.add_item("kfc_popcorn_box", 2)
	if game_state.get_item_count("kfc_popcorn_box") != 2:
		failures.append("Inventory did not add item counts")
	if not game_state.consume_item("kfc_popcorn_box", 1):
		failures.append("Inventory did not consume an available item")
	if game_state.get_item_count("kfc_popcorn_box") != 1:
		failures.append("Inventory did not reduce consumed item count")
	if game_state.consume_item("kfc_popcorn_box", 5):
		failures.append("Inventory allowed over-consuming an item")


func _check_gear(game_state: Node, failures: Array[String]) -> void:
	if not _has_methods(game_state, ["unlock_gear", "has_gear", "equip_weapon"], failures):
		return
	game_state.reset_progression()
	if not game_state.unlock_gear("revolver"):
		failures.append("Gear system did not unlock revolver")
	if not game_state.has_gear("revolver"):
		failures.append("Gear system did not report unlocked revolver")
	if game_state.current_weapon != "revolver":
		failures.append("Gear system did not auto-equip first weapon")
	game_state.unlock_gear("banana_gun")
	if not game_state.equip_weapon("banana_gun"):
		failures.append("Gear system did not equip unlocked banana gun")
	if game_state.current_weapon != "banana_gun":
		failures.append("Gear system did not update current weapon")
	if game_state.equip_weapon("musical_guitar"):
		failures.append("Gear system equipped a locked weapon")


func _check_clues(game_state: Node, failures: Array[String]) -> void:
	if not _has_methods(game_state, ["collect_clue", "has_clue", "get_collected_clue_ids"], failures):
		return
	game_state.reset_progression()
	game_state.collect_clue("165_files")
	if not game_state.has_clue("165_files"):
		failures.append("Clue system did not collect 165-files")
	if not game_state.get_flag("165_files_collected"):
		failures.append("Clue system did not set story flag for collected clue")
	if not game_state.get_collected_clue_ids().has("165_files"):
		failures.append("Clue system did not list collected clue IDs")


func _check_growth(game_state: Node, failures: Array[String]) -> void:
	if not _has_methods(game_state, ["set_growth_stage", "get_growth_stage", "apply_growth_to_node"], failures):
		return
	game_state.reset_progression()
	game_state.set_growth_stage(4)
	if game_state.get_growth_stage() != 4:
		failures.append("Growth system did not set stage 4")
	var body := Node2D.new()
	game_state.apply_growth_to_node(body)
	if body.scale.x <= 1.0 or body.scale.y <= 1.0:
		failures.append("Growth system did not visibly scale a node")
	body.queue_free()


func _check_objectives(game_state: Node, failures: Array[String]) -> void:
	if not _has_methods(game_state, ["set_current_objective", "get_current_objective", "update_objective_from_level"], failures):
		return
	game_state.reset_progression()
	game_state.update_objective_from_level("level_02")
	if not game_state.get_current_objective().contains("Banana-burbs"):
		failures.append("Objective tracker did not derive a level objective")
	game_state.set_current_objective("Share the backup KFC popcorn box.")
	if game_state.get_current_objective() != "Share the backup KFC popcorn box.":
		failures.append("Objective tracker did not store manual objective text")


func _check_ui_scenes(game_state: Node, failures: Array[String]) -> void:
	if not _has_methods(game_state, ["collect_clue", "set_current_objective"], failures):
		return
	game_state.reset_progression()
	game_state.collect_clue("divorce_records")
	game_state.set_current_objective("Find the sheriff.")

	var journal_scene := load("res://scenes/ui/clue_journal.tscn")
	if journal_scene == null:
		failures.append("Missing clue journal UI scene")
	else:
		var journal: Node = journal_scene.instantiate()
		root.add_child(journal)
		if not journal.has_method("refresh"):
			failures.append("Clue journal UI missing refresh method")
		else:
			journal.refresh()
			if not str(journal.get("last_rendered_text")).contains("Divorce Records"):
				failures.append("Clue journal UI did not render collected clue text")
		journal.queue_free()

	var objective_scene := load("res://scenes/ui/objective_tracker.tscn")
	if objective_scene == null:
		failures.append("Missing objective tracker UI scene")
	else:
		var tracker: Node = objective_scene.instantiate()
		root.add_child(tracker)
		if not tracker.has_method("refresh"):
			failures.append("Objective tracker UI missing refresh method")
		else:
			tracker.refresh()
			if not str(tracker.get("last_rendered_text")).contains("Find the sheriff"):
				failures.append("Objective tracker UI did not render current objective")
		tracker.queue_free()


func _check_pass4_save_restore(game_state: Node, save_system: Node, failures: Array[String]) -> void:
	if not _has_methods(game_state, ["add_item", "get_item_count", "unlock_gear", "has_gear", "equip_weapon", "collect_clue", "has_clue", "set_growth_stage", "get_growth_stage", "set_current_objective", "get_current_objective"], failures):
		return
	save_system.save_path = "user://ishiville_pass4_save.json"
	save_system.clear_save()
	game_state.reset_progression()
	game_state.add_item("kfc_popcorn_box", 1)
	game_state.unlock_gear("banana_gun")
	game_state.equip_weapon("banana_gun")
	game_state.collect_clue("165_files")
	game_state.set_growth_stage(3)
	game_state.set_current_objective("Convince the monkey town.")
	if not save_system.save_game("level_02", "lab_exit"):
		failures.append("Pass 4 save failed to write")
		return
	game_state.reset_progression()
	save_system.load_game()
	if game_state.get_item_count("kfc_popcorn_box") != 1:
		failures.append("Pass 4 save did not restore inventory API state")
	if not game_state.has_gear("banana_gun") or game_state.current_weapon != "banana_gun":
		failures.append("Pass 4 save did not restore gear API state")
	if not game_state.has_clue("165_files"):
		failures.append("Pass 4 save did not restore clue API state")
	if game_state.get_growth_stage() != 3:
		failures.append("Pass 4 save did not restore growth API state")
	if game_state.get_current_objective() != "Convince the monkey town.":
		failures.append("Pass 4 save did not restore objective text")
	save_system.clear_save()


func _has_methods(node: Node, method_names: Array[String], failures: Array[String]) -> bool:
	var ok := true
	for method_name in method_names:
		if not node.has_method(method_name):
			failures.append("%s missing method %s" % [node.name, method_name])
			ok = false
	return ok
