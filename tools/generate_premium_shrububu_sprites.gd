extends SceneTree

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
const PALETTES := [
	{"coat": Color("28545b"), "coat_light": Color("4a7c80"), "accent": Color("d14e57"), "shirt": Color("161b22")},
	{"coat": Color("672b42"), "coat_light": Color("91445d"), "accent": Color("e4b842"), "shirt": Color("1a1c24")},
	{"coat": Color("245d62"), "coat_light": Color("43848a"), "accent": Color("9f4178"), "shirt": Color("e5ddd0")},
	{"coat": Color("173f3c"), "coat_light": Color("386963"), "accent": Color("a4376e"), "shirt": Color("171c20")},
	{"coat": Color("20252c"), "coat_light": Color("4a515c"), "accent": Color("23b8b5"), "shirt": Color("1d7880")}
]


func _init() -> void:
	call_deferred("_generate")


func _generate() -> void:
	var animations := [
		{"name": "idle_down", "direction": "down", "frames": 2, "action": "idle"},
		{"name": "idle_up", "direction": "up", "frames": 2, "action": "idle"},
		{"name": "idle_left", "direction": "left", "frames": 2, "action": "idle"},
		{"name": "idle_right", "direction": "right", "frames": 2, "action": "idle"},
		{"name": "walk_down", "direction": "down", "frames": 4, "action": "walk"},
		{"name": "walk_up", "direction": "up", "frames": 4, "action": "walk"},
		{"name": "walk_left", "direction": "left", "frames": 4, "action": "walk"},
		{"name": "walk_right", "direction": "right", "frames": 4, "action": "walk"},
		{"name": "battle_idle", "direction": "down", "frames": 4, "action": "battle"},
		{"name": "hurt", "direction": "down", "frames": 2, "action": "hurt"},
		{"name": "victory", "direction": "down", "frames": 4, "action": "victory"},
		{"name": "interact", "direction": "down", "frames": 4, "action": "interact"},
		{"name": "door_slam", "direction": "right", "frames": 6, "action": "door_slam"},
		{"name": "growth_transform", "direction": "down", "frames": 8, "action": "growth"}
	]

	for stage in range(1, 6):
		var stage_dir := "%s/form_%02d" % [OUTPUT_ROOT, stage]
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(stage_dir))
		for animation in animations:
			_write_sheet(stage, stage_dir, animation)
		_write_sheet(stage, stage_dir, {
			"name": ATTACK_NAMES[stage - 1],
			"direction": "right",
			"frames": 6,
			"action": "attack"
		})
	print("PASS: generated photo-informed Shrububu sprite sheets")
	quit(0)


func _write_sheet(stage: int, stage_dir: String, animation: Dictionary) -> void:
	var frame_size: Vector2i = FRAME_SIZES[stage - 1]
	var frame_count := int(animation["frames"])
	var image := Image.create(frame_size.x * frame_count, frame_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for frame in range(frame_count):
		_draw_character(
			image,
			Vector2i(frame * frame_size.x, 0),
			frame_size,
			stage,
			str(animation["direction"]),
			str(animation["action"]),
			frame
		)
	var output_path := "%s/%s.png" % [stage_dir, animation["name"]]
	var error := image.save_png(ProjectSettings.globalize_path(output_path))
	if error != OK:
		push_error("Could not save %s" % output_path)


func _draw_character(image: Image, origin: Vector2i, size: Vector2i, stage: int, direction: String, action: String, frame: int) -> void:
	var palette: Dictionary = PALETTES[stage - 1]
	var outline := Color("080a0e")
	var hair := Color("0e1017")
	var hair_mid := Color("242431")
	var hair_glint := Color("414052")
	var skin_shadow := Color("7e432f")
	var skin := Color("a76045")
	var skin_light := Color("d18a69")
	var lip := Color("73343e")
	var pants := Color("111720")
	var pants_light := Color("28313f")
	var boot := Color("20191d")
	var metal := Color("b7c2c4")
	var gold := Color("e2b348")
	var berry := Color("a33770")
	var teal := Color("25aaa8")
	var cx := origin.x + int(size.x / 2)
	var phase := frame % 4
	var bob := 1 if action in ["walk", "battle"] and phase in [1, 3] else 0
	if action == "hurt":
		cx += 1 if frame == 0 else -1
	if action == "growth":
		_draw_growth_aura(image, origin, size, frame, Color(palette["accent"]))

	# Growth is vertical only: the body width remains stable from Form 1 through Form 5.
	var head_y := origin.y + 5 + bob
	var torso_y := head_y + 11
	var torso_height := 10 + stage
	var hip_y := torso_y + torso_height
	var foot_y := origin.y + size.y - 4
	var shoulder_half := 7
	var waist_half := 5

	_draw_shadow(image, cx, foot_y, stage)
	_draw_long_hair(image, cx, head_y, torso_y, hip_y, direction, phase, hair, hair_mid, hair_glint, outline)
	_draw_face(image, cx, head_y, direction, stage, skin_shadow, skin, skin_light, lip, hair, outline)
	_draw_coat_and_torso(image, cx, torso_y, hip_y, stage, shoulder_half, waist_half, palette, outline, gold)
	_draw_arms(image, cx, torso_y, hip_y, direction, action, frame, skin, skin_light, outline, Color(palette["coat"]), Color(palette["coat_light"]))
	_draw_legs(image, cx, hip_y, foot_y, action, phase, pants, pants_light, boot, outline, gold)
	_draw_stage_gear(image, cx, torso_y, hip_y, stage, direction, action, frame, outline, metal, gold, berry, teal)

	if action == "hurt":
		_rect(image, cx - 10, torso_y + frame * 2, 4, 1, Color("ff5b69"))
	if action == "victory":
		_pixel(image, cx - 11 + frame, head_y - 2, gold)
		_pixel(image, cx + 10 - frame, head_y, teal if stage == 5 else gold)


func _draw_shadow(image: Image, cx: int, foot_y: int, stage: int) -> void:
	var half_width := 8 + int(stage / 2)
	_rect(image, cx - half_width, foot_y + 2, half_width * 2, 2, Color(0.02, 0.025, 0.03, 0.42))


func _draw_long_hair(image: Image, cx: int, head_y: int, torso_y: int, hip_y: int, direction: String, phase: int, hair: Color, hair_mid: Color, hair_glint: Color, outline: Color) -> void:
	var sway := -1 if phase == 1 else (1 if phase == 3 else 0)
	# Rounded crown, long wavy sides, and bangs are the identity anchor from the references.
	_rect(image, cx - 6, head_y - 3, 12, 3, outline)
	_rect(image, cx - 7, head_y - 1, 14, 7, outline)
	_rect(image, cx - 6, head_y - 3, 12, 3, hair)
	_rect(image, cx - 7, head_y, 3, hip_y - head_y - 1, hair)
	_rect(image, cx + 5, head_y, 3, hip_y - head_y - 1, hair)
	_rect(image, cx - 8 + sway, torso_y + 3, 3, hip_y - torso_y - 2, outline)
	_rect(image, cx + 6 + sway, torso_y + 4, 3, hip_y - torso_y - 3, outline)
	_rect(image, cx - 7 + sway, torso_y + 3, 2, hip_y - torso_y - 3, hair_mid)
	_rect(image, cx + 6 + sway, torso_y + 4, 2, hip_y - torso_y - 4, hair)
	# Soft wave pixels and asymmetrical highlight.
	_pixel(image, cx - 7 + sway, torso_y + 5, hair_glint)
	_pixel(image, cx - 6 + sway, torso_y + 8, hair_mid)
	_pixel(image, cx + 7 + sway, torso_y + 7, hair_glint)
	_pixel(image, cx + 6 + sway, hip_y - 3, hair_mid)
	if direction == "up":
		_rect(image, cx - 5, head_y, 10, 8, hair)
		_rect(image, cx - 3, head_y + 1, 6, 2, hair_mid)


func _draw_face(image: Image, cx: int, head_y: int, direction: String, stage: int, skin_shadow: Color, skin: Color, skin_light: Color, lip: Color, hair: Color, outline: Color) -> void:
	if direction == "up":
		return
	_rect(image, cx - 4, head_y, 8, 9, skin_shadow)
	_rect(image, cx - 3, head_y, 7, 8, skin)
	_rect(image, cx - 2, head_y + 1, 5, 2, skin_light)
	# Bangs frame the face without hiding the large expressive eyes.
	_rect(image, cx - 4, head_y - 1, 3, 3, hair)
	_rect(image, cx, head_y - 1, 4, 2, hair)
	var eye_y := head_y + 4
	if direction == "left":
		_rect(image, cx - 3, eye_y, 2, 1, outline)
		_pixel(image, cx + 1, eye_y, outline)
		_rect(image, cx + 3, head_y + 1, 2, 7, hair)
	elif direction == "right":
		_pixel(image, cx - 2, eye_y, outline)
		_rect(image, cx + 1, eye_y, 2, 1, outline)
		_rect(image, cx - 5, head_y + 1, 2, 7, hair)
	else:
		# Slight side-eye gives Shrububu her dry, suspicious resting expression.
		_rect(image, cx - 3, eye_y, 2, 1, Color("f2eee8"))
		_rect(image, cx + 1, eye_y, 2, 1, Color("f2eee8"))
		_pixel(image, cx - 2, eye_y, outline)
		_pixel(image, cx + 1, eye_y, outline)
		_pixel(image, cx + 2, head_y + 7, lip)
	if stage == 2:
		# Clear-frame glasses echo the references and distinguish the sheriff form.
		_rect(image, cx - 4, eye_y - 1, 3, 3, Color("d7c6bd"))
		_rect(image, cx + 1, eye_y - 1, 3, 3, Color("d7c6bd"))
		_rect(image, cx - 1, eye_y, 2, 1, Color("d7c6bd"))
		_pixel(image, cx - 3, eye_y, outline)
		_pixel(image, cx + 2, eye_y, outline)


func _draw_coat_and_torso(image: Image, cx: int, torso_y: int, hip_y: int, stage: int, shoulder_half: int, waist_half: int, palette: Dictionary, outline: Color, gold: Color) -> void:
	var coat: Color = Color(palette["coat"])
	var coat_light: Color = Color(palette["coat_light"])
	var shirt: Color = Color(palette["shirt"])
	_rect(image, cx - shoulder_half, torso_y - 1, shoulder_half * 2 + 1, hip_y - torso_y + 3, outline)
	_rect(image, cx - shoulder_half + 1, torso_y, shoulder_half * 2 - 1, hip_y - torso_y + 1, coat)
	# A narrow center panel and tapered lower torso keep the silhouette slim at every stage.
	_rect(image, cx - 3, torso_y + 1, 7, hip_y - torso_y - 1, shirt)
	_rect(image, cx - shoulder_half + 1, torso_y, 3, hip_y - torso_y, coat_light)
	_rect(image, cx - waist_half, hip_y - 3, waist_half * 2 + 1, 3, coat)
	_pixel(image, cx - 2, torso_y + 2, gold)
	_pixel(image, cx + 2, torso_y + 2, gold)
	_rect(image, cx, torso_y + 3, 1, hip_y - torso_y - 4, gold)
	if stage == 5:
		_rect(image, cx - shoulder_half + 1, torso_y, shoulder_half * 2 - 1, 4, Color("1a1d23"))
		_rect(image, cx - 3, torso_y + 1, 7, 6, shirt)
		_pixel(image, cx - 5, torso_y + 1, Color("d4d8da"))
		_pixel(image, cx + 5, torso_y + 1, Color("d4d8da"))


func _draw_arms(image: Image, cx: int, torso_y: int, hip_y: int, direction: String, action: String, frame: int, skin: Color, skin_light: Color, outline: Color, coat: Color, coat_light: Color) -> void:
	var reach := mini(frame, 4) if action in ["attack", "door_slam", "interact"] else 0
	if action == "victory":
		_rect(image, cx - 9, torso_y - 5, 3, 12, outline)
		_rect(image, cx + 7, torso_y - 5, 3, 12, outline)
		_rect(image, cx - 8, torso_y - 4, 2, 10, coat_light)
		_rect(image, cx + 7, torso_y - 4, 2, 10, coat)
		_pixel(image, cx - 8, torso_y - 6, skin_light)
		_pixel(image, cx + 8, torso_y - 6, skin)
		return
	if direction == "left":
		_rect(image, cx - 9 - reach, torso_y + 2, 4 + reach, 4, outline)
		_rect(image, cx - 8 - reach, torso_y + 3, 3 + reach, 2, coat_light)
		_pixel(image, cx - 9 - reach, torso_y + 4, skin_light)
		_rect(image, cx + 6, torso_y + 2, 3, hip_y - torso_y - 1, outline)
		_rect(image, cx + 6, torso_y + 3, 2, hip_y - torso_y - 3, coat)
	elif direction == "right":
		_rect(image, cx + 6, torso_y + 2, 4 + reach, 4, outline)
		_rect(image, cx + 6, torso_y + 3, 3 + reach, 2, coat)
		_pixel(image, cx + 9 + reach, torso_y + 4, skin)
		_rect(image, cx - 9, torso_y + 2, 3, hip_y - torso_y - 1, outline)
		_rect(image, cx - 8, torso_y + 3, 2, hip_y - torso_y - 3, coat_light)
	else:
		_rect(image, cx - 9, torso_y + 2, 3, hip_y - torso_y, outline)
		_rect(image, cx + 7, torso_y + 2, 3, hip_y - torso_y, outline)
		_rect(image, cx - 8, torso_y + 3, 2, hip_y - torso_y - 2, coat_light)
		_rect(image, cx + 7, torso_y + 3, 2, hip_y - torso_y - 2, coat)
		_pixel(image, cx - 8, hip_y + 1, skin_light)
		_pixel(image, cx + 8, hip_y + 1, skin)


func _draw_legs(image: Image, cx: int, hip_y: int, foot_y: int, action: String, phase: int, pants: Color, pants_light: Color, boot: Color, outline: Color, gold: Color) -> void:
	var left_step := 0
	var right_step := 0
	if action == "walk":
		left_step = -1 if phase == 1 else (1 if phase == 3 else 0)
		right_step = 1 if phase == 1 else (-1 if phase == 3 else 0)
	var leg_height := maxi(5, foot_y - hip_y - 2)
	_rect(image, cx - 5 + left_step, hip_y + 1, 4, leg_height, outline)
	_rect(image, cx + 1 + right_step, hip_y + 1, 4, leg_height, outline)
	_rect(image, cx - 4 + left_step, hip_y + 1, 3, leg_height - 1, pants_light)
	_rect(image, cx + 1 + right_step, hip_y + 1, 3, leg_height - 1, pants)
	_rect(image, cx - 6 + left_step, foot_y - 2, 5, 3, boot)
	_rect(image, cx + 1 + right_step, foot_y - 2, 5, 3, boot)
	_pixel(image, cx - 5 + left_step, foot_y - 2, gold)
	_pixel(image, cx + 2 + right_step, foot_y - 2, gold)


func _draw_stage_gear(image: Image, cx: int, torso_y: int, hip_y: int, stage: int, direction: String, action: String, frame: int, outline: Color, metal: Color, gold: Color, berry: Color, teal: Color) -> void:
	match stage:
		1:
			# Unbranded red-and-white fried chicken bucket.
			_rect(image, cx - 12, hip_y - 1, 5, 6, outline)
			_rect(image, cx - 11, hip_y, 3, 4, Color("efe4ce"))
			_pixel(image, cx - 10, hip_y + 1, Color("b63e44"))
			_pixel(image, cx - 8, hip_y + 2, Color("b63e44"))
			_pixel(image, cx - 11, hip_y - 2, Color("c57b3a"))
			_pixel(image, cx - 9, hip_y - 2, Color("dfa448"))
		2:
			_rect(image, cx - 5, torso_y - 3, 11, 2, Color("5c3329"))
			_rect(image, cx + 7, torso_y + 2, 6 + (frame if action == "attack" else 0), 3, outline)
			_rect(image, cx + 8, torso_y + 2, 4 + (frame if action == "attack" else 0), 1, metal)
			_pixel(image, cx - 4, torso_y + 1, gold)
		3:
			_rect(image, cx - 10, hip_y - 1, 5, 7, outline)
			_rect(image, cx - 9, hip_y, 3, 5, berry)
			_rect(image, cx + 7, torso_y + 1, 7 + (frame if action == "attack" else 0), 4, outline)
			_rect(image, cx + 8, torso_y + 1, 5 + (frame if action == "attack" else 0), 2, gold)
			_pixel(image, cx + 10, torso_y, Color("fff07a"))
		4:
			_rect(image, cx - 10, hip_y - 2, 4, 8, outline)
			_rect(image, cx - 9, hip_y - 1, 2, 6, berry)
			_rect(image, cx + 7, hip_y - 3, 4, 9, outline)
			_rect(image, cx + 8, hip_y - 2, 2, 7, teal)
			if action == "attack":
				_pixel(image, cx + 11 + frame, torso_y, berry)
				_pixel(image, cx + 12 + frame, torso_y - 1, Color("e76aac"))
		5:
			var guitar_x := cx + 5
			_rect(image, guitar_x, torso_y, 3, hip_y - torso_y + 10, outline)
			_rect(image, guitar_x + 1, torso_y + 1, 1, hip_y - torso_y + 7, metal)
			_rect(image, guitar_x - 4, hip_y + 2, 10, 6, outline)
			_rect(image, guitar_x - 3, hip_y + 3, 8, 4, teal)
			_pixel(image, guitar_x + 1, hip_y + 4, Color("f0e7d5"))
			if action == "attack":
				_pixel(image, guitar_x + 7 + frame, torso_y + frame % 3, Color("bb62eb"))
				_pixel(image, guitar_x + 9 + frame, torso_y - 2 + frame % 2, teal)


func _draw_growth_aura(image: Image, origin: Vector2i, size: Vector2i, frame: int, accent: Color) -> void:
	var inset := frame % 4
	var points := [
		Vector2i(origin.x + 3 + inset, origin.y + 7),
		Vector2i(origin.x + size.x - 4 - inset, origin.y + 10),
		Vector2i(origin.x + 5, origin.y + size.y - 8 - inset),
		Vector2i(origin.x + size.x - 6, origin.y + size.y - 6 + inset)
	]
	for point in points:
		_pixel(image, point.x, point.y, accent)
		_pixel(image, point.x + 1, point.y, Color(accent, 0.55))


func _rect(image: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	if width <= 0 or height <= 0:
		return
	var clipped := Rect2i(x, y, width, height).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	if clipped.size.x > 0 and clipped.size.y > 0:
		image.fill_rect(clipped, color)


func _pixel(image: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
		image.set_pixel(x, y, color)
