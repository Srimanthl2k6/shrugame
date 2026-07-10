extends SceneTree

const LEVEL_03_SCENE := "res://scenes/levels/level_03.tscn"
const LEVEL_03_CONTROLLER := "res://scripts/levels/level_03_controller.gd"
const PRESENTATION_GUIDE := "res://scripts/visual/presentation_guide.gd"

const REQUIRED_ROUTE_PANELS := [
	"World/ClarityLayer/BerryRoutePanel",
	"World/ClarityLayer/ContractRoutePanel",
	"World/ClarityLayer/ChefRoutePanel",
	"World/ClarityLayer/AnkitRoutePanel",
	"World/ClarityLayer/ExitRoutePanel"
]

const REQUIRED_ROUTE_LINES := [
	"World/ClarityLayer/CriticalPathRail",
	"World/RouteGuides/BerryGuide",
	"World/RouteGuides/ContractGuide",
	"World/RouteGuides/ChefGuide",
	"World/RouteGuides/AnkitGuide",
	"World/RouteGuides/ExitArrowGuide"
]

const REQUIRED_LANDMARK_LABELS := {
	"World/LandmarkLabels/BerryClustersLabel": "1000 Berries",
	"World/LandmarkLabels/ContractLabel": "Berry Contract",
	"World/LandmarkLabels/NishalLabel": "Nishal",
	"World/LandmarkLabels/BerryShareLabel": "Berry Share",
	"World/LandmarkLabels/AnkitLabel": "Ankit",
	"World/LandmarkLabels/ExitLabel": "Auticity"
}

const REQUIRED_STEP_LABELS := {
	"World/ClarityLayer/FirstRouteSteps/StepBerries": "1",
	"World/ClarityLayer/FirstRouteSteps/StepContract": "2",
	"World/ClarityLayer/FirstRouteSteps/StepNishal": "3",
	"World/ClarityLayer/FirstRouteSteps/StepShare": "4",
	"World/ClarityLayer/FirstRouteSteps/StepAnkit": "5",
	"World/ClarityLayer/FirstRouteSteps/StepExit": "6"
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_level03_authored_clarity(failures)
	_check_controller_route_summary(failures)
	_check_presentation_route_overlay(failures)
	_check_readme(failures)

	if failures.is_empty():
		print("PASS: Ishiville Pass 24 Level 3 visual clarity smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_level03_authored_clarity(failures: Array[String]) -> void:
	var scene := load(LEVEL_03_SCENE)
	if scene == null:
		failures.append("Level 3 scene failed to load")
		return
	var level: Node = scene.instantiate()
	var clarity_layer := level.get_node_or_null("World/ClarityLayer") as Node2D
	if clarity_layer == null:
		failures.append("Level 3 needs World/ClarityLayer authored into the scene")
	else:
		if clarity_layer.z_index > -3:
			failures.append("Level 3 ClarityLayer should sit behind actors but above base art")
	for panel_path in REQUIRED_ROUTE_PANELS:
		var panel := level.get_node_or_null(panel_path) as Polygon2D
		if panel == null:
			failures.append("Level 3 missing route panel %s" % panel_path)
			continue
		if panel.polygon.size() < 4:
			failures.append("%s needs a readable polygon area" % panel_path)
		if panel.color.a < 0.32:
			failures.append("%s alpha must be strong enough to read at PC scale" % panel_path)
	for line_path in REQUIRED_ROUTE_LINES:
		var line := level.get_node_or_null(line_path) as Line2D
		if line == null:
			failures.append("Level 3 missing readable route line %s" % line_path)
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
			failures.append("Level 3 missing landmark label %s" % label_path)
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
			failures.append("Level 3 missing critical-path step label %s" % step_path)
			continue
		if not label.text.begins_with(str(REQUIRED_STEP_LABELS[step_path])):
			failures.append("%s should begin with route step %s" % [step_path, REQUIRED_STEP_LABELS[step_path]])
	level.free()


func _check_controller_route_summary(failures: Array[String]) -> void:
	if not ResourceLoader.exists(LEVEL_03_CONTROLLER, "Script"):
		failures.append("Level 3 controller script missing")
		return
	var controller: Node = load(LEVEL_03_CONTROLLER).new()
	if not controller.has_method("get_level03_route_summary"):
		failures.append("Level 3 controller needs get_level03_route_summary")
		controller.free()
		return
	var summary: Array = controller.get_level03_route_summary()
	if summary.size() < 6:
		failures.append("Level 3 route summary should list the six critical path beats")
	var joined := " ".join(PackedStringArray(summary))
	for required_text in ["berries", "contract", "Nishal", "share", "Ankit", "Auticity"]:
		if not joined.contains(required_text):
			failures.append("Level 3 route summary missing %s" % required_text)
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
	var route_text := str(guide.get_route_steps_text("Level03"))
	for required_text in ["berries", "contract", "Nishal", "share", "Ankit", "exit"]:
		if not route_text.contains(required_text):
			failures.append("Level 3 route overlay missing %s" % required_text)
	guide.free()


func _check_readme(failures: Array[String]) -> void:
	var readme := FileAccess.get_file_as_string("res://README.md")
	for required_text in [
		"Pass 24 Level 3 Berry Barks visual clarity",
		"Berry Barks authored clarity layer",
		"1000 Berries",
		"Ankit route"
	]:
		if not readme.contains(required_text):
			failures.append("README missing Pass 24 note: %s" % required_text)
