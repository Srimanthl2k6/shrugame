extends SceneTree

const BOSS_SPECS := {
	"nitin": Vector2i(60, 70),
	"deepak_reddy": Vector2i(66, 76)
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_image("res://assets/level_02/sprites/npc_happy_monkey_idle.png", Vector2i(32, 40), failures)
	_check_image("res://assets/level_02/sprites/boss_nitin_overworld.png", Vector2i(38, 54), failures)
	_check_image("res://assets/level_02/sprites/boss_deepak_reddy_overworld.png", Vector2i(42, 58), failures)
	for boss_id in BOSS_SPECS.keys():
		var frame_size: Vector2i = BOSS_SPECS[boss_id]
		for animation_name in ["intro", "idle", "talk", "attack", "hurt", "defeat"]:
			var frames := 2 if animation_name == "hurt" else (6 if animation_name in ["intro", "defeat"] else 4)
			_check_image(
				"res://assets/level_02/sprites/boss_%s_%s.png" % [boss_id, animation_name],
				Vector2i(frame_size.x * frames, frame_size.y),
				failures
			)
	_check_cutscene_flow(failures)
	_check_encounters(failures)
	_check_scene_staging(failures)
	_finish(failures)


func _check_image(path: String, expected_size: Vector2i, failures: Array[String]) -> void:
	if not FileAccess.file_exists(path):
		failures.append("Missing Level 2 premium cast image: %s" % path)
		return
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		failures.append("Could not load Level 2 premium cast image: %s" % path)
		return
	if image.get_size() != expected_size:
		failures.append("Unexpected dimensions for %s: %s" % [path, image.get_size()])
	var colors := {}
	for y in range(0, image.get_height(), maxi(1, int(image.get_height() / 10))):
		for x in range(0, image.get_width(), maxi(1, int(image.get_width() / 10))):
			var color := image.get_pixel(x, y)
			if color.a > 0.5:
				colors[color.to_html(false)] = true
	if colors.size() < 8:
		failures.append("Level 2 premium cast image lacks authored color detail: %s" % path)


func _check_cutscene_flow(failures: Array[String]) -> void:
	var lab := _load_json("res://data/cutscenes/banana_lab_discovery.json", failures)
	var popcorn := _load_json("res://data/cutscenes/popcorn_spell_break.json", failures)
	if str(lab.get("completion_flag", "")) != "165_files_collected":
		failures.append("Lab cutscene must complete the canonical 165_files_collected flag")
	if not _has_step(lab, "collect_clue", "165_files"):
		failures.append("Lab cutscene must collect the 165-files clue")
	if str(popcorn.get("completion_flag", "")) != "monkeys_spell_broken":
		failures.append("Popcorn cutscene must complete the canonical monkeys_spell_broken flag")
	if not _has_step(popcorn, "unlock_gear", "banana_gun"):
		failures.append("Popcorn cutscene must unlock the banana gun")
	var director_source := FileAccess.get_file_as_string("res://scripts/cutscenes/cutscene_director.gd")
	for step_type in ["collect_clue", "unlock_gear", "add_item", "set_growth_stage"]:
		if not director_source.contains('"%s"' % step_type):
			failures.append("CutsceneDirector lacks reward step: %s" % step_type)


func _check_encounters(failures: Array[String]) -> void:
	var encounters := _load_json("res://data/encounters/level_02_encounters.json", failures)
	for encounter_id in ["nitin_janitor_boss", "deepak_reddy_boss"]:
		var encounter: Dictionary = encounters.get(encounter_id, {})
		if encounter.is_empty():
			failures.append("Missing Level 2 premium encounter: %s" % encounter_id)
			continue
		if int(encounter.get("battle_frames", 0)) != 4:
			failures.append("%s must use a four-frame authored battle visual" % encounter_id)
		if (encounter.get("phases", []) as Array).size() < 3:
			failures.append("%s must have at least three boss phases" % encounter_id)
		if not encounter.has("difficulty_overrides"):
			failures.append("%s must define Shrububu/SRMT overrides" % encounter_id)


func _check_scene_staging(failures: Array[String]) -> void:
	var packed := load("res://scenes/levels/level_02.tscn") as PackedScene
	if packed == null:
		failures.append("Level 2 failed to load")
		return
	var level := packed.instantiate()
	for node_path in ["World/HappyMonkeyLoop", "World/HappyMonkeyResident02", "World/HappyMonkeyResident03", "World/HappyMonkeyResident04", "World/NitinJanitor", "World/DeepakBoss"]:
		if level.get_node_or_null(node_path) == null:
			failures.append("Level 2 missing staged cast node: %s" % node_path)
	for node_path in ["World/Vela", "World/Objective", "World/PracticeEncounter"]:
		var legacy := level.get_node_or_null(node_path) as CanvasItem
		if legacy != null and legacy.visible:
			failures.append("Legacy prototype node remains visible: %s" % node_path)
	level.free()


func _has_step(data: Dictionary, step_type: String, id: String) -> bool:
	for raw_step in data.get("steps", []):
		if typeof(raw_step) == TYPE_DICTIONARY and str(raw_step.get("type", "")) == step_type and str(raw_step.get("id", "")) == id:
			return true
	return false


func _load_json(path: String, failures: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(path):
		failures.append("Missing JSON file: %s" % path)
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		failures.append("Invalid JSON object: %s" % path)
		return {}
	return parsed


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("PASS: Level 2 premium cast, cutscene rewards, and three-phase bosses")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
