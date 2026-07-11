extends SceneTree

const CONTRACT_PATH := "res://data/art/scale_contract.json"
const REQUIRED_ANIMATIONS := {
	"idle_down": 2,
	"idle_up": 2,
	"idle_left": 2,
	"idle_right": 2,
	"walk_down": 4,
	"walk_up": 4,
	"walk_left": 4,
	"walk_right": 4,
	"battle_idle": 4,
	"hurt": 2,
	"victory": 4,
	"interact": 4,
	"door_slam": 6,
	"growth_transform": 8
}

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var contract := _load_json(CONTRACT_PATH)
	var viewport_values: Array = contract.get("viewport", [])
	_assert(viewport_values.size() == 2 and int(viewport_values[0]) == 640 and int(viewport_values[1]) == 360, "Art contract must use 640x360")
	var forms: Dictionary = contract.get("shrububu_forms", {})
	var previous_height := 0
	for stage in range(1, 6):
		var form_id := "form_%02d" % stage
		var form: Dictionary = forms.get(form_id, {})
		var frame_values: Array = form.get("frame_size", [])
		_assert(frame_values.size() == 2, "%s must define frame size" % form_id)
		if frame_values.size() != 2:
			continue
		var frame_size := Vector2i(int(frame_values[0]), int(frame_values[1]))
		_assert(frame_size.y > previous_height, "%s must grow vertically" % form_id)
		_assert(float(frame_size.x) / float(frame_size.y) < 0.79, "%s violates slim canvas ratio" % form_id)
		previous_height = frame_size.y
		var directory := "res://assets/shared/sprites/shrububu/%s" % form_id
		for animation_name in REQUIRED_ANIMATIONS:
			_check_sheet(directory, animation_name, int(REQUIRED_ANIMATIONS[animation_name]), frame_size)
	var art_bible := FileAccess.get_file_as_string("res://docs/ART_BIBLE.md")
	_assert(art_bible.contains("Base resolution: 640x360"), "Art bible must match migrated viewport")
	_assert(art_bible.contains("Never portray Shrububu as fat"), "Slim identity lock must remain explicit")
	if failures.is_empty():
		print("PASS: Pass 50 art scale, frame, alpha, and slim-silhouette contract")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _check_sheet(directory: String, animation_name: String, frames: int, frame_size: Vector2i) -> void:
	var path := "%s/%s.png" % [directory, animation_name]
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		failures.append("Missing animation sheet: %s" % path)
		return
	_assert(image.get_size() == Vector2i(frame_size.x * frames, frame_size.y), "Invalid sheet dimensions: %s" % path)
	var has_transparency := false
	for point in [Vector2i(0, 0), Vector2i(image.get_width() - 1, 0), Vector2i(0, image.get_height() - 1), Vector2i(image.get_width() - 1, image.get_height() - 1)]:
		if image.get_pixelv(point).a < 0.05:
			has_transparency = true
	_assert(has_transparency, "Animation sheet must preserve transparent padding: %s" % path)


func _load_json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
