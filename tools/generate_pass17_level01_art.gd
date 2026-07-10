extends SceneTree

const OUTLINE := Color("#08090d")
const INK := Color("#111018")
const HARBOUR_SKY := Color("#0e1b24")
const HARBOUR_WET := Color("#182835")
const HARBOUR_PLANK := Color("#3b2e2d")
const HARBOUR_PLANK_DARK := Color("#21191b")
const PAPER := Color("#f0e7d0")
const PAPER_SHADOW := Color("#d8c7a3")
const RED := Color("#7b2e3a")
const YELLOW := Color("#d8a734")
const TEAL := Color("#355060")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_ensure_dir("res://assets/level_01/sprites/")
	_ensure_dir("res://assets/level_01/tilesets/")
	_save_harbour_backplate()
	_save_fake_chicken_storefront()
	_save_sheriff_office()
	_save_dock_route()
	_save_save_notice()
	_save_divorce_records()
	_save_kfc_door()
	_save_pantry_tag()
	_save_resident()
	_save_shelf_echo()
	_save_poojan()
	_save_satyaki()
	_save_rain_overlay()
	print("Generated Pass 17 Divorcee Harbour art")
	quit(0)


func _save_harbour_backplate() -> void:
	var image := Image.create(320, 180, false, Image.FORMAT_RGBA8)
	image.fill(HARBOUR_SKY)
	_rect(image, Rect2i(0, 0, 320, 180), HARBOUR_SKY)
	for y in range(0, 88):
		var shade := float(y) / 88.0
		_rect(image, Rect2i(0, y, 320, 1), HARBOUR_SKY.lerp(Color("#172b36"), shade))
	_rect(image, Rect2i(0, 86, 320, 34), Color("#122531"))
	for wave_y in range(90, 118, 7):
		for x in range((wave_y * 3) % 14, 320, 28):
			_rect(image, Rect2i(x, wave_y, 16, 1), Color("#3f6472"))
	_rect(image, Rect2i(0, 24, 320, 88), HARBOUR_WET)
	for y in range(32, 112, 16):
		_rect(image, Rect2i(0, y, 320, 1), Color("#203746"))
	for x in range(16, 320, 32):
		_rect(image, Rect2i(x, 24, 1, 88), Color("#243c4a"))
	_rect(image, Rect2i(0, 112, 320, 54), HARBOUR_PLANK_DARK)
	for y in range(114, 164, 9):
		_rect(image, Rect2i(0, y, 320, 2), HARBOUR_PLANK)
	for x in range(8, 320, 24):
		_rect(image, Rect2i(x, 113, 2, 52), Color("#4a3934"))
		for nail_y in range(120, 160, 18):
			_rect(image, Rect2i(x + 8, nail_y, 2, 2), Color("#140f10"))
	_rect(image, Rect2i(0, 164, 320, 16), Color("#071019"))
	_draw_distant_building(image, 9, 38, 48, 48, RED.darkened(0.25), "MOTEL")
	_draw_distant_building(image, 105, 42, 46, 44, Color("#273a44"), "PIER")
	_draw_distant_building(image, 246, 38, 56, 48, Color("#262f3a"), "EXIT")
	_draw_sign(image, Vector2i(116, 9), "DIVORCEE", Color("#1a2934"), PAPER)
	_draw_sign(image, Vector2i(121, 19), "HARBOUR", Color("#1a2934"), PAPER_SHADOW)
	for x in range(7, 318, 23):
		_rect(image, Rect2i(x, 27 + (x % 3), 1, 13), Color("#91b9c4").darkened(0.15))
	image.save_png("res://assets/level_01/tilesets/tiles_divorcee_harbour_ground.png")


func _save_fake_chicken_storefront() -> void:
	var image := Image.create(96, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_rect(image, Rect2i(9, 19, 62, 38), OUTLINE)
	_rect(image, Rect2i(12, 22, 56, 32), Color("#6b4b42"))
	_rect(image, Rect2i(7, 16, 66, 8), Color("#2a1d1d"))
	_rect(image, Rect2i(10, 13, 60, 10), RED)
	_pixel_text(image, "NOT", Vector2i(18, 16), Color("#ffd86a"), 1)
	_pixel_text(image, "KFC", Vector2i(44, 16), Color("#ffd86a"), 1)
	_rect(image, Rect2i(34, 30, 17, 24), OUTLINE)
	_rect(image, Rect2i(36, 32, 13, 22), Color("#9d2e2a"))
	_rect(image, Rect2i(47, 42, 2, 2), YELLOW)
	_rect(image, Rect2i(14, 29, 14, 9), Color("#203746"))
	_rect(image, Rect2i(53, 29, 12, 9), Color("#203746"))
	for p in [Vector2i(68, 27), Vector2i(74, 34), Vector2i(79, 45), Vector2i(17, 56), Vector2i(61, 58)]:
		_rubble(image, p)
	_line(image, Vector2i(14, 24), Vector2i(31, 41), Color("#261b1b"))
	_line(image, Vector2i(61, 24), Vector2i(50, 46), Color("#261b1b"))
	image.save_png("res://assets/level_01/sprites/prop_fake_chicken_storefront.png")


func _save_sheriff_office() -> void:
	var image := Image.create(72, 52, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_rect(image, Rect2i(6, 15, 60, 31), OUTLINE)
	_rect(image, Rect2i(9, 18, 54, 25), Color("#314253"))
	_rect(image, Rect2i(3, 10, 66, 9), OUTLINE)
	_rect(image, Rect2i(6, 12, 60, 5), Color("#5d4533"))
	_pixel_text(image, "SHERIFF", Vector2i(15, 13), PAPER, 1)
	_rect(image, Rect2i(30, 25, 13, 18), Color("#18222b"))
	_star(image, Vector2i(37, 31), YELLOW)
	_rect(image, Rect2i(14, 24, 10, 8), Color("#7aa2ad"))
	_rect(image, Rect2i(49, 24, 10, 8), Color("#7aa2ad"))
	image.save_png("res://assets/level_01/sprites/prop_sheriff_office.png")


func _save_dock_route() -> void:
	var image := Image.create(96, 44, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_rect(image, Rect2i(1, 9, 94, 27), OUTLINE)
	for x in range(4, 92, 12):
		_rect(image, Rect2i(x, 12, 10, 21), HARBOUR_PLANK)
		_rect(image, Rect2i(x + 9, 12, 1, 21), HARBOUR_PLANK_DARK)
	_rect(image, Rect2i(0, 8, 96, 3), Color("#5c4639"))
	_rect(image, Rect2i(0, 35, 96, 3), Color("#5c4639"))
	_pixel_text(image, "SATYAKI", Vector2i(29, 2), PAPER, 1)
	_line(image, Vector2i(76, 18), Vector2i(88, 22), YELLOW)
	_line(image, Vector2i(88, 22), Vector2i(76, 28), YELLOW)
	image.save_png("res://assets/level_01/sprites/prop_dock_route.png")


func _save_save_notice() -> void:
	var image := Image.create(24, 28, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_rect(image, Rect2i(10, 16, 4, 10), OUTLINE)
	_rect(image, Rect2i(11, 16, 2, 10), Color("#5c4639"))
	_rect(image, Rect2i(2, 4, 20, 14), OUTLINE)
	_rect(image, Rect2i(4, 6, 16, 10), Color("#2d5062"))
	_pixel_text(image, "SAVE", Vector2i(5, 8), Color("#8fe7ff"), 1)
	_rect(image, Rect2i(1, 2, 22, 2), Color("#8fe7ff").darkened(0.1))
	image.save_png("res://assets/level_01/sprites/prop_save_notice.png")


func _save_divorce_records() -> void:
	var image := Image.create(32, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_rect(image, Rect2i(5, 5, 20, 14), OUTLINE)
	_rect(image, Rect2i(7, 7, 18, 12), PAPER)
	_rect(image, Rect2i(10, 3, 20, 14), OUTLINE)
	_rect(image, Rect2i(12, 5, 16, 12), PAPER_SHADOW)
	_pixel_text(image, "DIV", Vector2i(14, 8), RED, 1)
	_rect(image, Rect2i(14, 14, 11, 1), Color("#745e50"))
	image.save_png("res://assets/level_01/sprites/prop_divorce_records.png")


func _save_kfc_door() -> void:
	var image := Image.create(28, 36, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_rect(image, Rect2i(4, 3, 20, 30), OUTLINE)
	_rect(image, Rect2i(6, 5, 16, 26), RED)
	_rect(image, Rect2i(8, 7, 12, 7), Color("#3b1a1e"))
	_pixel_text(image, "NO", Vector2i(10, 9), PAPER, 1)
	_rect(image, Rect2i(19, 19, 2, 2), YELLOW)
	_rect(image, Rect2i(2, 31, 24, 3), Color("#4e332e"))
	image.save_png("res://assets/level_01/sprites/prop_kfc_door.png")


func _save_pantry_tag() -> void:
	var image := Image.create(18, 12, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_rect(image, Rect2i(1, 2, 16, 8), OUTLINE)
	_rect(image, Rect2i(2, 3, 14, 6), YELLOW)
	_rect(image, Rect2i(4, 5, 10, 1), Color("#6d5422"))
	image.save_png("res://assets/level_01/sprites/prop_pantry_tag.png")


func _save_resident() -> void:
	var image := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_character_body(image, Vector2i(8, 21), Color("#a85d79"), Color("#f2c6aa"), Color("#3a1f29"))
	_rect(image, Rect2i(2, 8, 12, 3), Color("#e7d6b4"))
	_rect(image, Rect2i(3, 13, 10, 2), Color("#5f3548"))
	image.save_png("res://assets/level_01/sprites/npc_divorcee_resident_idle.png")


func _save_shelf_echo() -> void:
	var image := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_character_body(image, Vector2i(8, 21), Color("#786b56"), Color("#d2c29c"), Color("#2a2420"))
	_rect(image, Rect2i(2, 7, 12, 9), Color("#5b4535").lightened(0.1))
	_rect(image, Rect2i(3, 9, 10, 1), PAPER_SHADOW)
	_rect(image, Rect2i(3, 13, 10, 1), PAPER_SHADOW)
	image.save_png("res://assets/level_01/sprites/npc_shelf_echo_idle.png")


func _save_poojan() -> void:
	var image := Image.create(24, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_character_body(image, Vector2i(12, 29), Color("#2d4d68"), Color("#bc8c69"), Color("#111018"), 14, 18)
	_rect(image, Rect2i(5, 4, 14, 4), OUTLINE)
	_rect(image, Rect2i(7, 2, 10, 5), Color("#4c3829"))
	_star(image, Vector2i(12, 17), YELLOW)
	_rect(image, Rect2i(18, 18, 5, 2), Color("#c8c8c8"))
	image.save_png("res://assets/level_01/sprites/boss_poojan_overworld.png")


func _save_satyaki() -> void:
	var image := Image.create(32, 40, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_character_body(image, Vector2i(16, 37), Color("#5b4638"), Color("#c18f6e"), Color("#111018"), 18, 24)
	_rect(image, Rect2i(8, 14, 16, 4), Color("#ded6bc"))
	_rect(image, Rect2i(14, 14, 4, 18), Color("#7b2e3a"))
	_rect(image, Rect2i(4, 19, 8, 6), PAPER)
	_rect(image, Rect2i(21, 22, 8, 6), PAPER_SHADOW)
	_pixel_text(image, "$", Vector2i(13, 4), YELLOW, 1)
	image.save_png("res://assets/level_01/sprites/boss_satyaki_tirumal_overworld.png")


func _save_rain_overlay() -> void:
	var image := Image.create(320, 180, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for x in range(-20, 340, 11):
		for y in range(-20, 200, 18):
			var start := Vector2i(x + (y % 4), y)
			_line(image, start, start + Vector2i(4, 10), Color(0.62, 0.82, 0.9, 0.35))
	image.save_png("res://assets/level_01/sprites/fx_level01_rain_sheet.png")


func _draw_distant_building(image: Image, x: int, y: int, width: int, height: int, color: Color, label: String) -> void:
	_rect(image, Rect2i(x, y, width, height), OUTLINE)
	_rect(image, Rect2i(x + 2, y + 2, width - 4, height - 4), color)
	for wx in range(x + 7, x + width - 8, 14):
		_rect(image, Rect2i(wx, y + 18, 6, 7), Color("#d8c7a3").darkened(0.25))
	_pixel_text(image, label, Vector2i(x + 5, y + 6), PAPER_SHADOW, 1)


func _draw_sign(image: Image, position: Vector2i, text: String, bg: Color, fg: Color) -> void:
	var width := text.length() * 4 + 4
	_rect(image, Rect2i(position.x - 2, position.y - 2, width + 4, 9), OUTLINE)
	_rect(image, Rect2i(position.x, position.y, width, 5), bg)
	_pixel_text(image, text, position + Vector2i(2, 0), fg, 1)


func _character_body(image: Image, feet: Vector2i, coat: Color, skin: Color, hair: Color, body_w: int = 10, body_h: int = 14) -> void:
	var cx := feet.x
	var ground := feet.y
	_rect(image, Rect2i(cx - body_w / 2 - 1, ground - body_h - 1, body_w + 2, body_h + 2), OUTLINE)
	_rect(image, Rect2i(cx - body_w / 2, ground - body_h, body_w, body_h), coat)
	_rect(image, Rect2i(cx - 4, ground - body_h - 7, 8, 7), OUTLINE)
	_rect(image, Rect2i(cx - 3, ground - body_h - 6, 6, 6), skin)
	_rect(image, Rect2i(cx - 5, ground - body_h - 8, 10, 4), hair)
	_rect(image, Rect2i(cx - body_w / 2, ground - 2, 4, 3), OUTLINE)
	_rect(image, Rect2i(cx + body_w / 2 - 4, ground - 2, 4, 3), OUTLINE)


func _star(image: Image, center: Vector2i, color: Color) -> void:
	_rect(image, Rect2i(center.x, center.y - 3, 1, 7), color)
	_rect(image, Rect2i(center.x - 3, center.y, 7, 1), color)
	_rect(image, Rect2i(center.x - 1, center.y - 1, 3, 3), color.lightened(0.15))


func _rubble(image: Image, p: Vector2i) -> void:
	_rect(image, Rect2i(p.x, p.y, 5, 3), OUTLINE)
	_rect(image, Rect2i(p.x + 1, p.y, 3, 2), Color("#8a6350"))


func _pixel_text(image: Image, text: String, position: Vector2i, color: Color, scale: int = 1) -> void:
	var cursor_x := position.x
	for i in range(text.length()):
		var letter := text.substr(i, 1).to_upper()
		if letter == " ":
			cursor_x += 4 * scale
			continue
		var glyph := _glyph(letter)
		for row in range(glyph.size()):
			var row_text := glyph[row]
			for col in range(row_text.length()):
				if row_text.substr(col, 1) == "1":
					_rect(image, Rect2i(cursor_x + col * scale, position.y + row * scale, scale, scale), color)
		cursor_x += 4 * scale


func _glyph(letter: String) -> PackedStringArray:
	match letter:
		"A": return PackedStringArray(["010", "101", "111", "101", "101"])
		"B": return PackedStringArray(["110", "101", "110", "101", "110"])
		"C": return PackedStringArray(["111", "100", "100", "100", "111"])
		"D": return PackedStringArray(["110", "101", "101", "101", "110"])
		"E": return PackedStringArray(["111", "100", "110", "100", "111"])
		"F": return PackedStringArray(["111", "100", "110", "100", "100"])
		"G": return PackedStringArray(["111", "100", "101", "101", "111"])
		"H": return PackedStringArray(["101", "101", "111", "101", "101"])
		"I": return PackedStringArray(["111", "010", "010", "010", "111"])
		"J": return PackedStringArray(["001", "001", "001", "101", "111"])
		"K": return PackedStringArray(["101", "101", "110", "101", "101"])
		"L": return PackedStringArray(["100", "100", "100", "100", "111"])
		"M": return PackedStringArray(["101", "111", "111", "101", "101"])
		"N": return PackedStringArray(["101", "111", "111", "111", "101"])
		"O": return PackedStringArray(["111", "101", "101", "101", "111"])
		"P": return PackedStringArray(["111", "101", "111", "100", "100"])
		"Q": return PackedStringArray(["111", "101", "101", "111", "001"])
		"R": return PackedStringArray(["110", "101", "110", "101", "101"])
		"S": return PackedStringArray(["111", "100", "111", "001", "111"])
		"T": return PackedStringArray(["111", "010", "010", "010", "010"])
		"U": return PackedStringArray(["101", "101", "101", "101", "111"])
		"V": return PackedStringArray(["101", "101", "101", "101", "010"])
		"W": return PackedStringArray(["101", "101", "111", "111", "101"])
		"X": return PackedStringArray(["101", "101", "010", "101", "101"])
		"Y": return PackedStringArray(["101", "101", "010", "010", "010"])
		"Z": return PackedStringArray(["111", "001", "010", "100", "111"])
		"$": return PackedStringArray(["111", "110", "111", "011", "111"])
		_:
			return PackedStringArray(["111", "101", "001", "000", "001"])


func _line(image: Image, start: Vector2i, end: Vector2i, color: Color) -> void:
	var x0: int = start.x
	var y0: int = start.y
	var x1: int = end.x
	var y1: int = end.y
	var dx: int = abs(x1 - x0)
	var sx: int = 1 if x0 < x1 else -1
	var dy: int = -abs(y1 - y0)
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy
	while true:
		_set_pixel_safe(image, x0, y0, color)
		if x0 == x1 and y0 == y1:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


func _rect(image: Image, rect: Rect2i, color: Color) -> void:
	var x_start: int = clamp(rect.position.x, 0, image.get_width())
	var y_start: int = clamp(rect.position.y, 0, image.get_height())
	var x_end: int = clamp(rect.position.x + rect.size.x, 0, image.get_width())
	var y_end: int = clamp(rect.position.y + rect.size.y, 0, image.get_height())
	for y in range(y_start, y_end):
		for x in range(x_start, x_end):
			image.set_pixel(x, y, color)


func _set_pixel_safe(image: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return
	image.set_pixel(x, y, color)


func _ensure_dir(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
