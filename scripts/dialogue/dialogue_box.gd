extends Control

@onready var speaker_label: Label = $Panel/SpeakerLabel
@onready var line_label: Label = $Panel/LineLabel


func _ready() -> void:
	visible = false
	var manager := get_node_or_null("/root/DialogueManager")
	if manager == null:
		return
	manager.dialogue_started.connect(_show_line)
	manager.dialogue_advanced.connect(_show_line)
	manager.dialogue_finished.connect(_hide_box)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact"):
		var manager := get_node_or_null("/root/DialogueManager")
		if manager != null:
			manager.advance()
		get_viewport().set_input_as_handled()


func _show_line(speaker: String, line: String) -> void:
	visible = true
	speaker_label.text = speaker
	line_label.text = line


func _hide_box(_flag_name: String) -> void:
	visible = false
