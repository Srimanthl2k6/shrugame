extends Node


func change_level(scene_path: String) -> void:
	if scene_path.is_empty():
		return
	get_tree().change_scene_to_file(scene_path)
