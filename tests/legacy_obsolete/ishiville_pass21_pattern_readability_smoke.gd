extends SceneTree

const LEVEL_01_ENCOUNTERS := "res://data/encounters/level_01_encounters.json"
const TUNING_PATH := "res://data/tuning/gameplay_tuning.json"
const BULLET_PATTERN_SCRIPT := "res://scripts/battle/bullet_pattern_base.gd"
const BATTLE_SCENE := "res://scenes/battle/battle_scene.tscn"

const LEVEL_01_BOSSES := ["poojan_strength_test", "satyaki_tirumal_boss"]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_tuning(failures)
	_check_level_01_pattern_metadata(failures)
	_check_bullet_pattern_api(failures)
	_check_battle_manager_pattern_label(failures)
	_check_readme(failures)

	if failures.is_empty():
		print("PASS: Ishiville Pass 21 pattern readability smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_tuning(failures: Array[String]) -> void:
	var tuning := _load_dict(TUNING_PATH, failures)
	var battle: Dictionary = tuning.get("battle", {})
	if float(battle.get("pattern_telegraph_seconds", 0.0)) < 0.45:
		failures.append("battle.pattern_telegraph_seconds must be at least 0.45")
	if float(battle.get("enemy_phase_seconds", 0.0)) < 1.25:
		failures.append("battle.enemy_phase_seconds must be at least 1.25 for readable Level 1 pacing")
	if int(battle.get("bullet_count", 0)) > 5:
		failures.append("battle.bullet_count should stay <= 5 for Level 1 readability")


func _check_level_01_pattern_metadata(failures: Array[String]) -> void:
	var encounters := _load_dict(LEVEL_01_ENCOUNTERS, failures)
	for encounter_id in LEVEL_01_BOSSES:
		var encounter: Dictionary = encounters.get(encounter_id, {})
		if not encounter.has("pacing_note"):
			failures.append("%s needs pacing_note" % encounter_id)
		var phases: Array = encounter.get("phases", [])
		for phase_data in phases:
			if typeof(phase_data) != TYPE_DICTIONARY:
				failures.append("%s has non-dictionary phase" % encounter_id)
				continue
			if not phase_data.has("readability_hint"):
				failures.append("%s/%s missing readability_hint" % [encounter_id, phase_data.get("id", "phase")])
			var patterns: Array = phase_data.get("patterns", [])
			for pattern in patterns:
				if typeof(pattern) != TYPE_DICTIONARY:
					failures.append("%s/%s has non-dictionary pattern" % [encounter_id, phase_data.get("id", "phase")])
					continue
				if float(pattern.get("telegraph_seconds", 0.0)) < 0.45:
					failures.append("%s/%s pattern needs telegraph_seconds >= 0.45" % [encounter_id, phase_data.get("id", "phase")])
				if not pattern.has("safe_hint"):
					failures.append("%s/%s pattern missing safe_hint" % [encounter_id, phase_data.get("id", "phase")])
				if not pattern.has("visual_id"):
					failures.append("%s/%s pattern missing visual_id" % [encounter_id, phase_data.get("id", "phase")])


func _check_bullet_pattern_api(failures: Array[String]) -> void:
	if not ResourceLoader.exists(BULLET_PATTERN_SCRIPT, "Script"):
		failures.append("Bullet pattern script missing")
		return
	var script: Script = load(BULLET_PATTERN_SCRIPT)
	var pattern: Node = script.new()
	for method_name in [
		"get_active_telegraph_text",
		"get_last_pattern_metadata",
		"is_telegraphing"
	]:
		if not pattern.has_method(method_name):
			failures.append("BulletPattern missing %s" % method_name)
	if pattern.has_method("start_pattern"):
		pattern.start_pattern({
			"type": "straight_lanes",
			"count": 4,
			"telegraph_seconds": 0.6,
			"safe_hint": "Watch the lanes.",
			"visual_id": "badge"
		})
		if pattern.has_method("is_telegraphing") and not pattern.is_telegraphing():
			failures.append("BulletPattern should enter telegraphing state before spawning bullets")
		if pattern.has_method("get_active_telegraph_text") and not str(pattern.get_active_telegraph_text()).contains("Watch"):
			failures.append("BulletPattern telegraph text should include safe_hint")
		if pattern.get_child_count() != 0:
			failures.append("BulletPattern should not spawn bullets during telegraph state")
	pattern.free()


func _check_battle_manager_pattern_label(failures: Array[String]) -> void:
	var scene := load(BATTLE_SCENE)
	if scene == null:
		failures.append("Battle scene failed to load")
		return
	var battle: Node = scene.instantiate()
	for method_name in ["get_current_pattern_readability_text", "get_phase_readability_hint"]:
		if not battle.has_method(method_name):
			failures.append("BattleManager missing %s" % method_name)
	battle.free()


func _check_readme(failures: Array[String]) -> void:
	var readme := FileAccess.get_file_as_string("res://README.md")
	for required_text in [
		"Pass 21 Level 1 boss pattern readability",
		"telegraph timing",
		"safe-lane hints",
		"slower Level 1 pacing"
	]:
		if not readme.contains(required_text):
			failures.append("README missing Pass 21 note: %s" % required_text)


func _load_dict(path: String, failures: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(path):
		failures.append("Missing data file %s" % path)
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		failures.append("%s must parse as a dictionary" % path)
		return {}
	return data
