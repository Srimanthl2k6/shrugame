extends SceneTree

const LEVEL_05_SCENE := "res://scenes/levels/level_05.tscn"
const LEVEL_05_CONTROLLER := "res://scripts/levels/level_05_controller.gd"
const PRESENTATION_GUIDE := "res://scripts/visual/presentation_guide.gd"

const REQUIRED_ROUTE_PANELS := [
	"World/ClarityLayer/PubRoutePanel",
	"World/ClarityLayer/SuhasRoutePanel",
	"World/ClarityLayer/BikeGuitarRoutePanel",
	"World/ClarityLayer/MansionRoutePanel",
	"World/ClarityLayer/SRMTRoutePanel",
	"World/ClarityLayer/IshiYogaRoutePanel",
	"World/ClarityLayer/EndingRoutePanel"
]

const REQUIRED_ROUTE_LINES := [
	"World/ClarityLayer/CriticalPathRail",
	"World/RouteGuides/PubGuide",
	"World/RouteGuides/SuhasGuide",
	"World/RouteGuides/BikeGuitarGuide",
	"World/RouteGuides/MansionGuide",
	"World/RouteGuides/SRMTGuide",
	"World/RouteGuides/IshiYogaGuide",
	"World/RouteGuides/EndingGuide"
]

const REQUIRED_LANDMARK_LABELS := {
	"World/LandmarkLabels/PubLabel": "Gummies Pub",
	"World/LandmarkLabels/SuhasLabel": "Suhas",
	"World/LandmarkLabels/BikeLabel": "Bike",
	"World/LandmarkLabels/GuitarLabel": "Guitar",
	"World/LandmarkLabels/MansionLabel": "Fallen Mansion",
	"World/LandmarkLabels/SRMTLabel": "SRMT Throne",
	"World/LandmarkLabels/IshiYogaLabel": "IshiYoga",
	"World/LandmarkLabels/EndingLabel": "Ending"
}

const REQUIRED_STEP_LABELS := {
	"World/ClarityLayer/FirstRouteSteps/StepPub": "1",
	"World/ClarityLayer/FirstRouteSteps/StepSuhas": "2",
	"World/ClarityLayer/FirstRouteSteps/StepGear": "3",
	"World/ClarityLayer/FirstRouteSteps/StepMansion": "4",
	"World/ClarityLayer/FirstRouteSteps/StepSRMT": "5",
	"World/ClarityLayer/FirstRouteSteps/StepIshiYoga": "6",
	"World/ClarityLayer/FirstRouteSteps/StepEnding": "7"
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_level05_authored_clarity(failures)
	_check_controller_route_summary(failures)
	_check_presentation_route_overlay(failures)
	_check_readme(failures)

	if failures.is_empty():
		print("PASS: Ishiville Pass 26 Level 5 visual clarity smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_level05_authored_clarity(failures: Array[String]) -> void:
	var scene := load(LEVEL_05_SCENE)
	if scene == null:
		failures.append("Level 5 scene failed to load")
		return
	var level: Node = scene.instantiate()
	var clarity_layer := level.get_node_or_null("World/ClarityLayer") as Node2D
	if clarity_layer == null:
		failures.append("Level 5 needs World/ClarityLayer authored into the scene")
	else:
		if clarity_layer.z_index > -3:
			failures.append("Level 5 ClarityLayer should sit behind actors but above base art")
	for panel_path in REQUIRED_ROUTE_PANELS:
		var panel := level.get_node_or_null(panel_path) as Polygon2D
		if panel == null:
			failures.append("Level 5 missing route panel %s" % panel_path)
			continue
		if panel.polygon.size() < 4:
			failures.append("%s needs a readable polygon area" % panel_path)
		if panel.color.a < 0.32:
			failures.append("%s alpha must be strong enough to read at PC scale" % panel_path)
	for line_path in REQUIRED_ROUTE_LINES:
		var line := level.get_node_or_null(line_path) as Line2D
		if line == null:
			failures.append("Level 5 missing readable route line %s" % line_path)
			continue
		if line.points.size() < 2:
			failures.append("%s must have at least two points" % line_path)
		if line.width < 3.0:
			failures.append("%s must be at least 3 px wide" % line_path)
		if line.default_color.a < 0.62:
			failures.append("%s must have high enough alpha for PC readability" % line_path)
	for label_path in REQUIRED_LANDMARK_LABELS.keys():
		var label := level.get_node_or_null(label_path) as Label
		if label == null:
			failures.append("Level 5 missing landmark label %s" % label_path)
			continue
		if not label.text.contains(str(REQUIRED_LANDMARK_LABELS[label_path])):
			failures.append("%s should name %s" % [label_path, REQUIRED_LANDMARK_LABELS[label_path]])
		if label.custom_minimum_size.x < 58.0 or label.custom_minimum_size.y < 13.0:
			failures.append("%s needs stable readable dimensions" % label_path)
		if label.get_theme_constant("outline_size") < 2:
			failures.append("%s needs text outline for contrast" % label_path)
	for step_path in REQUIRED_STEP_LABELS.keys():
		var label := level.get_node_or_null(step_path) as Label
		if label == null:
			failures.append("Level 5 missing critical-path step label %s" % step_path)
			continue
		if not label.text.begins_with(str(REQUIRED_STEP_LABELS[step_path])):
			failures.append("%s should begin with route step %s" % [step_path, REQUIRED_STEP_LABELS[step_path]])
	level.free()


func _check_controller_route_summary(failures: Array[String]) -> void:
	if not ResourceLoader.exists(LEVEL_05_CONTROLLER, "Script"):
		failures.append("Level 5 controller script missing")
		return
	var controller: Node = load(LEVEL_05_CONTROLLER).new()
	if not controller.has_method("get_level05_route_summary"):
		failures.append("Level 5 controller needs get_level05_route_summary")
		controller.free()
		return
	var summary: Array = controller.get_level05_route_summary()
	if summary.size() < 7:
		failures.append("Level 5 route summary should list the seven critical path beats")
	var joined := " ".join(PackedStringArray(summary))
	for required_text in ["pub", "Suhas", "bike", "guitar", "mansion", "SRMT", "IshiYoga", "ending"]:
		if not joined.contains(required_text):
			failures.append("Level 5 route summary missing %s" % required_text)
	controller.free()


func _check_presentation_route_overlay(failures: Array[String]) -> void:
	if not ResourceLoader.exists(PRESENTATION_GUIDE, "Script"):
		failures.append("Presentation guide script missing")
		return
	var guide: Node = load(PRESENTATION_GUIDE).new()
	if not guide.has_method("get_route_steps_text"):
		failures.append("PresentationGuide needs get_route_steps_text")
		guide.free()
		return
	var route_text := str(guide.get_route_steps_text("Level05"))
	for required_text in ["pub", "Suhas", "bike", "guitar", "mansion", "SRMT", "IshiYoga", "ending"]:
		if not route_text.contains(required_text):
			failures.append("Level 5 route overlay missing %s" % required_text)
	guide.free()


func _check_readme(failures: Array[String]) -> void:
	var readme := FileAccess.get_file_as_string("res://README.md")
	for required_text in [
		"Pass 26 Level 5 Area 111 visual clarity",
		"Area 111 authored clarity layer",
		"Gummies Pub",
		"SRMT route",
		"IshiYoga rescue route"
	]:
		if not readme.contains(required_text):
			failures.append("README missing Pass 26 note: %s" % required_text)
