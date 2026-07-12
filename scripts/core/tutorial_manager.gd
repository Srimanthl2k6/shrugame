extends Node

signal intro_ready
signal overworld_tutorial_completed
signal battle_tutorial_completed

const OverlayScene := preload("res://scenes/ui/tutorial_overlay.tscn")

const MODE_IDLE := "idle"
const MODE_INTRO_CARD := "intro_card"
const MODE_REPLAY_CARD := "replay_card"
const MODE_WAITING_OPENING := "waiting_opening"
const MODE_OVERWORLD_MOVEMENT := "overworld_movement"
const MODE_OVERWORLD_INTERACTION := "overworld_interaction"
const MODE_BATTLE_COMMANDS := "battle_commands"
const MODE_BATTLE_ENEMY := "battle_enemy"
const MODE_BATTLE_MOVEMENT := "battle_movement"

var mode := MODE_IDLE
var _overlay
var _tracked_node: Node2D
var _tracked_start := Vector2.ZERO
var _battle_command_card_seen := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay = OverlayScene.instantiate()
	add_child(_overlay)
	_overlay.confirmed.connect(_on_confirmed)
	_overlay.skipped.connect(_on_skipped)
	var input_manager := get_node_or_null("/root/InputManager")
	if input_manager != null:
		input_manager.input_device_changed.connect(_on_input_device_changed)
	var director := get_node_or_null("/root/CutsceneDirector")
	if director != null:
		director.cutscene_completed.connect(_on_cutscene_completed)


func _process(_delta: float) -> void:
	if mode == MODE_OVERWORLD_MOVEMENT:
		if not is_instance_valid(_tracked_node):
			_track_player()
		elif _tracked_node.global_position.distance_to(_tracked_start) >= 24.0:
			mode = MODE_OVERWORLD_INTERACTION
			_show_overworld_interaction_prompt()
	elif mode == MODE_BATTLE_MOVEMENT:
		if not is_instance_valid(_tracked_node):
			return
		if _tracked_node.global_position.distance_to(_tracked_start) >= 8.0:
			_complete_battle_tutorial()


func begin_new_game_sequence() -> void:
	if _get_flag("tutorial_overworld_completed"):
		intro_ready.emit()
		return
	mode = MODE_INTRO_CARD
	get_tree().paused = true
	_show_controls_card("CONTROLS")


func replay_overworld_tutorial() -> void:
	mode = MODE_REPLAY_CARD
	get_tree().paused = true
	_show_controls_card("CONTROLS REVIEW")


func begin_battle_command_tutorial(encounter_id: String) -> void:
	if encounter_id != "poojan_strength_test" or _get_flag("tutorial_battle_completed"):
		return
	_battle_command_card_seen = true
	mode = MODE_BATTLE_COMMANDS
	get_tree().paused = true
	_overlay.show_card(
		"BATTLE COMMANDS",
		"ACT attacks and builds RESONANCE.\nITEM restores or changes Shrububu.\nGEAR switches weapons. GUARD reduces damage.\n\nWin by strength or by filling RESONANCE.",
		"%s: CONTINUE    HOLD %s: SKIP" % [_action_prompt("interact"), _action_prompt("ui_cancel")]
	)


func begin_battle_enemy_tutorial(encounter_id: String, soul_cursor: Node2D) -> void:
	if encounter_id != "poojan_strength_test" or _get_flag("tutorial_battle_completed"):
		return
	if not _battle_command_card_seen:
		return
	_tracked_node = soul_cursor
	_tracked_start = soul_cursor.global_position if soul_cursor != null else Vector2.ZERO
	mode = MODE_BATTLE_ENEMY
	get_tree().paused = true
	_overlay.show_card(
		"DODGE PHASE",
		"Move Shrububu's heart inside the battle box.\nAvoid bullets until the enemy phase ends.\nLosing all HP restarts the fight.",
		"%s: CONTINUE    HOLD %s: SKIP" % [_action_prompt("interact"), _action_prompt("ui_cancel")]
	)


func notify_interaction_completed(_source: Node = null) -> void:
	if mode != MODE_OVERWORLD_INTERACTION:
		return
	_set_flag("tutorial_overworld_completed")
	_save_progress()
	mode = MODE_IDLE
	_overlay.hide_overlay()
	overworld_tutorial_completed.emit()


func is_tutorial_active() -> bool:
	return mode != MODE_IDLE


func _on_confirmed() -> void:
	match mode:
		MODE_INTRO_CARD:
			mode = MODE_WAITING_OPENING
			_overlay.hide_overlay()
			get_tree().paused = false
			intro_ready.emit()
		MODE_REPLAY_CARD:
			get_tree().paused = false
			_start_overworld_movement()
		MODE_BATTLE_COMMANDS:
			mode = MODE_IDLE
			_overlay.hide_overlay()
			get_tree().paused = false
		MODE_BATTLE_ENEMY:
			mode = MODE_BATTLE_MOVEMENT
			get_tree().paused = false
			_tracked_start = _tracked_node.global_position if is_instance_valid(_tracked_node) else Vector2.ZERO
			_overlay.show_context("DODGE", "Move with %s." % _movement_prompt())


func _on_skipped() -> void:
	match mode:
		MODE_INTRO_CARD, MODE_WAITING_OPENING, MODE_OVERWORLD_MOVEMENT, MODE_OVERWORLD_INTERACTION:
			_set_flag("tutorial_overworld_completed")
			_save_progress()
			var should_start_intro := mode == MODE_INTRO_CARD
			mode = MODE_IDLE
			_overlay.hide_overlay()
			get_tree().paused = false
			if should_start_intro:
				intro_ready.emit()
		MODE_REPLAY_CARD:
			mode = MODE_IDLE
			_overlay.hide_overlay()
			get_tree().paused = false
		MODE_BATTLE_COMMANDS, MODE_BATTLE_ENEMY, MODE_BATTLE_MOVEMENT:
			_complete_battle_tutorial()


func _on_cutscene_completed(cutscene_id: String, _skipped: bool) -> void:
	if cutscene_id == "opening_arrival" and mode == MODE_WAITING_OPENING:
		_start_overworld_movement()


func _start_overworld_movement() -> void:
	mode = MODE_OVERWORLD_MOVEMENT
	_track_player()
	_overlay.show_context("MOVE", "Walk using %s. Move a short distance to continue." % _movement_prompt())


func _track_player() -> void:
	var current_scene := get_tree().current_scene
	_tracked_node = current_scene.find_child("Player", true, false) as Node2D if current_scene != null else null
	if _tracked_node != null:
		_tracked_start = _tracked_node.global_position


func _show_overworld_interaction_prompt() -> void:
	_overlay.show_context(
		"INTERACT",
		"Approach a highlighted person or object and press %s." % _action_prompt("interact")
	)


func _show_controls_card(title: String) -> void:
	_overlay.show_card(
		title,
		"MOVE    %s\nINTERACT / CONFIRM    %s\nPAUSE / BACK    %s" % [_movement_prompt(), _action_prompt("interact"), _action_prompt("ui_cancel")],
		"%s: CONTINUE    HOLD %s: SKIP" % [_action_prompt("interact"), _action_prompt("ui_cancel")]
	)


func _complete_battle_tutorial() -> void:
	_set_flag("tutorial_battle_completed")
	_save_progress()
	mode = MODE_IDLE
	_overlay.hide_overlay()
	get_tree().paused = false
	battle_tutorial_completed.emit()


func _on_input_device_changed(_device_id: String) -> void:
	match mode:
		MODE_INTRO_CARD:
			_show_controls_card("CONTROLS")
		MODE_REPLAY_CARD:
			_show_controls_card("CONTROLS REVIEW")
		MODE_OVERWORLD_MOVEMENT:
			_overlay.show_context("MOVE", "Walk using %s. Move a short distance to continue." % _movement_prompt())
		MODE_OVERWORLD_INTERACTION:
			_show_overworld_interaction_prompt()


func _movement_prompt() -> String:
	var input_manager := get_node_or_null("/root/InputManager")
	if input_manager != null and input_manager.has_method("get_movement_prompt"):
		return str(input_manager.get_movement_prompt())
	return "WASD / ARROW KEYS"


func _action_prompt(action: String) -> String:
	var input_manager := get_node_or_null("/root/InputManager")
	if input_manager != null and input_manager.has_method("get_action_prompt"):
		return str(input_manager.get_action_prompt(action))
	return "E / ENTER" if action == "interact" else "ESC"


func _get_flag(flag_name: String) -> bool:
	var game_state := get_node_or_null("/root/GameState")
	return game_state != null and game_state.get_flag(flag_name)


func _set_flag(flag_name: String) -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.set_flag(flag_name, true)


func _save_progress() -> void:
	var game_state := get_node_or_null("/root/GameState")
	var save_system := get_node_or_null("/root/SaveSystem")
	if game_state != null and save_system != null:
		save_system.save_game(str(game_state.current_level_id), str(game_state.spawn_point), str(game_state.current_room_id))
