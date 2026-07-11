extends SceneTree

const DISTRICTS := {
	"level_01": {"scene": "res://scenes/levels/districts/level_01.tscn", "start": "arrival", "rooms": 5},
	"level_02": {"scene": "res://scenes/levels/districts/level_02.tscn", "start": "suburb", "rooms": 5},
	"level_03": {"scene": "res://scenes/levels/districts/level_03.tscn", "start": "forest_entrance", "rooms": 5},
	"level_04": {"scene": "res://scenes/levels/districts/level_04.tscn", "start": "pun_street", "rooms": 5},
	"level_05": {"scene": "res://scenes/levels/districts/level_05.tscn", "start": "ruined_boulevard", "rooms": 7}
}

const REQUIRED_ENCOUNTERS := [
	"poojan_strength_test",
	"satyaki_tirumal_boss",
	"nitin_janitor_boss",
	"deepak_reddy_boss",
	"niggesh_nishal_boss",
	"ankit_boss",
	"doctor_sushan_boss",
	"mitta_boss",
	"suhas_bar_fight",
	"srmt_final_boss"
]

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_system := root.get_node_or_null("SaveSystem")
	var game_state := root.get_node_or_null("GameState")
	_assert(save_system != null and game_state != null, "Production districts require state and save autoloads")
	if save_system != null:
		save_system.new_game("shrububu")
	for level_id in DISTRICTS:
		await _test_district(level_id, DISTRICTS[level_id])
	_test_encounter_catalog()
	_test_canonical_finale()
	if failures.is_empty():
		print("PASS: Passes 52-61 production districts, 27 rooms, ten encounters, progression gates, and finale")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _test_district(level_id: String, contract: Dictionary) -> void:
	var packed := load(str(contract.scene)) as PackedScene
	_assert(packed != null, "%s district scene must load" % level_id)
	if packed == null:
		return
	var district = packed.instantiate()
	root.add_child(district)
	await process_frame
	_assert(str(district.get_current_room_id()) == str(contract.start), "%s must open in its canonical start room" % level_id)
	_assert(district._room_paths.size() == int(contract.rooms), "%s must index %d production rooms" % [level_id, int(contract.rooms)])
	var player := district.get_node_or_null("Player") as CharacterBody2D
	_assert(player != null, "%s must preserve one player across rooms" % level_id)
	for room_id in district._room_paths:
		_assert(district.switch_room(str(room_id), "start", false), "%s/%s must instantiate" % [level_id, room_id])
		await process_frame
		var room = district.current_room
		_assert(room != null, "%s/%s must become current" % [level_id, room_id])
		if room == null:
			continue
		var background := room.get_node_or_null("Background") as Sprite2D
		_assert(background != null and background.texture != null, "%s/%s must have a room backplate" % [level_id, room_id])
		if background != null and background.texture != null:
			_assert(background.texture.get_size() == Vector2(640, 360), "%s/%s backplate must be 640x360" % [level_id, room_id])
		_assert(room.get_node_or_null("BoundaryWalls") != null, "%s/%s must have authored boundaries" % [level_id, room_id])
		var interactions: Node = room.get_node_or_null("Interactions")
		_assert(interactions != null and interactions.get_child_count() > 0, "%s/%s must contain authored interactions" % [level_id, room_id])
		var spawns: Node = room.get_node_or_null("SpawnPoints")
		_assert(spawns != null and spawns.get_child_count() > 0, "%s/%s must expose a spawn point" % [level_id, room_id])
		if player != null:
			var camera := player.get_node_or_null("Camera2D") as Camera2D
			_assert(camera != null and camera.limit_right == 640 and camera.limit_bottom == 360, "%s/%s must clamp the camera" % [level_id, room_id])
	district.queue_free()
	await process_frame


func _test_encounter_catalog() -> void:
	var found: Dictionary = {}
	for path in [
		"res://data/encounters/level_01_encounters.json",
		"res://data/encounters/level_02_encounters.json",
		"res://data/encounters/level_03_encounters.json",
		"res://data/encounters/level_04_encounters.json",
		"res://data/encounters/level_05_encounters.json"
	]:
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		_assert(typeof(parsed) == TYPE_DICTIONARY, "%s must parse" % path)
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		for encounter_id in parsed:
			var encounter: Dictionary = parsed[encounter_id]
			found[str(encounter_id)] = encounter
	for encounter_id in REQUIRED_ENCOUNTERS:
		_assert(found.has(encounter_id), "Missing canonical encounter %s" % encounter_id)
		if found.has(encounter_id):
			var encounter: Dictionary = found[encounter_id]
			_assert(encounter.get("phases", []).size() >= (5 if encounter_id == "srmt_final_boss" else 3), "%s needs production phase depth" % encounter_id)
			_assert(not str(encounter.get("defeated_flag", "")).is_empty(), "%s needs a persistent defeated flag" % encounter_id)


func _test_canonical_finale() -> void:
	var room_text := FileAccess.get_file_as_string("res://data/rooms/level_05_rooms.json")
	var ending_text := FileAccess.get_file_as_string("res://scenes/ending.tscn")
	_assert(room_text.contains("mansion_court_clues_collected"), "SRMT route must require the mansion clues")
	_assert(room_text.contains("musical_guitar"), "SRMT route must require the musical guitar")
	_assert(room_text.contains("ishiyoga_rescued"), "Finale must persist IshiYoga rescue")
	_assert(ending_text.contains("Happy Birthday Tingu Verma."), "Finale must contain exact birthday greeting")
	_assert(ending_text.contains("~ Taklu Taklu Chuha."), "Finale must contain exact birthday signature")
	_assert(not room_text.contains("ishiyoga_freed"), "Finale must use one canonical rescue flag")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
