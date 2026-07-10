extends SceneTree

const LEVEL_01_SCENE := "res://scenes/levels/level_01.tscn"
const PLAYER_SCENE := "res://scenes/overworld/player.tscn"
const PRESENTATION_GUIDE := "res://scripts/visual/presentation_guide.gd"

const REQUIRED_BLOCKERS := {
	"FakeChickenStoreBlocker": Vector2(70.0, 28.0),
	"SheriffOfficeBlocker": Vector2(62.0, 24.0),
	"HarbourWaterEdgeBlocker": Vector2(292.0, 8.0),
	"DockRailBlocker": Vector2(88.0, 8.0)
}

const REQUIRED_GUIDES := [
	"World/RouteGuides/MainStreetGuide",
	"World/RouteGuides/DockRouteGuide",
	"World/RouteGuides/ExitArrowGuide"
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_player_camera_limits(failures)
	_check_level_collision_and_guides(failures)
	_check_presentation_prompt(failures)
	_check_readme(failures)

	if failures.is_empty():
		print("PASS: Ishiville Pass 18 Level 1 QA smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_player_camera_limits(failures: Array[String]) -> void:
	var scene := load(PLAYER_SCENE)
	if scene == null:
		failures.append("Player scene failed to load")
		return
	var player: Node = scene.instantiate()
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		failures.append("Player missing Camera2D")
	else:
		if camera.limit_left != 0:
			failures.append("Camera limit_left must be 0")
		if camera.limit_top != 0:
			failures.append("Camera limit_top must be 0")
		if camera.limit_right != 320:
			failures.append("Camera limit_right must be 320")
		if camera.limit_bottom != 180:
			failures.append("Camera limit_bottom must be 180")
		if not camera.limit_smoothed:
			failures.append("Camera limit_smoothed should be enabled for PC readability")
	player.free()


func _check_level_collision_and_guides(failures: Array[String]) -> void:
	var scene := load(LEVEL_01_SCENE)
	if scene == null:
		failures.append("Level 1 scene failed to load")
		return
	var level: Node = scene.instantiate()
	var blockers := level.get_node_or_null("World/CollisionBlockers")
	if blockers == null:
		failures.append("Level 1 missing World/CollisionBlockers")
	else:
		for blocker_name in REQUIRED_BLOCKERS.keys():
			var blocker := blockers.get_node_or_null(blocker_name) as StaticBody2D
			if blocker == null:
				failures.append("Level 1 missing blocker %s" % blocker_name)
				continue
			var shape_node := blocker.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if shape_node == null or not (shape_node.shape is RectangleShape2D):
				failures.append("Blocker %s must have RectangleShape2D collision" % blocker_name)
				continue
			var rect := shape_node.shape as RectangleShape2D
			var minimum: Vector2 = REQUIRED_BLOCKERS[blocker_name]
			if rect.size.x < minimum.x or rect.size.y < minimum.y:
				failures.append("Blocker %s too small: %s" % [blocker_name, rect.size])
			var visual := blocker.get_node_or_null("DebugTint") as CanvasItem
			if visual == null:
				failures.append("Blocker %s needs a subtle DebugTint visual" % blocker_name)
	for guide_path in REQUIRED_GUIDES:
		var guide := level.get_node_or_null(guide_path) as Line2D
		if guide == null:
			failures.append("Level 1 missing route guide %s" % guide_path)
			continue
		if guide.points.size() < 2:
			failures.append("Route guide %s must have at least two points" % guide_path)
		if guide.width < 2.0:
			failures.append("Route guide %s must be visible at 1x" % guide_path)
	level.free()


func _check_presentation_prompt(failures: Array[String]) -> void:
	if not ResourceLoader.exists(PRESENTATION_GUIDE, "Script"):
		failures.append("Presentation guide script missing")
		return
	var guide_script: Script = load(PRESENTATION_GUIDE)
	var guide: Node = guide_script.new()
	if not guide.has_method("build_pc_overlay"):
		failures.append("Presentation guide missing build_pc_overlay")
		guide.free()
		return
	var overlay: Control = guide.build_pc_overlay()
	var prompt_panel := overlay.get_node_or_null("PromptPanel") as Panel
	if prompt_panel == null:
		failures.append("PC overlay missing PromptPanel")
	else:
		var prompt_label := prompt_panel.get_node_or_null("PromptLabel") as Label
		if prompt_label == null:
			failures.append("PromptPanel missing PromptLabel")
		elif not prompt_label.text.contains("E/Enter"):
			failures.append("PromptLabel must mention E/Enter interact")
	overlay.free()
	guide.free()


func _check_readme(failures: Array[String]) -> void:
	var readme := FileAccess.get_file_as_string("res://README.md")
	for required_text in [
		"Pass 18 Level 1 QA polish",
		"camera limits",
		"collision blockers",
		"route guides"
	]:
		if not readme.contains(required_text):
			failures.append("README missing Pass 18 note: %s" % required_text)
