extends SceneTree

const PRESENTATION_GUIDE_PATH := "res://scripts/visual/presentation_guide.gd"
const LEVEL_SCENES := [
	"res://scenes/levels/level_01.tscn",
	"res://scenes/levels/level_02.tscn",
	"res://scenes/levels/level_03.tscn",
	"res://scenes/levels/level_04.tscn",
	"res://scenes/levels/level_05.tscn"
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_pc_window_settings(failures)
	_check_main_menu_readability(failures)
	_check_presentation_guide_autoload(failures)
	_check_runtime_level_decoration(failures)

	if failures.is_empty():
		print("PASS: Ishiville Pass 16 visual readability smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_pc_window_settings(failures: Array[String]) -> void:
	if int(ProjectSettings.get_setting("display/window/size/viewport_width")) != 320:
		failures.append("Base viewport must remain 320 wide for pixel art")
	if int(ProjectSettings.get_setting("display/window/size/viewport_height")) != 180:
		failures.append("Base viewport must remain 180 high for pixel art")
	if int(ProjectSettings.get_setting("display/window/size/window_width_override", 0)) < 960:
		failures.append("PC window width override must be at least 960")
	if int(ProjectSettings.get_setting("display/window/size/window_height_override", 0)) < 540:
		failures.append("PC window height override must be at least 540")
	if ProjectSettings.get_setting("display/window/stretch/scale_mode") != "integer":
		failures.append("Pixel scale mode must remain integer")


func _check_main_menu_readability(failures: Array[String]) -> void:
	var scene := load("res://scenes/main.tscn")
	if scene == null:
		failures.append("Main scene failed to load")
		return
	var main: Node = scene.instantiate()
	var panel := main.get_node_or_null("TitleLayer/Panel") as Control
	if panel == null:
		failures.append("Main menu missing TitleLayer/Panel")
	else:
		if panel.size.x < 240.0 or panel.size.y < 130.0:
			failures.append("Main menu panel must be large enough for PC readability")
	for node_path in [
		"TitleLayer/Panel/NewGameButton",
		"TitleLayer/Panel/ContinueButton",
		"TitleLayer/Panel/QuitButton",
		"TitleLayer/Panel/SubtitleLabel",
		"TitleLayer/Panel/ControlsLabel"
	]:
		if main.get_node_or_null(node_path) == null:
			failures.append("Main menu missing %s" % node_path)
	main.free()


func _check_presentation_guide_autoload(failures: Array[String]) -> void:
	if not ProjectSettings.has_setting("autoload/PresentationGuide"):
		failures.append("PresentationGuide must be registered as an autoload")
	if not ResourceLoader.exists(PRESENTATION_GUIDE_PATH, "Script"):
		failures.append("Missing presentation guide script")
		return
	var guide_script: Script = load(PRESENTATION_GUIDE_PATH)
	var guide: Node = guide_script.new()
	for method_name in ["decorate_scene", "build_pc_overlay", "get_area_display_name"]:
		if not guide.has_method(method_name):
			failures.append("PresentationGuide missing %s" % method_name)
	guide.free()


func _check_runtime_level_decoration(failures: Array[String]) -> void:
	if not ResourceLoader.exists(PRESENTATION_GUIDE_PATH, "Script"):
		return
	var guide_script: Script = load(PRESENTATION_GUIDE_PATH)
	for level_path in LEVEL_SCENES:
		var scene := load(level_path)
		if scene == null:
			failures.append("%s failed to load" % level_path)
			continue
		var level: Node = scene.instantiate()
		var guide: Node = guide_script.new()
		if guide.has_method("decorate_scene"):
			guide.decorate_scene(level)
		var boundary_walls := level.get_node_or_null("World/BoundaryWalls")
		if boundary_walls == null or boundary_walls.get_child_count() < 4:
			failures.append("%s must receive visible collision boundaries" % level_path)
		var labels := level.get_node_or_null("World/MapLabels")
		if labels == null or labels.get_child_count() < 6:
			failures.append("%s must receive readable object labels" % level_path)
		var visual_markers := level.get_node_or_null("World/ReadableMarkers")
		if visual_markers == null or visual_markers.get_child_count() < 6:
			failures.append("%s must receive readable object markers" % level_path)
		var overlay: Control = guide.build_pc_overlay()
		if overlay.get_node_or_null("TopBar") == null:
			failures.append("PC overlay missing TopBar")
		if overlay.get_node_or_null("LegendPanel") == null:
			failures.append("PC overlay missing LegendPanel")
		overlay.free()
		guide.free()
		level.free()
