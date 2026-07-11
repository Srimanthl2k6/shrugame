extends SceneTree

const MAIN_SCENE := "res://scenes/main.tscn"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_game_state(failures)
	_check_menu_scene(failures)
	_check_save_round_trip(failures)
	_finish(failures)


func _check_game_state(failures: Array[String]) -> void:
	var game_state := root.get_node_or_null("GameState")
	if game_state == null:
		failures.append("GameState autoload is missing")
		return
	if not game_state.set_difficulty("srmt") or game_state.get_difficulty_id() != "srmt":
		failures.append("GameState could not select SRMT difficulty")
	if game_state.set_difficulty("not_a_mode"):
		failures.append("GameState accepted an invalid difficulty")
	game_state.set_difficulty("shrububu")


func _check_menu_scene(failures: Array[String]) -> void:
	var packed := load(MAIN_SCENE) as PackedScene
	if packed == null:
		failures.append("Main scene failed to load")
		return
	var menu := packed.instantiate()
	for path in [
		"TitleLayer/DifficultyLayer",
		"TitleLayer/DifficultyLayer/Modal/ShrububuButton",
		"TitleLayer/DifficultyLayer/Modal/SrmtButton",
		"TitleLayer/DifficultyLayer/Modal/CancelButton"
	]:
		if menu.get_node_or_null(path) == null:
			failures.append("Difficulty menu node missing: %s" % path)
	var easy_button := menu.get_node_or_null("TitleLayer/DifficultyLayer/Modal/ShrububuButton") as Button
	var hard_button := menu.get_node_or_null("TitleLayer/DifficultyLayer/Modal/SrmtButton") as Button
	if easy_button != null and not easy_button.text.contains("Extremely easy"):
		failures.append("Shrububu button lacks its difficulty description")
	if hard_button != null and not hard_button.text.contains("Extremely hard"):
		failures.append("SRMT button lacks its difficulty description")
	menu.free()


func _check_save_round_trip(failures: Array[String]) -> void:
	var save_system := root.get_node_or_null("SaveSystem")
	var game_state := root.get_node_or_null("GameState")
	if save_system == null or game_state == null:
		failures.append("SaveSystem or GameState autoload is missing")
		return
	var original_path: String = save_system.save_path
	save_system.save_path = "user://premium_difficulty_test.json"
	save_system.clear_save()
	save_system.new_game("srmt")
	if not save_system.save_game("level_01", "start"):
		failures.append("Could not write difficulty test save")
	else:
		game_state.set_difficulty("shrububu")
		save_system.load_game()
		if game_state.get_difficulty_id() != "srmt":
			failures.append("Save/load did not preserve SRMT difficulty")
	save_system.clear_save()
	save_system.save_path = original_path
	game_state.set_difficulty("shrububu")


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("PASS: Premium difficulty menu and save smoke test")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
