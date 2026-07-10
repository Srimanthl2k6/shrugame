extends SceneTree

const PRESENTATION_GUIDE := "res://scripts/visual/presentation_guide.gd"
const OBJECTIVE_TRACKER := "res://scenes/ui/objective_tracker.tscn"
const CLUE_JOURNAL := "res://scenes/ui/clue_journal.tscn"
const LEVEL_01 := "res://scenes/levels/level_01.tscn"

const MAX_OVERLAY_FONT_SIZE := 8
const MAX_WORLD_LABEL_FONT_SIZE := 6
const MAX_OBJECTIVE_FONT_SIZE := 7
const MAX_CLUE_JOURNAL_FONT_SIZE := 7
const MAX_OVERLAY_PANEL_AREA := 14500.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_overlay_scale_budget(failures)
	_check_runtime_world_label_scale(failures)
	_check_objective_tracker_scale(failures)
	_check_clue_journal_default_state(failures)

	if failures.is_empty():
		print("PASS: Ishiville Pass 29 presentation scale regression smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_overlay_scale_budget(failures: Array[String]) -> void:
	var guide := _make_guide(failures)
	if guide == null:
		return
	var overlay: Control = guide.build_pc_overlay()
	var labels: Array[Label] = []
	_collect_labels(overlay, labels)
	for label in labels:
		var font_size := label.get_theme_font_size("font_size")
		if font_size > MAX_OVERLAY_FONT_SIZE:
			failures.append("%s overlay font is %d; max is %d" % [label.name, font_size, MAX_OVERLAY_FONT_SIZE])
	var panel_area := 0.0
	for panel_name in ["TopBar", "RouteStepsPanel", "PromptPanel", "LegendPanel"]:
		var panel := overlay.get_node_or_null(panel_name) as Control
		if panel == null:
			failures.append("Overlay missing %s" % panel_name)
			continue
		panel_area += panel.size.x * panel.size.y
	if panel_area > MAX_OVERLAY_PANEL_AREA:
		failures.append("Overlay panels consume %.1f px; max is %.1f" % [panel_area, MAX_OVERLAY_PANEL_AREA])
	overlay.free()
	guide.free()


func _check_runtime_world_label_scale(failures: Array[String]) -> void:
	var guide := _make_guide(failures)
	var scene := load(LEVEL_01)
	if guide == null or scene == null:
		failures.append("Could not load guide or Level 1 for world label scale check")
		return
	var level: Node = scene.instantiate()
	guide.decorate_scene(level)
	var generated_labels := level.get_node_or_null("World/MapLabels") as CanvasItem
	if generated_labels == null:
		failures.append("Runtime map label layer missing")
	elif generated_labels.visible:
		failures.append("Runtime-generated map labels should be hidden by default to avoid duplicate screen text")
	var labels: Array[Label] = []
	_collect_labels(level.get_node("World"), labels)
	for label in labels:
		var font_size := label.get_theme_font_size("font_size")
		if font_size > MAX_WORLD_LABEL_FONT_SIZE:
			failures.append("%s world label font is %d; max is %d" % [label.name, font_size, MAX_WORLD_LABEL_FONT_SIZE])
	level.free()
	guide.free()


func _check_objective_tracker_scale(failures: Array[String]) -> void:
	var scene := load(OBJECTIVE_TRACKER)
	if scene == null:
		failures.append("Objective tracker scene failed to load")
		return
	var tracker: Node = scene.instantiate()
	var tracker_control := tracker as Control
	if tracker_control != null and tracker_control.visible:
		failures.append("Objective tracker should be hidden by default because PresentationGuide owns the visible objective overlay")
	var label := tracker.get_node_or_null("Panel/ObjectiveLabel") as Label
	if label == null:
		failures.append("Objective tracker missing Panel/ObjectiveLabel")
	else:
		var font_size := label.get_theme_font_size("font_size")
		if font_size > MAX_OBJECTIVE_FONT_SIZE:
			failures.append("Objective tracker font is %d; max is %d" % [font_size, MAX_OBJECTIVE_FONT_SIZE])
	tracker.free()


func _check_clue_journal_default_state(failures: Array[String]) -> void:
	var scene := load(CLUE_JOURNAL)
	if scene == null:
		failures.append("Clue journal scene failed to load")
		return
	var journal: Control = scene.instantiate()
	if journal.visible:
		failures.append("Clue journal should be hidden by default so it does not cover the playfield")
	var label := journal.get_node_or_null("Panel/ClueLabel") as Label
	if label == null:
		failures.append("Clue journal missing Panel/ClueLabel")
	else:
		var font_size := label.get_theme_font_size("font_size")
		if font_size > MAX_CLUE_JOURNAL_FONT_SIZE:
			failures.append("Clue journal font is %d; max is %d" % [font_size, MAX_CLUE_JOURNAL_FONT_SIZE])
	journal.free()


func _make_guide(failures: Array[String]) -> Node:
	if not ResourceLoader.exists(PRESENTATION_GUIDE, "Script"):
		failures.append("Presentation guide script missing")
		return null
	return load(PRESENTATION_GUIDE).new()


func _collect_labels(node: Node, labels: Array[Label]) -> void:
	for child in node.get_children():
		var label := child as Label
		if label != null:
			labels.append(label)
		_collect_labels(child, labels)
