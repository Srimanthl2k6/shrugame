extends Control

@onready var enemy_label: Label = $Panel/EnemyLabel
@onready var hp_label: Label = $Panel/HpLabel
@onready var phase_label: Label = $Panel/PhaseLabel
@onready var command_label: Label = $Panel/CommandLabel
@onready var player_status_label: Label = $Panel/PlayerStatusLabel
@onready var boss_status_label: Label = $Panel/BossStatusLabel


func update_hud(enemy_name: String, player_hp: int, player_max_hp: int, phase: String, resonance: int, resonance_goal: int) -> void:
	enemy_label.text = enemy_name
	hp_label.text = "Shrububu HP %s/%s" % [player_hp, player_max_hp]
	boss_status_label.text = "Boss RES %s/%s" % [resonance, resonance_goal]
	player_status_label.text = _format_player_status(player_hp, player_max_hp)
	phase_label.text = format_phase_label(phase)
	command_label.text = format_command_hint(phase)


func show_message(message: String) -> void:
	command_label.text = message


func format_phase_label(phase: String) -> String:
	match phase:
		"player_command":
			return "Your turn"
		"enemy_phase":
			return "Dodge phase"
		"resolved":
			return "Battle clear"
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
		"resolved":
			return "Returning to town"
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
