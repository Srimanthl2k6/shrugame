extends Control

signal command_selected(command_id: String)
signal item_selected(item_id: String)
signal gear_selected(gear_id: String)
signal choice_cancelled

@onready var enemy_label: Label = $Panel/EnemyLabel
@onready var hp_label: Label = $Panel/HpLabel
@onready var phase_label: Label = $Panel/PhaseLabel
@onready var command_label: Label = $Panel/CommandLabel
@onready var player_status_label: Label = $Panel/PlayerStatusLabel
@onready var boss_status_label: Label = $Panel/BossStatusLabel
@onready var command_buttons: Array[Button] = [
	$Panel/ActButton,
	$Panel/ItemButton,
	$Panel/GearButton,
	$Panel/GuardButton
]
@onready var choice_panel: Panel = $ChoicePanel
@onready var choice_title: Label = $ChoicePanel/Title
@onready var choices: VBoxContainer = $ChoicePanel/Choices


func _ready() -> void:
	$Panel/ActButton.pressed.connect(command_selected.emit.bind("act"))
	$Panel/ItemButton.pressed.connect(command_selected.emit.bind("item"))
	$Panel/GearButton.pressed.connect(command_selected.emit.bind("gear"))
	$Panel/GuardButton.pressed.connect(command_selected.emit.bind("guard"))


func _unhandled_input(event: InputEvent) -> void:
	if choice_panel.visible and event.is_action_pressed("ui_cancel"):
		hide_choice_menu()
		choice_cancelled.emit()
		get_viewport().set_input_as_handled()


func update_hud(enemy_name: String, player_hp: int, player_max_hp: int, phase: String, resonance: int, resonance_goal: int) -> void:
	enemy_label.text = enemy_name
	hp_label.text = "Shrububu HP %s/%s" % [player_hp, player_max_hp]
	boss_status_label.text = "Boss RES %s/%s" % [resonance, resonance_goal]
	player_status_label.text = _format_player_status(player_hp, player_max_hp)
	phase_label.text = format_phase_label(phase)
	command_label.text = format_command_hint(phase)


func show_message(message: String) -> void:
	command_label.text = message
	command_label.visible = true


func set_commands_enabled(enabled: bool) -> void:
	for button in command_buttons:
		button.disabled = not enabled
		button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	if enabled:
		command_label.visible = false


func show_item_menu(entries: Array[Dictionary]) -> void:
	_show_choice_menu("USE ITEM", entries, item_selected)


func show_gear_menu(entries: Array[Dictionary]) -> void:
	_show_choice_menu("EQUIP GEAR", entries, gear_selected)


func hide_choice_menu() -> void:
	choice_panel.visible = false
	for child in choices.get_children():
		child.queue_free()


func _show_choice_menu(title: String, entries: Array[Dictionary], selected_signal: Signal) -> void:
	hide_choice_menu()
	choice_title.text = title
	for entry in entries:
		var button := Button.new()
		button.text = str(entry.get("label", entry.get("id", "Choice")))
		button.tooltip_text = str(entry.get("description", ""))
		button.add_theme_font_size_override("font_size", 15)
		button.pressed.connect(_select_choice.bind(str(entry.get("id", "")), selected_signal))
		choices.add_child(button)
	choice_panel.visible = true
	if choices.get_child_count() > 0:
		(choices.get_child(0) as Control).grab_focus()


func _select_choice(id: String, selected_signal: Signal) -> void:
	hide_choice_menu()
	selected_signal.emit(id)


func format_phase_label(phase: String) -> String:
	match phase:
		"player_command":
			return "Your turn"
		"enemy_phase":
			return "Dodge phase"
		"weapon_timing":
			return "Time the attack"
		"resolved":
			return "Battle clear"
		"defeated":
			return "Defeated"
		"idle":
			return "Battle starting"
		_:
			return phase.capitalize()


func format_command_hint(phase: String) -> String:
	match phase:
		"player_command":
			return "E: Act | Item | Gear | Guard"
		"enemy_phase":
			return "Move: dodge bullets"
		"weapon_timing":
			return "Confirm on the gold mark"
		"resolved":
			return "Returning to town"
		"defeated":
			return "E retry | Esc retreat"
		_:
			return "Read the arena"


func _format_player_status(player_hp: int, player_max_hp: int) -> String:
	if player_max_hp <= 0:
		return "Shrububu status unknown"
	var ratio := float(player_hp) / float(player_max_hp)
	if ratio <= 0.3:
		return "Shrububu critical"
	if ratio <= 0.6:
		return "Shrububu hurt"
	return "Shrububu steady"
