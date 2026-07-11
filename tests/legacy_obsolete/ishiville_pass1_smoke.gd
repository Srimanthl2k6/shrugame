extends SceneTree

const DESIGN_PATH := "res://docs/DESIGN.md"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var text := FileAccess.get_file_as_string(DESIGN_PATH)

	if text.is_empty():
		failures.append("DESIGN.md must exist and contain the Ishiville design bible")
	else:
		_check_required_canon(text, failures)
		_check_story_progression(text, failures)
		_check_tone_and_art_rules(text, failures)
		_check_old_lore_removed(text, failures)

	if failures.is_empty():
		print("PASS: Ishiville Pass 1 smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_required_canon(text: String, failures: Array[String]) -> void:
	for required in [
		"Shrububu",
		"Shruti",
		"Ishiville",
		"SRMT",
		"IshiYoga",
		"KFC",
		"Divorcee Harbour",
		"Banana-burbs",
		"Berry Barks",
		"Auticity",
		"Area 111"
	]:
		if not text.contains(required):
			failures.append("DESIGN.md missing required canon term: %s" % required)


func _check_story_progression(text: String, failures: Array[String]) -> void:
	for required in [
		"| Level | Area | Intro Event | Mini Boss | Main Boss | Reward/Gear | Clue Gained | Growth Form | Town State After Defeat |",
		"Poojan",
		"Satyaki Tirumal",
		"revolver",
		"Nitin",
		"Deepak Reddy",
		"banana gun",
		"165-files",
		"Niggesh Nishal",
		"Ankit",
		"berry potions",
		"Doctor Sushan",
		"Mitta",
		"Aeon",
		"Suhas",
		"musical guitar"
	]:
		if not text.contains(required):
			failures.append("DESIGN.md missing story progression detail: %s" % required)


func _check_tone_and_art_rules(text: String, failures: Array[String]) -> void:
	for required in [
		"Pacific Northwest mystery",
		"Twin Peaks",
		"Gravity Falls",
		"rainy, strange, funny, unsettling",
		"chunky expressive pixel sprites",
		"rain, neon, mist, paper clutter, cursed signage",
		"palette and animation motif"
	]:
		if not text.contains(required):
			failures.append("DESIGN.md missing tone/art rule: %s" % required)


func _check_old_lore_removed(text: String, failures: Array[String]) -> void:
	for forbidden in [
		"Undergrid",
		"Marn",
		"Vela",
		"Tickroot",
		"Judge Luma",
		"Nulla",
		"The Dust Pantry",
		"The Glass Canal",
		"The Clock Orchard",
		"The Lantern Court",
		"The Static Door"
	]:
		if text.contains(forbidden):
			failures.append("DESIGN.md still contains old prototype lore: %s" % forbidden)
