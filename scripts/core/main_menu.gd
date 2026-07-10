extends Node

@onready var _title_layer: CanvasLayer = $TitleLayer
@onready var _continue_button: Button = $TitleLayer/Panel/ContinueButton


func _ready() -> void:
	if _continue_button != null:
		var save_system := get_node_or_null("/root/SaveSystem")
		_continue_button.disabled = save_system == null or not save_system.has_save()
	var new_game_button: Button = $TitleLayer/Panel/NewGameButton
	if new_game_button != null:
		new_game_button.pressed.connect(start_new_game)
	if _continue_button != null:
		_continue_button.pressed.connect(continue_game)
	var quit_button: Button = get_node_or_null("TitleLayer/Panel/QuitButton") as Button
	if quit_button != null:
		quit_button.pressed.connect(quit_game)


func start_new_game() -> void:
	_play_ui_select()
	var save_system := get_node_or_null("/root/SaveSystem")
	if save_system != null:
		save_system.new_game()
	if _title_layer != null:
		_title_layer.visible = false


func continue_game() -> void:
	_play_ui_select()
	var save_system := get_node_or_null("/root/SaveSystem")
	if save_system == null or not save_system.has_save():
		start_new_game()
		return
	var save_data: Dictionary = save_system.load_game()
	var level_id := str(save_data.get("level_id", "level_01"))
	get_tree().change_scene_to_file(save_system.get_level_scene_path(level_id))


func quit_game() -> void:
	_play_ui_select()
	get_tree().quit()


func _play_ui_select() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.play_ui_select()
