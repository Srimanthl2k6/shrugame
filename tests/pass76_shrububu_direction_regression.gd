extends SceneTree

const FRAME_SIZES := [
	Vector2i(48, 64),
	Vector2i(50, 68),
	Vector2i(52, 72),
	Vector2i(54, 76),
	Vector2i(58, 80)
]
const ATTACK_NAMES := [
	"attack_unarmed",
	"attack_revolver",
	"attack_banana_gun",
	"attack_berry_potions",
	"attack_musical_guitar"
]

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_processor_contract()
	_test_generated_sheets()
	await _test_runtime_facing()
	_finish("Pass 76 Shrububu horizontal direction mapping")


func _test_processor_contract() -> void:
	var processor := FileAccess.get_file_as_string("res://tools/process_shrububu_turnarounds.gd")
	_assert(processor.contains('1: {"down": 0, "left": 1, "up": 2, "right": 3}'), "Form 1 must use its left/right source order")
	_assert(processor.contains('2: {"down": 0, "left": 1, "up": 2, "right": 3}'), "Form 2 must use its left/right source order")
	_assert(processor.contains('3: {"down": 0, "right": 1, "up": 2, "left": 3}'), "Forms 3-5 must retain their source order")
	_assert(processor.contains('"up": 2'), "Up must map to source pose 2")
	_assert(processor.contains('"down": 0'), "Down must map to source pose 0")
	_assert(processor.contains('"door_slam", poses[right_pose_index]'), "Door slam must start from each form's right-facing pose")
	_assert(processor.contains('ATTACK_NAMES[stage - 1], poses[right_pose_index]'), "Weapon attacks must start from each form's right-facing pose")
	var director := FileAccess.get_file_as_string("res://scripts/cutscenes/cutscene_director.gd")
	_assert(director.contains('target.call("set_facing_direction", direction)'), "Cutscene facing must use PlayerController's immediate facing API")


func _test_generated_sheets() -> void:
	for stage in range(1, 6):
		var frame_size: Vector2i = FRAME_SIZES[stage - 1]
		var source_path := "res://source_art/shrububu/form_%02d_turnaround.png" % stage
		var source := Image.load_from_file(ProjectSettings.globalize_path(source_path))
		_assert(source != null and not source.is_empty(), "Form %d turnaround source must load" % stage)
		if source == null or source.is_empty():
			continue
		var right_source_index := 3 if stage <= 2 else 1
		var left_source_index := 1 if stage <= 2 else 3
		var expected_right := _extract_pose(source, right_source_index, frame_size)
		var expected_left := _extract_pose(source, left_source_index, frame_size)
		_assert(_first_frame_matches(stage, "idle_right", expected_right, frame_size), "Form %d idle_right must use source pose %d" % [stage, right_source_index])
		_assert(_first_frame_matches(stage, "walk_right", _offset_pose(expected_right, Vector2i(-1, 0)), frame_size), "Form %d walk_right must use source pose %d" % [stage, right_source_index])
		_assert(_first_frame_matches(stage, "idle_left", expected_left, frame_size), "Form %d idle_left must use source pose %d" % [stage, left_source_index])
		_assert(_first_frame_matches(stage, "walk_left", _offset_pose(expected_left, Vector2i(-1, 0)), frame_size), "Form %d walk_left must use source pose %d" % [stage, left_source_index])
		_assert(_first_frame_matches(stage, "door_slam", expected_right, frame_size), "Form %d door slam must face right" % stage)
		_assert(_first_frame_matches(stage, ATTACK_NAMES[stage - 1], expected_right, frame_size), "Form %d weapon attack must face right" % stage)


func _test_runtime_facing() -> void:
	var packed := load("res://scenes/overworld/player.tscn") as PackedScene
	var player = packed.instantiate() if packed != null else null
	_assert(player != null, "Player scene must instantiate")
	if player == null:
		return
	root.add_child(player)
	await process_frame
	var sprite := player.get_node("Sprite") as Sprite2D
	sprite.flip_h = true
	player.set_facing_direction("right")
	_assert(player.facing_direction == "right" and player.current_animation == "idle_right", "set_facing_direction(right) must update the displayed animation immediately")
	_assert(not sprite.flip_h, "Changing the horizontal texture must clear Sprite2D.flip_h")
	sprite.flip_h = true
	player.set_facing_direction("left")
	_assert(player.facing_direction == "left" and player.current_animation == "idle_left", "set_facing_direction(left) must update the displayed animation immediately")
	_assert(not sprite.flip_h, "Changing back to the left texture must clear Sprite2D.flip_h")
	player.queue_free()
	await process_frame


func _first_frame_matches(stage: int, animation_name: String, expected: Image, frame_size: Vector2i) -> bool:
	var path := "res://assets/shared/sprites/shrububu/form_%02d/%s.png" % [stage, animation_name]
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(path))
	if sheet == null or sheet.is_empty() or sheet.get_height() != frame_size.y or sheet.get_width() < frame_size.x:
		return false
	var actual := sheet.get_region(Rect2i(Vector2i.ZERO, frame_size))
	return actual.get_format() == expected.get_format() and actual.get_size() == expected.get_size() and actual.get_data() == expected.get_data()


func _offset_pose(pose: Image, offset: Vector2i) -> Image:
	var result := Image.create(pose.get_width(), pose.get_height(), false, Image.FORMAT_RGBA8)
	result.fill(Color(0, 0, 0, 0))
	var used := pose.get_used_rect()
	result.blend_rect(pose, used, used.position + offset)
	return result


func _extract_pose(source: Image, source_index: int, frame_size: Vector2i) -> Image:
	var section_width := int(source.get_width() / 4)
	var search := Rect2i(source_index * section_width, 0, section_width, source.get_height())
	var bounds := _alpha_bounds(source, search)
	var crop := source.get_region(bounds)
	var max_size := Vector2(frame_size.x - 6, frame_size.y - 4)
	var fit_scale := minf(max_size.x / float(crop.get_width()), max_size.y / float(crop.get_height()))
	var target_size := Vector2i(
		maxi(1, int(round(crop.get_width() * fit_scale))),
		maxi(1, int(round(crop.get_height() * fit_scale)))
	)
	crop.resize(target_size.x, target_size.y, Image.INTERPOLATE_NEAREST)
	_harden_alpha(crop)
	var pose := Image.create(frame_size.x, frame_size.y, false, Image.FORMAT_RGBA8)
	pose.fill(Color(0, 0, 0, 0))
	var destination := Vector2i(int((frame_size.x - target_size.x) / 2), frame_size.y - target_size.y - 2)
	pose.blend_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), destination)
	return pose


func _alpha_bounds(source: Image, search_rect: Rect2i) -> Rect2i:
	var min_x := search_rect.end.x
	var min_y := search_rect.end.y
	var max_x := search_rect.position.x - 1
	var max_y := search_rect.position.y - 1
	for y in range(search_rect.position.y, search_rect.end.y):
		for x in range(search_rect.position.x, search_rect.end.x):
			if source.get_pixel(x, y).a > 0.08:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _harden_alpha(image: Image) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a < 0.28:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				color.a = 1.0
				image.set_pixel(x, y, color)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish(label: String) -> void:
	if failures.is_empty():
		print("PASS: %s" % label)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
