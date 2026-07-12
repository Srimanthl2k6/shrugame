extends Control

var _input_ready := false


func _ready() -> void:
	get_tree().create_timer(1.2).timeout.connect(func(): _input_ready = true)


func _unhandled_input(event: InputEvent) -> void:
	if not _input_ready:
		return
	if event.is_action_pressed("interact"):
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		get_tree().quit()
		get_viewport().set_input_as_handled()
