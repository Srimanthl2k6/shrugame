extends SceneTree

const OUTLINE := Color("#08090d")
const INK := Color("#111018")
const SKY := Color("#0e1b24")
const WET := Color("#182835")
const PAPER := Color("#f0e7d0")
const PAPER_SHADOW := Color("#d8c7a3")
const RED := Color("#7b2e3a")
const GOLD := Color("#d8a734")
const STEEL := Color("#8aa2ad")
const BLUE := Color("#355060")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_ensure_dir("res://assets/level_01/sprites/")
	_save_battle_backdrop()
	_save_poojan_battle()
	_save_satyaki_battle()
	_save_badge_bullet()
	_save_legal_paper_bullet()
	_save_broken_ring_bullet()
	print("Generated Pass 20 Level 1 battle art")
	quit(0)


func _save_battle_backdrop() -> void:
	var image := Image.create(320, 180, false, Image.FORMAT_RGBA8)
	image.fill(SKY)
	for y in range(0, 180):
		_rect(image, Rect2i(0, y, 320, 1), SKY.lerp(Color("#172b36"), float(y) / 180.0))
	_rect(image, Rect2i(0, 114, 320, 66), Color("#0b1119"))
	_rect(image, Rect2i(64, 16, 192, 42), OUTLINE)
	_rect(image, Rect2i(68, 19, 184, 36), Color("#1d2f3c"))
	_pixel_text(image, "DIVORCEE HARBOUR COURT", Vector2i(85, 27), PAPER, 1)
	_pixel_text(image, "NO KFC FOUND", Vector2i(119, 41), RED.lightened(0.35), 1)
	for x in range(28, 320, 38):
		_rect(image, Rect2i(x, 70, 26, 42), OUTLINE)
		_rect(image, Rect2i(x + 2, 72, 22, 38), Color("#253743"))
		_rect(image, Rect2i(x + 7, 82, 12, 8), Color("#6f8e98"))
	for x in range(0, 320, 16):
		_rect(image, Rect2i(x, 132, 14, 4), Color("#3b2e2d"))
		_rect(image, Rect2i(x + 13, 132, 1, 38), Color("#21191b"))
	for y in range(136, 174, 10):
		_rect(image, Rect2i(0, y, 320, 2), Color("#4a3934"))
	for x in range(4, 318, 25):
		_line(image, Vector2i(x, 0), Vector2i(x + 5, 18), Color(0.62, 0.82, 0.9, 0.3))
	_rect(image, Rect2i(78, 60, 164, 100), Color(0.02, 0.025, 0.035, 0.28))
	image.save_png("res://assets/level_01/sprites/battle_bg_divorcee_harbour.png")


func _save_poojan_battle() -> void:
	var image := Image.create(72, 72, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_character_body(image, Vector2i(36, 66), Color("#2d4d68"), Color("#bc8c69"), Color("#111018"), 30, 42)
	_rect(image, Rect2i(19, 13, 34, 8), OUTLINE)
	_rect(image, Rect2i(24, 8, 24, 11), Color("#4c3829"))
	_star(image, Vector2i(36, 40), GOLD, 2)
	_rect(image, Rect2i(51, 41, 15, 4), STEEL)
	_rect(image, Rect2i(61, 38, 6, 5), OUTLINE)
	_pixel_text(image, "POOJAN", Vector2i(24, 1), PAPER, 1)
	image.save_png("res://assets/level_01/sprites/battle_poojan_strength_test.png")


func _save_satyaki_battle() -> void:
	var image := Image.create(88, 80, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_character_body(image, Vector2i(44, 74), Color("#5b4638"), Color("#c18f6e"), Color("#111018"), 34, 48)
	_rect(image, Rect2i(27, 31, 34, 7), PAPER)
	_rect(image, Rect2i(40, 31, 8, 33), RED)
	_rect(image, Rect2i(6, 38, 24, 16), OUTLINE)
	_rect(image, Rect2i(8, 40, 20, 12), PAPER)
	_pixel_text(image, "DIV", Vector2i(12, 43), RED, 1)
	_rect(image, Rect2i(60, 43, 22, 14), OUTLINE)
	_rect(image, Rect2i(62, 45, 18, 10), PAPER_SHADOW)
	_pixel_text(image, "DEED", Vector2i(63, 48), RED, 1)
	_pixel_text(image, "$", Vector2i(42, 4), GOLD, 2)
	_pixel_text(image, "SATYAKI", Vector2i(29, 14), PAPER, 1)
	image.save_png("res://assets/level_01/sprites/battle_satyaki_tirumal.png")


func _save_badge_bullet() -> void:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_star(image, Vector2i(8, 8), GOLD, 2)
	_rect(image, Rect2i(7, 7, 2, 2), PAPER)
	image.save_png("res://assets/level_01/sprites/bullet_badge_warning.png")


func _save_legal_paper_bullet() -> void:
	var image := Image.create(18, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_rect(image, Rect2i(3, 2, 12, 12), OUTLINE)
	_rect(image, Rect2i(4, 3, 10, 10), PAPER)
	_rect(image, Rect2i(6, 5, 6, 1), RED)
	_rect(image, Rect2i(6, 8, 5, 1), BLUE)
	_rect(image, Rect2i(6, 11, 7, 1), BLUE.darkened(0.15))
	image.save_png("res://assets/level_01/sprites/bullet_legal_paper.png")


func _save_broken_ring_bullet() -> void:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for p in [Vector2i(6, 3), Vector2i(9, 3), Vector2i(4, 5), Vector2i(11, 5), Vector2i(3, 8), Vector2i(12, 8), Vector2i(5, 11), Vector2i(10, 11)]:
		_rect(image, Rect2i(p.x, p.y, 2, 2), GOLD)
	_rect(image, Rect2i(8, 7, 3, 2), Color(0, 0, 0, 0))
	_rect(image, Rect2i(11, 4, 2, 2), RED)
	image.save_png("res://assets/level_01/sprites/bullet_broken_ring.png")


func _character_body(image: Image, feet: Vector2i, coat: Color, skin: Color, hair: Color, body_w: int, body_h: int) -> void:
	var cx := feet.x
	var ground := feet.y
	_rect(image, Rect2i(cx - body_w / 2 - 2, ground - body_h - 2, body_w + 4, body_h + 4), OUTLINE)
	_rect(image, Rect2i(cx - body_w / 2, ground - body_h, body_w, body_h), coat)
	_rect(image, Rect2i(cx - 9, ground - body_h - 15, 18, 15), OUTLINE)
	_rect(image, Rect2i(cx - 7, ground - body_h - 13, 14, 13), skin)
	_rect(image, Rect2i(cx - 11, ground - body_h - 17, 22, 7), hair)
	_rect(image, Rect2i(cx - body_w / 2 + 3, ground - 4, 8, 5), OUTLINE)
	_rect(image, Rect2i(cx + body_w / 2 - 11, ground - 4, 8, 5), OUTLINE)


func _star(image: Image, center: Vector2i, color: Color, scale: int = 1) -> void:
	_rect(image, Rect2i(center.x - scale / 2, center.y - 4 * scale, scale, 9 * scale), OUTLINE)
	_rect(image, Rect2i(center.x - 4 * scale, center.y - scale / 2, 9 * scale, scale), OUTLINE)
	_rect(image, Rect2i(center.x - scale / 2, center.y - 3 * scale, scale, 7 * scale), color)
	_rect(image, Rect2i(center.x - 3 * scale, center.y - scale / 2, 7 * scale, scale), color)
	_rect(image, Rect2i(center.x - scale, center.y - scale, 3 * scale, 3 * scale), color.lightened(0.18))


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
		"K": return PackedStringArray(["101", "101", "110", "101", "101"])
		"L": return PackedStringArray(["100", "100", "100", "100", "111"])
		"M": return PackedStringArray(["101", "111", "111", "101", "101"])
		"N": return PackedStringArray(["101", "111", "111", "111", "101"])
		"O": return PackedStringArray(["111", "101", "101", "101", "111"])
		"P": return PackedStringArray(["111", "101", "111", "100", "100"])
		"R": return PackedStringArray(["110", "101", "110", "101", "101"])
		"S": return PackedStringArray(["111", "100", "111", "001", "111"])
		"T": return PackedStringArray(["111", "010", "010", "010", "010"])
		"U": return PackedStringArray(["101", "101", "101", "101", "111"])
		"V": return PackedStringArray(["101", "101", "101", "101", "010"])
		"Y": return PackedStringArray(["101", "101", "010", "010", "010"])
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
