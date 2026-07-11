extends SceneTree

const FRAME_SIZES := [Vector2i(48, 64), Vector2i(50, 68), Vector2i(52, 72), Vector2i(54, 76), Vector2i(58, 80)]
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
const ATTACKS := ["attack_unarmed", "attack_revolver", "attack_banana_gun", "attack_berry_potions", "attack_musical_guitar"]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	for stage in range(1, 6):
		var frame_size: Vector2i = FRAME_SIZES[stage - 1]
		var directory := "res://assets/shared/sprites/shrububu/form_%02d" % stage
		for animation_name in REQUIRED_ANIMATIONS.keys():
			_check_sheet(directory, str(animation_name), int(REQUIRED_ANIMATIONS[animation_name]), frame_size, failures)
		_check_sheet(directory, ATTACKS[stage - 1], 6, frame_size, failures)
	if not FileAccess.file_exists("res://assets/shared/concept/shrububu_forms_reference.png"):
		failures.append("Shrububu five-form production reference is missing")

	var player_scene := load("res://scenes/overworld/player.tscn") as PackedScene
	if player_scene == null:
		failures.append("Player scene failed to load")
	else:
		var player := player_scene.instantiate()
		for method_name in ["get_animation_sprite_path", "get_animation_frame_count", "play_action", "apply_growth_visual"]:
			if not player.has_method(method_name):
				failures.append("Player controller lacks %s" % method_name)
		player.free()
	_finish(failures)


func _check_sheet(directory: String, animation_name: String, frame_count: int, frame_size: Vector2i, failures: Array[String]) -> void:
	var path := "%s/%s.png" % [directory, animation_name]
	if not FileAccess.file_exists(path):
		failures.append("Missing animation sheet: %s" % path)
		return
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		failures.append("Animation sheet failed to load: %s" % path)
		return
	if image.get_width() != frame_size.x * frame_count or image.get_height() != frame_size.y:
		failures.append("Unexpected sheet dimensions for %s: %s" % [path, image.get_size()])


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("PASS: Premium Shrububu animation production smoke test")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
