extends SceneTree

const FRAME_SIZES := [Vector2i(48, 64), Vector2i(50, 68), Vector2i(52, 72), Vector2i(54, 76), Vector2i(58, 80)]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_text("res://docs/ART_BIBLE.md", [
		"assets/shared/concept/shrububu_forms_reference.png",
		"Her body does not widen as she grows",
		"Never portray Shrububu as fat",
		"Raw photo references are production-only"
	], failures)
	_check_text("res://docs/SHRUBUBU_CHARACTER_BIBLE.md", [
		"Shrububu remains slim and naturally proportioned in every form",
		"Increasing height",
		"Godot never imports them"
	], failures)
	_check_text("res://.gitignore", ["shrububu- child/", "shrububu- older/"], failures)
	_check_text("res://export_presets.cfg", ["source_art/*", "electron/*", "site/*"], failures)
	_check_text("res://tools/generate_premium_shrububu_sprites.gd", [
		"Growth is vertical only",
		"var shoulder_half := 7",
		"long wavy sides",
		"side-eye"
	], failures)

	var previous_height := 0
	for stage in range(1, 6):
		var path := "res://assets/shared/sprites/shrububu/form_%02d/idle_down.png" % stage
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if image == null or image.is_empty():
			failures.append("Missing photo-informed idle sheet: %s" % path)
			continue
		var expected: Vector2i = FRAME_SIZES[stage - 1]
		if image.get_size() != Vector2i(expected.x * 2, expected.y):
			failures.append("Unexpected photo-informed sheet dimensions: %s" % path)
		if expected.y <= previous_height:
			failures.append("Growth form %d is not taller than the preceding form" % stage)
		if float(expected.x) / float(expected.y) > 0.78:
			failures.append("Growth form %d canvas is too wide for the locked slim silhouette" % stage)
		previous_height = expected.y

	_finish(failures)


func _check_text(path: String, needles: Array, failures: Array[String]) -> void:
	if not FileAccess.file_exists(path):
		failures.append("Missing identity contract file: %s" % path)
		return
	var source := FileAccess.get_file_as_string(path)
	for needle in needles:
		if not source.contains(str(needle)):
			failures.append("%s is missing identity contract text: %s" % [path, needle])


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("PASS: Shrububu photo-informed identity and slim-silhouette smoke test")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
