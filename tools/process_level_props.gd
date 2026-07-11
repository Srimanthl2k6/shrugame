extends SceneTree

const PROP_SHEETS := [
	{
		"source": "res://source_art/level_03_props.png",
		"sections": 5,
		"props": [
			{"section": 0, "path": "res://assets/level_03/sprites/prop_berry_cluster.png", "size": Vector2i(34, 42)},
			{"section": 1, "path": "res://assets/level_03/sprites/prop_berry_contract.png", "size": Vector2i(32, 36)},
			{"section": 2, "path": "res://assets/level_03/sprites/prop_berry_share_table.png", "size": Vector2i(58, 42)},
			{"section": 3, "path": "res://assets/level_03/sprites/prop_berry_watch_save.png", "size": Vector2i(30, 42)},
			{"section": 4, "path": "res://assets/level_03/sprites/prop_auticity_exit_arch.png", "size": Vector2i(46, 54)}
		]
	},
	{
		"source": "res://source_art/level_04_props.png",
		"sections": 6,
		"props": [
			{"section": 0, "path": "res://assets/level_04/sprites/prop_pun_vendor_cart.png", "size": Vector2i(58, 46)},
			{"section": 1, "path": "res://assets/level_04/sprites/prop_hospital_records_terminal.png", "size": Vector2i(38, 46)},
			{"section": 2, "path": "res://assets/level_04/sprites/prop_pattern_serum_lab.png", "size": Vector2i(58, 44)},
			{"section": 3, "path": "res://assets/level_04/sprites/prop_aeon_stage.png", "size": Vector2i(64, 50)},
			{"section": 4, "path": "res://assets/level_04/sprites/prop_save_kiosk.png", "size": Vector2i(30, 44)},
			{"section": 5, "path": "res://assets/level_04/sprites/prop_area111_exit.png", "size": Vector2i(48, 56)}
		]
	},
	{
		"source": "res://source_art/level_05_props.png",
		"sections": 7,
		"props": [
			{"section": 0, "path": "res://assets/level_05/sprites/prop_gummies_bar.png", "size": Vector2i(110, 84)},
			{"section": 1, "path": "res://assets/level_05/sprites/prop_suhas_motorcycle.png", "size": Vector2i(104, 68)},
			{"section": 2, "path": "res://assets/level_05/sprites/prop_musical_guitar.png", "size": Vector2i(58, 86)},
			{"section": 3, "path": "res://assets/level_05/sprites/prop_mansion_clue_console.png", "size": Vector2i(94, 74)},
			{"section": 4, "path": "res://assets/level_05/sprites/prop_srmt_throne.png", "size": Vector2i(94, 112)},
			{"section": 5, "path": "res://assets/level_05/sprites/prop_kfc_dungeon_gate.png", "size": Vector2i(98, 112)},
			{"section": 6, "path": "res://assets/level_05/sprites/prop_ending_feast.png", "size": Vector2i(112, 84)}
		]
	}
]


func _init() -> void:
	call_deferred("_process_props")


func _process_props() -> void:
	var processed := 0
	for sheet_data in PROP_SHEETS:
		var source_path := str(sheet_data["source"])
		var source := Image.load_from_file(ProjectSettings.globalize_path(source_path))
		if source == null or source.is_empty():
			continue
		var section_count := int(sheet_data["sections"])
		for prop in sheet_data["props"]:
			var output := _extract_prop(source, int(prop["section"]), section_count, prop["size"])
			if output == null or output.is_empty():
				push_error("Could not extract prop section %s from %s" % [prop["section"], source_path])
				quit(1)
			var path := str(prop["path"])
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
			if output.save_png(ProjectSettings.globalize_path(path)) != OK:
				push_error("Could not save processed prop: %s" % path)
				quit(1)
			processed += 1
	print("PASS: processed %d authored level props" % processed)
	quit(0)


func _extract_prop(source: Image, section: int, section_count: int, canvas_size: Vector2i) -> Image:
	var section_width := int(source.get_width() / section_count)
	var search_rect := Rect2i(section * section_width, 0, section_width, source.get_height())
	var bounds := _alpha_bounds(source, search_rect)
	if bounds.size.x <= 0 or bounds.size.y <= 0:
		return null
	var crop := source.get_region(bounds)
	var fit_scale := minf(
		float(canvas_size.x - 2) / float(crop.get_width()),
		float(canvas_size.y - 2) / float(crop.get_height())
	)
	var target_size := Vector2i(
		maxi(1, int(round(crop.get_width() * fit_scale))),
		maxi(1, int(round(crop.get_height() * fit_scale)))
	)
	crop.resize(target_size.x, target_size.y, Image.INTERPOLATE_NEAREST)
	_harden_alpha(crop)
	var result := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	result.fill(Color(0, 0, 0, 0))
	var destination := Vector2i(int((canvas_size.x - target_size.x) / 2), canvas_size.y - target_size.y - 1)
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
