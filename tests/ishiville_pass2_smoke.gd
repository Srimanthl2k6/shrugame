extends SceneTree

const ART_BIBLE_PATH := "res://docs/ART_BIBLE.md"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var text := FileAccess.get_file_as_string(ART_BIBLE_PATH)

	if text.is_empty():
		failures.append("ART_BIBLE.md must exist and contain the Ishiville art bible")
	else:
		_check_core_specs(text, failures)
		_check_growth_forms(text, failures)
		_check_levels(text, failures)
		_check_animation_requirements(text, failures)
		_check_asset_naming(text, failures)

	if failures.is_empty():
		print("PASS: Ishiville Pass 2 smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_core_specs(text: String, failures: Array[String]) -> void:
	for required in [
		"Base resolution: 320x180",
		"Tile size: 16x16",
		"Integer scale target: 3x or 4x",
		"Battle arena: 160x96",
		"UI style",
		"battle portrait/cut-in style",
		"NPC sprite size classes",
		"boss sprite sizes"
	]:
		if not text.contains(required):
			failures.append("ART_BIBLE.md missing core spec: %s" % required)


func _check_growth_forms(text: String, failures: Array[String]) -> void:
	for required in [
		"Form 1: KFC seeker",
		"Form 2: revolver carrier",
		"Form 3: banana gun + berry satchel",
		"Form 4: oversized mythic town breaker",
		"Form 5: biker guitar final form",
		"16x24",
		"18x26",
		"20x28",
		"24x32",
		"28x36"
	]:
		if not text.contains(required):
			failures.append("ART_BIBLE.md missing growth form spec: %s" % required)


func _check_levels(text: String, failures: Array[String]) -> void:
	for required in [
		"Divorcee Harbour",
		"Banana-burbs",
		"Berry Barks",
		"Auticity",
		"Area 111",
		"Palette",
		"Tileset target",
		"Animation motif",
		"NPC direction",
		"Boss direction"
	]:
		if not text.contains(required):
			failures.append("ART_BIBLE.md missing level art spec: %s" % required)


func _check_animation_requirements(text: String, failures: Array[String]) -> void:
	for required in [
		"overworld idle",
		"overworld walk",
		"door slam",
		"interact",
		"battle idle",
		"hurt",
		"attack per weapon",
		"victory",
		"boss intro",
		"boss defeat",
		"2 frames",
		"4 frames",
		"6 frames",
		"8 frames"
	]:
		if not text.contains(required):
			failures.append("ART_BIBLE.md missing animation requirement: %s" % required)


func _check_asset_naming(text: String, failures: Array[String]) -> void:
	for required in [
		"assets/shared/sprites/shrububu/form_01/",
		"assets/shared/sprites/shrububu/form_02/",
		"assets/shared/sprites/shrububu/form_03/",
		"assets/shared/sprites/shrububu/form_04/",
		"assets/shared/sprites/shrububu/form_05/",
		"assets/level_01/sprites/",
		"assets/level_01/tilesets/",
		"assets/level_02/sprites/",
		"assets/level_03/sprites/",
		"assets/level_04/sprites/",
		"assets/level_05/sprites/"
	]:
		if not text.contains(required):
			failures.append("ART_BIBLE.md missing asset naming rule: %s" % required)
