extends Node2D

const FRAME_SIZE := Vector2(320.0, 180.0)
const DEFAULT_WALL_THICKNESS := 8.0
const DEFAULT_EDGE_WIDTH := 4.0

@export var frame_size: Vector2 = FRAME_SIZE
@export var wall_thickness: float = DEFAULT_WALL_THICKNESS
@export var edge_width: float = DEFAULT_EDGE_WIDTH
@export var frame_color: Color = Color(0.96, 0.88, 0.58, 0.86)
@export var corner_color: Color = Color(1.0, 0.96, 0.66, 0.92)
@export var safe_zone_color: Color = Color(0.02, 0.024, 0.032, 0.08)


func _ready() -> void:
	rebuild_frame()


func rebuild_frame() -> void:
	_clear_generated_children()
	z_index = max(z_index, 9)
	_build_safe_zone()
	_build_visual_edges()
	_build_corner_markers()
	_build_collision_walls()


func get_frame_rect() -> Rect2:
	return Rect2(Vector2.ZERO, frame_size)


func get_safe_rect() -> Rect2:
	var inset: float = maxf(wall_thickness + 4.0, 12.0)
	return Rect2(Vector2(inset, inset), frame_size - Vector2(inset * 2.0, inset * 2.0))


func get_wall_specs() -> Dictionary:
	var thickness: float = maxf(wall_thickness, 6.0)
	return {
		"TopWall": {
			"position": Vector2(frame_size.x * 0.5, thickness * 0.5),
			"size": Vector2(frame_size.x, thickness)
		},
		"BottomWall": {
			"position": Vector2(frame_size.x * 0.5, frame_size.y - thickness * 0.5),
			"size": Vector2(frame_size.x, thickness)
		},
		"LeftWall": {
			"position": Vector2(thickness * 0.5, frame_size.y * 0.5),
			"size": Vector2(thickness, frame_size.y)
		},
		"RightWall": {
			"position": Vector2(frame_size.x - thickness * 0.5, frame_size.y * 0.5),
			"size": Vector2(thickness, frame_size.y)
		}
	}


func _clear_generated_children() -> void:
	for child in get_children():
		remove_child(child)
		child.free()


func _build_safe_zone() -> void:
	var safe_rect := get_safe_rect()
	var tint := Polygon2D.new()
	tint.name = "SafeZoneTint"
	tint.z_index = -18
	tint.color = safe_zone_color
	tint.polygon = PackedVector2Array([
		safe_rect.position,
		Vector2(safe_rect.end.x, safe_rect.position.y),
		safe_rect.end,
		Vector2(safe_rect.position.x, safe_rect.end.y)
	])
	add_child(tint)


func _build_visual_edges() -> void:
	var edge_root := Node2D.new()
	edge_root.name = "VisualEdges"
	edge_root.z_index = 2
	add_child(edge_root)

	var inset: float = maxf(wall_thickness, 6.0)
	_add_edge(edge_root, "TopEdge", PackedVector2Array([Vector2(0.0, inset), Vector2(frame_size.x, inset)]))
	_add_edge(edge_root, "BottomEdge", PackedVector2Array([Vector2(0.0, frame_size.y - inset), Vector2(frame_size.x, frame_size.y - inset)]))
	_add_edge(edge_root, "LeftEdge", PackedVector2Array([Vector2(inset, 0.0), Vector2(inset, frame_size.y)]))
	_add_edge(edge_root, "RightEdge", PackedVector2Array([Vector2(frame_size.x - inset, 0.0), Vector2(frame_size.x - inset, frame_size.y)]))


func _add_edge(parent: Node, edge_name: String, points: PackedVector2Array) -> void:
	var line := Line2D.new()
	line.name = edge_name
	line.points = points
	line.width = max(edge_width, 4.0)
	line.default_color = frame_color
	line.joint_mode = Line2D.LINE_JOINT_SHARP
	line.begin_cap_mode = Line2D.LINE_CAP_NONE
	line.end_cap_mode = Line2D.LINE_CAP_NONE
	parent.add_child(line)


func _build_corner_markers() -> void:
	var corner_root := Node2D.new()
	corner_root.name = "CornerMarkers"
	corner_root.z_index = 3
	add_child(corner_root)

	var inset: float = maxf(wall_thickness, 6.0)
	var length := 14.0
	_add_corner(corner_root, "TopLeftCorner", PackedVector2Array([Vector2(inset, inset), Vector2(inset + length, inset), Vector2(inset, inset + length)]))
	_add_corner(corner_root, "TopRightCorner", PackedVector2Array([Vector2(frame_size.x - inset, inset), Vector2(frame_size.x - inset - length, inset), Vector2(frame_size.x - inset, inset + length)]))
	_add_corner(corner_root, "BottomLeftCorner", PackedVector2Array([Vector2(inset, frame_size.y - inset), Vector2(inset + length, frame_size.y - inset), Vector2(inset, frame_size.y - inset - length)]))
	_add_corner(corner_root, "BottomRightCorner", PackedVector2Array([Vector2(frame_size.x - inset, frame_size.y - inset), Vector2(frame_size.x - inset - length, frame_size.y - inset), Vector2(frame_size.x - inset, frame_size.y - inset - length)]))


func _add_corner(parent: Node, corner_name: String, points: PackedVector2Array) -> void:
	var marker := Polygon2D.new()
	marker.name = corner_name
	marker.color = corner_color
	marker.polygon = points
	parent.add_child(marker)


func _build_collision_walls() -> void:
	var wall_root := Node2D.new()
	wall_root.name = "CollisionWalls"
	add_child(wall_root)

	for wall_name in get_wall_specs().keys():
		var spec: Dictionary = get_wall_specs()[wall_name]
		var body := StaticBody2D.new()
		body.name = wall_name
		body.position = spec["position"]
		wall_root.add_child(body)

		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var rect := RectangleShape2D.new()
		rect.size = spec["size"]
		shape.shape = rect
		body.add_child(shape)
