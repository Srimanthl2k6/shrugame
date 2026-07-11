extends SceneTree

const SOURCE_ROOT := "res://source_art/shrububu"
const OUTPUT_ROOT := "res://assets/shared/sprites/shrububu"
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
const DIRECTIONS := ["down", "left", "up", "right"]


func _init() -> void:
	call_deferred("_process_sources")


func _process_sources() -> void:
	var processed := 0
	for stage in range(1, 6):
		var source_path := "%s/form_%02d_turnaround.png" % [SOURCE_ROOT, stage]
		var absolute_source := ProjectSettings.globalize_path(source_path)
		if not FileAccess.file_exists(absolute_source):
			continue
		var source := Image.load_from_file(absolute_source)
		if source == null or source.is_empty():
			push_error("Could not load turnaround source: %s" % source_path)
			quit(1)
		var poses := _extract_direction_poses(source, FRAME_SIZES[stage - 1])
		if poses.size() != 4:
			push_error("Could not extract four direction poses from %s" % source_path)
			quit(1)
		_write_stage(stage, poses)
		processed += 1
	print("PASS: processed %d high-detail Shrububu turnarounds" % processed)
	quit(0)


func _extract_direction_poses(source: Image, frame_size: Vector2i) -> Array[Image]:
	var poses: Array[Image] = []
	var section_width := int(source.get_width() / 4)
	for section in range(4):
		var section_rect := Rect2i(section * section_width, 0, section_width, source.get_height())
		var bounds := _alpha_bounds(source, section_rect)
		if bounds.size.x <= 0 or bounds.size.y <= 0:
			return []
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
		var destination := Vector2i(
			int((frame_size.x - target_size.x) / 2),
			frame_size.y - target_size.y - 2
		)
		pose.blend_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), destination)
		poses.append(pose)
	return poses


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
	if max_x < min_x or max_y < min_y:
		return Rect2i()
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


func _write_stage(stage: int, poses: Array[Image]) -> void:
	var stage_dir := "%s/form_%02d" % [OUTPUT_ROOT, stage]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(stage_dir))
	for direction_index in range(DIRECTIONS.size()):
		var direction: String = str(DIRECTIONS[direction_index])
		_write_motion_sheet(stage_dir, "idle_%s" % direction, poses[direction_index], 2, "idle", stage)
		_write_motion_sheet(stage_dir, "walk_%s" % direction, poses[direction_index], 4, "walk", stage)
	_write_motion_sheet(stage_dir, "battle_idle", poses[0], 4, "battle", stage)
	_write_motion_sheet(stage_dir, "hurt", poses[0], 2, "hurt", stage)
	_write_motion_sheet(stage_dir, "victory", poses[0], 4, "victory", stage)
	_write_motion_sheet(stage_dir, "interact", poses[0], 4, "interact", stage)
	_write_motion_sheet(stage_dir, "door_slam", poses[3], 6, "door_slam", stage)
	_write_motion_sheet(stage_dir, "growth_transform", poses[0], 8, "growth", stage)
	_write_motion_sheet(stage_dir, ATTACK_NAMES[stage - 1], poses[3], 6, "attack", stage)


func _write_motion_sheet(stage_dir: String, animation_name: String, pose: Image, frame_count: int, action: String, stage: int) -> void:
	var frame_size := pose.get_size()
	var sheet := Image.create(frame_size.x * frame_count, frame_size.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for frame in range(frame_count):
		var rendered := _render_motion_frame(pose, action, frame, frame_count, stage)
		sheet.blend_rect(rendered, Rect2i(Vector2i.ZERO, frame_size), Vector2i(frame * frame_size.x, 0))
	var output_path := "%s/%s.png" % [stage_dir, animation_name]
	var error := sheet.save_png(ProjectSettings.globalize_path(output_path))
	if error != OK:
		push_error("Could not save processed sprite sheet: %s" % output_path)


func _render_motion_frame(pose: Image, action: String, frame: int, frame_count: int, stage: int) -> Image:
	var result := Image.create(pose.get_width(), pose.get_height(), false, Image.FORMAT_RGBA8)
	result.fill(Color(0, 0, 0, 0))
	var offset := Vector2i.ZERO
	match action:
		"idle":
			offset.y = frame % 2
		"walk":
			offset.x = [-1, 0, 1, 0][frame % 4]
			offset.y = [0, 1, 0, 1][frame % 4]
		"battle":
			offset.y = [0, -1, 0, 1][frame % 4]
		"hurt":
			offset.x = -2 if frame == 0 else 2
		"victory":
			offset.y = [0, -2, -3, -1][frame % 4]
		"interact":
			offset.y = [0, 1, 1, 0][frame % 4]
		"door_slam":
			offset.x = [0, 1, 3, 5, 2, 0][frame % 6]
		"attack":
			offset.x = [0, 1, 3, 4, 2, 0][frame % 6]
		"growth":
			offset.y = [0, 1, 2, -2, -3, -2, -1, 0][frame % 8]
	var used := pose.get_used_rect()
	result.blend_rect(pose, used, used.position + offset)
	if action == "hurt":
		_tint_opaque_pixels(result, Color("ff5f6d"), 0.36)
	if action == "growth":
		_draw_aura(result, frame, stage)
	if action in ["attack", "door_slam"] and frame in [2, 3]:
		_draw_motion_streak(result, offset, stage)
	return result


func _tint_opaque_pixels(image: Image, tint: Color, amount: float) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a > 0.0:
				image.set_pixel(x, y, color.lerp(Color(tint.r, tint.g, tint.b, color.a), amount))


func _draw_aura(image: Image, frame: int, stage: int) -> void:
	var accent_colors := [Color("d64d58"), Color("e2b348"), Color("a33f78"), Color("ac3b73"), Color("25bbb8")]
	var accent: Color = accent_colors[stage - 1]
	var inset := 2 + frame % 4
	var points := [
		Vector2i(inset, 8 + frame % 3),
		Vector2i(image.get_width() - 1 - inset, 11),
		Vector2i(5 + frame % 2, image.get_height() - 10),
		Vector2i(image.get_width() - 7, image.get_height() - 7 - frame % 3)
	]
	for point in points:
		if point.x >= 0 and point.y >= 0 and point.x < image.get_width() and point.y < image.get_height():
			image.set_pixel(point.x, point.y, accent)


func _draw_motion_streak(image: Image, offset: Vector2i, stage: int) -> void:
	var accent := Color("25bbb8") if stage == 5 else Color("e2b348")
	var start_x := maxi(1, image.get_width() - 8 + offset.x)
	var y := int(image.get_height() * 0.42)
	for i in range(4):
		var x := mini(image.get_width() - 1, start_x + i)
		image.set_pixel(x, y + i % 2, accent)
