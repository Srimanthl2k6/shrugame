extends SceneTree

const LEVEL_01_SCENE := "res://scenes/levels/level_01.tscn"

const REQUIRED_ART := {
	"res://assets/level_01/tilesets/tiles_divorcee_harbour_ground.png": Vector2i(320, 180),
	"res://assets/level_01/sprites/prop_fake_chicken_storefront.png": Vector2i(96, 64),
	"res://assets/level_01/sprites/prop_sheriff_office.png": Vector2i(72, 52),
	"res://assets/level_01/sprites/prop_dock_route.png": Vector2i(96, 44),
	"res://assets/level_01/sprites/prop_save_notice.png": Vector2i(24, 28),
	"res://assets/level_01/sprites/prop_divorce_records.png": Vector2i(32, 24),
	"res://assets/level_01/sprites/prop_kfc_door.png": Vector2i(28, 36),
	"res://assets/level_01/sprites/prop_pantry_tag.png": Vector2i(18, 12),
	"res://assets/level_01/sprites/npc_divorcee_resident_idle.png": Vector2i(16, 24),
	"res://assets/level_01/sprites/npc_shelf_echo_idle.png": Vector2i(16, 24),
	"res://assets/level_01/sprites/boss_poojan_overworld.png": Vector2i(24, 32),
	"res://assets/level_01/sprites/boss_satyaki_tirumal_overworld.png": Vector2i(32, 40),
	"res://assets/level_01/sprites/fx_level01_rain_sheet.png": Vector2i(128, 180)
}

const SPRITE_NODES := [
	"World/SceneArt/HarbourBackplate",
	"World/SceneArt/SheriffOffice",
	"World/SceneArt/DockRoute",
	"World/BrokenChickenBuilding/StorefrontSprite",
	"World/KfcDoor/ReadableSprite",
	"World/HarbourResident/ReadableSprite",
	"World/Marn/ReadableSprite",
	"World/TagFlour/ReadableSprite",
	"World/TagCups/ReadableSprite",
	"World/TagBroom/ReadableSprite",
	"World/SheriffPoojan/ReadableSprite",
	"World/DivorceRecords/ReadableSprite",
	"World/SatyakiApproach/ReadableSprite",
	"World/SatyakiBoss/ReadableSprite",
	"World/SavePoint/ReadableSprite",
	"World/TransitionDoor/ReadableSprite",
	"VisualFxLayer/RainSprite"
]

const HIDDEN_POLYGON_STAND_INS := [
	"World/KfcDoor/Visual",
	"World/HarbourResident/Visual",
	"World/Marn/Visual",
	"World/SheriffPoojan/Visual",
	"World/DivorceRecords/Visual",
	"World/SatyakiBoss/Visual",
	"World/SavePoint/Visual"
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_art_files(failures)
	_check_level_scene_wiring(failures)
	_check_readability_documentation(failures)

	if failures.is_empty():
		print("PASS: Ishiville Pass 17 Level 1 art smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_art_files(failures: Array[String]) -> void:
	for path in REQUIRED_ART.keys():
		var min_size: Vector2i = REQUIRED_ART[path]
		if not FileAccess.file_exists(path):
			failures.append("Missing Level 1 art asset %s" % path)
			continue
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if image == null or image.is_empty():
			failures.append("Level 1 art asset failed to load: %s" % path)
			continue
		if image.get_width() < min_size.x or image.get_height() < min_size.y:
			failures.append("%s too small: got %sx%s, expected at least %sx%s" % [path, image.get_width(), image.get_height(), min_size.x, min_size.y])


func _check_level_scene_wiring(failures: Array[String]) -> void:
	var scene := load(LEVEL_01_SCENE)
	if scene == null:
		failures.append("Level 1 scene failed to load")
		return
	var level: Node = scene.instantiate()
	for node_path in SPRITE_NODES:
		var node := level.get_node_or_null(node_path)
		if node == null:
			failures.append("Level 1 missing sprite node %s" % node_path)
			continue
		if not (node is Sprite2D):
			failures.append("Level 1 node %s must be Sprite2D" % node_path)
			continue
		var sprite := node as Sprite2D
		if sprite.texture == null:
			failures.append("Level 1 sprite %s has no texture" % node_path)
		if sprite.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
			failures.append("Level 1 sprite %s must use nearest filtering" % node_path)
	for node_path in HIDDEN_POLYGON_STAND_INS:
		var node := level.get_node_or_null(node_path)
		if node == null:
			failures.append("Level 1 missing legacy stand-in %s; hide it instead of deleting interaction context" % node_path)
			continue
		var canvas_item := node as CanvasItem
		if canvas_item != null and canvas_item.visible:
			failures.append("Legacy polygon stand-in %s should be hidden after sprite replacement" % node_path)
	var street := level.get_node_or_null("World/WetStreet") as CanvasItem
	var planks := level.get_node_or_null("World/HarbourPlanks") as CanvasItem
	if street != null and street.visible:
		failures.append("WetStreet polygon should be hidden behind the painted backplate")
	if planks != null and planks.visible:
		failures.append("HarbourPlanks polygon should be hidden behind the painted backplate")
	level.free()


func _check_readability_documentation(failures: Array[String]) -> void:
	if not FileAccess.file_exists("res://README.md"):
		failures.append("Missing README.md")
		return
	var readme := FileAccess.get_file_as_string("res://README.md")
	for required_text in [
		"Pass 17 Level 1 art replacement",
		"Divorcee Harbour",
		"painted backplate",
		"fake chicken storefront"
	]:
		if not readme.contains(required_text):
			failures.append("README missing Pass 17 note: %s" % required_text)
