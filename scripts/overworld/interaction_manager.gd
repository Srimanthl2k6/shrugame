extends Node

const CLOSE_TIE_DISTANCE := 6.0

var _candidates: Dictionary = {}
var _focused_interaction: InteractionArea
var _focused_player: Node2D
var _last_activated_name := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var input_manager := get_node_or_null("/root/InputManager")
	if input_manager != null:
		if input_manager.has_signal("input_device_changed"):
			input_manager.input_device_changed.connect(_on_prompt_source_changed)
		if input_manager.has_signal("bindings_changed"):
			input_manager.bindings_changed.connect(_on_prompt_source_changed)


func _process(_delta: float) -> void:
	_refresh_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or event.is_echo():
		return
	_refresh_focus()
	if _focused_interaction == null or not _can_target(_focused_player):
		return
	if _focused_interaction.try_activate():
		_last_activated_name = str(_focused_interaction.name)
		_publish_web_diagnostics(_focused_interaction, _focused_player)
		get_viewport().set_input_as_handled()
		_refresh_focus()


func register_candidate(area: InteractionArea, player: Node2D) -> void:
	if area == null or player == null:
		return
	_candidates[area.get_instance_id()] = {"area": area, "player": player}
	_refresh_focus()


func unregister_candidate(area: InteractionArea) -> void:
	if area == null:
		return
	_candidates.erase(area.get_instance_id())
	if _focused_interaction == area:
		_set_focused(null, null)


func get_focused_interaction() -> InteractionArea:
	return _focused_interaction


func _refresh_focus() -> void:
	var active_player := get_tree().get_first_node_in_group("player") as Node2D
	var nearby_names: Array[String] = []
	if active_player != null:
		for node in get_tree().get_nodes_in_group("interaction_targets"):
			var discovered_area := node as InteractionArea
			if discovered_area != null and discovered_area.is_player_candidate(active_player):
				nearby_names.append(str(discovered_area.name))
				_candidates[discovered_area.get_instance_id()] = {"area": discovered_area, "player": active_player}
	var best_area: InteractionArea
	var best_player: Node2D
	var best_distance := INF
	var best_alignment := -2.0
	var best_priority := -2147483648
	var best_path := ""
	var stale_ids: Array = []
	for candidate_id in _candidates:
		var entry: Dictionary = _candidates[candidate_id]
		var area := entry.get("area") as InteractionArea
		var player := entry.get("player") as Node2D
		if not is_instance_valid(area) or not is_instance_valid(player):
			stale_ids.append(candidate_id)
			continue
		if not area.is_player_candidate(player) or not _can_target(player):
			continue
		var distance := _distance_to_authored_boundary(area, player)
		var alignment := _facing_alignment(area, player)
		var priority := int(area.focus_priority)
		var stable_path := str(area.get_path())
		var wins := best_area == null or distance < best_distance - CLOSE_TIE_DISTANCE
		if not wins and absf(distance - best_distance) <= CLOSE_TIE_DISTANCE:
			wins = alignment > best_alignment + 0.01
			if is_equal_approx(alignment, best_alignment):
				wins = priority > best_priority or (priority == best_priority and stable_path < best_path)
		if wins:
			best_area = area
			best_player = player
			best_distance = distance
			best_alignment = alignment
			best_priority = priority
			best_path = stable_path
	for candidate_id in stale_ids:
		_candidates.erase(candidate_id)
	_set_focused(best_area, best_player)
	_publish_web_diagnostics(_focused_interaction, active_player, nearby_names)


func _set_focused(area: InteractionArea, player: Node2D) -> void:
	if _focused_interaction == area and _focused_player == player:
		if area != null:
			area.refresh_focus_prompt()
		return
	if is_instance_valid(_focused_interaction):
		_focused_interaction.set_focused(false)
	_focused_interaction = area
	_focused_player = player
	if is_instance_valid(_focused_interaction):
		_focused_interaction.set_focused(true)
	_publish_web_diagnostics(_focused_interaction, _focused_player)


func _can_target(player: Node2D) -> bool:
	if player == null or get_tree() == null or get_tree().paused:
		return false
	var dialogue_manager := get_node_or_null("/root/DialogueManager")
	if dialogue_manager != null and dialogue_manager.has_method("is_active") and dialogue_manager.is_active():
		return false
	var director := get_node_or_null("/root/CutsceneDirector")
	if director != null and bool(director.is_playing):
		return false
	if "movement_locked" in player and bool(player.get("movement_locked")):
		return false
	if not player.is_physics_processing():
		return false
	var district := player.get_parent() as DistrictLevel
	if district != null and bool(district.get("_transitioning")):
		return false
	return true


func _distance_to_authored_boundary(area: InteractionArea, player: Node2D) -> float:
	var delta := area.global_position - player.global_position
	var half_size := area.interaction_size * 0.5
	var outside := Vector2(
		maxf(absf(delta.x) - half_size.x, 0.0),
		maxf(absf(delta.y) - half_size.y, 0.0)
	)
	return outside.length()


func _facing_alignment(area: InteractionArea, player: Node2D) -> float:
	var direction := area.global_position - player.global_position
	if direction.is_zero_approx():
		return 1.0
	var facing := Vector2.DOWN
	if "facing_direction" in player:
		match str(player.get("facing_direction")):
			"left": facing = Vector2.LEFT
			"right": facing = Vector2.RIGHT
			"up": facing = Vector2.UP
			_: facing = Vector2.DOWN
	return facing.dot(direction.normalized())


func _on_prompt_source_changed(_value = null) -> void:
	if is_instance_valid(_focused_interaction):
		_focused_interaction.refresh_focus_prompt()


func _publish_web_diagnostics(area: InteractionArea, player: Node2D, nearby: Array[String] = []) -> void:
	if not OS.has_feature("web"):
		return
	var payload := {
		"focused": str(area.name) if is_instance_valid(area) else "",
		"last_activated": _last_activated_name,
		"nearby": nearby,
		"suppressed": _suppression_reason(player),
		"player_x": snappedf(player.global_position.x, 0.1) if is_instance_valid(player) else -1.0,
		"player_y": snappedf(player.global_position.y, 0.1) if is_instance_valid(player) else -1.0
	}
	JavaScriptBridge.eval("window.__shrugameInteractionDiagnostics = %s" % JSON.stringify(payload), true)


func _suppression_reason(player: Node2D) -> String:
	if player == null:
		return "no_player"
	if get_tree().paused:
		return "paused"
	var dialogue_manager := get_node_or_null("/root/DialogueManager")
	if dialogue_manager != null and dialogue_manager.has_method("is_active") and dialogue_manager.is_active():
		return "dialogue"
	var director := get_node_or_null("/root/CutsceneDirector")
	if director != null and bool(director.is_playing):
		return "cutscene"
	if "movement_locked" in player and bool(player.get("movement_locked")):
		return "movement_locked"
	if not player.is_physics_processing():
		return "physics_disabled"
	return ""
