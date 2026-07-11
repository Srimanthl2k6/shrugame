extends Node2D

const CLEAR_FLAGS := ["berry_contract_collected", "niggesh_nishal_defeated", "berries_shared", "ankit_defeated"]
const LEGACY_CLEAR_FLAGS := ["level_03_objective_done", "tickroot_practice_cleared"]
const BERRY_CLUSTER_FLAGS := ["berry_cluster_01", "berry_cluster_02", "berry_cluster_03", "berry_cluster_04"]
const ROUTE_SUMMARY := [
	"1. Collect the 1000 berries as clusters.",
	"2. Read the berry contract.",
	"3. Beat Nishal over the fake chicken promise.",
	"4. share berries with the town.",
	"5. Defeat Ankit near the forest route.",
	"6. Exit to Auticity."
]


func _ready() -> void:
	var game_state := _get_game_state()
	if game_state != null:
		var entering_level: bool = game_state.current_level_id != "level_03"
		game_state.current_level_id = "level_03"
		if entering_level or (game_state.has_method("get_current_objective") and game_state.get_current_objective().is_empty()):
			game_state.set_current_objective("Collect 1000 berries as clusters in Berry Barks.")
	_sync_progression_rewards()
	_apply_world_state()
	_refresh_exit_hint()
	var director := get_node_or_null("/root/CutsceneDirector")
	if director != null and not director.cutscene_completed.is_connected(_on_cutscene_completed):
		director.cutscene_completed.connect(_on_cutscene_completed)
	_play_pending_return_cutscene.call_deferred()


func complete_objective() -> void:
	var game_state := _get_game_state()
	if game_state == null:
		return
	game_state.set_flag("level_03_objective_done", true)
	_refresh_exit_hint()


func collect_objective(flag_name: String = "") -> void:
	var game_state := _get_game_state()
	if game_state == null:
		return
	if not flag_name.is_empty():
		game_state.set_flag(flag_name, true)
	if BERRY_CLUSTER_FLAGS.has(flag_name):
		var collected := _get_collected_cluster_count(game_state)
		if collected >= BERRY_CLUSTER_FLAGS.size():
			game_state.set_flag("berries_collected", true)
			game_state.set_current_objective("Berry order complete. Read the contract and confront Nishal.")
		else:
			game_state.set_current_objective("Berry order: %d / 1000." % (collected * 250))
	if flag_name == "berries_shared":
		complete_objective()
	_sync_progression_rewards()
	_apply_world_state()
	_refresh_exit_hint()


func can_clear_level() -> bool:
	var game_state := _get_game_state()
	if game_state == null:
		return false
	if _has_flags(game_state, LEGACY_CLEAR_FLAGS):
		return true
	return _has_flags(game_state, CLEAR_FLAGS)


func get_level03_route_summary() -> Array[String]:
	return ROUTE_SUMMARY.duplicate()


func _sync_progression_rewards() -> void:
	var game_state := _get_game_state()
	if game_state == null:
		return
	if game_state.get_flag("berries_shared") and game_state.has_method("unlock_gear"):
		game_state.unlock_gear("berry_potions")
	if game_state.get_flag("ankit_defeated"):
		if game_state.has_method("set_growth_stage"):
			game_state.set_growth_stage(4)
		game_state.set_flag("level_03_objective_done", true)
		game_state.set_flag("tickroot_practice_cleared", true)
		if game_state.has_method("set_current_objective"):
			game_state.set_current_objective("Berry Barks is fed. Leave for Auticity.")


func _get_collected_cluster_count(game_state: Node) -> int:
	var count := 0
	if game_state == null:
		return count
	for flag_name in BERRY_CLUSTER_FLAGS:
		if game_state.get_flag(flag_name):
			count += 1
	return count


func _apply_world_state() -> void:
	var game_state := _get_game_state()
	if game_state == null:
		return
	var nishal := get_node_or_null("World/ChefNishal") as Area2D
	if nishal != null:
		var nishal_active: bool = not game_state.get_flag("niggesh_nishal_defeated")
		nishal.visible = nishal_active
		nishal.monitoring = nishal_active
		nishal.monitorable = nishal_active
	var share := get_node_or_null("World/BerryShare") as Area2D
	if share != null:
		var share_active: bool = game_state.get_flag("niggesh_nishal_defeated") and not game_state.get_flag("berries_shared")
		share.visible = share_active
		share.monitoring = share_active
		share.monitorable = share_active
	var ankit := get_node_or_null("World/AnkitBoss") as Area2D
	if ankit != null:
		var ankit_active: bool = game_state.get_flag("berries_shared") and not game_state.get_flag("ankit_defeated")
		ankit.visible = ankit_active
		ankit.monitoring = ankit_active
		ankit.monitorable = ankit_active


func _play_pending_return_cutscene() -> void:
	var game_state := _get_game_state()
	var director := get_node_or_null("/root/CutsceneDirector")
	if game_state == null or director == null or director.is_playing:
		return
	if game_state.get_flag("ankit_defeated") and not game_state.get_flag("ankit_defeat_seen"):
		director.play("ankit_aftermath", self)
		return
	if game_state.get_flag("niggesh_nishal_defeated") and not game_state.get_flag("nishal_defeat_seen"):
		director.play("nishal_aftermath", self)


func _on_cutscene_completed(cutscene_id: String, _skipped: bool) -> void:
	if cutscene_id in ["nishal_aftermath", "berry_sharing", "ankit_confrontation", "ankit_aftermath"]:
		_sync_progression_rewards()
		_apply_world_state()
		_refresh_exit_hint()


func _has_flags(game_state: Node, flag_names: Array) -> bool:
	for flag_name in flag_names:
		if not game_state.get_flag(flag_name):
			return false
	return true


func _refresh_exit_hint() -> void:
	var exit_door := get_node_or_null("World/TransitionDoor")
	if exit_door == null:
		return
	if can_clear_level():
		exit_door.interaction_message = "Berry Barks is fed. Auticity waits past the mist."
	else:
		exit_door.locked_message = "Berry Barks is not free yet: collect the contract, beat Nishal, share berries, and defeat Ankit."


func _get_game_state() -> Node:
	if is_inside_tree():
		return get_tree().root.get_node_or_null("GameState")
	return null
