extends SceneTree

const REQUIRED_CUTSCENES := [
	"opening_arrival",
	"door_slam_collapse",
	"poojan_challenge",
	"satyaki_reveal",
	"banana_lab_discovery",
	"popcorn_spell_break",
	"deepak_moral_twist",
	"false_chicken_promise",
	"berry_sharing",
	"sushan_injection_failure",
	"aeon_festival",
	"area111_bar_fight",
	"bike_guitar_acquisition",
	"srmt_throne_reveal",
	"ishiyoga_rescue",
	"birthday_card"
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var director := root.get_node_or_null("CutsceneDirector")
	var game_state := root.get_node_or_null("GameState")
	if director == null or game_state == null:
		failures.append("CutsceneDirector or GameState autoload is missing")
		_finish(failures)
		return

	var catalog: Dictionary = director.load_catalog()
	for cutscene_id in REQUIRED_CUTSCENES:
		if not catalog.has(cutscene_id):
			failures.append("Cutscene catalog missing %s" % cutscene_id)
			continue
		var data: Dictionary = director.load_cutscene(cutscene_id)
		if str(data.get("id", "")) != cutscene_id:
			failures.append("Cutscene ID mismatch for %s" % cutscene_id)
		if str(data.get("completion_flag", "")).is_empty():
			failures.append("Cutscene %s lacks a completion flag" % cutscene_id)
		if not data.has("trigger") or typeof(data["trigger"]) != TYPE_DICTIONARY:
			failures.append("Cutscene %s lacks trigger data" % cutscene_id)
		if not data.has("skippable"):
			failures.append("Cutscene %s lacks explicit skip behavior" % cutscene_id)
		if typeof(data.get("steps", null)) != TYPE_ARRAY or data["steps"].is_empty():
			failures.append("Cutscene %s has no steps" % cutscene_id)

	var context := Node2D.new()
	context.name = "CutsceneTestContext"
	var world := Node2D.new()
	world.name = "World"
	var player := CharacterBody2D.new()
	player.name = "Player"
	player.add_to_group("player")
	world.add_child(player)
	context.add_child(world)
	root.add_child(context)
	game_state.set_flag("cutscene_smoke_complete", false)
	var test_data := {
		"id": "cutscene_smoke",
		"caption": "TEST",
		"completion_flag": "cutscene_smoke_complete",
		"skippable": true,
		"steps": [
			{"type": "lock_player", "locked": true},
			{"type": "move_actor", "target": "World/Player", "position": [12, 8], "duration": 0.01},
			{"type": "set_objective", "text": "Cutscene smoke objective"},
			{"type": "wait", "seconds": 0.01},
			{"type": "lock_player", "locked": false}
		]
	}
	var played: bool = await director.play_sequence(test_data, context)
	if not played:
		failures.append("CutsceneDirector rejected a valid sequence")
	if player.position != Vector2(12, 8):
		failures.append("CutsceneDirector did not move the actor")
	if not player.is_physics_processing():
		failures.append("CutsceneDirector did not restore player processing")
	if not game_state.get_flag("cutscene_smoke_complete"):
		failures.append("CutsceneDirector did not set the completion flag")
	if game_state.get_current_objective() != "Cutscene smoke objective":
		failures.append("CutsceneDirector did not update the objective")
	context.queue_free()
	game_state.set_flag("cutscene_smoke_complete", false)
	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("PASS: Premium cutscene director and catalog smoke test")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
