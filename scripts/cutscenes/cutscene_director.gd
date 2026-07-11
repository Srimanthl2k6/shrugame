extends Node

signal cutscene_started(cutscene_id: String)
signal step_started(cutscene_id: String, step_index: int, step_type: String)
signal cutscene_completed(cutscene_id: String, skipped: bool)
signal advance_requested

const CATALOG_PATH := "res://data/cutscenes/index.json"
const LETTERBOX_SCENE := preload("res://scenes/ui/cutscene_letterbox.tscn")

var active_cutscene_id := ""
var is_playing := false
var _context_root: Node
var _current_data: Dictionary = {}
var _skip_requested := false
var _skippable := true
var _overlay: Control
var _active_tween: Tween
var _locked_players: Array[Node] = []
var _skip_hold_elapsed := 0.0
var _skip_hold_seconds := 0.65


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if not is_playing or not _skippable:
		_skip_hold_elapsed = 0.0
		return
	if Input.is_action_pressed("ui_cancel"):
		_skip_hold_elapsed += delta
		if _skip_hold_elapsed >= _skip_hold_seconds:
			skip_current()
	else:
		_skip_hold_elapsed = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if not is_playing:
		return
	if event.is_action_pressed("ui_cancel") and _skippable:
		var settings_manager := get_node_or_null("/root/SettingsManager")
		if settings_manager != null and not bool(settings_manager.get_setting("hold_to_skip", true)):
			skip_current()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		advance_requested.emit()


func load_catalog() -> Dictionary:
	return _load_json(CATALOG_PATH)


func load_cutscene(cutscene_id: String) -> Dictionary:
	var catalog := load_catalog()
	var path := str(catalog.get(cutscene_id, ""))
	if path.is_empty():
		return {}
	return _load_json(path)


func play(cutscene_id: String, context_root: Node = null) -> bool:
	var data := load_cutscene(cutscene_id)
	if data.is_empty():
		return false
	return await play_sequence(data, context_root)


func play_sequence(data: Dictionary, context_root: Node = null) -> bool:
	if is_playing:
		return false
	active_cutscene_id = str(data.get("id", "unnamed_cutscene"))
	_current_data = data.duplicate(true)
	_context_root = context_root if context_root != null else get_tree().current_scene
	_skip_requested = false
	_skip_hold_elapsed = 0.0
	_skippable = bool(data.get("skippable", true))
	is_playing = true
	_ensure_overlay()
	_overlay.show_frame(str(data.get("caption", "")), _skippable)
	cutscene_started.emit(active_cutscene_id)

	var steps: Array = data.get("steps", [])
	for index in range(steps.size()):
		if _skip_requested:
			break
		var step = steps[index]
		if typeof(step) != TYPE_DICTIONARY:
			continue
		var step_type := str(step.get("type", "wait"))
		step_started.emit(active_cutscene_id, index, step_type)
		await _execute_step(step)

	if _skip_requested:
		_apply_skip_state(steps)
	_apply_completion_state(data)
	_finish_cutscene(_skip_requested)
	return true


func skip_current() -> void:
	if not is_playing or not _skippable:
		return
	_skip_requested = true
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	var dialogue_manager := get_node_or_null("/root/DialogueManager")
	if dialogue_manager != null and dialogue_manager.has_method("cancel_dialogue"):
		dialogue_manager.cancel_dialogue()
	advance_requested.emit()


func _execute_step(step: Dictionary) -> void:
	match str(step.get("type", "wait")):
		"lock_player":
			_set_player_locked(bool(step.get("locked", true)))
		"move_actor", "camera_to":
			await _move_actor(step)
		"camera_pan":
			await _camera_pan(step)
		"camera_zoom":
			await _camera_zoom(step)
		"actor_animation":
			await _play_actor_animation(step)
		"face_actor":
			_face_actor(step)
		"spawn_actor":
			_spawn_actor(step)
		"despawn_actor":
			_despawn_actor(str(step.get("target", "")))
		"music_state":
			_set_music_state(step)
		"wait_signal":
			await _wait_for_signal(step)
		"checkpoint":
			_set_flag(str(step.get("flag", "%s_checkpoint" % active_cutscene_id)), true)
		"dialogue":
			await _play_dialogue(step)
		"caption":
			_overlay.set_caption(str(step.get("text", "")))
		"cut_in":
			_play_cut_in(step)
		"sfx":
			_play_sfx(str(step.get("id", "")))
		"shake":
			_play_shake(float(step.get("strength", 2.0)), float(step.get("duration", 0.18)))
		"fade":
			await _overlay.fade_to(float(step.get("alpha", 1.0)), float(step.get("duration", 0.2)))
		"wait":
			await get_tree().create_timer(maxf(float(step.get("seconds", 0.1)), 0.01), true, false, true).timeout
		"wait_input":
			await advance_requested
		"set_flag":
			_set_flag(str(step.get("flag", "")), bool(step.get("value", true)))
		"set_objective":
			_set_objective(str(step.get("text", "")))
		"collect_clue":
			_collect_clue(str(step.get("id", "")))
		"unlock_gear":
			_unlock_gear(str(step.get("id", "")))
		"add_item":
			_add_item(str(step.get("id", "")), int(step.get("amount", 1)))
		"set_growth_stage":
			_set_growth_stage(int(step.get("stage", 1)))
		"set_visible":
			_set_target_visible(str(step.get("target", "")), bool(step.get("visible", true)))
		"set_property":
			_set_target_property(step)
		"start_battle":
			_start_battle(step)
		"change_scene":
			_change_scene(str(step.get("path", "")))


func _move_actor(step: Dictionary) -> void:
	var target := _find_target(str(step.get("target", ""))) as Node2D
	if target == null:
		return
	var destination := _to_vector2(step.get("position", [target.position.x, target.position.y]), target.position)
	var duration := maxf(float(step.get("duration", 0.2)), 0.01)
	_active_tween = create_tween()
	_active_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_active_tween.tween_property(target, "position", destination, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _active_tween.finished


func _camera_pan(step: Dictionary) -> void:
	var camera := _find_camera(str(step.get("target", "")))
	if camera == null:
		return
	var destination := _to_vector2(step.get("offset", step.get("position", [0, 0])), camera.offset)
	var duration := maxf(float(step.get("duration", 0.35)), 0.01)
	_active_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_active_tween.tween_property(camera, "offset", destination, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _active_tween.finished


func _camera_zoom(step: Dictionary) -> void:
	var camera := _find_camera(str(step.get("target", "")))
	if camera == null:
		return
	var destination := _to_vector2(step.get("zoom", [1, 1]), camera.zoom)
	var duration := maxf(float(step.get("duration", 0.35)), 0.01)
	_active_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_active_tween.tween_property(camera, "zoom", destination, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _active_tween.finished


func _play_actor_animation(step: Dictionary) -> void:
	var target := _find_target(str(step.get("target", "")))
	if target == null:
		return
	var animation_name := str(step.get("animation", "idle_down"))
	var fps := float(step.get("fps", 10.0))
	if target.has_method("play_action"):
		target.call("play_action", animation_name, fps)
	elif target is AnimatedSprite2D:
		(target as AnimatedSprite2D).play(animation_name)
	var duration := float(step.get("duration", 0.0))
	if duration > 0.0:
		await get_tree().create_timer(duration, true, false, true).timeout


func _face_actor(step: Dictionary) -> void:
	var target := _find_target(str(step.get("target", "")))
	if target == null:
		return
	var direction := str(step.get("direction", "down"))
	if "facing_direction" in target:
		target.set("facing_direction", direction)
	if target.has_method("apply_growth_visual"):
		target.call("apply_growth_visual")


func _spawn_actor(step: Dictionary) -> void:
	var path := str(step.get("scene", step.get("texture", "")))
	if path.is_empty():
		return
	var parent := _find_target(str(step.get("parent", "")))
	if parent == null:
		parent = _context_root
	if parent == null:
		return
	var actor: Node
	var resource := load(path)
	if resource is PackedScene:
		actor = (resource as PackedScene).instantiate()
	elif resource is Texture2D:
		var sprite := Sprite2D.new()
		sprite.texture = resource as Texture2D
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		actor = sprite
	if actor == null:
		return
	actor.name = str(step.get("name", "CutsceneActor"))
	parent.add_child(actor)
	if actor is Node2D:
		(actor as Node2D).position = _to_vector2(step.get("position", [0, 0]), Vector2.ZERO)


func _despawn_actor(target_path: String) -> void:
	var target := _find_target(target_path)
	if target != null:
		target.queue_free()


func _set_music_state(step: Dictionary) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager == null:
		return
	var music_id := str(step.get("id", ""))
	if music_id.is_empty() or bool(step.get("stop", false)):
		audio_manager.stop_music()
	else:
		audio_manager.play_music(music_id, float(step.get("fade_seconds", 0.45)))


func _wait_for_signal(step: Dictionary) -> void:
	var target := _find_target(str(step.get("target", "")))
	var signal_name := str(step.get("signal", ""))
	if target != null and not signal_name.is_empty() and target.has_signal(signal_name):
		await Signal(target, signal_name)
		return
	await get_tree().create_timer(maxf(float(step.get("timeout", 0.1)), 0.01), true, false, true).timeout


func _play_dialogue(step: Dictionary) -> void:
	var manager := get_node_or_null("/root/DialogueManager")
	if manager == null:
		return
	var lines: Array = step.get("lines", [])
	if not manager.start_inline_dialogue(str(step.get("speaker", "")), lines, str(step.get("flag", ""))):
		return
	await manager.dialogue_finished


func _play_cut_in(step: Dictionary) -> void:
	var cut_in := _overlay.get_node_or_null("CutInPlayer")
	if cut_in != null and cut_in.has_method("play_cut_in"):
		cut_in.play_cut_in(str(step.get("id", "")), str(step.get("title", "")))


func _play_sfx(audio_id: String) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and not audio_id.is_empty():
		audio_manager.play_sfx(audio_id)


func _play_shake(strength: float, duration: float) -> void:
	var shake := _find_named_node(_context_root, "ScreenShake")
	if shake != null and shake.has_method("play"):
		shake.play(strength, duration)


func _set_player_locked(locked: bool) -> void:
	var player := _find_target("World/Player")
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	player.set_physics_process(not locked)
	player.set_process_unhandled_input(not locked)
	if locked and not _locked_players.has(player):
		_locked_players.append(player)
	elif not locked:
		_locked_players.erase(player)


func _set_flag(flag_name: String, value: bool = true) -> void:
	if flag_name.is_empty():
		return
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.set_flag(flag_name, value)


func _set_objective(text: String) -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.set_current_objective(text)


func _collect_clue(clue_id: String) -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and not clue_id.is_empty() and game_state.has_method("collect_clue"):
		game_state.collect_clue(clue_id)


func _unlock_gear(gear_id: String) -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and not gear_id.is_empty() and game_state.has_method("unlock_gear"):
		game_state.unlock_gear(gear_id)


func _add_item(item_id: String, amount: int) -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and not item_id.is_empty() and game_state.has_method("add_item"):
		game_state.add_item(item_id, maxi(1, amount))


func _set_growth_stage(stage: int) -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and game_state.has_method("set_growth_stage"):
		game_state.set_growth_stage(stage)


func _set_target_visible(path: String, visible: bool) -> void:
	var target := _find_target(path) as CanvasItem
	if target != null:
		target.visible = visible


func _set_target_property(step: Dictionary) -> void:
	var target := _find_target(str(step.get("target", "")))
	var property_name := str(step.get("property", ""))
	if target == null or property_name.is_empty():
		return
	var value = step.get("value")
	if property_name == "position" or property_name == "scale":
		value = _to_vector2(value, target.get(property_name))
	target.set(property_name, value)


func _start_battle(step: Dictionary) -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.pending_encounter_id = str(step.get("encounter_id", ""))
	_change_scene(str(step.get("scene", "res://scenes/battle/battle_scene.tscn")))


func _change_scene(path: String) -> void:
	if not path.is_empty():
		get_tree().change_scene_to_file(path)


func _apply_skip_state(steps: Array) -> void:
	for raw_step in steps:
		if typeof(raw_step) != TYPE_DICTIONARY:
			continue
		var step: Dictionary = raw_step
		match str(step.get("type", "")):
			"move_actor", "camera_to":
				var target := _find_target(str(step.get("target", ""))) as Node2D
				if target != null:
					target.position = _to_vector2(step.get("position", []), target.position)
			"camera_pan":
				var camera := _find_camera(str(step.get("target", "")))
				if camera != null:
					camera.offset = _to_vector2(step.get("offset", step.get("position", [0, 0])), camera.offset)
			"camera_zoom":
				var camera := _find_camera(str(step.get("target", "")))
				if camera != null:
					camera.zoom = _to_vector2(step.get("zoom", [1, 1]), camera.zoom)
			"face_actor":
				_face_actor(step)
			"spawn_actor":
				_spawn_actor(step)
			"despawn_actor":
				_despawn_actor(str(step.get("target", "")))
			"music_state":
				_set_music_state(step)
			"checkpoint":
				_set_flag(str(step.get("flag", "%s_checkpoint" % active_cutscene_id)), true)
			"set_visible":
				_set_target_visible(str(step.get("target", "")), bool(step.get("visible", true)))
			"set_property":
				_set_target_property(step)
			"set_flag":
				_set_flag(str(step.get("flag", "")), bool(step.get("value", true)))
			"set_objective":
				_set_objective(str(step.get("text", "")))
			"collect_clue":
				_collect_clue(str(step.get("id", "")))
			"unlock_gear":
				_unlock_gear(str(step.get("id", "")))
			"add_item":
				_add_item(str(step.get("id", "")), int(step.get("amount", 1)))
			"set_growth_stage":
				_set_growth_stage(int(step.get("stage", 1)))
			"start_battle":
				_start_battle(step)
			"change_scene":
				_change_scene(str(step.get("path", "")))


func _apply_completion_state(data: Dictionary) -> void:
	_set_flag(str(data.get("completion_flag", "")), true)
	var completion_flags = data.get("completion_flags", {})
	if typeof(completion_flags) == TYPE_DICTIONARY:
		for flag_name in completion_flags.keys():
			_set_flag(str(flag_name), bool(completion_flags[flag_name]))


func _finish_cutscene(skipped: bool) -> void:
	for player in _locked_players.duplicate():
		if is_instance_valid(player):
			player.set_physics_process(true)
			player.set_process_unhandled_input(true)
	_locked_players.clear()
	if _overlay != null:
		_overlay.hide_frame()
	var completed_id := active_cutscene_id
	active_cutscene_id = ""
	_current_data = {}
	_context_root = null
	is_playing = false
	cutscene_completed.emit(completed_id, skipped)


func _ensure_overlay() -> void:
	if _overlay != null and is_instance_valid(_overlay):
		return
	_overlay = LETTERBOX_SCENE.instantiate()
	_overlay.name = "CutsceneOverlay"
	_overlay.scale = Vector2(2.0, 2.0)
	get_tree().root.add_child(_overlay)


func _find_target(path: String) -> Node:
	if path.is_empty():
		return null
	if path.begins_with("/root/"):
		return get_node_or_null(path)
	if _context_root != null:
		var local := _context_root.get_node_or_null(path)
		if local != null:
			return local
	return get_tree().root.get_node_or_null(path)


func _find_named_node(node: Node, target_name: String) -> Node:
	if node == null:
		return null
	if node.name == target_name:
		return node
	for child in node.get_children():
		var match_node := _find_named_node(child, target_name)
		if match_node != null:
			return match_node
	return null


func _find_camera(path: String = "") -> Camera2D:
	if not path.is_empty():
		var explicit := _find_target(path) as Camera2D
		if explicit != null:
			return explicit
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		var camera := player.get_node_or_null("Camera2D") as Camera2D
		if camera != null:
			return camera
	return get_viewport().get_camera_2d()


func _to_vector2(value, fallback: Vector2) -> Vector2:
	if typeof(value) == TYPE_ARRAY and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return fallback


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data
