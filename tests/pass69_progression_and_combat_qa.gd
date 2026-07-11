extends SceneTree

const CANONICAL_ENCOUNTERS := {
	"level_01": ["poojan_strength_test", "satyaki_tirumal_boss"],
	"level_02": ["nitin_janitor_boss", "deepak_reddy_boss"],
	"level_03": ["niggesh_nishal_boss", "ankit_boss"],
	"level_04": ["doctor_sushan_boss", "mitta_boss"],
	"level_05": ["suhas_bar_fight", "srmt_final_boss"]
}

var failures: Array[String] = []
var encounter_catalog: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_room_graphs_and_interactions()
	_test_encounter_fairness_contracts()
	await _test_all_bosses_on_both_difficulties()
	_test_complete_progression_state()
	_finish("Pass 69 progression, interaction, combat, and softlock QA")


func _test_room_graphs_and_interactions() -> void:
	for level_number in range(1, 6):
		var level_id := "level_%02d" % level_number
		var data := _load_json("res://data/rooms/%s_rooms.json" % level_id)
		var rooms: Dictionary = data.get("rooms", {})
		var start_room := str(data.get("start_room", ""))
		_assert(rooms.size() >= (7 if level_number == 5 else 5), "%s needs its full connected room count" % level_id)
		_assert(rooms.has(start_room), "%s start room is invalid" % level_id)
		var visited: Dictionary = {}
		var pending: Array[String] = [start_room]
		var interaction_count := 0
		var scene_targets: Array[String] = []
		while not pending.is_empty():
			var room_id: String = pending.pop_front()
			if visited.has(room_id) or not rooms.has(room_id):
				continue
			visited[room_id] = true
			var room: Dictionary = rooms[room_id]
			var background := str(room.get("background", ""))
			_assert(ResourceLoader.exists(background), "%s/%s background is missing" % [level_id, room_id])
			var interactions: Array = room.get("interactions", [])
			interaction_count += interactions.size()
			for interaction_value in interactions:
				if typeof(interaction_value) != TYPE_DICTIONARY:
					_assert(false, "%s/%s contains malformed interaction data" % [level_id, room_id])
					continue
				var interaction: Dictionary = interaction_value
				var visual := str(interaction.get("visual", ""))
				if not visual.is_empty():
					_assert(ResourceLoader.exists(visual), "%s interaction visual is missing" % interaction.get("id", "unknown"))
				var dialogue_id := str(interaction.get("dialogue_id", ""))
				if not dialogue_id.is_empty():
					var dialogue_path := str(interaction.get("dialogue_file_path", ""))
					var dialogue := _load_json(dialogue_path)
					_assert(dialogue.has(dialogue_id), "%s/%s points to missing dialogue %s" % [level_id, room_id, dialogue_id])
				var target_scene := str(interaction.get("target_scene_path", ""))
				if not target_scene.is_empty():
					_assert(ResourceLoader.exists(target_scene), "%s scene transition target is missing" % target_scene)
					scene_targets.append(target_scene)
			for exit_value in room.get("exits", []):
				var exit_data: Dictionary = exit_value
				var target_room := str(exit_data.get("target_room_id", ""))
				var target_spawn := str(exit_data.get("target_spawn_id", "default"))
				_assert(rooms.has(target_room), "%s/%s exit targets missing room %s" % [level_id, room_id, target_room])
				if rooms.has(target_room):
					var target_spawns: Dictionary = (rooms[target_room] as Dictionary).get("spawn_points", {})
					_assert(target_spawns.has(target_spawn), "%s/%s exit targets missing spawn %s/%s" % [level_id, room_id, target_room, target_spawn])
					if not visited.has(target_room):
						pending.append(target_room)
		_assert(visited.size() == rooms.size(), "%s room graph has unreachable rooms" % level_id)
		_assert(interaction_count >= (18 if level_number == 5 else 12), "%s needs enough authored interactions" % level_id)
		if level_number < 5:
			var expected_next := "res://scenes/levels/districts/level_%02d.tscn" % (level_number + 1)
			_assert(scene_targets.has(expected_next), "%s must expose the canonical next route %s" % [level_id, expected_next])
		else:
			var birthday := _load_json("res://data/cutscenes/birthday_card.json")
			var reaches_ending := false
			for step_value in birthday.get("steps", []):
				var step: Dictionary = step_value
				reaches_ending = reaches_ending or (str(step.get("type", "")) == "change_scene" and str(step.get("path", "")) == "res://scenes/ending.tscn")
			_assert(reaches_ending, "Area 111 finale must transition to the ending through the birthday card")


func _test_encounter_fairness_contracts() -> void:
	var required_count := 0
	for level_id in CANONICAL_ENCOUNTERS:
		var path := "res://data/encounters/%s_encounters.json" % level_id
		var entries := _load_json(path)
		for encounter_id in CANONICAL_ENCOUNTERS[level_id]:
			required_count += 1
			_assert(entries.has(encounter_id), "Missing canonical encounter %s" % encounter_id)
			if not entries.has(encounter_id):
				continue
			var encounter: Dictionary = entries[encounter_id]
			encounter_catalog[encounter_id] = encounter
			var phases: Array = encounter.get("phases", [])
			_assert(phases.size() >= (5 if encounter_id == "srmt_final_boss" else 3), "%s lacks production phase depth" % encounter_id)
			_assert(not str(encounter.get("defeated_flag", "")).is_empty(), "%s lacks a persistent defeat flag" % encounter_id)
			var overrides: Dictionary = encounter.get("difficulty_overrides", {})
			_assert(overrides.has("shrububu") and overrides.has("srmt"), "%s lacks both difficulty variants" % encounter_id)
			for phase_value in phases:
				var phase: Dictionary = phase_value
				_assert(not str(phase.get("intro_dialogue", "")).is_empty(), "%s phase lacks dialogue" % encounter_id)
				_assert(not str(phase.get("readability_hint", "")).is_empty(), "%s phase lacks a readable tell" % encounter_id)
				var patterns: Array = phase.get("patterns", [])
				_assert(not patterns.is_empty(), "%s phase has no attack pattern" % encounter_id)
				for pattern_value in patterns:
					var pattern: Dictionary = pattern_value
					_assert(float(pattern.get("telegraph_seconds", 0.0)) >= 0.45, "%s has an unfair base telegraph" % encounter_id)
					_assert(not str(pattern.get("safe_hint", "")).is_empty(), "%s pattern lacks a safe-route hint" % encounter_id)
					_assert(int(pattern.get("count", 0)) > 0 and int(pattern.get("count", 0)) <= 16, "%s pattern count is outside the authored fairness budget" % encounter_id)
	_assert(required_count == 10 and encounter_catalog.size() == 10, "Exactly ten canonical boss encounters must be audited")
	_assert(str((encounter_catalog.get("srmt_final_boss", {}) as Dictionary).get("required_weapon", "")) == "musical_guitar", "SRMT must require the musical guitar")


func _test_all_bosses_on_both_difficulties() -> void:
	var save_system = root.get_node_or_null("SaveSystem")
	var game_state = root.get_node_or_null("GameState")
	var original_paths := [save_system.save_path, save_system.backup_path, save_system.temporary_path]
	save_system.save_path = "user://pass69_save.json"
	save_system.backup_path = "user://pass69_save.backup.json"
	save_system.temporary_path = "user://pass69_save.tmp.json"
	save_system.clear_save()
	var battle_scene := load("res://scenes/battle/battle_scene.tscn") as PackedScene
	_assert(battle_scene != null, "Battle scene must load for full boss QA")
	if battle_scene == null:
		return
	for difficulty_id in ["shrububu", "srmt"]:
		for encounter_id in encounter_catalog:
			game_state.reset_progression()
			game_state.set_difficulty(difficulty_id, true)
			game_state.lock_difficulty()
			for gear_id in ["revolver", "banana_gun", "berry_potions", "festival_clearance", "musical_guitar"]:
				game_state.unlock_gear(gear_id, false)
			game_state.equip_weapon("musical_guitar")
			game_state.pending_encounter_id = str(encounter_id)
			var battle = battle_scene.instantiate()
			root.add_child(battle)
			await process_frame
			_assert(battle.active_encounter_id == encounter_id, "%s must start on %s" % [encounter_id, difficulty_id])
			_assert(battle.phase == "player_command", "%s must enter a command phase" % encounter_id)
			var easy_stats: Dictionary = battle.get_effective_encounter_stats(str(encounter_id), "shrububu")
			var hard_stats: Dictionary = battle.get_effective_encounter_stats(str(encounter_id), "srmt")
			_assert(float(easy_stats.get("bullet_speed_multiplier", 1.0)) < float(hard_stats.get("bullet_speed_multiplier", 1.0)), "%s difficulty bullet speeds must differ" % encounter_id)
			_assert(float(easy_stats.get("telegraph_multiplier", 1.0)) > float(hard_stats.get("telegraph_multiplier", 1.0)), "%s difficulty telegraphs must differ" % encounter_id)
			battle.battle_resolution = "resonance"
			battle.resolve_battle(false)
			var defeat_flag := str((encounter_catalog[encounter_id] as Dictionary).get("defeated_flag", ""))
			_assert(game_state.get_flag(defeat_flag), "%s must persist its defeated flag" % encounter_id)
			battle.queue_free()
			await process_frame
	save_system.clear_save()
	save_system.save_path = original_paths[0]
	save_system.backup_path = original_paths[1]
	save_system.temporary_path = original_paths[2]


func _test_complete_progression_state() -> void:
	var game_state = root.get_node_or_null("GameState")
	game_state.reset_progression()
	for clue_id in ["divorce_records", "165_files", "berry_contract", "hospital_records", "mansion_court_clues"]:
		game_state.collect_clue(clue_id)
	for gear_id in ["revolver", "banana_gun", "berry_potions", "festival_clearance", "musical_guitar"]:
		game_state.unlock_gear(gear_id, false)
	for encounter_id in encounter_catalog:
		var flag := str((encounter_catalog[encounter_id] as Dictionary).get("defeated_flag", ""))
		game_state.mark_boss_defeated(flag)
	game_state.set_growth_stage(5)
	game_state.set_flag("ishiyoga_rescued", true)
	_assert(game_state.get_collected_clue_ids().size() == 5, "Full progression must retain all critical clues")
	_assert(game_state.gear.size() == 5 and game_state.current_weapon.is_empty(), "Full progression must retain all gear without forced equip churn")
	_assert(game_state.defeated_bosses.size() == 10, "Full progression must retain all ten boss flags")
	_assert(game_state.growth_stage == 5 and game_state.get_flag("ishiyoga_rescued"), "Full progression must reach Form 5 and rescue IshiYoga")


func _load_json(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish(label: String) -> void:
	if failures.is_empty():
		print("PASS: %s" % label)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
