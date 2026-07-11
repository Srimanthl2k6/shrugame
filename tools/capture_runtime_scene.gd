extends SceneTree


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var scene_path := OS.get_environment("SHRUGAME_CAPTURE_SCENE")
	var output_path := OS.get_environment("SHRUGAME_CAPTURE_OUTPUT")
	var room_id := OS.get_environment("SHRUGAME_CAPTURE_ROOM")
	if scene_path.is_empty():
		scene_path = "res://scenes/levels/districts/level_01.tscn"
	if output_path.is_empty():
		output_path = "res://builds/qa/runtime-capture.png"
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("Capture scene failed to load: %s" % scene_path)
		quit(1)
		return
	var instance := packed.instantiate()
	root.add_child(instance)
	await process_frame
	if not room_id.is_empty() and instance.has_method("switch_room"):
		instance.switch_room(room_id, "default", false)
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
