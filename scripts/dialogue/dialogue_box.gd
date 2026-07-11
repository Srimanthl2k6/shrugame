extends Control

@onready var speaker_label: Label = $Panel/SpeakerLabel
@onready var line_label: Label = $Panel/LineLabel
@onready var continue_label: Label = $Panel/ContinueLabel

var _full_line := ""
var _reveal_progress := 0.0
var _typing := false


func _ready() -> void:
	visible = false
	var manager := get_node_or_null("/root/DialogueManager")
	if manager == null:
		return
	manager.dialogue_started.connect(_show_line)
	manager.dialogue_advanced.connect(_show_line)
	manager.dialogue_finished.connect(_hide_box)
	set_process(true)


func _process(delta: float) -> void:
	if not _typing:
		return
	var settings_manager := get_node_or_null("/root/SettingsManager")
	var speed_multiplier := 1.0
	if settings_manager != null:
		speed_multiplier = float(settings_manager.get_setting("text_speed", 1.0))
	_reveal_progress += delta * 34.0 * speed_multiplier
	line_label.visible_characters = mini(int(_reveal_progress), _full_line.length())
	if line_label.visible_characters >= _full_line.length():
		_finish_typing()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact"):
		if _typing:
			line_label.visible_characters = -1
			_finish_typing()
			get_viewport().set_input_as_handled()
			return
		var manager := get_node_or_null("/root/DialogueManager")
		if manager != null:
			manager.advance()
		get_viewport().set_input_as_handled()


func _show_line(speaker: String, line: String) -> void:
	visible = true
	speaker_label.text = speaker
	_full_line = line
	line_label.text = _full_line
	line_label.visible_characters = 0
	_reveal_progress = 0.0
	_typing = true
	continue_label.visible = false


func _hide_box(_flag_name: String) -> void:
	visible = false
	_typing = false
	continue_label.visible = false


func _finish_typing() -> void:
	_typing = false
	line_label.visible_characters = -1
	continue_label.visible = true
