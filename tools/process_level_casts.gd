extends SceneTree

const CAST_SHEETS := [
	{
		"source": "res://source_art/level_01_cast.png",
		"sections": 7,
		"characters": [
			{"section": 0, "overworld_path": "res://assets/level_01/sprites/npc_lantern_woman_idle.png", "overworld_size": Vector2i(36, 52)},
			{"section": 1, "overworld_path": "res://assets/level_01/sprites/npc_boathouse_woman_idle.png", "overworld_size": Vector2i(38, 54)},
			{"section": 2, "overworld_path": "res://assets/level_01/sprites/npc_raincoat_woman_idle.png", "overworld_size": Vector2i(36, 54)},
			{"section": 3, "overworld_path": "res://assets/level_01/sprites/npc_radio_woman_idle.png", "overworld_size": Vector2i(36, 52)},
			{"section": 4, "overworld_path": "res://assets/level_01/sprites/npc_dock_woman_idle.png", "overworld_size": Vector2i(38, 54)},
			{
				"section": 5,
				"overworld_path": "res://assets/level_01/sprites/boss_poojan_overworld.png",
				"overworld_size": Vector2i(42, 60),
				"boss_prefix": "res://assets/level_01/sprites/boss_poojan",
				"battle_size": Vector2i(70, 84)
			},
			{
				"section": 6,
				"overworld_path": "res://assets/level_01/sprites/boss_satyaki_tirumal_overworld.png",
				"overworld_size": Vector2i(44, 62),
				"boss_prefix": "res://assets/level_01/sprites/boss_satyaki_tirumal",
				"battle_size": Vector2i(76, 90)
			}
		]
	},
	{
		"source": "res://source_art/level_02_cast.png",
		"sections": 3,
		"characters": [
			{
				"section": 0,
				"overworld_path": "res://assets/level_02/sprites/npc_happy_monkey_idle.png",
				"overworld_size": Vector2i(32, 40)
			},
			{
				"section": 1,
				"overworld_path": "res://assets/level_02/sprites/boss_nitin_overworld.png",
				"overworld_size": Vector2i(38, 54),
				"boss_prefix": "res://assets/level_02/sprites/boss_nitin",
				"battle_size": Vector2i(60, 70)
			},
			{
				"section": 2,
				"overworld_path": "res://assets/level_02/sprites/boss_deepak_reddy_overworld.png",
				"overworld_size": Vector2i(42, 58),
				"boss_prefix": "res://assets/level_02/sprites/boss_deepak_reddy",
				"battle_size": Vector2i(66, 76)
			}
		]
	},
	{
		"source": "res://source_art/level_03_cast.png",
		"sections": 6,
		"characters": [
			{
				"section": 0,
				"overworld_path": "res://assets/level_03/sprites/npc_fir_grandmother_idle.png",
				"overworld_size": Vector2i(34, 50)
			},
			{
				"section": 1,
				"overworld_path": "res://assets/level_03/sprites/npc_berry_picker_idle.png",
				"overworld_size": Vector2i(32, 46)
			},
			{
				"section": 2,
				"overworld_path": "res://assets/level_03/sprites/npc_mist_ranger_idle.png",
				"overworld_size": Vector2i(34, 50)
			},
			{
				"section": 3,
				"overworld_path": "res://assets/level_03/sprites/boss_niggesh_nishal_overworld.png",
				"overworld_size": Vector2i(40, 56),
				"boss_prefix": "res://assets/level_03/sprites/boss_niggesh_nishal",
				"battle_size": Vector2i(64, 74)
			},
			{
				"section": 4,
				"overworld_path": "res://assets/level_03/sprites/boss_ankit_overworld.png",
				"overworld_size": Vector2i(42, 58),
				"boss_prefix": "res://assets/level_03/sprites/boss_ankit",
				"battle_size": Vector2i(68, 76)
			},
			{
				"section": 5,
				"overworld_path": "res://assets/level_03/sprites/npc_berry_apothecary_idle.png",
				"overworld_size": Vector2i(34, 50)
			}
		]
	},
	{
		"source": "res://source_art/level_04_cast.png",
		"sections": 6,
		"characters": [
			{"section": 0, "overworld_path": "res://assets/level_04/sprites/npc_pun_vendor_idle.png", "overworld_size": Vector2i(34, 48)},
			{"section": 1, "overworld_path": "res://assets/level_04/sprites/npc_clinic_receptionist_idle.png", "overworld_size": Vector2i(32, 48)},
			{"section": 2, "overworld_path": "res://assets/level_04/sprites/npc_festival_drummer_idle.png", "overworld_size": Vector2i(34, 50)},
			{"section": 3, "overworld_path": "res://assets/level_04/sprites/npc_neon_patient_idle.png", "overworld_size": Vector2i(34, 48)},
			{
				"section": 4,
				"overworld_path": "res://assets/level_04/sprites/boss_doctor_sushan_overworld.png",
				"overworld_size": Vector2i(40, 56),
				"boss_prefix": "res://assets/level_04/sprites/boss_doctor_sushan",
				"battle_size": Vector2i(64, 74)
			},
			{
				"section": 5,
				"overworld_path": "res://assets/level_04/sprites/boss_mitta_overworld.png",
				"overworld_size": Vector2i(42, 58),
				"boss_prefix": "res://assets/level_04/sprites/boss_mitta",
				"battle_size": Vector2i(68, 76)
			}
		]
	},
	{
		"source": "res://source_art/level_05_cast.png",
		"sections": 7,
		"characters": [
			{"section": 0, "overworld_path": "res://assets/level_05/sprites/npc_pub_keeper_idle.png", "overworld_size": Vector2i(36, 52)},
			{"section": 1, "overworld_path": "res://assets/level_05/sprites/npc_pink_hooligan_idle.png", "overworld_size": Vector2i(36, 52)},
			{"section": 2, "overworld_path": "res://assets/level_05/sprites/npc_bike_mechanic_idle.png", "overworld_size": Vector2i(38, 54)},
			{"section": 3, "overworld_path": "res://assets/level_05/sprites/npc_ruin_vendor_idle.png", "overworld_size": Vector2i(38, 54)},
			{
				"section": 4,
				"overworld_path": "res://assets/level_05/sprites/boss_suhas_overworld.png",
				"overworld_size": Vector2i(42, 60),
				"boss_prefix": "res://assets/level_05/sprites/boss_suhas",
				"battle_size": Vector2i(76, 92)
			},
			{
				"section": 5,
				"overworld_path": "res://assets/level_05/sprites/boss_srmt_overworld.png",
				"overworld_size": Vector2i(48, 68),
				"boss_prefix": "res://assets/level_05/sprites/boss_srmt",
				"battle_size": Vector2i(112, 128)
			},
			{"section": 6, "overworld_path": "res://assets/level_05/sprites/npc_ishiyoga_idle.png", "overworld_size": Vector2i(44, 64)}
		]
	}
]

const BOSS_ANIMATIONS := {
	"intro": 6,
	"idle": 4,
	"talk": 4,
	"attack": 4,
	"hurt": 2,
	"defeat": 6
}


func _init() -> void:
	call_deferred("_process_casts")


func _process_casts() -> void:
	var processed := 0
	for cast_sheet in CAST_SHEETS:
		var source_path := str(cast_sheet["source"])
		var absolute_path := ProjectSettings.globalize_path(source_path)
		if not FileAccess.file_exists(absolute_path):
			continue
		var source := Image.load_from_file(absolute_path)
		if source == null or source.is_empty():
			push_error("Could not load cast source: %s" % source_path)
			quit(1)
		var section_count := int(cast_sheet["sections"])
		for character in cast_sheet["characters"]:
			var section := int(character["section"])
			var overworld_size: Vector2i = character["overworld_size"]
			var overworld := _extract_character(source, section, section_count, overworld_size)
			if overworld == null or overworld.is_empty():
				push_error("Could not extract section %d from %s" % [section, source_path])
				quit(1)
			_save_image(overworld, str(character["overworld_path"]))
			if character.has("boss_prefix"):
				var battle_size: Vector2i = character["battle_size"]
				var battle_pose := _extract_character(source, section, section_count, battle_size)
				for animation_name in BOSS_ANIMATIONS.keys():
					_write_boss_animation(
						battle_pose,
						"%s_%s.png" % [str(character["boss_prefix"]), str(animation_name)],
						str(animation_name),
						int(BOSS_ANIMATIONS[animation_name])
					)
			processed += 1
	print("PASS: processed %d authored level-cast sprites" % processed)
	quit(0)


func _extract_character(source: Image, section: int, section_count: int, canvas_size: Vector2i) -> Image:
	var section_width := int(source.get_width() / section_count)
	var search_rect := Rect2i(section * section_width, 0, section_width, source.get_height())
	var bounds := _alpha_bounds(source, search_rect)
	if bounds.size.x <= 0 or bounds.size.y <= 0:
		return null
	var crop := source.get_region(bounds)
	var fit_scale := minf(
		float(canvas_size.x - 4) / float(crop.get_width()),
		float(canvas_size.y - 4) / float(crop.get_height())
	)
	var target_size := Vector2i(
		maxi(1, int(round(crop.get_width() * fit_scale))),
		maxi(1, int(round(crop.get_height() * fit_scale)))
	)
	crop.resize(target_size.x, target_size.y, Image.INTERPOLATE_NEAREST)
	_harden_alpha(crop)
	var result := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	result.fill(Color(0, 0, 0, 0))
	var destination := Vector2i(
		int((canvas_size.x - target_size.x) / 2),
		canvas_size.y - target_size.y - 2
	)
	result.blend_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), destination)
	return result


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


func _write_boss_animation(pose: Image, output_path: String, animation_name: String, frame_count: int) -> void:
	var size := pose.get_size()
	var sheet := Image.create(size.x * frame_count, size.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for frame in range(frame_count):
		var rendered := _render_boss_frame(pose, animation_name, frame)
		sheet.blend_rect(rendered, Rect2i(Vector2i.ZERO, size), Vector2i(frame * size.x, 0))
	_save_image(sheet, output_path)


func _render_boss_frame(pose: Image, animation_name: String, frame: int) -> Image:
	var result := Image.create(pose.get_width(), pose.get_height(), false, Image.FORMAT_RGBA8)
	result.fill(Color(0, 0, 0, 0))
	var offset := Vector2i.ZERO
	match animation_name:
		"intro":
			offset.y = [5, 3, 2, 1, 0, 0][frame % 6]
		"idle":
			offset.y = [0, -1, 0, 1][frame % 4]
		"talk":
			offset.y = [0, 0, -1, 0][frame % 4]
		"attack":
			offset.x = [0, 2, 4, 1][frame % 4]
		"hurt":
			offset.x = -2 if frame == 0 else 2
		"defeat":
			offset.y = [0, 1, 3, 5, 8, 11][frame % 6]
	result.blend_rect(pose, pose.get_used_rect(), pose.get_used_rect().position + offset)
	if animation_name == "hurt":
		_tint(result, Color("ff6670"), 0.42)
	if animation_name == "defeat":
		_fade(result, 1.0 - float(frame) * 0.13)
	return result


func _tint(image: Image, tint: Color, amount: float) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a > 0.0:
				image.set_pixel(x, y, color.lerp(Color(tint.r, tint.g, tint.b, color.a), amount))


func _fade(image: Image, opacity: float) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a > 0.0:
				color.a *= opacity
				image.set_pixel(x, y, color)


func _save_image(image: Image, resource_path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(resource_path.get_base_dir()))
	var error := image.save_png(ProjectSettings.globalize_path(resource_path))
	if error != OK:
		push_error("Could not save level-cast sprite: %s" % resource_path)
