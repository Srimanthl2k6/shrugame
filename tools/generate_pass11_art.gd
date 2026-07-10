extends SceneTree

const SHRUBUBU_FORMS := [
	{"id": "form_01", "size": Vector2i(16, 24), "attack": "attack_unarmed.png", "accent": Color("#d8c7a3"), "gear": Color("#f0e7d0")},
	{"id": "form_02", "size": Vector2i(18, 26), "attack": "attack_revolver.png", "accent": Color("#7b2e3a"), "gear": Color("#c7c7c7")},
	{"id": "form_03", "size": Vector2i(20, 28), "attack": "attack_banana_gun.png", "accent": Color("#f0c53a"), "gear": Color("#7fb069")},
	{"id": "form_04", "size": Vector2i(24, 32), "attack": "attack_berry_potions.png", "accent": Color("#d63a5c"), "gear": Color("#8b1e3f")},
	{"id": "form_05", "size": Vector2i(28, 36), "attack": "attack_musical_guitar.png", "accent": Color("#ff78b7"), "gear": Color("#49e6ff")}
]

const LEVEL_PALETTES := {
	"level_01": [Color("#0e1b24"), Color("#355060"), Color("#7b2e3a"), Color("#d8c7a3"), Color("#f0e7d0")],
	"level_02": [Color("#1e2a18"), Color("#f0c53a"), Color("#7fb069"), Color("#ffffff"), Color("#2f5d50")],
	"level_03": [Color("#07140e"), Color("#1f4a2f"), Color("#8b1e3f"), Color("#d63a5c"), Color("#a7c8a0")],
	"level_04": [Color("#15161c"), Color("#e8e8dd"), Color("#4da3ff"), Color("#ffcf40"), Color("#e55c8a")],
	"level_05": [Color("#120d18"), Color("#ff78b7"), Color("#49e6ff"), Color("#f7d44a"), Color("#202030")]
}

const BOSS_SPECS := [
	{"level": "level_01", "bosses": ["poojan", "satyaki_tirumal"]},
	{"level": "level_02", "bosses": ["nitin", "deepak_reddy"]},
	{"level": "level_03", "bosses": ["niggesh_nishal", "ankit"]},
	{"level": "level_04", "bosses": ["doctor_sushan", "mitta"]},
	{"level": "level_05", "bosses": ["suhas", "srmt"]}
]

const BOSS_ANIMS := {
	"intro": 6,
	"idle": 4,
	"talk": 4,
	"attack": 4,
	"hurt": 2,
	"defeat": 6
}

const LEVEL_FX := {
	"level_01": {"fx": [["rain_loop", 4], ["neon_flicker", 4], ["paper_flutter", 4]]},
	"level_02": {"fx": [["monkey_loop", 2], ["lab_monitor_pulse", 4]]},
	"level_03": {"fx": [["mist_drift", 4], ["berry_glow", 4]]},
	"level_04": {"fx": [["fluorescent_buzz", 2], ["aeon_fireworks", 8]]},
	"level_05": {"fx": [["club_static", 4], ["musical_notes", 6], ["throne_reveal", 8]]}
}

const CUTINS := [
	["door_slam", 6],
	["weapon_unlocks", 6],
	["boss_intro", 6],
	["growth_transform", 8],
	["srmt_throne_reveal", 8],
	["ishiyoga_rescue", 8]
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_generate_shrububu_forms()
	_generate_boss_sheets()
	_generate_environment_fx()
	_generate_cutins()
	_write_catalog()
	print("Generated Pass 11 art assets")
	quit(0)


func _generate_shrububu_forms() -> void:
	for form in SHRUBUBU_FORMS:
		var form_id: String = form["id"]
		var size: Vector2i = form["size"]
		var base_path := "res://assets/shared/sprites/shrububu/%s/" % form_id
		_ensure_dir(base_path)
		_save_shrububu_strip(base_path + "idle_down.png", size, 2, form, "idle")
		_save_shrububu_strip(base_path + "walk_down.png", size, 4, form, "walk_down")
		_save_shrububu_strip(base_path + "walk_up.png", size, 4, form, "walk_up")
		_save_shrububu_strip(base_path + "walk_left.png", size, 4, form, "walk_left")
		_save_shrububu_strip(base_path + "walk_right.png", size, 4, form, "walk_right")
		_save_shrububu_strip(base_path + "battle_idle.png", Vector2i(size.x * 2, size.y + 16), 4, form, "battle")
		_save_shrububu_strip(base_path + "hurt.png", size, 2, form, "hurt")
		_save_shrububu_strip(base_path + "victory.png", size, 4, form, "victory")
		_save_shrububu_strip(base_path + String(form["attack"]), Vector2i(size.x * 2, size.y + 8), 6, form, "attack")


func _generate_boss_sheets() -> void:
	for spec in BOSS_SPECS:
		var level_id: String = spec["level"]
		var palette: Array = LEVEL_PALETTES[level_id]
		var base_path := "res://assets/%s/sprites/" % level_id
		_ensure_dir(base_path)
		for boss_id in spec["bosses"]:
			var boss_index: int = Array(spec["bosses"]).find(boss_id)
			var frame_size := Vector2i(56 + boss_index * 18, 56 + boss_index * 10)
			if boss_id == "srmt":
				frame_size = Vector2i(96, 80)
			for anim_id in BOSS_ANIMS.keys():
				var frames: int = BOSS_ANIMS[anim_id]
				_save_boss_strip(base_path + "boss_%s_%s.png" % [boss_id, anim_id], frame_size, frames, boss_id, anim_id, palette)


func _generate_environment_fx() -> void:
	for level_id in LEVEL_FX.keys():
		var palette: Array = LEVEL_PALETTES[level_id]
		var base_path := "res://assets/%s/sprites/" % level_id
		_ensure_dir(base_path)
		for fx_entry in LEVEL_FX[level_id]["fx"]:
			var fx_id: String = fx_entry[0]
			var frames: int = fx_entry[1]
			_save_fx_strip(base_path + "fx_%s.png" % fx_id, Vector2i(32, 32), frames, fx_id, palette)


func _generate_cutins() -> void:
	var base_path := "res://assets/shared/sprites/cutins/"
	_ensure_dir(base_path)
	for cutin in CUTINS:
		var cutin_id: String = cutin[0]
		var frames: int = cutin[1]
		_save_cutin_strip(base_path + "%s.png" % cutin_id, frames, cutin_id)


func _save_shrububu_strip(path: String, frame_size: Vector2i, frames: int, form: Dictionary, motion: String) -> void:
	var image := Image.create(frame_size.x * frames, frame_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for frame in range(frames):
		var x0 := frame * frame_size.x
		var foot_offset := int(abs(sin(float(frame) * PI / 2.0)) * 2.0)
		var body_color: Color = form["accent"]
		var gear_color: Color = form["gear"]
		var outline := Color("#111018")
		var center_x := x0 + frame_size.x / 2
		var ground_y := frame_size.y - 2
		var body_h := frame_size.y - 8
		var body_w: int = max(8, frame_size.x / 2)
		if motion == "hurt":
			body_color = Color("#ffffff")
		_draw_rect(image, Rect2i(center_x - body_w / 2 - 1, ground_y - body_h - 1, body_w + 2, body_h + 2), outline)
		_draw_rect(image, Rect2i(center_x - body_w / 2, ground_y - body_h, body_w, body_h), body_color)
		_draw_rect(image, Rect2i(center_x - 4, ground_y - body_h - 5, 8, 6), outline)
		_draw_rect(image, Rect2i(center_x - 3, ground_y - body_h - 4, 6, 5), Color("#f0c8a8"))
		_draw_rect(image, Rect2i(center_x - body_w / 2, ground_y - body_h - 3, body_w, 4), Color("#24140f"))
		_draw_rect(image, Rect2i(center_x - body_w / 2 - 2, ground_y - 4 + foot_offset, 5, 3), outline)
		_draw_rect(image, Rect2i(center_x + body_w / 2 - 3, ground_y - 4 - foot_offset, 5, 3), outline)
		if motion == "attack" or motion == "battle":
			_draw_rect(image, Rect2i(center_x + body_w / 2 - 1, ground_y - body_h + 6, max(4, frame_size.x / 3), 4), gear_color)
		elif motion == "victory":
			_draw_rect(image, Rect2i(center_x - 1, ground_y - body_h - 10, 3, 8), gear_color)
		else:
			_draw_rect(image, Rect2i(center_x + body_w / 2 - 1, ground_y - body_h + 10, 4, 8), gear_color)
	image.save_png(path)


func _save_boss_strip(path: String, frame_size: Vector2i, frames: int, boss_id: String, anim_id: String, palette: Array) -> void:
	var image := Image.create(frame_size.x * frames, frame_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for frame in range(frames):
		var x0 := frame * frame_size.x
		var pulse: int = int(abs(sin(float(frame) * PI / max(1.0, float(frames - 1)))) * 4.0)
		var outline := Color("#0b0b10")
		var base: Color = palette[1 + (frame % 3)]
		var accent: Color = palette[3 + (frame % 2)]
		if anim_id == "hurt":
			base = Color("#ffffff")
			accent = palette[2]
		elif anim_id == "defeat":
			base = palette[0].lerp(Color("#ffffff"), 0.25)
		var cx := x0 + frame_size.x / 2
		var cy := frame_size.y / 2 + pulse
		var body_rect := Rect2i(cx - frame_size.x / 4, cy - frame_size.y / 4, frame_size.x / 2, frame_size.y / 2)
		_draw_rect(image, body_rect.grow(2), outline)
		_draw_rect(image, body_rect, base)
		_draw_rect(image, Rect2i(cx - frame_size.x / 5, cy - frame_size.y / 3, frame_size.x / 3, 8), accent)
		if anim_id == "attack" or anim_id == "intro":
			_draw_rect(image, Rect2i(cx + frame_size.x / 4 - 2, cy - 2, frame_size.x / 4, 5), accent)
		if anim_id == "talk":
			_draw_rect(image, Rect2i(cx - 6, cy + 2 + frame % 2, 12, 3), outline)
		if boss_id == "srmt":
			_draw_rect(image, Rect2i(cx - 26, 6, 52, 12), Color("#f7d44a"))
			_draw_rect(image, Rect2i(cx - 6, 12, 12, 8), Color("#ffef9a"))
	image.save_png(path)


func _save_fx_strip(path: String, frame_size: Vector2i, frames: int, fx_id: String, palette: Array) -> void:
	var image := Image.create(frame_size.x * frames, frame_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for frame in range(frames):
		var x0 := frame * frame_size.x
		var c1: Color = palette[1]
		var c2: Color = palette[3]
		match fx_id:
			"rain_loop":
				for drop in range(6):
					var dx := (drop * 7 + frame * 3) % frame_size.x
					_draw_rect(image, Rect2i(x0 + dx, (drop * 5 + frame * 2) % frame_size.y, 1, 5), c2)
			"neon_flicker", "lab_monitor_pulse", "fluorescent_buzz":
				_draw_rect(image, Rect2i(x0 + 4, 10, 24, 8), c1.lerp(c2, float(frame) / max(1.0, float(frames - 1))))
			"paper_flutter":
				_draw_rect(image, Rect2i(x0 + 6 + frame, 8 + frame % 3, 10, 6), c2)
				_draw_rect(image, Rect2i(x0 + 18 - frame, 18, 8, 5), c2.darkened(0.2))
			"monkey_loop":
				_draw_rect(image, Rect2i(x0 + 10, 8 + frame, 12, 16), c1)
				_draw_rect(image, Rect2i(x0 + 8 + frame * 2, 18, 6, 3), c2)
			"mist_drift":
				_draw_rect(image, Rect2i(x0 + 2 + frame * 2, 12, 22, 3), c2)
				_draw_rect(image, Rect2i(x0 + 10, 20, 18, 3), c2.darkened(0.2))
			"berry_glow":
				_draw_rect(image, Rect2i(x0 + 12, 12, 8, 8), c2)
				_draw_rect(image, Rect2i(x0 + 10 - frame % 2, 10 - frame % 2, 12 + frame % 2 * 2, 12 + frame % 2 * 2), c2.lightened(0.2))
			"aeon_fireworks":
				_draw_rect(image, Rect2i(x0 + 16, 16, 2, 2), c2)
				for ray in range(4):
					_draw_rect(image, Rect2i(x0 + 16 + int(cos(ray * PI / 2.0) * (2 + frame)), 16 + int(sin(ray * PI / 2.0) * (2 + frame)), 2, 2), c1)
			"club_static":
				for band in range(4):
					_draw_rect(image, Rect2i(x0, band * 8 + (frame % 2), frame_size.x, 2), c2)
			"musical_notes":
				_draw_rect(image, Rect2i(x0 + 10 + frame, 8, 3, 14), c2)
				_draw_rect(image, Rect2i(x0 + 7 + frame, 20, 8, 5), c2)
			"throne_reveal":
				_draw_rect(image, Rect2i(x0 + 8, 6, 16, 22), c1)
				_draw_rect(image, Rect2i(x0 + 6, 4, 20, 6 + frame), c2)
			_:
				_draw_rect(image, Rect2i(x0 + 8, 8, 16, 16), c2)
	image.save_png(path)


func _save_cutin_strip(path: String, frames: int, cutin_id: String) -> void:
	var frame_size := Vector2i(320, 80)
	var image := Image.create(frame_size.x * frames, frame_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for frame in range(frames):
		var x0 := frame * frame_size.x
		_draw_rect(image, Rect2i(x0, 0, frame_size.x, frame_size.y), Color("#111018"))
		_draw_rect(image, Rect2i(x0, 58, frame_size.x, 22), Color("#7b2e3a"))
		var accent := Color("#f0c53a")
		if cutin_id.contains("srmt"):
			accent = Color("#ff78b7")
		elif cutin_id.contains("ishiyoga"):
			accent = Color("#49e6ff")
		elif cutin_id.contains("growth"):
			accent = Color("#d63a5c")
		_draw_rect(image, Rect2i(x0 + 14 + frame * 5, 16, 56, 42), accent)
		_draw_rect(image, Rect2i(x0 + 82, 20 + frame % 3, 180, 8), Color("#f0e7d0"))
		_draw_rect(image, Rect2i(x0 + 82, 36 + frame % 2, 130, 6), Color("#d8c7a3"))
	image.save_png(path)


func _write_catalog() -> void:
	_ensure_dir("res://data/art/")
	var catalog := {
		"shrububu_forms": [],
		"bosses": [],
		"environment_fx": [],
		"cutins": []
	}
	for form in SHRUBUBU_FORMS:
		catalog["shrububu_forms"].append({
			"id": form["id"],
			"sprite_dir": "res://assets/shared/sprites/shrububu/%s/" % form["id"],
			"growth_stage": int(String(form["id"]).get_slice("_", 1))
		})
	for spec in BOSS_SPECS:
		for boss_id in spec["bosses"]:
			catalog["bosses"].append({
				"id": boss_id,
				"level": spec["level"],
				"sprite_dir": "res://assets/%s/sprites/" % spec["level"],
				"animations": BOSS_ANIMS.keys()
			})
	for level_id in LEVEL_FX.keys():
		for fx_entry in LEVEL_FX[level_id]["fx"]:
			catalog["environment_fx"].append({
				"id": fx_entry[0],
				"level": level_id,
				"frame_count": fx_entry[1],
				"path": "res://assets/%s/sprites/fx_%s.png" % [level_id, fx_entry[0]]
			})
	for cutin in CUTINS:
		catalog["cutins"].append({
			"id": cutin[0],
			"frame_count": cutin[1],
			"path": "res://assets/shared/sprites/cutins/%s.png" % cutin[0]
		})
	var file := FileAccess.open("res://data/art/animation_catalog.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(catalog, "\t"))


func _draw_rect(image: Image, rect: Rect2i, color: Color) -> void:
	var x_start: int = clamp(rect.position.x, 0, image.get_width())
	var y_start: int = clamp(rect.position.y, 0, image.get_height())
	var x_end: int = clamp(rect.position.x + rect.size.x, 0, image.get_width())
	var y_end: int = clamp(rect.position.y + rect.size.y, 0, image.get_height())
	for y in range(y_start, y_end):
		for x in range(x_start, x_end):
			image.set_pixel(x, y, color)


func _ensure_dir(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
