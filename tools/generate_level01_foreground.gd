extends SceneTree

const OUTPUT := "res://assets/level_01/sprites"
const OUTLINE := Color("080a0f")
const DEEP_SHADOW := Color(0.01, 0.015, 0.025, 0.55)


func _init() -> void:
	call_deferred("_generate")


func _generate() -> void:
	_write_character("npc_divorcee_resident_idle.png", Vector2i(24, 36), "resident")
	_write_resident_variant("npc_lantern_woman_idle.png", "lantern", Color("4e6e72"), Color("79a6a5"))
	_write_resident_variant("npc_boathouse_woman_idle.png", "rope", Color("5b4c75"), Color("8a72a1"))
	_write_resident_variant("npc_raincoat_woman_idle.png", "hood", Color("9b6d24"), Color("d5a63f"))
	_write_resident_variant("npc_radio_woman_idle.png", "radio", Color("465a7d"), Color("6886a9"))
	_write_resident_variant("npc_dock_woman_idle.png", "dock", Color("3c665a"), Color("5d9683"))
	_write_character("boss_poojan_overworld.png", Vector2i(28, 42), "poojan")
	_write_character("boss_satyaki_tirumal_overworld.png", Vector2i(32, 46), "satyaki")
	_write_battle_sheet("battle_poojan_strength_test.png", "boss_poojan_overworld.png", Color("f1bc3f"))
	_write_battle_sheet("battle_satyaki_tirumal.png", "boss_satyaki_tirumal_overworld.png", Color("b94748"))
	_write_records()
	_write_save_lantern()
	print("PASS: generated Level 1 foreground pixel art")
	quit(0)


func _write_character(file_name: String, size: Vector2i, role: String) -> void:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	match role:
		"resident":
			_draw_resident(image)
		"poojan":
			_draw_poojan(image)
		"satyaki":
			_draw_satyaki(image)
	_save(image, file_name)


func _write_resident_variant(file_name: String, accessory: String, coat: Color, coat_light: Color) -> void:
	var image := Image.create(24, 36, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_draw_resident(image)
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.is_equal_approx(Color("863f6a")):
				image.set_pixel(x, y, coat)
			elif color.is_equal_approx(Color("c16694")) or color.is_equal_approx(Color("e58cb0")):
				image.set_pixel(x, y, coat_light)
	match accessory:
		"lantern":
			_rect(image, 19, 23, 5, 8, OUTLINE)
			_rect(image, 20, 24, 3, 5, Color("f2b943"))
			_pixel(image, 21, 25, Color("fff4b0"))
		"rope":
			_rect(image, 7, 1, 11, 3, OUTLINE)
			_rect(image, 8, 2, 9, 2, Color("35506d"))
			_rect(image, 18, 20, 2, 9, Color("c7a35a"))
			_pixel(image, 17, 23, Color("c7a35a"))
			_pixel(image, 17, 27, Color("c7a35a"))
		"hood":
			_rect(image, 5, 2, 16, 13, OUTLINE)
			_rect(image, 6, 3, 14, 11, coat)
			_rect(image, 8, 5, 10, 9, Color("b96d63"))
			_rect(image, 9, 5, 8, 2, Color("251923"))
		"radio":
			_rect(image, 18, 22, 6, 8, OUTLINE)
			_rect(image, 19, 23, 4, 6, Color("2c313c"))
			_rect(image, 20, 24, 2, 2, Color("e7b84a"))
			_pixel(image, 23, 20, Color("a8b7bd"))
			_pixel(image, 23, 21, Color("a8b7bd"))
		"dock":
			_rect(image, 6, 2, 14, 3, OUTLINE)
			_rect(image, 7, 3, 12, 2, Color("314d48"))
			_rect(image, 4, 29, 17, 2, coat_light)
	_save(image, file_name)


func _write_battle_sheet(file_name: String, source_file_name: String, accent: Color) -> void:
	var source_path := ProjectSettings.globalize_path("%s/%s" % [OUTPUT, source_file_name])
	var source := Image.load_from_file(source_path)
	if source == null or source.is_empty():
		push_error("Could not load %s" % source_path)
		return
	var target_height := 58
	var target_width := maxi(1, int(round(float(source.get_width()) * float(target_height) / float(source.get_height()))))
	source.resize(target_width, target_height, Image.INTERPOLATE_NEAREST)
	var frame_size := Vector2i(60, 82)
	var sheet := Image.create(frame_size.x * 4, frame_size.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for frame in 4:
		var x_offset := frame * frame_size.x + int((frame_size.x - target_width) * 0.5)
		var y_offset := 1 if frame in [0, 2] else 0
		sheet.blit_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), Vector2i(x_offset, y_offset))
		var sparkle_x := frame * frame_size.x + 43 - frame * 2
		var sparkle_y := 8 + frame * 3
		_pixel(sheet, sparkle_x, sparkle_y, accent)
		if frame == 2:
			_pixel(sheet, sparkle_x - 1, sparkle_y, Color("fff2aa"))
			_pixel(sheet, sparkle_x + 1, sparkle_y, Color("fff2aa"))
			_pixel(sheet, sparkle_x, sparkle_y - 1, Color("fff2aa"))
			_pixel(sheet, sparkle_x, sparkle_y + 1, Color("fff2aa"))
	_save(sheet, file_name)


func _draw_resident(image: Image) -> void:
	var skin := Color("b96d63")
	var skin_light := Color("e09a82")
	var hair := Color("251923")
	var coat := Color("863f6a")
	var coat_light := Color("c16694")
	var scarf := Color("f1d6b2")
	var boot := Color("2b2532")
	_rect(image, 4, 33, 16, 2, DEEP_SHADOW)
	# Boots and rain-slick hems.
	_rect(image, 7, 28, 4, 6, OUTLINE)
	_rect(image, 14, 28, 4, 6, OUTLINE)
	_rect(image, 7, 29, 3, 4, boot)
	_rect(image, 14, 29, 3, 4, boot)
	_rect(image, 6, 32, 5, 2, Color("151824"))
	_rect(image, 14, 32, 5, 2, Color("151824"))
	# Long coat with lapels and pocket details.
	_rect(image, 4, 14, 17, 17, OUTLINE)
	_rect(image, 5, 15, 15, 15, coat)
	_rect(image, 6, 15, 4, 14, coat_light)
	_rect(image, 10, 15, 5, 7, Color("54263f"))
	_rect(image, 9, 16, 2, 4, scarf)
	_rect(image, 14, 16, 2, 4, scarf)
	_rect(image, 12, 19, 1, 10, Color("edb248"))
	_pixel(image, 8, 24, Color("f0bfcf"))
	_pixel(image, 17, 24, Color("f0bfcf"))
	# Sleeves and hands.
	_rect(image, 2, 16, 4, 12, OUTLINE)
	_rect(image, 3, 17, 3, 10, coat_light)
	_rect(image, 20, 16, 3, 12, OUTLINE)
	_rect(image, 20, 17, 2, 10, coat)
	_pixel(image, 3, 28, skin_light)
	_pixel(image, 21, 28, skin)
	# Head, bob haircut, and tired expression.
	_rect(image, 7, 3, 12, 12, OUTLINE)
	_rect(image, 8, 4, 10, 10, skin)
	_rect(image, 8, 4, 10, 4, hair)
	_rect(image, 7, 6, 3, 8, hair)
	_rect(image, 17, 6, 3, 8, hair)
	_rect(image, 10, 3, 7, 2, Color("4b293f"))
	_pixel(image, 11, 9, OUTLINE)
	_pixel(image, 16, 9, OUTLINE)
	_rect(image, 12, 12, 4, 1, Color("783e4a"))
	_pixel(image, 9, 5, Color("824e72"))
	# Rain highlights.
	_pixel(image, 5, 18, Color("e58cb0"))
	_pixel(image, 6, 21, Color("e58cb0"))
	_pixel(image, 18, 17, Color("b55a86"))


func _draw_poojan(image: Image) -> void:
	var skin := Color("985536")
	var skin_light := Color("d28755")
	var uniform := Color("244b66")
	var uniform_light := Color("3c7590")
	var hat := Color("59442c")
	var gold := Color("f1bc3f")
	var boot := Color("171b22")
	_rect(image, 3, 39, 22, 2, DEEP_SHADOW)
	# Heavy boots and squared sheriff stance.
	_rect(image, 7, 31, 5, 8, OUTLINE)
	_rect(image, 16, 31, 5, 8, OUTLINE)
	_rect(image, 8, 32, 3, 6, Color("26313d"))
	_rect(image, 17, 32, 3, 6, Color("202a36"))
	_rect(image, 6, 37, 7, 3, boot)
	_rect(image, 16, 37, 7, 3, boot)
	# Uniform coat, belt, badge, radio, and shoulder piping.
	_rect(image, 4, 16, 20, 17, OUTLINE)
	_rect(image, 5, 17, 18, 15, uniform)
	_rect(image, 6, 18, 5, 12, uniform_light)
	_rect(image, 11, 17, 6, 14, Color("173247"))
	_rect(image, 5, 16, 18, 3, Color("315f79"))
	_rect(image, 5, 29, 18, 3, Color("1a1719"))
	_rect(image, 12, 29, 4, 3, gold)
	_pixel(image, 15, 21, gold)
	_pixel(image, 14, 22, gold)
	_pixel(image, 16, 22, gold)
	_pixel(image, 15, 23, gold)
	_rect(image, 6, 20, 2, 4, Color("111820"))
	# Arms; one hand rests beside a holstered revolver.
	_rect(image, 2, 18, 4, 13, OUTLINE)
	_rect(image, 3, 19, 3, 11, uniform_light)
	_rect(image, 22, 18, 4, 13, OUTLINE)
	_rect(image, 22, 19, 3, 11, uniform)
	_pixel(image, 3, 31, skin_light)
	_pixel(image, 24, 31, skin)
	_rect(image, 21, 27, 6, 4, OUTLINE)
	_rect(image, 22, 28, 4, 2, Color("a9b2b2"))
	_pixel(image, 26, 29, Color("e0d9c8"))
	# Face, moustache, and broad rain hat.
	_rect(image, 7, 5, 14, 12, OUTLINE)
	_rect(image, 8, 6, 12, 10, skin)
	_rect(image, 9, 6, 10, 3, skin_light)
	_pixel(image, 11, 10, OUTLINE)
	_pixel(image, 17, 10, OUTLINE)
	_rect(image, 11, 13, 7, 2, Color("372018"))
	_pixel(image, 10, 13, Color("372018"))
	_pixel(image, 18, 13, Color("372018"))
	_rect(image, 5, 2, 18, 4, OUTLINE)
	_rect(image, 6, 3, 16, 2, hat)
	_rect(image, 9, 0, 11, 4, OUTLINE)
	_rect(image, 10, 1, 9, 3, Color("6e5536"))
	_rect(image, 10, 3, 10, 1, gold)
	_pixel(image, 8, 3, Color("92774e"))


func _draw_satyaki(image: Image) -> void:
	var skin := Color("9d5b3f")
	var skin_light := Color("d59366")
	var suit := Color("54283a")
	var suit_light := Color("814252")
	var paper := Color("efe2bd")
	var red := Color("b94748")
	_rect(image, 3, 43, 26, 2, DEEP_SHADOW)
	# Polished shoes and long, severe suit.
	_rect(image, 8, 34, 5, 9, OUTLINE)
	_rect(image, 19, 34, 5, 9, OUTLINE)
	_rect(image, 9, 35, 3, 7, Color("29212a"))
	_rect(image, 20, 35, 3, 7, Color("241d25"))
	_rect(image, 6, 41, 8, 3, Color("0d1016"))
	_rect(image, 18, 41, 9, 3, Color("0d1016"))
	_rect(image, 5, 17, 22, 19, OUTLINE)
	_rect(image, 6, 18, 20, 17, suit)
	_rect(image, 7, 19, 6, 14, suit_light)
	_rect(image, 13, 18, 7, 16, Color("eee2d1"))
	_rect(image, 15, 19, 3, 11, red)
	_pixel(image, 16, 31, Color("f4b840"))
	_rect(image, 6, 32, 20, 3, Color("281a22"))
	# Raised legal papers and property briefcase.
	_rect(image, 1, 18, 5, 13, OUTLINE)
	_rect(image, 2, 19, 4, 11, suit_light)
	_rect(image, 0, 11, 9, 10, OUTLINE)
	_rect(image, 1, 12, 7, 8, paper)
	_rect(image, 2, 14, 5, 1, Color("83735e"))
	_rect(image, 2, 17, 4, 1, red)
	_rect(image, 26, 20, 5, 14, OUTLINE)
	_rect(image, 26, 21, 4, 12, suit)
	_rect(image, 25, 31, 7, 9, OUTLINE)
	_rect(image, 26, 32, 6, 7, Color("5b3a28"))
	_rect(image, 27, 33, 4, 1, Color("a6743f"))
	_pixel(image, 28, 35, Color("f0bc48"))
	# Slick hair and pinched expression.
	_rect(image, 9, 4, 14, 14, OUTLINE)
	_rect(image, 10, 5, 12, 12, skin)
	_rect(image, 10, 5, 12, 4, Color("1d1720"))
	_rect(image, 12, 3, 12, 4, OUTLINE)
	_rect(image, 13, 4, 10, 3, Color("302231"))
	_pixel(image, 12, 11, OUTLINE)
	_pixel(image, 19, 11, OUTLINE)
	_pixel(image, 11, 10, Color("d6ad5b"))
	_pixel(image, 20, 10, Color("d6ad5b"))
	_rect(image, 14, 15, 5, 1, Color("63343c"))
	_pixel(image, 22, 6, Color("715063"))


func _write_records() -> void:
	var image := Image.create(24, 18, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_rect(image, 2, 15, 20, 2, DEEP_SHADOW)
	_rect(image, 1, 4, 22, 12, OUTLINE)
	_rect(image, 2, 5, 20, 10, Color("c49545"))
	_rect(image, 3, 3, 8, 3, OUTLINE)
	_rect(image, 4, 4, 7, 2, Color("e3b95f"))
	_rect(image, 4, 7, 16, 6, Color("eee3c4"))
	_rect(image, 5, 8, 10, 1, Color("786a60"))
	_rect(image, 5, 10, 13, 1, Color("9b8773"))
	_rect(image, 16, 7, 4, 4, Color("9e3b4c"))
	_pixel(image, 17, 8, Color("f2a9a7"))
	_pixel(image, 18, 9, Color("f2a9a7"))
	_save(image, "prop_divorce_records.png")


func _write_save_lantern() -> void:
	var image := Image.create(18, 26, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_rect(image, 2, 23, 14, 2, DEEP_SHADOW)
	# Soft cyan halo drawn as stepped translucent pixels.
	_rect(image, 3, 4, 12, 14, Color(0.25, 0.9, 1.0, 0.12))
	_rect(image, 5, 2, 8, 18, Color(0.35, 0.95, 1.0, 0.16))
	_rect(image, 6, 4, 6, 12, OUTLINE)
	_rect(image, 7, 5, 4, 10, Color("59d4df"))
	_rect(image, 8, 6, 2, 8, Color("d8ffff"))
	_pixel(image, 9, 4, Color("ffffff"))
	_rect(image, 7, 16, 4, 6, OUTLINE)
	_rect(image, 8, 17, 2, 5, Color("a17b45"))
	_rect(image, 5, 22, 8, 2, OUTLINE)
	_pixel(image, 3, 8, Color("91ffff"))
	_pixel(image, 14, 11, Color("91ffff"))
	_pixel(image, 4, 16, Color("4ed6e8"))
	_save(image, "prop_save_notice.png")


func _save(image: Image, file_name: String) -> void:
	var path := ProjectSettings.globalize_path("%s/%s" % [OUTPUT, file_name])
	var error := image.save_png(path)
	if error != OK:
		push_error("Could not save %s" % path)


func _rect(image: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	for py in range(y, y + height):
		for px in range(x, x + width):
			if px >= 0 and py >= 0 and px < image.get_width() and py < image.get_height():
				image.set_pixel(px, py, color)


func _pixel(image: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
		image.set_pixel(x, y, color)
