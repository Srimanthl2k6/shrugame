class_name AmbienceZone
extends Area2D

@export var music_id := ""
@export var one_shot := true

var _played := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or (_played and one_shot):
		return
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and not music_id.is_empty():
		audio_manager.play_music(music_id)
	_played = true
