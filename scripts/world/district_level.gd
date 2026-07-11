class_name DistrictLevel
extends Node2D

const RuntimeResourceManifest := preload("res://scripts/core/runtime_resource_manifest.gd")

signal room_change_started(from_room_id: String, to_room_id: String)
signal room_changed(room_id: String, spawn_id: String)
signal route_reminder_requested(objective_text: String)

@export var level_id := "level_01"
@export var start_room_id := "arrival"
@export_file("*.tscn") var room_scene_paths: PackedStringArray = []
@export var idle_reminder_seconds := 25.0
@export_file("*.json") var story_flow_path := ""
@export var intro_cutscene_id := ""

var current_room: WorldRoom
var current_room_id := ""
var _room_paths: Dictionary = {}
var _transitioning := false
var _idle_seconds := 0.0
var _reminder_sent := false
var runtime_diagnostics: Dictionary = {}

@onready var room_container: Node2D = get_node_or_null("RoomContainer") as Node2D
@onready var player: CharacterBody2D = get_node_or_null("Player") as CharacterBody2D


func _ready() -> void:
	_index_rooms()
	_record_diagnostic("indexed_rooms", _room_paths.size())
	var game_state := get_node_or_null("/root/GameState")
	var initial_room := start_room_id
	var initial_spawn := "start"
	if game_state != null:
		if game_state.current_level_id == level_id and not str(game_state.current_room_id).is_empty():
			initial_room = str(game_state.current_room_id)
			initial_spawn = str(game_state.spawn_point)
		game_state.current_level_id = level_id
	if not _room_paths.has(initial_room):
		initial_room = start_room_id
	var switched := switch_room(initial_room, initial_spawn, false)
	_record_diagnostic("initial_room", initial_room)
	_record_diagnostic("switch_succeeded", switched)
	_record_diagnostic("current_room", current_room_id)
	call_deferred("_run_pending_story_flow")


func begin_level_intro() -> void:
	if intro_cutscene_id.is_empty():
		return
	var director := get_node_or_null("/root/CutsceneDirector")
	if director != null and not director.is_playing:
		director.play(intro_cutscene_id, self)


func _process(delta: float) -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or not game_state.is_story_difficulty():
		_idle_seconds = 0.0
		_reminder_sent = false
		return
	if player != null and (not player.velocity.is_zero_approx() or Input.is_action_pressed("interact")):
		_idle_seconds = 0.0
		_reminder_sent = false
		return
	_idle_seconds += delta
	if not _reminder_sent and _idle_seconds >= idle_reminder_seconds:
		_reminder_sent = true
		route_reminder_requested.emit(str(game_state.get_current_objective()))


func request_room_change(target_room_id: String, target_spawn_id: String = "default") -> bool:
	if _transitioning:
		return false
	return switch_room(target_room_id, target_spawn_id, true)


func switch_room(target_room_id: String, target_spawn_id: String = "default", save_after_transition: bool = true) -> bool:
	if target_room_id.is_empty() or not _room_paths.has(target_room_id):
		return false
	_transitioning = true
	var previous_id := current_room_id
	room_change_started.emit(previous_id, target_room_id)
	if current_room != null:
		room_container.remove_child(current_room)
		current_room.queue_free()
	var room_source = _room_paths[target_room_id]
	var packed := room_source as PackedScene if room_source is PackedScene else load(str(room_source)) as PackedScene
	if packed == null:
		_transitioning = false
		return false
	current_room = packed.instantiate() as WorldRoom
	if current_room == null:
		_transitioning = false
		return false
	room_container.add_child(current_room)
	current_room_id = target_room_id
	current_room.configure_player_camera(player)
	if player != null:
		player.global_position = current_room.get_spawn_position(target_spawn_id)
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.current_level_id = level_id
		game_state.current_room_id = current_room_id
		game_state.spawn_point = target_spawn_id
	if save_after_transition:
		var save_system := get_node_or_null("/root/SaveSystem")
		if save_system != null:
			save_system.save_game(level_id, target_spawn_id, current_room_id)
	_transitioning = false
	room_changed.emit(current_room_id, target_spawn_id)
	call_deferred("_run_pending_story_flow")
	return true


func get_current_room_id() -> String:
	return current_room_id


func collect_objective(_flag_name: String = "") -> void:
	call_deferred("_run_pending_story_flow")


func complete_objective() -> void:
	call_deferred("_run_pending_story_flow")


func _index_rooms() -> void:
	_room_paths.clear()
	for packed in RuntimeResourceManifest.get_room_scenes(level_id):
		_index_packed_room(packed)
	for path in room_scene_paths:
		var packed := load(str(path)) as PackedScene
		_index_packed_room(packed)


func _index_packed_room(packed: PackedScene) -> void:
	if packed == null:
		return
	var instance := packed.instantiate() as WorldRoom
	if instance == null:
		return
	_room_paths[instance.room_id] = packed
	instance.free()


func _record_diagnostic(key: String, value) -> void:
	runtime_diagnostics[key] = value
	if not OS.has_feature("web"):
		return
	var payload := JSON.stringify(runtime_diagnostics)
	JavaScriptBridge.eval("window.__shrugameDiagnostics = %s" % payload, true)


func _run_pending_story_flow() -> void:
	if story_flow_path.is_empty() or not FileAccess.file_exists(story_flow_path):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(story_flow_path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var game_state := get_node_or_null("/root/GameState")
	var director := get_node_or_null("/root/CutsceneDirector")
	if game_state == null or director == null or director.is_playing:
		return
	for rule_value in parsed.get("completion_rules", []):
		if typeof(rule_value) != TYPE_DICTIONARY:
			continue
		var rule: Dictionary = rule_value
		var requirements_met := true
		for required_flag in rule.get("requires", []):
			if not game_state.get_flag(str(required_flag)):
				requirements_met = false
				break
		if requirements_met:
			game_state.set_flag(str(rule.get("set_flag", "")), true)
	for entry_value in parsed.get("post_battle_cutscenes", []):
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_value
		var flag := str(entry.get("flag", ""))
		var unless_flag := str(entry.get("unless_flag", ""))
		if not flag.is_empty() and game_state.get_flag(flag) and (unless_flag.is_empty() or not game_state.get_flag(unless_flag)):
			director.play(str(entry.get("cutscene_id", "")), self)
			return
