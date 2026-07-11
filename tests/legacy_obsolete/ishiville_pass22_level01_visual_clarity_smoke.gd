extends SceneTree

const LEVEL_01_SCENE := "res://scenes/levels/level_01.tscn"
const LEVEL_01_CONTROLLER := "res://scripts/levels/level_01_controller.gd"
const PRESENTATION_GUIDE := "res://scripts/visual/presentation_guide.gd"

const REQUIRED_ROUTE_PANELS := [
	"World/ClarityLayer/StreetRoutePanel",
	"World/ClarityLayer/DockRoutePanel",
	"World/ClarityLayer/ExitRoutePanel"
]

const REQUIRED_ROUTE_LINES := [
	"World/ClarityLayer/CriticalPathRail",
	"World/RouteGuides/MainStreetGuide",
	"World/RouteGuides/DockRouteGuide",
	"World/RouteGuides/ExitArrowGuide"
]

const REQUIRED_LANDMARK_LABELS := {
	"World/LandmarkLabels/FakeChickenLabel": "Fake Chicken",
	"World/LandmarkLabels/SheriffOfficeLabel": "Sheriff",
	"World/LandmarkLabels/DockRouteLabel": "Dock",
	"World/LandmarkLabels/SatyakiLabel": "Satyaki",
	"World/LandmarkLabels/ExitLabel": "Banana-burbs"
}

const REQUIRED_STEP_LABELS := {
	"World/ClarityLayer/FirstRouteSteps/StepDoor": "1",
	"World/ClarityLayer/FirstRouteSteps/StepPoojan": "2",
	"World/ClarityLayer/FirstRouteSteps/StepRecords": "3",
	"World/ClarityLayer/FirstRouteSteps/StepSatyaki": "4",
	"World/ClarityLayer/FirstRouteSteps/StepExit": "5"
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_level01_authored_clarity(failures)
	_check_controller_route_summary(failures)
	_check_presentation_route_overlay(failures)
	_check_readme(failures)

	if failures.is_empty():
		print("PASS: Ishiville Pass 22 Level 1 visual clarity smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_level01_authored_clarity(failures: Array[String]) -> void:
	var scene := load(LEVEL_01_SCENE)
	if scene == null:
		failures.append("Level 1 scene failed to load")
		return
	var level: Node = scene.instantiate()
	var clarity_layer := level.get_node_or_null("World/ClarityLayer") as Node2D
	if clarity_layer == null:
		failures.append("Level 1 needs World/ClarityLayer authored into the scene")
	else:
		if clarity_layer.z_index > -3:
			failures.append("ClarityLayer should sit behind actors but above the painted backplate")
	for panel_path in REQUIRED_ROUTE_PANELS:
		var panel := level.get_node_or_null(panel_path) as Polygon2D
		if panel == null:
			failures.append("Level 1 missing route panel %s" % panel_path)
			continue
		if not panel.visible:
			failures.append("%s must be visible" % panel_path)
		if panel.polygon.size() < 4:
			failures.append("%s needs a readable polygon area" % panel_path)
		if panel.color.a < 0.32:
			failures.append("%s alpha must be strong enough to read at PC scale" % panel_path)
	for line_path in REQUIRED_ROUTE_LINES:
		var line := level.get_node_or_null(line_path) as Line2D
		if line == null:
			failures.append("Level 1 missing readable route line %s" % line_path)
			continue
		if line.width < 3.0:
			failures.append("%s must be at least 3 px wide" % line_path)
		if line.default_color.a < 0.62:
			failures.append("%s must have high enough alpha for PC readability" % line_path)
	for label_path in REQUIRED_LANDMARK_LABELS.keys():
		var label := level.get_node_or_null(label_path) as Label
		if label == null:
			failures.append("Level 1 missing landmark label %s" % label_path)
			continue
		if not label.text.contains(str(REQUIRED_LANDMARK_LABELS[label_path])):
			failures.append("%s should name %s" % [label_path, REQUIRED_LANDMARK_LABELS[label_path]])
		if label.custom_minimum_size.x < 54.0 or label.custom_minimum_size.y < 13.0:
			failures.append("%s needs stable readable dimensions" % label_path)
		if label.get_theme_constant("outline_size") < 2:
			failures.append("%s needs text outline for contrast" % label_path)
	for step_path in REQUIRED_STEP_LABELS.keys():
		var label := level.get_node_or_null(step_path) as Label
		if label == null:
			failures.append("Level 1 missing critical-path step label %s" % step_path)
			continue
		if not label.text.begins_with(str(REQUIRED_STEP_LABELS[step_path])):
			failures.append("%s should begin with route step %s" % [step_path, REQUIRED_STEP_LABELS[step_path]])
	level.free()


func _check_controller_route_summary(failures: Array[String]) -> void:
	if not ResourceLoader.exists(LEVEL_01_CONTROLLER, "Script"):
		failures.append("Level 1 controller script missing")
		return
	var controller: Node = load(LEVEL_01_CONTROLLER).new()
	if not controller.has_method("get_level01_route_summary"):
		failures.append("Level 1 controller needs get_level01_route_summary")
		controller.free()
		return
	var summary: Array = controller.get_level01_route_summary()
	if summary.size() < 5:
		failures.append("Level 1 route summary should list the five critical path beats")
	var joined := " ".join(PackedStringArray(summary))
	for required_text in ["KFC", "Poojan", "records", "Satyaki", "Banana-burbs"]:
		if not joined.contains(required_text):
			failures.append("Level 1 route summary missing %s" % required_text)
	controller.free()


func _check_presentation_route_overlay(failures: Array[String]) -> void:
	if not ResourceLoader.exists(PRESENTATION_GUIDE, "Script"):
		failures.append("Presentation guide script missing")
		return
	var guide: Node = load(PRESENTATION_GUIDE).new()
	var overlay: Control = guide.build_pc_overlay()
	var route_panel := overlay.get_node_or_null("RouteStepsPanel") as Panel
	if route_panel == null:
		failures.append("PC overlay missing RouteStepsPanel")
	else:
		var route_label := route_panel.get_node_or_null("RouteStepsLabel") as Label
		if route_label == null:
			failures.append("RouteStepsPanel missing RouteStepsLabel")
		else:
			for required_text in ["door", "Poojan", "records", "Satyaki", "exit"]:
				if not route_label.text.contains(required_text):
					failures.append("RouteStepsLabel missing %s" % required_text)
	overlay.free()
	guide.free()


func _check_readme(failures: Array[String]) -> void:
	var readme := FileAccess.get_file_as_string("res://README.md")
	for required_text in [
		"Pass 22 Level 1 full playthrough visual clarity",
		"authored clarity layer",
		"landmark labels",
		"critical-path route"
	]:
		if not readme.contains(required_text):
			failures.append("README missing Pass 22 note: %s" % required_text)
