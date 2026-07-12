extends Node

@onready var _title_layer: CanvasLayer = $TitleLayer
@onready var _menu_panel: Control = $TitleLayer/MenuPanel
@onready var _new_game_button: Button = $TitleLayer/MenuPanel/NewGameButton
@onready var _continue_button: Button = $TitleLayer/MenuPanel/ContinueButton
@onready var _difficulty_layer: Control = $TitleLayer/DifficultyLayer
@onready var _shrububu_button: Button = $TitleLayer/DifficultyLayer/Modal/ShrububuButton
@onready var _srmt_button: Button = $TitleLayer/DifficultyLayer/Modal/SrmtButton
@onready var _cancel_button: Button = $TitleLayer/DifficultyLayer/Modal/CancelButton
@onready var _settings_panel: Control = $TitleLayer/SettingsPanel
@onready var _credits_layer: Control = $TitleLayer/CreditsLayer
@onready var _overwrite_dialog: ConfirmationDialog = $OverwriteDialog
@onready var _controls_panel: Control = $TitleLayer/ControlsPanel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	var save_system := get_node_or_null("/root/SaveSystem")
	_continue_button.disabled = save_system == null or not save_system.has_save()
	_new_game_button.pressed.connect(start_new_game)
	_overwrite_dialog.confirmed.connect(_open_difficulty_selection)
	_continue_button.pressed.connect(continue_game)
	$TitleLayer/MenuPanel/OptionsButton.pressed.connect(open_options)
	$TitleLayer/MenuPanel/ControlsButton.pressed.connect(open_controls)
	$TitleLayer/MenuPanel/CreditsButton.pressed.connect(open_credits)
	$TitleLayer/MenuPanel/QuitButton.pressed.connect(quit_game)
	_shrububu_button.pressed.connect(select_difficulty.bind("shrububu"))
	_srmt_button.pressed.connect(select_difficulty.bind("srmt"))
	_cancel_button.pressed.connect(close_difficulty_selection)
	_settings_panel.close_requested.connect(_return_from_options)
	_controls_panel.close_requested.connect(_return_from_controls)
	$TitleLayer/CreditsLayer/Modal/BackButton.pressed.connect(close_credits)
	_difficulty_layer.visible = false
	_credits_layer.visible = false
	_new_game_button.grab_focus.call_deferred()
	if not _get_electron_smoke_target().is_empty():
		_run_electron_smoke_flow.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _credits_layer.visible:
		close_credits()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and _difficulty_layer.visible:
		close_difficulty_selection()
		get_viewport().set_input_as_handled()


func start_new_game() -> void:
	_play_ui_select()
	var save_system := get_node_or_null("/root/SaveSystem")
	if save_system != null and save_system.has_save():
		_overwrite_dialog.popup_centered()
		return
	_open_difficulty_selection()


func _open_difficulty_selection() -> void:
	_difficulty_layer.visible = true
	_menu_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shrububu_button.grab_focus.call_deferred()


func select_difficulty(selected_difficulty_id: String) -> void:
	_play_ui_select()
	var save_system := get_node_or_null("/root/SaveSystem")
	if save_system != null:
		save_system.new_game(selected_difficulty_id)
	else:
		var game_state := get_node_or_null("/root/GameState")
		if game_state != null and game_state.has_method("set_difficulty"):
			game_state.set_difficulty(selected_difficulty_id)
	_difficulty_layer.visible = false
	get_tree().paused = false
	_title_layer.visible = false
	var tutorial_manager := get_node_or_null("/root/TutorialManager")
	if tutorial_manager != null:
		if not tutorial_manager.intro_ready.is_connected(_begin_level_intro):
			tutorial_manager.intro_ready.connect(_begin_level_intro, CONNECT_ONE_SHOT)
		tutorial_manager.begin_new_game_sequence()
	else:
		_begin_level_intro()


func close_difficulty_selection() -> void:
	_play_ui_select()
	_difficulty_layer.visible = false
	_menu_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_new_game_button.grab_focus.call_deferred()


func open_options() -> void:
	_play_ui_select()
	_menu_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_settings_panel.open()


func _return_from_options() -> void:
	_menu_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	$TitleLayer/MenuPanel/OptionsButton.grab_focus.call_deferred()


func open_controls() -> void:
	_play_ui_select()
	_menu_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_controls_panel.open()


func _return_from_controls() -> void:
	_menu_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	$TitleLayer/MenuPanel/ControlsButton.grab_focus.call_deferred()


func open_credits() -> void:
	_play_ui_select()
	_menu_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_credits_layer.visible = true
	$TitleLayer/CreditsLayer/Modal/BackButton.grab_focus.call_deferred()


func close_credits() -> void:
	_play_ui_select()
	_credits_layer.visible = false
	_menu_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	$TitleLayer/MenuPanel/CreditsButton.grab_focus.call_deferred()


func continue_game() -> void:
	_play_ui_select()
	var save_system := get_node_or_null("/root/SaveSystem")
	if save_system == null or not save_system.has_save():
		start_new_game()
		return
	var save_data: Dictionary = save_system.load_game()
	var level_id := str(save_data.get("level_id", "level_01"))
	get_tree().paused = false
	get_tree().change_scene_to_file(save_system.get_level_scene_path(level_id))


func quit_game() -> void:
	_play_ui_select()
	get_tree().quit()


func _play_ui_select() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.play_ui_select()


func _begin_level_intro() -> void:
	var level_one := get_node_or_null("Level01")
	if level_one != null and level_one.has_method("begin_level_intro"):
		level_one.begin_level_intro()


func _get_electron_smoke_target() -> String:
	if not OS.has_feature("web"):
		return ""
	var result = JavaScriptBridge.eval("new URLSearchParams(window.parent.location.search).get('smoke') || ''", true)
	return str(result)


func _run_electron_smoke_flow() -> void:
	await get_tree().create_timer(1.5, true, false, true).timeout
	var smoke_target := _get_electron_smoke_target()
	if smoke_target == "battle":
		var save_system := get_node_or_null("/root/SaveSystem")
		if save_system != null:
			save_system.new_game("shrububu")
		var game_state := get_node_or_null("/root/GameState")
		if game_state != null:
			game_state.pending_encounter_id = "poojan_strength_test"
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/battle/battle_scene.tscn")
		return
	if smoke_target == "ending":
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/ending.tscn")
		return
	if smoke_target == "transition_level_01":
		var transition_save := get_node_or_null("/root/SaveSystem")
		if transition_save != null:
			transition_save.new_game("shrububu")
		var transition_state := get_node_or_null("/root/GameState")
		if transition_state != null:
			transition_state.current_level_id = "level_01"
			transition_state.current_room_id = "satyaki_waterfront"
			transition_state.spawn_point = "from_records"
			transition_state.pending_encounter_id = ""
			transition_state.set_flag("satyaki_tirumal_defeated", true)
			transition_state.set_flag("satyaki_defeat_seen", true)
			transition_state.set_flag("tutorial_overworld_completed", true)
			transition_state.set_flag("tutorial_battle_completed", true)
			transition_state.set_current_objective("Walk east to Banana-burbs.")
			transition_save.save_game("level_01", "from_records", "satyaki_waterfront")
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/levels/districts/level_01.tscn")
		return
	if smoke_target.begins_with("level_0"):
		var level_number := smoke_target.trim_prefix("level_")
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/levels/districts/level_%s.tscn" % level_number)
		return
	start_new_game()
	await get_tree().create_timer(0.15, true, false, true).timeout
	select_difficulty("shrububu")
