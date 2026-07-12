extends SceneTree


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var scene_path := OS.get_environment("SHRUGAME_CAPTURE_SCENE")
	var output_path := OS.get_environment("SHRUGAME_CAPTURE_OUTPUT")
	var room_id := OS.get_environment("SHRUGAME_CAPTURE_ROOM")
	var view_id := OS.get_environment("SHRUGAME_CAPTURE_VIEW")
	var encounter_id := OS.get_environment("SHRUGAME_CAPTURE_ENCOUNTER")
	if scene_path.is_empty():
		scene_path = "res://scenes/levels/districts/level_01.tscn"
	if output_path.is_empty():
		output_path = "res://builds/qa/runtime-capture.png"
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("Capture scene failed to load: %s" % scene_path)
		quit(1)
		return
	if not encounter_id.is_empty():
		var game_state := root.get_node_or_null("GameState")
		if game_state != null:
			game_state.pending_encounter_id = encounter_id
			if view_id != "battle_tutorial":
				game_state.set_flag("tutorial_battle_completed", true)
	var instance := packed.instantiate()
	root.add_child(instance)
	await process_frame
	if not room_id.is_empty() and instance.has_method("switch_room"):
		instance.switch_room(room_id, "default", false)
	match view_id:
		"controls":
			if instance.has_method("open_controls"):
				instance.open_controls()
		"settings":
			if instance.has_method("open_options"):
				instance.open_options()
		"tutorial":
			var tutorial_manager := root.get_node_or_null("TutorialManager")
			if tutorial_manager != null:
				tutorial_manager.replay_overworld_tutorial()
		"pause":
			var pause_menu := instance.find_child("PauseMenu", true, false)
			if pause_menu != null and pause_menu.has_method("open_menu"):
				pause_menu.open_menu()
		"dialogue":
			var dialogue_manager := root.get_node_or_null("DialogueManager")
			if dialogue_manager != null:
				dialogue_manager.load_dialogue_file("res://data/dialogue/level_01_dialogue.json")
				dialogue_manager.start_dialogue("divorcee_lantern_woman")
	for _frame in range(30):
		await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Capture viewport returned no pixels")
		quit(1)
		return
	var absolute_output := ProjectSettings.globalize_path(output_path)
	DirAccess.make_dir_recursive_absolute(absolute_output.get_base_dir())
	var error := image.save_png(absolute_output)
	if error != OK:
		push_error("Capture failed to write %s: %s" % [absolute_output, error_string(error)])
		quit(1)
		return
	print("CAPTURED: %s" % absolute_output)
	quit(0)
