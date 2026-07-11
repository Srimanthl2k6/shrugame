extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var source := FileAccess.get_file_as_string("res://data/difficulty/difficulty_modes.json")
	var modes = JSON.parse_string(source)
	if typeof(modes) != TYPE_DICTIONARY:
		failures.append("Difficulty data is not a JSON object")
	else:
		for mode_id in ["shrububu", "srmt"]:
			if not modes.has(mode_id):
				failures.append("Missing difficulty mode: %s" % mode_id)
		if modes.has("shrububu") and modes.has("srmt"):
			var easy: Dictionary = modes["shrububu"]
			var hard: Dictionary = modes["srmt"]
			if float(easy.get("player_hp_multiplier", 0.0)) <= float(hard.get("player_hp_multiplier", 0.0)):
				failures.append("Shrububu mode must grant more player HP than SRMT mode")
			if float(easy.get("bullet_speed_multiplier", 99.0)) >= float(hard.get("bullet_speed_multiplier", 0.0)):
				failures.append("Shrububu bullets must be slower than SRMT bullets")
			if not bool(easy.get("forgive_failed_puzzles", false)):
				failures.append("Shrububu mode must enable puzzle forgiveness")
			if bool(hard.get("forgive_failed_puzzles", true)):
				failures.append("SRMT mode must disable puzzle forgiveness")
	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("PASS: Premium difficulty data smoke test")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
