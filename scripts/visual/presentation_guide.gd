extends CanvasLayer

const VIEWPORT_SIZE := Vector2(320.0, 180.0)
const PAUSE_MENU_SCENE := preload("res://scenes/ui/pause_menu.tscn")
const WALL_THICKNESS := 8.0
const OVERLAY_FONT_SIZE := 7
const OVERLAY_SMALL_FONT_SIZE := 6
const LEGEND_FONT_SIZE := 5
const WORLD_LABEL_FONT_SIZE := 5
const WORLD_STEP_FONT_SIZE := 5
const UI_OUTLINE_SIZE := 1

const LEVEL_TITLES := {
	"Level01": "Divorcee Harbour",
	"Level02": "Banana-burbs",
	"Level03": "Berry Barks",
	"Level04": "Auticity",
	"Level05": "Area 111"
}

const ROUTE_STEPS := {
	"Level01": "Route: door > Poojan > records > Satyaki > exit",
	"Level02": "Route: monkeys > 165-files > Nitin > popcorn > Deepak > exit",
	"Level03": "Route: berries > contract > Nishal > share > Ankit > exit",
	"Level04": "Route: puns > records > Sushan > festival > Mitta > exit",
	"Level05": "Route: pub > Suhas > bike/guitar > mansion > SRMT > IshiYoga > ending"
}

const DISPLAY_NAMES := {
	"KfcDoor": "Fake chicken door",
	"HarbourResident": "Harbour resident",
	"NoticeSign": "Harbour notice",
	"Marn": "Shelf echo",
	"TagFlour": "FLOUR tag",
	"TagCups": "CUPS tag",
	"TagBroom": "BROOM tag",
	"PracticeEncounter": "Old battle",
	"SheriffPoojan": "Sheriff Poojan",
	"DivorceRecords": "Divorce records",
	"SatyakiApproach": "Dock route",
	"SatyakiBoss": "Satyaki Tirumal",
	"SavePoint": "Save point",
	"TransitionDoor": "Exit route",
	"LabRecords": "165-files",
	"NitinBoss": "Nitin",
	"MonkeyPopcorn": "KFC popcorn",
	"DeepakBoss": "Deepak Reddy",
	"BerryContract": "Berry contract",
	"NishalBoss": "Nishal",
	"BerryShare": "Berry share",
	"AnkitBoss": "Ankit",
	"HospitalRecords": "Hospital records",
	"SushanBoss": "Doctor Sushan",
	"AeonFestival": "Aeon Festival",
	"MittaBoss": "Mitta",
	"PubCounter": "Gummies bar",
	"SuhasBoss": "Suhas",
	"CourtClues": "Court clues",
	"SrmtBoss": "SRMT",
	"IshiYogaRescue": "IshiYoga"
}

const CATEGORY_COLORS := {
	"npc": Color(0.95, 0.62, 0.82, 1.0),
	"boss": Color(1.0, 0.24, 0.2, 1.0),
	"clue": Color(1.0, 0.86, 0.32, 1.0),
	"save": Color(0.3, 0.78, 1.0, 1.0),
	"exit": Color(0.38, 1.0, 0.62, 1.0),
	"object": Color(0.9, 0.76, 0.48, 1.0)
}

var _overlay: Control
var _area_label: Label
var _objective_label: Label
var _route_steps_label: Label
var _last_level_instance_id := 0


func _ready() -> void:
	layer = 35
	_overlay = build_pc_overlay()
	add_child(_overlay)
	_overlay.visible = false
	set_process(true)
	call_deferred("_refresh_presentation")


func _process(_delta: float) -> void:
	_refresh_presentation()


func decorate_scene(level_root: Node) -> void:
	if level_root == null or not level_root.has_node("World"):
		return
	var world := level_root.get_node("World") as Node2D
	if world == null:
		return
	if world.get_node_or_null("BoundaryWalls") == null:
		_add_level_boundaries(world)
	if world.get_node_or_null("ReadableMarkers") == null:
		_add_readable_markers(world)
	for obsolete_path in ["RouteGuides", "ClarityLayer", "LandmarkLabels", "ReadableMarkers", "MapLabels", "PlayableFrame", "ForestFloor", "DouglasFirTown", "CityFloor", "PinkRuins"]:
		var obsolete := world.get_node_or_null(obsolete_path) as CanvasItem
		if obsolete != null:
			obsolete.visible = false
	_hide_polygon_blockouts(world)
	if level_root.get_node_or_null("PauseMenu") == null:
		var pause_menu := PAUSE_MENU_SCENE.instantiate()
		pause_menu.name = "PauseMenu"
		level_root.add_child(pause_menu)
	_scale_world_labels(world)


func build_pc_overlay() -> Control:
	var root := Control.new()
	root.name = "Root"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root.size = VIEWPORT_SIZE
	root.scale = Vector2(2.0, 2.0)

	var top_bar := Panel.new()
	top_bar.name = "TopBar"
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.offset_left = 6.0
	top_bar.offset_top = 5.0
	top_bar.offset_right = 314.0
	top_bar.offset_bottom = 21.0
	top_bar.add_theme_stylebox_override("panel", _make_style_box(Color(0.015, 0.018, 0.026, 0.9), Color(0.66, 0.78, 0.86, 1.0)))
	root.add_child(top_bar)

	_area_label = Label.new()
	_area_label.name = "AreaLabel"
	_area_label.offset_left = 7.0
	_area_label.offset_top = 2.0
	_area_label.offset_right = 88.0
	_area_label.offset_bottom = 14.0
	_area_label.text = "Area"
	_style_label(_area_label, OVERLAY_FONT_SIZE, Color(0.95, 0.9, 0.72, 1.0))
	top_bar.add_child(_area_label)

	_objective_label = Label.new()
	_objective_label.name = "ObjectiveLabel"
	_objective_label.offset_left = 92.0
	_objective_label.offset_top = 2.0
	_objective_label.offset_right = 302.0
	_objective_label.offset_bottom = 14.0
	_objective_label.text = "Goal: Find KFC."
	_objective_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_style_label(_objective_label, OVERLAY_FONT_SIZE, Color(0.88, 0.95, 1.0, 1.0))
	top_bar.add_child(_objective_label)

	var legend_panel := Panel.new()
	legend_panel.name = "LegendPanel"
	legend_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	legend_panel.offset_left = 8.0
	legend_panel.offset_top = 164.0
	legend_panel.offset_right = 312.0
	legend_panel.offset_bottom = 176.0
	legend_panel.add_theme_stylebox_override("panel", _make_style_box(Color(0.01, 0.011, 0.018, 0.86), Color(0.5, 0.58, 0.64, 1.0)))
	root.add_child(legend_panel)
	legend_panel.visible = false

	var legend_label := Label.new()
	legend_label.name = "LegendLabel"
	legend_label.offset_left = 6.0
	legend_label.offset_top = 1.0
	legend_label.offset_right = 298.0
	legend_label.offset_bottom = 10.0
	legend_label.text = "NPC pink  Boss red  Clue yellow  Save blue  Exit green"
	legend_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_style_label(legend_label, LEGEND_FONT_SIZE, Color(0.92, 0.94, 0.9, 1.0))
	legend_panel.add_child(legend_label)

	var prompt_panel := Panel.new()
	prompt_panel.name = "PromptPanel"
	prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_panel.offset_left = 100.0
	prompt_panel.offset_top = 140.0
	prompt_panel.offset_right = 220.0
	prompt_panel.offset_bottom = 152.0
	prompt_panel.add_theme_stylebox_override("panel", _make_style_box(Color(0.012, 0.014, 0.02, 0.78), Color(0.86, 0.72, 0.34, 0.88)))
	root.add_child(prompt_panel)
	prompt_panel.visible = false

	var prompt_label := Label.new()
	prompt_label.name = "PromptLabel"
	prompt_label.offset_left = 5.0
	prompt_label.offset_top = 1.0
	prompt_label.offset_right = 115.0
	prompt_label.offset_bottom = 10.0
	prompt_label.text = "E/Enter interact near labels"
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_style_label(prompt_label, OVERLAY_SMALL_FONT_SIZE, Color(0.98, 0.9, 0.62, 1.0))
	prompt_panel.add_child(prompt_label)

	var route_steps_panel := Panel.new()
	route_steps_panel.name = "RouteStepsPanel"
	route_steps_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	route_steps_panel.offset_left = 8.0
	route_steps_panel.offset_top = 23.0
	route_steps_panel.offset_right = 312.0
	route_steps_panel.offset_bottom = 34.0
	route_steps_panel.add_theme_stylebox_override("panel", _make_style_box(Color(0.014, 0.016, 0.022, 0.78), Color(0.98, 0.82, 0.28, 0.8)))
	root.add_child(route_steps_panel)
	route_steps_panel.visible = false

	_route_steps_label = Label.new()
	_route_steps_label.name = "RouteStepsLabel"
	_route_steps_label.offset_left = 5.0
	_route_steps_label.offset_top = 1.0
	_route_steps_label.offset_right = 299.0
	_route_steps_label.offset_bottom = 9.0
	_route_steps_label.text = get_route_steps_text("Level01")
	_route_steps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_route_steps_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_style_label(_route_steps_label, OVERLAY_SMALL_FONT_SIZE, Color(1.0, 0.9, 0.56, 1.0))
	route_steps_panel.add_child(_route_steps_label)

	return root


func get_route_steps_text(level_name: String) -> String:
	return str(ROUTE_STEPS.get(level_name, "Route: inspect > talk > clue > boss > exit"))


func get_area_display_name(area: Node) -> String:
	if area == null:
		return "Object"
	var node_name := str(area.name)
	if DISPLAY_NAMES.has(node_name):
		return str(DISPLAY_NAMES[node_name])
	return _split_camel_case(node_name)


func _refresh_presentation() -> void:
	var level_root := _find_level_root()
	if level_root == null:
		if _overlay != null:
			_overlay.visible = false
		return
	var instance_id := int(level_root.get_instance_id())
	if instance_id != _last_level_instance_id:
		decorate_scene(level_root)
		_last_level_instance_id = instance_id
	if _overlay != null:
		var show_objectives := true
		var settings_manager := get_node_or_null("/root/SettingsManager")
		if settings_manager != null:
			show_objectives = bool(settings_manager.get_setting("show_objectives", true))
		var director := get_node_or_null("/root/CutsceneDirector")
		var cutscene_active: bool = director != null and bool(director.is_playing)
		_overlay.visible = not _title_layer_is_visible() and not cutscene_active and show_objectives
	_update_overlay_text(level_root)
	_update_context_prompt(level_root)


func _find_level_root() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	var current := tree.current_scene
	if current == null:
		return null
	if current.has_node("World"):
		return current
	for child in current.get_children():
		var node_child := child as Node
		if node_child != null and node_child.has_node("World"):
			return node_child
	return null


func _title_layer_is_visible() -> bool:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return false
	var title_layer := tree.current_scene.get_node_or_null("TitleLayer") as CanvasLayer
	return title_layer != null and title_layer.visible


func _update_overlay_text(level_root: Node) -> void:
	if _area_label != null:
		_area_label.text = str(LEVEL_TITLES.get(str(level_root.name), str(level_root.name)))
	if _objective_label == null:
		return
	var objective_text := "Find KFC."
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and game_state.has_method("get_current_objective"):
		var state_objective := str(game_state.get_current_objective())
		if not state_objective.is_empty():
			objective_text = state_objective
	_objective_label.text = "Goal: %s" % objective_text
	if _route_steps_label != null:
		_route_steps_label.text = get_route_steps_text(str(level_root.name))


func _update_context_prompt(level_root: Node) -> void:
	if _overlay == null:
		return
	var prompt_panel := _overlay.get_node_or_null("PromptPanel") as Control
	var prompt_label := _overlay.get_node_or_null("PromptPanel/PromptLabel") as Label
	if prompt_panel == null or prompt_label == null:
		return
	var focused_area := _find_focused_area(level_root)
	prompt_panel.visible = focused_area != null and _overlay.visible
	if focused_area != null:
		if focused_area.has_method("get_focus_prompt"):
			prompt_label.text = focused_area.get_focus_prompt()
		else:
			prompt_label.text = "E/Enter: %s" % get_area_display_name(focused_area)


func _find_focused_area(node: Node) -> Area2D:
	for child in node.get_children():
		var area := child as Area2D
		if area != null and bool(area.get("_player_inside")):
			return area
		var nested := _find_focused_area(child)
		if nested != null:
			return nested
	return null


func _add_level_boundaries(world: Node2D) -> void:
	var layer := Node2D.new()
	layer.name = "BoundaryWalls"
	world.add_child(layer)
	_add_wall(layer, "TopWall", Vector2(VIEWPORT_SIZE.x * 0.5, WALL_THICKNESS * 0.5), Vector2(VIEWPORT_SIZE.x, WALL_THICKNESS))
	_add_wall(layer, "BottomWall", Vector2(VIEWPORT_SIZE.x * 0.5, VIEWPORT_SIZE.y - WALL_THICKNESS * 0.5), Vector2(VIEWPORT_SIZE.x, WALL_THICKNESS))
	_add_wall(layer, "LeftWall", Vector2(WALL_THICKNESS * 0.5, VIEWPORT_SIZE.y * 0.5), Vector2(WALL_THICKNESS, VIEWPORT_SIZE.y))
	_add_wall(layer, "RightWall", Vector2(VIEWPORT_SIZE.x - WALL_THICKNESS * 0.5, VIEWPORT_SIZE.y * 0.5), Vector2(WALL_THICKNESS, VIEWPORT_SIZE.y))


func _add_wall(parent: Node2D, node_name: String, center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = center
	parent.add_child(body)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)

	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.color = Color(0.018, 0.025, 0.034, 0.96)
	visual.polygon = PackedVector2Array([
		Vector2(-size.x * 0.5, -size.y * 0.5),
		Vector2(size.x * 0.5, -size.y * 0.5),
		Vector2(size.x * 0.5, size.y * 0.5),
		Vector2(-size.x * 0.5, size.y * 0.5)
	])
	body.add_child(visual)


func _add_readable_markers(world: Node2D) -> void:
	var marker_layer := Node2D.new()
	marker_layer.name = "ReadableMarkers"
	marker_layer.visible = false
	world.add_child(marker_layer)

	var label_layer := Node2D.new()
	label_layer.name = "MapLabels"
	label_layer.visible = false
	world.add_child(label_layer)

	var area_nodes: Array[Area2D] = []
	_collect_area_nodes(world, area_nodes)
	for area in area_nodes:
		var category := _get_area_category(area)
		var display_name := get_area_display_name(area)
		_add_marker(marker_layer, area.global_position - world.global_position, category)
		_add_map_label(label_layer, area.global_position - world.global_position, display_name, category)


func _collect_area_nodes(node: Node, area_nodes: Array[Area2D]) -> void:
	for child in node.get_children():
		var area := child as Area2D
		if area != null:
			area_nodes.append(area)
		_collect_area_nodes(child, area_nodes)


func _hide_polygon_blockouts(node: Node) -> void:
	for child in node.get_children():
		if child is Polygon2D and child.name == "Visual":
			child.visible = false
		_hide_polygon_blockouts(child)


func _get_area_category(area: Area2D) -> String:
	var node_name := str(area.name).to_lower()
	var save_value: Variant = area.get("save_on_interact")
	if save_value is bool and bool(save_value):
		return "save"
	var target_scene_path := str(area.get("target_scene_path"))
	var encounter_id := str(area.get("encounter_id"))
	if node_name.contains("boss") or node_name.contains("poojan") or node_name.contains("suhas") or node_name.contains("srmt") or (not encounter_id.is_empty() and target_scene_path.contains("battle")):
		return "boss"
	if node_name.contains("transition") or target_scene_path.contains("level_") or target_scene_path.contains("ending"):
		return "exit"
	var clue_id := str(area.get("clue_id"))
	if not clue_id.is_empty() or node_name.contains("record") or node_name.contains("file") or node_name.contains("clue") or node_name.contains("contract"):
		return "clue"
	var dialogue_id := str(area.get("dialogue_id"))
	if not dialogue_id.is_empty() or node_name.contains("resident") or node_name.contains("npc"):
		return "npc"
	return "object"


func _add_marker(parent: Node2D, position: Vector2, category: String) -> void:
	var marker := Node2D.new()
	marker.name = "%sMarker" % category.capitalize()
	marker.position = position
	parent.add_child(marker)

	var color := _get_category_color(category)
	var shadow := Polygon2D.new()
	shadow.name = "Shadow"
	shadow.color = Color(0.0, 0.0, 0.0, 0.32)
	shadow.polygon = PackedVector2Array([
		Vector2(-9.0, -7.0),
		Vector2(9.0, -7.0),
		Vector2(9.0, 7.0),
		Vector2(-9.0, 7.0)
	])
	marker.add_child(shadow)

	var ring := Line2D.new()
	ring.name = "ReadabilityRing"
	ring.width = 1.0
	ring.default_color = color
	ring.closed = true
	ring.points = PackedVector2Array([
		Vector2(-10.0, -8.0),
		Vector2(10.0, -8.0),
		Vector2(10.0, 8.0),
		Vector2(-10.0, 8.0)
	])
	marker.add_child(ring)

	var pip := Polygon2D.new()
	pip.name = "CategoryPip"
	pip.color = color
	pip.polygon = PackedVector2Array([
		Vector2(-4.0, -4.0),
		Vector2(4.0, -4.0),
		Vector2(4.0, 4.0),
		Vector2(-4.0, 4.0)
	])
	marker.add_child(pip)


func _add_map_label(parent: Node2D, position: Vector2, label_text: String, category: String) -> void:
	var label := Label.new()
	label.name = "%sLabel" % label_text.replace(" ", "")
	label.position = position + Vector2(-22.0, -16.0)
	label.size = Vector2(44.0, 8.0)
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_style_label(label, WORLD_LABEL_FONT_SIZE, _get_category_color(category))
	parent.add_child(label)


func _get_category_color(category: String) -> Color:
	if CATEGORY_COLORS.has(category):
		return CATEGORY_COLORS[category]
	return CATEGORY_COLORS["object"]


func _make_style_box(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	return style


func _scale_world_labels(node: Node) -> void:
	for child in node.get_children():
		var label := child as Label
		if label != null:
			var font_size := WORLD_LABEL_FONT_SIZE
			if str(label.name).begins_with("Step"):
				font_size = WORLD_STEP_FONT_SIZE
			_style_label(label, font_size, label.get_theme_color("font_color"))
			label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_scale_world_labels(child)


func _style_label(label: Label, font_size: int, font_color: Color) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", UI_OUTLINE_SIZE)


func _split_camel_case(value: String) -> String:
	var output := ""
	for index in value.length():
		var character := value.substr(index, 1)
		if index > 0 and character == character.to_upper() and character != character.to_lower():
			output += " "
		output += character
	return output.strip_edges()
