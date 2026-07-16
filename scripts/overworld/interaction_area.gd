class_name InteractionArea
extends Area2D

signal interacted(message: String)

const TuningLoader := preload("res://scripts/core/tuning_loader.gd")

@export var interaction_message: String = "Interacted."
@export var display_name: String = ""
@export var prompt_action_text: String = "E/Enter"
@export_file("*.tscn") var target_scene_path: String = ""
@export var dialogue_id: String = ""
@export_file("*.json") var dialogue_file_path: String = ""
@export var flag_on_interact: String = ""
@export var post_flag: String = ""
@export var post_dialogue_id: String = ""
@export var required_flags: PackedStringArray = []
@export var locked_message: String = "It will not open yet."
@export var save_on_interact := false
@export var level_id := "level_01"
@export var spawn_point := "start"
@export var encounter_id := ""
@export var clue_id := ""
@export var item_id := ""
@export var item_amount := 1
@export var gear_id := ""
@export var growth_stage_on_interact := 0
@export var objective_text := ""
@export var interaction_size := Vector2(34.0, 22.0)
@export var interaction_padding := Vector2(-1.0, -1.0)
@export var focus_priority := 0
@export var disabled_if_flag := ""
@export var one_shot := false
@export var hide_when_disabled := false
@export var cutscene_id := ""
@export var focus_highlight := true
@export var auto_activate_on_body_enter := false
@export var persist_progress_on_activate := false

var _player_inside := false
var _disabled := false
var _activation_in_progress := false
var _focused := false
var _focus_marker: Label


func _ready() -> void:
	_apply_tuning()
	_create_focus_marker()
	add_to_group("interaction_targets")
	if not disabled_if_flag.is_empty() and _get_story_flag(disabled_if_flag):
		_disable_interaction()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _exit_tree() -> void:
	var interaction_manager := get_node_or_null("/root/InteractionManager")
	if interaction_manager != null:
		interaction_manager.unregister_candidate(self)


func _process(_delta: float) -> void:
	if auto_activate_on_body_enter and _player_inside and not _disabled and not _activation_in_progress and _has_required_flags():
		_try_auto_activate()


func try_activate() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D if is_inside_tree() else null
	if _disabled or _activation_in_progress or (not _player_inside and not _focused and not is_player_candidate(player)):
		return false
	if not _has_required_flags():
		print(locked_message)
		interacted.emit(locked_message)
		return true
	if not cutscene_id.is_empty():
		return _try_start_cutscene()

	print(interaction_message)
	interacted.emit(interaction_message)
	_play_ui_select()
	_play_contextual_interaction_sfx()
	_apply_progression_rewards()
	_notify_tutorial_interaction()
	if not flag_on_interact.is_empty() and dialogue_id.is_empty():
		_set_story_flag(flag_on_interact)
		_notify_level_controller(flag_on_interact)
	if save_on_interact:
		var save_system := get_node_or_null("/root/SaveSystem")
		if save_system != null:
			save_system.save_game(level_id, spawn_point)
			_set_story_flag("%s_saved" % level_id)
			_play_save_chime()
	if persist_progress_on_activate:
		_persist_current_progress()
	if not dialogue_id.is_empty():
		var manager := get_node_or_null("/root/DialogueManager")
		if manager != null:
			if not dialogue_file_path.is_empty():
				manager.load_dialogue_file(dialogue_file_path)
			manager.start_dialogue(resolve_dialogue_id(), flag_on_interact)
	if not target_scene_path.is_empty():
		if not encounter_id.is_empty():
			var game_state := get_node_or_null("/root/GameState")
			if game_state != null:
				game_state.pending_encounter_id = encounter_id
			_play_encounter_start()
		_play_transition_wipe()
		get_tree().change_scene_to_file(target_scene_path)
	if one_shot:
		call_deferred("_disable_interaction")
	return true


func _try_start_cutscene() -> bool:
	var director := get_node_or_null("/root/CutsceneDirector")
	if director == null or director.is_playing or director.load_cutscene(cutscene_id).is_empty():
		return false
	_activation_in_progress = true
	_play_ui_select()
	_apply_progression_rewards()
	if not flag_on_interact.is_empty():
		_set_story_flag(flag_on_interact)
		_notify_level_controller(flag_on_interact)
	if persist_progress_on_activate:
		_persist_current_progress()
	director.play(cutscene_id, _find_level_root())
	_notify_tutorial_interaction()
	if one_shot:
		call_deferred("_disable_interaction")
	return true


func _on_body_entered(body: Node2D) -> void:
	if not _disabled and body.is_in_group("player"):
		_player_inside = true
		var interaction_manager := get_node_or_null("/root/InteractionManager")
		if interaction_manager != null:
			interaction_manager.register_candidate(self, body)
		if auto_activate_on_body_enter and _has_required_flags():
			call_deferred("_try_auto_activate")


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		var interaction_manager := get_node_or_null("/root/InteractionManager")
		if interaction_manager != null:
			interaction_manager.unregister_candidate(self)
		set_focused(false)


func _try_auto_activate() -> void:
	if _player_inside and not _disabled and not _activation_in_progress and _has_required_flags():
		try_activate()


func get_display_name() -> String:
	if not display_name.is_empty():
		return display_name
	return _split_camel_case(str(name))


func get_focus_prompt() -> String:
	var resolved_prompt := prompt_action_text
	var input_manager := get_node_or_null("/root/InputManager")
	if input_manager != null and prompt_action_text in ["E/Enter", "E/ENTER"]:
		resolved_prompt = input_manager.get_interact_prompt()
	return "%s: %s" % [resolved_prompt, get_display_name()]


func is_player_candidate(player: Node2D) -> bool:
	if _disabled or player == null or not player.is_in_group("player"):
		return false
	var player_half_size := Vector2(8.0, 12.0)
	var player_collision := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if player_collision != null and player_collision.shape is RectangleShape2D:
		player_half_size = (player_collision.shape as RectangleShape2D).size * 0.5
	var delta := (global_position - player.global_position).abs()
	var reach := interaction_size * 0.5 + interaction_padding + player_half_size
	return delta.x <= reach.x and delta.y <= reach.y


func set_focused(focused: bool) -> void:
	_focused = focused and not _disabled
	_set_focus_highlight(_focused)
	if _focus_marker != null:
		_focus_marker.visible = _focused
	refresh_focus_prompt()


func refresh_focus_prompt() -> void:
	if _focus_marker == null:
		return
	var input_manager := get_node_or_null("/root/InputManager") if is_inside_tree() else null
	_focus_marker.text = "[%s]" % (input_manager.get_action_prompt("interact") if input_manager != null else "E")


func _has_required_flags() -> bool:
	if required_flags.is_empty():
		return true
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return false
	for flag_name in required_flags:
		if not game_state.get_flag(flag_name):
			return false
	return true


func _apply_tuning() -> void:
	if interaction_padding.x < 0.0 or interaction_padding.y < 0.0:
		interaction_padding = TuningLoader.get_vector2(["overworld", "interaction_padding"], Vector2(24.0, 20.0))
	var collision: CollisionShape2D = get_node_or_null("CollisionShape2D")
	if collision != null and collision.shape is RectangleShape2D:
		var rect := collision.shape.duplicate() as RectangleShape2D
		rect.size = interaction_size + interaction_padding * 2.0
		collision.shape = rect


func resolve_dialogue_id() -> String:
	if post_flag.is_empty() or post_dialogue_id.is_empty():
		return dialogue_id
	var game_state := get_tree().root.get_node_or_null("GameState")
	if game_state == null:
		return dialogue_id
	if game_state.get_flag(post_flag):
		return post_dialogue_id
	return dialogue_id


func _set_story_flag(flag_name: String) -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.set_flag(flag_name, true)


func _persist_current_progress() -> void:
	var game_state := get_node_or_null("/root/GameState")
	var save_system := get_node_or_null("/root/SaveSystem")
	if game_state != null and save_system != null:
		save_system.save_game(str(game_state.current_level_id), str(game_state.spawn_point), str(game_state.current_room_id))


func _get_story_flag(flag_name: String) -> bool:
	var game_state := get_node_or_null("/root/GameState")
	return game_state != null and bool(game_state.get_flag(flag_name))


func _disable_interaction() -> void:
	var interaction_manager := get_node_or_null("/root/InteractionManager") if is_inside_tree() else null
	if interaction_manager != null:
		interaction_manager.unregister_candidate(self)
	set_focused(false)
	_disabled = true
	_player_inside = false
	monitoring = false
	monitorable = false
	if hide_when_disabled:
		visible = false


func _set_focus_highlight(active: bool) -> void:
	if not focus_highlight:
		return
	for child in get_children():
		if child == _focus_marker:
			continue
		var item := child as CanvasItem
		if item == null:
			continue
		if not item.has_meta("interaction_base_modulate"):
			item.set_meta("interaction_base_modulate", item.modulate)
		var base: Color = item.get_meta("interaction_base_modulate")
		item.modulate = base.lerp(Color(1.18, 1.14, 0.9, base.a), 0.34) if active else base


func _create_focus_marker() -> void:
	_focus_marker = Label.new()
	_focus_marker.name = "InteractionButtonMarker"
	_focus_marker.position = Vector2(-24.0, -interaction_size.y * 0.5 - 30.0)
	_focus_marker.size = Vector2(48.0, 22.0)
	_focus_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_focus_marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_focus_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_focus_marker.z_index = 4096
	_focus_marker.add_theme_font_size_override("font_size", 13)
	_focus_marker.add_theme_color_override("font_color", Color(1.0, 0.94, 0.64, 1.0))
	_focus_marker.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03, 1.0))
	_focus_marker.add_theme_constant_override("outline_size", 3)
	_focus_marker.visible = false
	add_child(_focus_marker)
	refresh_focus_prompt()


func _find_level_root() -> Node:
	var node: Node = self
	while node != null:
		if node.has_node("World"):
			return node
		node = node.get_parent()
	return get_tree().current_scene


func _notify_level_controller(flag_name: String) -> void:
	var node := get_parent()
	while node != null:
		if node.has_method("collect_tag"):
			node.collect_tag(flag_name)
			return
		if node.has_method("collect_objective"):
			node.collect_objective(flag_name)
			return
		if node.has_method("complete_objective"):
			node.complete_objective()
			return
		node = node.get_parent()


func _apply_progression_rewards() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return
	if not clue_id.is_empty() and game_state.has_method("collect_clue"):
		game_state.collect_clue(clue_id)
		_play_clue_pickup()
	if not item_id.is_empty() and game_state.has_method("add_item"):
		game_state.add_item(item_id, item_amount)
	if not gear_id.is_empty() and game_state.has_method("unlock_gear"):
		game_state.unlock_gear(gear_id)
	if growth_stage_on_interact > 0 and game_state.has_method("set_growth_stage"):
		game_state.set_growth_stage(growth_stage_on_interact)
		_play_growth_transform()
	if not objective_text.is_empty() and game_state.has_method("set_current_objective"):
		game_state.set_current_objective(objective_text)


func _play_ui_select() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.play_ui_select()


func _play_save_chime() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.play_save_chime()


func _play_encounter_start() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.play_encounter_start()


func _play_clue_pickup() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("play_clue_pickup"):
		audio_manager.play_clue_pickup()


func _play_growth_transform() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("play_growth_transform"):
		audio_manager.play_growth_transform()


func _play_transition_wipe() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.play_sfx("transition_wipe")


func _play_contextual_interaction_sfx() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager == null:
		return
	if dialogue_id == "opening_not_kfc" or flag_on_interact == "building_broken":
		audio_manager.play_sfx("door_slam")
		audio_manager.play_sfx("building_break")


func _notify_tutorial_interaction() -> void:
	var tutorial_manager := get_node_or_null("/root/TutorialManager")
	if tutorial_manager != null and tutorial_manager.has_method("notify_interaction_completed"):
		tutorial_manager.notify_interaction_completed(self)


func _split_camel_case(value: String) -> String:
	var output := ""
	for index in value.length():
		var character := value.substr(index, 1)
		if index > 0 and character == character.to_upper() and character != character.to_lower():
			output += " "
		output += character
	return output.strip_edges()
