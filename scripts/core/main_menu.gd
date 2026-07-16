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
	if OS.has_feature("web"):
		var electron_quit = JavaScriptBridge.eval("""
			(() => {
				const desktop = window.parent && window.parent.shrugameDesktop;
				if (!desktop || typeof desktop.quit !== 'function') return false;
				desktop.quit();
				return true;
			})()
		""", true)
		if bool(electron_quit):
			return
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
	var claimed = JavaScriptBridge.eval("""
		(() => {
			if (window.parent.__shrugameSmokeFlowStarted) return false;
			window.parent.__shrugameSmokeFlowStarted = true;
			return true;
		})()
	""", true)
	if not bool(claimed):
		return
	await get_tree().create_timer(1.5, true, false, true).timeout
	var smoke_target := _get_electron_smoke_target()
	JavaScriptBridge.eval("window.__shrugameSmokeTarget = %s" % JSON.stringify(smoke_target), true)
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
	if smoke_target == "ending_media":
		var ending_state := get_node_or_null("/root/GameState")
		if ending_state != null:
			ending_state.set_flag("srmt_defeated", true)
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/ending.tscn")
		return
	if smoke_target == "quit_button":
		quit_game()
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
	if smoke_target == "right_edge_level_02":
		var edge_save := get_node_or_null("/root/SaveSystem")
		if edge_save != null:
			edge_save.new_game("shrububu")
		var edge_state := get_node_or_null("/root/GameState")
		if edge_state != null:
			edge_state.current_level_id = "level_02"
			edge_state.current_room_id = "laboratory"
			edge_state.spawn_point = "from_approach"
			edge_state.pending_encounter_id = ""
			edge_state.set_flag("165_files_collected", true)
			edge_state.set_flag("tutorial_overworld_completed", true)
			edge_state.set_flag("tutorial_battle_completed", true)
			edge_state.set_current_objective("Keep walking east.")
			edge_save.save_game("level_02", "from_approach", "laboratory")
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/levels/districts/level_02.tscn")
		return
	if smoke_target == "level_02_lab_progression":
		var lab_save := get_node_or_null("/root/SaveSystem")
		if lab_save != null:
			lab_save.new_game("shrububu")
		var lab_state := get_node_or_null("/root/GameState")
		if lab_state != null:
			lab_state.current_level_id = "level_02"
			lab_state.current_room_id = "laboratory"
			lab_state.spawn_point = "from_plaza"
			lab_state.pending_encounter_id = ""
			lab_state.set_growth_stage(2)
			lab_state.set_flag("tutorial_overworld_completed", true)
			lab_state.set_flag("tutorial_battle_completed", true)
			lab_state.set_current_objective("Recover the visible 165-files.")
			lab_save.save_game("level_02", "from_plaza", "laboratory")
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/levels/districts/level_02.tscn")
		return
	if smoke_target == "level_04_hospital_progression":
		var hospital_save := get_node_or_null("/root/SaveSystem")
		if hospital_save != null:
			hospital_save.new_game("shrububu")
		var hospital_state := get_node_or_null("/root/GameState")
		if hospital_state != null:
			hospital_state.current_level_id = "level_04"
			hospital_state.current_room_id = "hospital_reception"
			hospital_state.spawn_point = "from_street"
			hospital_state.pending_encounter_id = ""
			hospital_state.set_growth_stage(4)
			hospital_state.set_flag("tutorial_overworld_completed", true)
			hospital_state.set_flag("tutorial_battle_completed", true)
			hospital_state.set_current_objective("Inspect the glowing hospital records terminal.")
			hospital_save.save_game("level_04", "from_street", "hospital_reception")
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/levels/districts/level_04.tscn")
		return
	if smoke_target == "full_progression":
		var probe := Node.new()
		probe.set_script(preload("res://scripts/core/release_progression_probe.gd"))
		get_tree().root.add_child(probe)
		probe.call_deferred("run")
		return
	if smoke_target == "right_edge_harbour_square":
		var harbour_save := get_node_or_null("/root/SaveSystem")
		if harbour_save != null:
			harbour_save.new_game("shrububu")
		var harbour_state := get_node_or_null("/root/GameState")
		if harbour_state != null:
			harbour_state.current_level_id = "level_01"
			harbour_state.current_room_id = "harbour_square"
			harbour_state.spawn_point = "from_docks"
			harbour_state.pending_encounter_id = ""
			harbour_state.set_flag("building_broken", true)
			harbour_state.set_flag("opening_arrival_seen", true)
			harbour_state.set_flag("tutorial_overworld_completed", true)
			harbour_state.set_flag("tutorial_battle_completed", true)
			harbour_state.set_current_objective("Keep walking east.")
			harbour_save.save_game("level_01", "from_docks", "harbour_square")
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
