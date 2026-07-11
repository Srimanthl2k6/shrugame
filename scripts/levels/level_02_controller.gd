extends Node2D

const CLEAR_FLAGS := ["165_files_collected", "nitin_defeated", "monkeys_spell_broken", "deepak_reddy_defeated"]
const LEGACY_CLEAR_FLAGS := ["level_02_objective_done", "vela_practice_cleared"]
const ROUTE_SUMMARY := [
	"1. Talk to the too-happy monkeys.",
	"2. Collect the 165-files in the lab.",
	"3. Beat Nitin before he hides the files.",
	"4. Share the KFC popcorn with the monkeys.",
	"5. Defeat Deepak Reddy at the mayor office.",
	"6. Exit to Berry Barks."
]
const MONKEY_SPRITES := ["HappyMonkeyLoop", "HappyMonkeyResident02", "HappyMonkeyResident03", "HappyMonkeyResident04"]


func _ready() -> void:
	var game_state := _get_game_state()
	if game_state != null:
		var entering_level: bool = game_state.current_level_id != "level_02"
		game_state.current_level_id = "level_02"
		if entering_level or (game_state.has_method("get_current_objective") and game_state.get_current_objective().is_empty()):
			game_state.set_current_objective("Investigate why Banana-burbs is too happy.")
	_sync_progression_rewards()
	_apply_population_state()
	_refresh_exit_hint()
	var director := get_node_or_null("/root/CutsceneDirector")
	if director != null and not director.cutscene_completed.is_connected(_on_cutscene_completed):
		director.cutscene_completed.connect(_on_cutscene_completed)
	_play_pending_return_cutscene.call_deferred()


func complete_objective() -> void:
	var game_state := _get_game_state()
	if game_state == null:
		return
	game_state.set_flag("level_02_objective_done", true)
	_refresh_exit_hint()


func collect_objective(flag_name: String = "") -> void:
	var game_state := _get_game_state()
	if game_state != null and not flag_name.is_empty():
		game_state.set_flag(flag_name, true)
	if flag_name == "monkeys_spell_broken":
		complete_objective()
	_sync_progression_rewards()
	_apply_population_state()
	_refresh_exit_hint()


func can_clear_level() -> bool:
	var game_state := _get_game_state()
	if game_state == null:
		return false
	if _has_flags(game_state, LEGACY_CLEAR_FLAGS):
		return true
	return _has_flags(game_state, CLEAR_FLAGS)


func get_level02_route_summary() -> Array[String]:
	return ROUTE_SUMMARY.duplicate()


func _has_flags(game_state: Node, flag_names: Array) -> bool:
	for flag_name in flag_names:
		if not game_state.get_flag(flag_name):
			return false
	return true


func _sync_progression_rewards() -> void:
	var game_state := _get_game_state()
	if game_state == null:
		return
	if game_state.get_flag("monkeys_spell_broken") and game_state.has_method("unlock_gear"):
		game_state.unlock_gear("banana_gun")
	if game_state.get_flag("deepak_reddy_defeated"):
		if game_state.has_method("set_growth_stage"):
			game_state.set_growth_stage(3)
		game_state.set_flag("level_02_objective_done", true)
		game_state.set_flag("vela_practice_cleared", true)
		if game_state.has_method("set_current_objective"):
			game_state.set_current_objective("Banana-burbs is awake. Leave for Berry Barks.")


func _apply_population_state() -> void:
	var game_state := _get_game_state()
	if game_state == null:
		return
	var awake: bool = bool(game_state.get_flag("monkeys_spell_broken"))
	for node_name in MONKEY_SPRITES:
		var monkey := get_node_or_null("World/%s" % node_name) as CanvasItem
		if monkey != null:
			monkey.modulate = Color(0.9, 1.0, 0.9) if awake else Color(1.0, 0.94, 0.72)


func _play_pending_return_cutscene() -> void:
	var game_state := _get_game_state()
	var director := get_node_or_null("/root/CutsceneDirector")
	if game_state == null or director == null or director.is_playing:
		return
	if game_state.get_flag("deepak_reddy_defeated") and not game_state.get_flag("deepak_truth_heard"):
		director.play("deepak_moral_twist", self)


func _on_cutscene_completed(cutscene_id: String, _skipped: bool) -> void:
	if cutscene_id in ["banana_lab_discovery", "popcorn_spell_break", "deepak_moral_twist"]:
		_sync_progression_rewards()
		_apply_population_state()
		_refresh_exit_hint()


func _refresh_exit_hint() -> void:
	var exit_door := get_node_or_null("World/TransitionDoor")
	if exit_door == null:
		return
	if can_clear_level():
		exit_door.interaction_message = "Banana-burbs is awake. Berry Barks waits beyond the trees."
	else:
		exit_door.locked_message = "Banana-burbs is not free yet: get the 165-files, beat Nitin, share the KFC popcorn, and defeat Deepak."


func _get_game_state() -> Node:
	if is_inside_tree():
		return get_tree().root.get_node_or_null("GameState")
	return null
