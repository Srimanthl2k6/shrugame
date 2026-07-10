extends Node

@export var music_id: String = ""


func _ready() -> void:
	if music_id.is_empty():
		return
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("play_music"):
		audio_manager.play_music(music_id)
