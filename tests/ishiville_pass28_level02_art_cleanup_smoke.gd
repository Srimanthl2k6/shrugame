extends SceneTree

const LEVEL_02_SCENE := "res://scenes/levels/level_02.tscn"

const REQUIRED_ART := {
	"res://assets/level_02/tilesets/tiles_banana_burbs_backplate.png": Vector2i(320, 180),
	"res://assets/level_02/sprites/prop_banana_house_row.png": Vector2i(128, 88),
	"res://assets/level_02/sprites/prop_165_files_lab.png": Vector2i(112, 72),
	"res://assets/level_02/sprites/prop_mayor_office.png": Vector2i(96, 64),
	"res://assets/level_02/sprites/prop_165_files.png": Vector2i(32, 24),
	"res://assets/level_02/sprites/prop_kfc_popcorn_box.png": Vector2i(32, 24),
	"res://assets/level_02/sprites/prop_banana_mailbox.png": Vector2i(24, 28),
	"res://assets/level_02/sprites/prop_banana_exit_gate.png": Vector2i(30, 38),
	"res://assets/level_02/sprites/npc_happy_monkey_idle.png": Vector2i(18, 24),
	"res://assets/level_02/sprites/npc_vela_echo_idle.png": Vector2i(18, 24),
	"res://assets/level_02/sprites/boss_nitin_overworld.png": Vector2i(24, 34),
	"res://assets/level_02/sprites/boss_deepak_reddy_overworld.png": Vector2i(32, 40),
	"res://assets/level_02/sprites/fx_level02_monkey_loop_sheet.png": Vector2i(128, 64)
}

const SPRITE_NODES := [
	"World/SceneArt/BananaBurbsBackplate",
	"World/SceneArt/BananaHouseRow",
	"World/SceneArt/LabExterior",
	"World/SceneArt/MayorOfficeSprite",
	"World/HappyMonkeyLoop/ReadableSprite",
	"World/LabRecords/ReadableSprite",
	"World/NitinJanitor/ReadableSprite",
	"World/PopcornShare/ReadableSprite",
	"World/MayorOffice/ReadableSprite",
	"World/DeepakBoss/ReadableSprite",
	"World/Vela/ReadableSprite",
	"World/Objective/ReadableSprite",
	"World/PracticeEncounter/ReadableSprite",
	"World/SavePoint/ReadableSprite",
	"World/TransitionDoor/ReadableSprite",
	"VisualFxLayer/MonkeyLoopSprite"
]

const HIDDEN_POLYGON_STAND_INS := [
	"World/SuburbLawn",
	"World/LabConcrete",
	"World/BananaHouses/HouseA",
	"World/BananaHouses/HouseB",
	"World/BananaHouses/HouseC",
	"World/HappyMonkeyLoop/Visual",
	"World/LabRecords/Visual",
	"World/NitinJanitor/Visual",
	"World/PopcornShare/Visual",
	"World/MayorOffice/Visual",
	"World/DeepakBoss/Visual",
	"World/Vela/Visual",
	"World/SavePoint/Visual",
	"World/TransitionDoor/Visual"
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_art_files(failures)
	_check_level_scene_wiring(failures)
	_check_readability_documentation(failures)

	if failures.is_empty():
		print("PASS: Ishiville Pass 28 Level 2 art cleanup smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_art_files(failures: Array[String]) -> void:
	for path in REQUIRED_ART.keys():
		var min_size: Vector2i = REQUIRED_ART[path]
		if not FileAccess.file_exists(path):
			failures.append("Missing Level 2 art asset %s" % path)
			continue
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if image == null or image.is_empty():
			failures.append("Level 2 art asset failed to load: %s" % path)
			continue
		if image.get_width() < min_size.x or image.get_height() < min_size.y:
			failures.append("%s too small: got %sx%s, expected at least %sx%s" % [path, image.get_width(), image.get_height(), min_size.x, min_size.y])
		if _count_sampled_colors(image) < 4:
			failures.append("%s needs multiple readable pixel colors, not a flat block" % path)


func _check_level_scene_wiring(failures: Array[String]) -> void:
	var scene := load(LEVEL_02_SCENE)
	if scene == null:
		failures.append("Level 2 scene failed to load")
		return
	var level: Node = scene.instantiate()
	var scene_art := level.get_node_or_null("World/SceneArt") as Node2D
	if scene_art == null:
		failures.append("Level 2 needs World/SceneArt for authored pixel art")
	elif scene_art.z_index > -8:
		failures.append("Level 2 SceneArt should sit behind route/interaction markers")
	for node_path in SPRITE_NODES:
		var node := level.get_node_or_null(node_path)
		if node == null:
			failures.append("Level 2 missing sprite node %s" % node_path)
			continue
		if not (node is Sprite2D):
			failures.append("Level 2 node %s must be Sprite2D" % node_path)
			continue
		var sprite := node as Sprite2D
		if sprite.texture == null:
			failures.append("Level 2 sprite %s has no texture" % node_path)
		if sprite.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
			failures.append("Level 2 sprite %s must use nearest filtering" % node_path)
	for node_path in HIDDEN_POLYGON_STAND_INS:
		var node := level.get_node_or_null(node_path)
		if node == null:
			failures.append("Level 2 missing legacy stand-in %s; hide it instead of deleting interaction context" % node_path)
			continue
		var canvas_item := node as CanvasItem
		if canvas_item != null and canvas_item.visible:
			failures.append("Legacy polygon stand-in %s should be hidden after sprite replacement" % node_path)
	level.free()


func _check_readability_documentation(failures: Array[String]) -> void:
	var readme := FileAccess.get_file_as_string("res://README.md")
	for required_text in [
		"Pass 28 Level 2 art cleanup",
		"Banana-burbs",
		"painted backplate",
		"happy monkey sprites",
		"165-files lab"
	]:
		if not readme.contains(required_text):
			failures.append("README missing Pass 28 note: %s" % required_text)
	var preset := FileAccess.get_file_as_string("res://export_presets.cfg")
	var version := _extract_product_version(preset)
	if version.is_empty():
		failures.append("Export metadata missing product version")
	elif not _is_version_at_least(version, "0.28.0"):
		failures.append("Export metadata should be at least 0.28.0")


func _count_sampled_colors(image: Image) -> int:
	var colors := {}
	var step_x: int = max(1, image.get_width() / 12)
	var step_y: int = max(1, image.get_height() / 12)
	for y in range(0, image.get_height(), step_y):
		for x in range(0, image.get_width(), step_x):
			var color := image.get_pixel(x, y)
			if color.a < 0.2:
				continue
			var key := "%02x%02x%02x" % [
				int(round(color.r * 255.0)),
				int(round(color.g * 255.0)),
				int(round(color.b * 255.0))
			]
			colors[key] = true
	return colors.size()


func _extract_product_version(preset: String) -> String:
	for line in preset.split("\n"):
		if line.begins_with("application/product_version="):
			return line.get_slice("\"", 1)
	return ""


func _is_version_at_least(actual_version: String, minimum_version: String) -> bool:
	var actual_parts := actual_version.split(".")
	var minimum_parts := minimum_version.split(".")
	for index in range(3):
		var actual_value := 0
		var minimum_value := 0
		if index < actual_parts.size():
			actual_value = int(actual_parts[index])
		if index < minimum_parts.size():
			minimum_value = int(minimum_parts[index])
		if actual_value > minimum_value:
			return true
		if actual_value < minimum_value:
			return false
	return true
