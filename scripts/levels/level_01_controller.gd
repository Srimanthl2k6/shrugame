extends Node2D

const CLEAR_FLAGS := ["poojan_defeated", "divorce_records_collected", "satyaki_tirumal_defeated"]
const TAG_FLAGS := ["tag_flour", "tag_cups", "tag_broom"]
const LEGACY_CLEAR_FLAGS := ["met_marn", "marn_practice_cleared", "pantry_tags_sorted"]
const ROUTE_SUMMARY := [
	"1. Slam the fake KFC door.",
	"2. Beat Sheriff Poojan.",
	"3. Collect the divorce records.",
	"4. Confront Satyaki Tirumal.",
	"5. Exit to Banana-burbs."
]
const OPTIONAL_RESIDENTS := ["LanternWoman", "BoathouseWoman", "RaincoatWoman", "RadioWoman", "DockWoman"]


func _ready() -> void:
	var game_state := _get_game_state()
	if game_state != null:
		game_state.current_level_id = "level_01"
		if game_state.has_method("get_current_objective") and game_state.get_current_objective().is_empty():
			game_state.set_current_objective("Find KFC in Divorcee Harbour.")
	_sync_progression_rewards()
	_apply_world_state()
	_apply_population_state()
	_refresh_exit_hint()
	var director := get_node_or_null("/root/CutsceneDirector")
	if director != null and not director.cutscene_completed.is_connected(_on_cutscene_completed):
		director.cutscene_completed.connect(_on_cutscene_completed)
	_play_pending_return_cutscene.call_deferred()
	if get_parent() == null or get_parent().name != "Main":
		begin_level_intro.call_deferred()


func begin_level_intro() -> void:
	var game_state := _get_game_state()
	if game_state == null or game_state.get_flag("level_01_opening_complete"):
		return
	var director := get_node_or_null("/root/CutsceneDirector")
	if director != null and not director.is_playing:
		director.play("opening_arrival", self)


func collect_objective(_flag_name: String = "") -> void:
	_sync_progression_rewards()
	_refresh_exit_hint()


func collect_tag(flag_name: String) -> void:
	var game_state := _get_game_state()
	if game_state == null or not TAG_FLAGS.has(flag_name):
		return
	game_state.set_flag(flag_name, true)
	if get_collected_tag_count() >= TAG_FLAGS.size():
		game_state.set_flag("pantry_tags_sorted", true)
	_refresh_exit_hint()


func get_collected_tag_count() -> int:
	var game_state := _get_game_state()
	if game_state == null:
		return 0
	var count := 0
	for flag_name in TAG_FLAGS:
		if game_state.get_flag(flag_name):
			count += 1
	return count


func can_clear_level() -> bool:
	var game_state := _get_game_state()
	if game_state == null:
		return false
	if _has_flags(game_state, LEGACY_CLEAR_FLAGS):
		return true
	return _has_flags(game_state, CLEAR_FLAGS)


func get_level01_route_summary() -> Array[String]:
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
	if game_state.get_flag("poojan_defeated") and game_state.has_method("unlock_gear"):
		game_state.unlock_gear("revolver")
	if game_state.get_flag("satyaki_tirumal_defeated") and game_state.has_method("set_growth_stage"):
		game_state.set_growth_stage(2)
		game_state.set_current_objective("Divorcee Harbour is free. Leave for Banana-burbs.")
		game_state.set_flag("met_marn", true)
		game_state.set_flag("marn_practice_cleared", true)
		game_state.set_flag("pantry_tags_sorted", true)


func _apply_world_state() -> void:
	var game_state := _get_game_state()
	var intact := get_node_or_null("World/SceneArt/HarbourBackplate") as CanvasItem
	var collapsed := get_node_or_null("World/SceneArt/CollapsedBackplate") as CanvasItem
	if intact == null or collapsed == null or game_state == null:
		return
	var building_is_broken: bool = bool(game_state.get_flag("building_broken")) or bool(game_state.get_flag("level_01_opening_complete"))
	intact.visible = not building_is_broken
	collapsed.visible = building_is_broken
	var satyaki := get_node_or_null("World/SatyakiBoss") as CanvasItem
	if satyaki != null:
		satyaki.visible = game_state.get_flag("satyaki_route_open") or game_state.get_flag("divorce_records_collected")


func _play_pending_return_cutscene() -> void:
	var game_state := _get_game_state()
	var director := get_node_or_null("/root/CutsceneDirector")
	if game_state == null or director == null or director.is_playing:
		return
	if game_state.get_flag("satyaki_tirumal_defeated") and not game_state.get_flag("satyaki_defeat_seen"):
		director.play("satyaki_aftermath", self)
		return
	if game_state.get_flag("poojan_defeated") and not game_state.get_flag("poojan_after_seen"):
		director.play("poojan_aftermath", self)


func _apply_population_state() -> void:
	var game_state := _get_game_state()
	if game_state == null:
		return
	var opening_complete: bool = bool(game_state.get_flag("level_01_opening_complete")) or bool(game_state.get_flag("building_broken"))
	for resident_name in OPTIONAL_RESIDENTS:
		var resident := get_node_or_null("World/%s" % resident_name) as Area2D
		if resident != null:
			resident.visible = opening_complete
			resident.monitoring = opening_complete
			resident.monitorable = opening_complete


func _on_cutscene_completed(cutscene_id: String, _skipped: bool) -> void:
	if cutscene_id in ["opening_arrival", "door_slam_collapse"]:
		_apply_population_state()


func _refresh_exit_hint() -> void:
	var exit_door := get_node_or_null("World/TransitionDoor")
	if exit_door == null:
		return
	if can_clear_level():
		exit_door.interaction_message = "Divorcee Harbour is free. Banana-burbs waits inland."
	else:
		exit_door.locked_message = "Divorcee Harbour is not free yet: beat Poojan, collect the divorce records, and defeat Satyaki."


func _get_game_state() -> Node:
	if is_inside_tree():
		return get_tree().root.get_node_or_null("GameState")
	return null
