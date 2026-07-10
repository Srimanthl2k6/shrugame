extends SceneTree

const OUTLINE := Color("#08090d")
const INK := Color("#121018")
const GRASS := Color("#223b16")
const GRASS_DARK := Color("#16270f")
const ROAD := Color("#5f5831")
const ROAD_DARK := Color("#3e3a24")
const BANANA := Color("#e7c94a")
const BANANA_DARK := Color("#9f7f24")
const LAB := Color("#354240")
const LAB_DARK := Color("#182321")
const GLASS := Color("#6ff0b0")
const PINK := Color("#e05b9d")
const PAPER := Color("#efe5c4")
const BROWN := Color("#6c4224")
const SKIN := Color("#c08a5b")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_ensure_dir("res://assets/level_02/sprites/")
	_ensure_dir("res://assets/level_02/tilesets/")
	_save_backplate()
	_save_house_row()
	_save_lab()
	_save_mayor_office()
	_save_165_files()
	_save_popcorn()
	_save_mailbox()
	_save_exit_gate()
	_save_happy_monkey()
	_save_vela_echo()
	_save_nitin()
	_save_deepak()
	_save_monkey_loop_sheet()
	print("Generated Pass 28 Banana-burbs art")
	quit(0)


func _save_backplate() -> void:
	var image := Image.create(320, 180, false, Image.FORMAT_RGBA8)
	image.fill(Color("#10190f"))
	for y in range(0, 180):
		var shade := float(y) / 180.0
		_rect(image, Rect2i(0, y, 320, 1), Color("#163017").lerp(Color("#314b1c"), shade))
	_rect(image, Rect2i(10, 24, 150, 140), GRASS)
	_rect(image, Rect2i(168, 20, 140, 74), LAB_DARK)
	_rect(image, Rect2i(174, 26, 128, 62), Color("#283431"))
	_rect(image, Rect2i(172, 104, 136, 46), Color("#4d371d"))
	_rect(image, Rect2i(26, 96, 132, 54), Color("#2a4218"))
	_draw_road(image, PackedVector2Array([Vector2(36, 118), Vector2(104, 106), Vector2(132, 134), Vector2(234, 118), Vector2(278, 126), Vector2(294, 74)]))
	for x in range(20, 150, 18):
		_rect(image, Rect2i(x, 29 + (x % 4), 4, 5), BANANA.lightened(0.08))
		_rect(image, Rect2i(x + 2, 32 + (x % 4), 3, 3), BANANA_DARK)
	for x in range(186, 292, 16):
		_rect(image, Rect2i(x, 34, 8, 6), GLASS.darkened(0.25))
		_rect(image, Rect2i(x, 50, 8, 6), GLASS.darkened(0.1))
	_rect(image, Rect2i(190, 12, 92, 10), OUTLINE)
	_rect(image, Rect2i(192, 14, 88, 6), Color("#25362f"))
	_pixel_text(image, "165 FILES", Vector2i(204, 15), GLASS, 1)
	_rect(image, Rect2i(190, 104, 100, 10), OUTLINE)
	_rect(image, Rect2i(192, 106, 96, 6), Color("#73521d"))
	_pixel_text(image, "MAYOR", Vector2i(224, 107), BANANA, 1)
	image.save_png("res://assets/level_02/tilesets/tiles_banana_burbs_backplate.png")


func _save_house_row() -> void:
	var image := Image.create(128, 88, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_draw_house(image, Vector2i(8, 16), "A")
	_draw_house(image, Vector2i(52, 16), "B")
	_draw_house(image, Vector2i(8, 52), "C")
	_rect(image, Rect2i(52, 56, 60, 12), OUTLINE)
	_rect(image, Rect2i(55, 58, 54, 8), Color("#3a4f19"))
	_pixel_text(image, "TOO HAPPY", Vector2i(60, 60), BANANA, 1)
	image.save_png("res://assets/level_02/sprites/prop_banana_house_row.png")


func _save_lab() -> void:
	var image := Image.create(112, 72, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_rect(image, Rect2i(5, 18, 96, 44), OUTLINE)
	_rect(image, Rect2i(8, 21, 90, 38), LAB)
	_rect(image, Rect2i(12, 26, 34, 16), LAB_DARK)
	_rect(image, Rect2i(15, 29, 28, 10), GLASS.darkened(0.15))
	_rect(image, Rect2i(56, 26, 30, 16), LAB_DARK)
	_rect(image, Rect2i(59, 29, 24, 10), GLASS.darkened(0.35))
	_rect(image, Rect2i(36, 43, 20, 16), OUTLINE)
	_rect(image, Rect2i(39, 45, 14, 14), Color("#1c2524"))
	_rect(image, Rect2i(2, 10, 102, 12), OUTLINE)
	_rect(image, Rect2i(5, 12, 96, 8), Color("#26342d"))
	_pixel_text(image, "165 FILES", Vector2i(34, 14), GLASS, 1)
	_line(image, Vector2i(88, 14), Vector2i(108, 4), Color("#8cffc2"))
	_line(image, Vector2i(94, 18), Vector2i(110, 12), Color("#8cffc2").darkened(0.25))
	image.save_png("res://assets/level_02/sprites/prop_165_files_lab.png")


func _save_mayor_office() -> void:
	var image := Image.create(96, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_rect(image, Rect2i(6, 18, 76, 38), OUTLINE)
	_rect(image, Rect2i(9, 21, 70, 32), Color("#73521d"))
	_rect(image, Rect2i(2, 11, 84, 12), OUTLINE)
	_rect(image, Rect2i(5, 13, 78, 8), BANANA_DARK)
	_pixel_text(image, "MAYOR", Vector2i(31, 15), BANANA.lightened(0.2), 1)
	_rect(image, Rect2i(36, 32, 18, 21), OUTLINE)
	_rect(image, Rect2i(39, 34, 12, 19), Color("#312217"))
	_rect(image, Rect2i(16, 30, 12, 9), Color("#f2d65a").darkened(0.18))
	_rect(image, Rect2i(60, 30, 12, 9), Color("#f2d65a").darkened(0.18))
	_rect(image, Rect2i(76, 37, 14, 12), OUTLINE)
	_rect(image, Rect2i(78, 39, 10, 8), Color("#4b3219"))
	image.save_png("res://assets/level_02/sprites/prop_mayor_office.png")


func _save_165_files() -> void:
	var image := Image.create(32, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_rect(image, Rect2i(4, 5, 22, 15), OUTLINE)
	_rect(image, Rect2i(6, 7, 18, 11), PAPER)
	_rect(image, Rect2i(9, 3, 19, 14), OUTLINE)
	_rect(image, Rect2i(11, 5, 15, 10), Color("#cfe8d0"))
	_pixel_text(image, "165", Vector2i(12, 8), Color("#255c42"), 1)
	_rect(image, Rect2i(13, 15, 10, 1), Color("#66785d"))
	image.save_png("res://assets/level_02/sprites/prop_165_files.png")


func _save_popcorn() -> void:
	var image := Image.create(32, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_rect(image, Rect2i(7, 7, 18, 14), OUTLINE)
	_rect(image, Rect2i(9, 9, 14, 10), Color("#b52c34"))
	_rect(image, Rect2i(10, 4, 12, 6), Color("#fff0b8"))
	for p in [Vector2i(9, 4), Vector2i(13, 2), Vector2i(17, 4), Vector2i(20, 3)]:
		_rect(image, Rect2i(p.x, p.y, 4, 4), Color("#ffe188"))
	_pixel_text(image, "KFC", Vector2i(11, 11), PAPER, 1)
	image.save_png("res://assets/level_02/sprites/prop_kfc_popcorn_box.png")


func _save_mailbox() -> void:
	var image := Image.create(24, 28, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_rect(image, Rect2i(10, 16, 4, 10), OUTLINE)
	_rect(image, Rect2i(11, 16, 2, 10), BROWN)
	_rect(image, Rect2i(3, 7, 18, 12), OUTLINE)
	_rect(image, Rect2i(5, 9, 14, 8), BANANA)
	_rect(image, Rect2i(16, 11, 4, 2), Color("#f4e179"))
	_rect(image, Rect2i(2, 18, 20, 2), GRASS_DARK)
	image.save_png("res://assets/level_02/sprites/prop_banana_mailbox.png")


func _save_exit_gate() -> void:
	var image := Image.create(30, 38, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_rect(image, Rect2i(4, 5, 22, 29), OUTLINE)
	_rect(image, Rect2i(6, 7, 18, 25), Color("#2f5124"))
	_rect(image, Rect2i(8, 8, 14, 5), Color("#6cc05e"))
	_pixel_text(image, "B3", Vector2i(11, 10), Color("#e7ffd6"), 1)
	_rect(image, Rect2i(7, 18, 16, 2), BANANA)
	_rect(image, Rect2i(7, 25, 16, 2), BANANA_DARK)
	image.save_png("res://assets/level_02/sprites/prop_banana_exit_gate.png")


func _save_happy_monkey() -> void:
	var image := Image.create(18, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_monkey(image, Vector2i(9, 22), true)
	image.save_png("res://assets/level_02/sprites/npc_happy_monkey_idle.png")


func _save_vela_echo() -> void:
	var image := Image.create(18, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_character(image, Vector2i(9, 22), Color("#56a8d8"), Color("#cfefff"), Color("#20384c"))
	_rect(image, Rect2i(3, 9, 12, 3), Color("#8eeaff"))
	image.save_png("res://assets/level_02/sprites/npc_vela_echo_idle.png")


func _save_nitin() -> void:
	var image := Image.create(24, 34, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_character(image, Vector2i(12, 31), Color("#5f7780"), SKIN, Color("#1e1b18"), 14, 18)
	_rect(image, Rect2i(16, 13, 3, 18), BROWN)
	_rect(image, Rect2i(18, 27, 5, 2), Color("#c9d3c5"))
	_rect(image, Rect2i(6, 18, 8, 4), Color("#d9e8ef"))
	image.save_png("res://assets/level_02/sprites/boss_nitin_overworld.png")


func _save_deepak() -> void:
	var image := Image.create(32, 40, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_character(image, Vector2i(16, 37), Color("#c08c28"), SKIN, Color("#1c120b"), 18, 24)
	_rect(image, Rect2i(6, 7, 20, 5), OUTLINE)
	_rect(image, Rect2i(8, 4, 16, 8), BANANA)
	_rect(image, Rect2i(12, 19, 8, 4), Color("#fff2a8"))
	_rect(image, Rect2i(5, 27, 7, 4), Color("#ffe470"))
	_rect(image, Rect2i(21, 26, 7, 4), Color("#ffe470"))
	image.save_png("res://assets/level_02/sprites/boss_deepak_reddy_overworld.png")


func _save_monkey_loop_sheet() -> void:
	var image := Image.create(128, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for frame in range(4):
		var offset := Vector2i(frame * 32 + 16, 42)
		_monkey(image, offset, frame % 2 == 0, 2)
		_rect(image, Rect2i(frame * 32 + 3, 50, 26, 5), Color(0.05, 0.08, 0.04, 0.38))
	image.save_png("res://assets/level_02/sprites/fx_level02_monkey_loop_sheet.png")


func _draw_house(image: Image, pos: Vector2i, label: String) -> void:
	_rect(image, Rect2i(pos.x + 2, pos.y + 14, 34, 26), OUTLINE)
	_rect(image, Rect2i(pos.x + 5, pos.y + 17, 28, 20), BANANA_DARK)
	_rect(image, Rect2i(pos.x, pos.y + 8, 40, 9), OUTLINE)
	_rect(image, Rect2i(pos.x + 3, pos.y + 10, 34, 5), BANANA)
	_rect(image, Rect2i(pos.x + 16, pos.y + 24, 8, 13), Color("#3b2a18"))
	_rect(image, Rect2i(pos.x + 8, pos.y + 22, 6, 6), Color("#fff0a8").darkened(0.2))
	_rect(image, Rect2i(pos.x + 27, pos.y + 22, 6, 6), Color("#fff0a8").darkened(0.2))
	_pixel_text(image, label, Vector2i(pos.x + 18, pos.y + 3), Color("#fff3a3"), 1)


func _draw_road(image: Image, points: PackedVector2Array) -> void:
	for i in range(points.size() - 1):
		var start := Vector2i(int(points[i].x), int(points[i].y))
		var end := Vector2i(int(points[i + 1].x), int(points[i + 1].y))
		for offset in range(-4, 5):
			_line(image, start + Vector2i(0, offset), end + Vector2i(0, offset), ROAD_DARK)
		for offset in range(-2, 3):
			_line(image, start + Vector2i(0, offset), end + Vector2i(0, offset), ROAD)


func _monkey(image: Image, feet: Vector2i, wave: bool, scale: int = 1) -> void:
	var body := Color("#8a5128")
	var face := Color("#d49a62")
	_rect(image, Rect2i(feet.x - 5 * scale, feet.y - 12 * scale, 10 * scale, 10 * scale), OUTLINE)
	_rect(image, Rect2i(feet.x - 4 * scale, feet.y - 11 * scale, 8 * scale, 9 * scale), body)
	_rect(image, Rect2i(feet.x - 5 * scale, feet.y - 20 * scale, 10 * scale, 8 * scale), OUTLINE)
	_rect(image, Rect2i(feet.x - 4 * scale, feet.y - 19 * scale, 8 * scale, 6 * scale), body)
	_rect(image, Rect2i(feet.x - 3 * scale, feet.y - 17 * scale, 6 * scale, 4 * scale), face)
	_rect(image, Rect2i(feet.x - 8 * scale, feet.y - 18 * scale, 3 * scale, 4 * scale), body)
	_rect(image, Rect2i(feet.x + 5 * scale, feet.y - 18 * scale, 3 * scale, 4 * scale), body)
	if wave:
		_rect(image, Rect2i(feet.x + 4 * scale, feet.y - 14 * scale, 8 * scale, 2 * scale), body)
	else:
		_rect(image, Rect2i(feet.x - 12 * scale, feet.y - 14 * scale, 8 * scale, 2 * scale), body)
	_rect(image, Rect2i(feet.x - 5 * scale, feet.y - 2 * scale, 4 * scale, 3 * scale), OUTLINE)
	_rect(image, Rect2i(feet.x + 1 * scale, feet.y - 2 * scale, 4 * scale, 3 * scale), OUTLINE)
	_rect(image, Rect2i(feet.x + 5 * scale, feet.y - 8 * scale, 4 * scale, 2 * scale), body.darkened(0.25))


func _character(image: Image, feet: Vector2i, coat: Color, skin: Color, hair: Color, body_w: int = 10, body_h: int = 14) -> void:
	var cx := feet.x
	var ground := feet.y
	_rect(image, Rect2i(cx - body_w / 2 - 1, ground - body_h - 1, body_w + 2, body_h + 2), OUTLINE)
	_rect(image, Rect2i(cx - body_w / 2, ground - body_h, body_w, body_h), coat)
	_rect(image, Rect2i(cx - 4, ground - body_h - 7, 8, 7), OUTLINE)
	_rect(image, Rect2i(cx - 3, ground - body_h - 6, 6, 6), skin)
	_rect(image, Rect2i(cx - 5, ground - body_h - 8, 10, 4), hair)
	_rect(image, Rect2i(cx - body_w / 2, ground - 2, 4, 3), OUTLINE)
	_rect(image, Rect2i(cx + body_w / 2 - 4, ground - 2, 4, 3), OUTLINE)


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
		"L": return PackedStringArray(["100", "100", "110", "100", "111"])
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
		"1": return PackedStringArray(["010", "110", "010", "010", "111"])
		"2": return PackedStringArray(["111", "001", "111", "100", "111"])
		"3": return PackedStringArray(["111", "001", "111", "001", "111"])
		"4": return PackedStringArray(["101", "101", "111", "001", "001"])
		"5": return PackedStringArray(["111", "100", "111", "001", "111"])
		"6": return PackedStringArray(["111", "100", "111", "101", "111"])
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
