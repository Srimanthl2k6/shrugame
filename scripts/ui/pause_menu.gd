extends CanvasLayer

@onready var _root: Control = $Root
@onready var _difficulty_label: Label = $Root/Shell/Left/DifficultyLabel
@onready var _section_title: Label = $Root/Shell/Content/SectionTitle
@onready var _content_text: RichTextLabel = $Root/Shell/Content/ContentText
@onready var _settings_panel: Control = $Root/SettingsPanel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.visible = false
	$Root/Shell/Left/ResumeButton.pressed.connect(close_menu)
	$Root/Shell/Left/JournalButton.pressed.connect(show_journal)
	$Root/Shell/Left/ItemsButton.pressed.connect(show_items)
	$Root/Shell/Left/OptionsButton.pressed.connect(open_options)
	$Root/Shell/Left/SaveButton.pressed.connect(save_game)
	$Root/Shell/Left/TitleButton.pressed.connect(quit_to_title)
	_settings_panel.close_requested.connect(_return_from_options)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _settings_panel.visible:
		return
	var director := get_node_or_null("/root/CutsceneDirector")
	if director != null and director.is_playing:
		return
	if _root.visible:
		close_menu()
	else:
		open_menu()
	get_viewport().set_input_as_handled()


func open_menu() -> void:
	_refresh_header()
	show_journal()
	_root.visible = true
	get_tree().paused = true
	$Root/Shell/Left/ResumeButton.grab_focus.call_deferred()


func close_menu() -> void:
	_root.visible = false
	_settings_panel.visible = false
	get_tree().paused = false


func show_journal() -> void:
	_section_title.text = "CLUE JOURNAL"
	_content_text.text = _build_journal_text()


func show_items() -> void:
	_section_title.text = "BAG & GEAR"
	_content_text.text = _build_items_text()


func open_options() -> void:
	_settings_panel.open()


func _return_from_options() -> void:
	$Root/Shell/Left/OptionsButton.grab_focus.call_deferred()


func save_game() -> void:
	var save_system := get_node_or_null("/root/SaveSystem")
	var game_state := get_node_or_null("/root/GameState")
	if save_system != null and game_state != null:
		save_system.save_game(str(game_state.current_level_id), str(game_state.spawn_point), str(game_state.current_room_id))
		_section_title.text = "GAME SAVED"
		_content_text.text = "One save file. Ishiville remembers this exact version of the rain."


func quit_to_title() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _refresh_header() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		_difficulty_label.text = "MODE: SHRUBUBU"
		return
	var mode: Dictionary = game_state.get_difficulty_data()
	_difficulty_label.text = "MODE: %s" % str(mode.get("display_name", game_state.difficulty_id)).to_upper()


func _build_journal_text() -> String:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or game_state.get_collected_clue_ids().is_empty():
		return "[color=#9eb5b5]NO CLUES YET[/color]\n\nThe rain has not admitted anything useful."
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/clues/clues.json"))
	var lines: Array[String] = []
	for clue_id in game_state.get_collected_clue_ids():
		var entry: Dictionary = data.get(clue_id, {}) if typeof(data) == TYPE_DICTIONARY else {}
		lines.append("[color=#efc757]%s[/color]\n%s" % [entry.get("display_name", clue_id), entry.get("summary", "No notes.")])
	return "\n\n".join(lines)


func _build_items_text() -> String:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return "Bag unavailable."
	var lines: Array[String] = ["[color=#efc757]CURRENT WEAPON[/color]\n%s" % (str(game_state.current_weapon).capitalize() if not str(game_state.current_weapon).is_empty() else "Bare hands and disappointment")]
	lines.append("[color=#efc757]GROWTH FORM[/color]\nForm %d of 5" % int(game_state.growth_stage))
	if game_state.inventory.is_empty():
		lines.append("[color=#efc757]BAG[/color]\nEmpty")
	else:
		var bag_lines: Array[String] = []
		for item_id in game_state.inventory.keys():
			bag_lines.append("%s x%d" % [str(item_id).replace("_", " ").capitalize(), int(game_state.inventory[item_id])])
		lines.append("[color=#efc757]BAG[/color]\n%s" % "\n".join(bag_lines))
	return "\n\n".join(lines)
