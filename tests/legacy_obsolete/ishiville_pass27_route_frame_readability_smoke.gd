extends SceneTree

const PLAYABLE_FRAME_SCRIPT := "res://scripts/visual/playable_frame.gd"
const LEVEL_SCENES := [
	"res://scenes/levels/level_01.tscn",
	"res://scenes/levels/level_02.tscn",
	"res://scenes/levels/level_03.tscn",
	"res://scenes/levels/level_04.tscn",
	"res://scenes/levels/level_05.tscn"
]

const EDGE_PATHS := [
	"VisualEdges/TopEdge",
	"VisualEdges/BottomEdge",
	"VisualEdges/LeftEdge",
	"VisualEdges/RightEdge"
]

const WALL_PATHS := [
	"CollisionWalls/TopWall",
	"CollisionWalls/BottomWall",
	"CollisionWalls/LeftWall",
	"CollisionWalls/RightWall"
]

const CORNER_PATHS := [
	"CornerMarkers/TopLeftCorner",
	"CornerMarkers/TopRightCorner",
	"CornerMarkers/BottomLeftCorner",
	"CornerMarkers/BottomRightCorner"
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_playable_frame_script(failures)
	_check_level_frames(failures)
	_check_readme_and_export_metadata(failures)

	if failures.is_empty():
		print("PASS: Ishiville Pass 27 route frame readability smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_playable_frame_script(failures: Array[String]) -> void:
	if not ResourceLoader.exists(PLAYABLE_FRAME_SCRIPT, "Script"):
		failures.append("Missing reusable PlayableFrame script")
		return
	var frame: Node = load(PLAYABLE_FRAME_SCRIPT).new()
	for method_name in ["rebuild_frame", "get_frame_rect", "get_safe_rect", "get_wall_specs"]:
		if not frame.has_method(method_name):
			failures.append("PlayableFrame missing %s" % method_name)
	frame.free()


func _check_level_frames(failures: Array[String]) -> void:
	for level_path in LEVEL_SCENES:
		var scene := load(level_path)
		if scene == null:
			failures.append("%s failed to load" % level_path)
			continue
		var level: Node = scene.instantiate()
		var frame := level.get_node_or_null("World/PlayableFrame") as Node2D
		if frame == null:
			failures.append("%s needs authored World/PlayableFrame" % level_path)
			level.free()
			continue
		if frame.get_script() == null or frame.get_script().resource_path != PLAYABLE_FRAME_SCRIPT:
			failures.append("%s PlayableFrame must use the reusable script" % level_path)
		if frame.z_index < 8:
			failures.append("%s PlayableFrame should draw above map art" % level_path)
		if frame.has_method("rebuild_frame"):
			frame.rebuild_frame()
		_check_edges(level_path, frame, failures)
		_check_collision_walls(level_path, frame, failures)
		_check_corner_markers(level_path, frame, failures)
		_check_safe_zone_and_spawn(level_path, level, frame, failures)
		level.free()


func _check_edges(level_path: String, frame: Node, failures: Array[String]) -> void:
	for edge_path in EDGE_PATHS:
		var line := frame.get_node_or_null(edge_path) as Line2D
		if line == null:
			failures.append("%s missing frame edge %s" % [level_path, edge_path])
			continue
		if line.points.size() < 2:
			failures.append("%s %s needs at least two points" % [level_path, edge_path])
		if line.width < 4.0:
			failures.append("%s %s must be thick enough for PC readability" % [level_path, edge_path])
		if line.default_color.a < 0.78:
			failures.append("%s %s alpha must be high enough to read" % [level_path, edge_path])


func _check_collision_walls(level_path: String, frame: Node, failures: Array[String]) -> void:
	var wall_specs: Dictionary = {}
	if frame.has_method("get_wall_specs"):
		wall_specs = frame.get_wall_specs()
	if wall_specs.size() < 4:
		failures.append("%s PlayableFrame must expose four wall specs" % level_path)
	for wall_path in WALL_PATHS:
		var wall := frame.get_node_or_null(wall_path) as StaticBody2D
		if wall == null:
			failures.append("%s missing collision wall %s" % [level_path, wall_path])
			continue
		var shape_node := wall.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape_node == null or not shape_node.shape is RectangleShape2D:
			failures.append("%s %s needs a RectangleShape2D collision shape" % [level_path, wall_path])
			continue
		var rect := shape_node.shape as RectangleShape2D
		if wall_path.contains("Top") or wall_path.contains("Bottom"):
			if rect.size.x < 320.0 or rect.size.y < 6.0:
				failures.append("%s %s needs full-width horizontal collision" % [level_path, wall_path])
		else:
			if rect.size.x < 6.0 or rect.size.y < 180.0:
				failures.append("%s %s needs full-height vertical collision" % [level_path, wall_path])


func _check_corner_markers(level_path: String, frame: Node, failures: Array[String]) -> void:
	for corner_path in CORNER_PATHS:
		var marker := frame.get_node_or_null(corner_path) as Polygon2D
		if marker == null:
			failures.append("%s missing corner marker %s" % [level_path, corner_path])
			continue
		if marker.polygon.size() < 3:
			failures.append("%s %s needs a visible polygon" % [level_path, corner_path])
		if marker.color.a < 0.78:
			failures.append("%s %s marker alpha must be high enough to read" % [level_path, corner_path])


func _check_safe_zone_and_spawn(level_path: String, level: Node, frame: Node, failures: Array[String]) -> void:
	var tint := frame.get_node_or_null("SafeZoneTint") as Polygon2D
	if tint == null:
		failures.append("%s missing SafeZoneTint" % level_path)
	elif tint.polygon.size() < 4:
		failures.append("%s SafeZoneTint needs a readable polygon" % level_path)
	var safe_rect := Rect2(Vector2(12.0, 12.0), Vector2(296.0, 156.0))
	if frame.has_method("get_safe_rect"):
		safe_rect = frame.get_safe_rect()
	if safe_rect.size.x < 292.0 or safe_rect.size.y < 152.0:
		failures.append("%s safe rect should leave most of the 320x180 field playable" % level_path)
	var player := level.get_node_or_null("World/Player") as Node2D
	if player == null:
		failures.append("%s missing player" % level_path)
		return
	if not safe_rect.has_point(player.position):
		failures.append("%s player spawn must be inside the playable safe rect" % level_path)


func _check_readme_and_export_metadata(failures: Array[String]) -> void:
	var readme := FileAccess.get_file_as_string("res://README.md")
	for required_text in [
		"Pass 27 full-route visual QA",
		"authored PlayableFrame",
		"visible/collidable boundaries"
	]:
		if not readme.contains(required_text):
			failures.append("README missing Pass 27 note: %s" % required_text)
	var preset := FileAccess.get_file_as_string("res://export_presets.cfg")
	var version := _extract_product_version(preset)
	if version.is_empty():
		failures.append("Export metadata missing product version")
	elif not _is_version_at_least(version, "0.27.0"):
		failures.append("Export metadata should be at least 0.27.0")


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
