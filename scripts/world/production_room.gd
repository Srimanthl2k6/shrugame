class_name ProductionRoom
extends "res://scripts/world/world_room.gd"

const InteractionScript := preload("res://scripts/overworld/interaction_area.gd")
const TransitionScript := preload("res://scripts/world/room_transition.gd")
const ActorScript := preload("res://scripts/world/room_actor.gd")
const EDGE_WALL_THICKNESS := 4.0
const EDGE_TRIGGER_WIDTH := 16.0
const EDGE_TRIGGER_INSET := 4.0

const INTERACTION_PROPERTIES := [
	"interaction_message", "display_name", "target_scene_path", "dialogue_id", "dialogue_file_path",
	"flag_on_interact", "post_flag", "post_dialogue_id", "locked_message", "save_on_interact",
	"level_id", "spawn_point", "encounter_id", "clue_id", "item_id", "item_amount", "gear_id",
	"growth_stage_on_interact", "objective_text", "disabled_if_flag", "one_shot", "hide_when_disabled",
	"cutscene_id", "focus_highlight", "auto_activate_on_body_enter", "persist_progress_on_activate",
	"interaction_size", "interaction_padding", "focus_priority"
]

@export_file("*.json") var definition_path := ""
@export var room_key := ""

var definition: Dictionary = {}


func _ready() -> void:
	definition = _load_room_definition()
	_report_diagnostic("definition_loaded", not definition.is_empty())
	if definition.is_empty():
		push_error("Missing production room definition: %s#%s" % [definition_path, room_key])
		return
	room_id = str(definition.get("id", room_key))
	display_name = str(definition.get("display_name", room_id))
	ambience_id = str(definition.get("ambience_id", ""))
	_build_background()
	_build_spawn_points()
	_build_boundaries()
	_build_blockers()
	_build_decorations()
	_build_interactions()
	_build_exits()
	super._ready()


func _build_background() -> void:
	var path := str(definition.get("background", ""))
	var texture := _load_texture(path)
	_report_diagnostic("background_path", path)
	_report_diagnostic("background_loaded", texture != null)
	if texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.name = "Background"
	sprite.position = room_size * 0.5
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = -100
	add_child(sprite)


func _build_spawn_points() -> void:
	var root := Node2D.new()
	root.name = "SpawnPoints"
	add_child(root)
	var spawns: Dictionary = definition.get("spawn_points", {})
	for spawn_id in spawns:
		var marker := Marker2D.new()
		marker.name = str(spawn_id)
		marker.position = _to_vector2(spawns[spawn_id], room_size * 0.5)
		root.add_child(marker)
	if root.get_node_or_null("default") == null:
		var fallback := Marker2D.new()
		fallback.name = "default"
		fallback.position = room_size * 0.5
		root.add_child(fallback)


func _build_boundaries() -> void:
	var root := Node2D.new()
	root.name = "BoundaryWalls"
	add_child(root)
	_add_blocker(root, "TopWall", Rect2(0, 0, room_size.x, 20))
	_add_blocker(root, "BottomWall", Rect2(0, room_size.y - 20, room_size.x, 20))
	_add_blocker(root, "LeftWall", Rect2(0, 0, EDGE_WALL_THICKNESS, room_size.y))
	_add_blocker(root, "RightWall", Rect2(room_size.x - EDGE_WALL_THICKNESS, 0, EDGE_WALL_THICKNESS, room_size.y))


func _build_blockers() -> void:
	var root := Node2D.new()
	root.name = "AuthoredBlockers"
	add_child(root)
	for index in range(definition.get("blockers", []).size()):
		var values: Array = definition["blockers"][index]
		if values.size() >= 4:
			_add_blocker(root, "Blocker%02d" % index, Rect2(float(values[0]), float(values[1]), float(values[2]), float(values[3])))


func _build_decorations() -> void:
	var root := Node2D.new()
	root.name = "Decorations"
	add_child(root)
	for entry_value in definition.get("decorations", []):
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_value
		var sprite := _create_actor(entry)
		if sprite != null:
			sprite.name = str(entry.get("id", "Decoration"))
			sprite.position = _to_vector2(entry.get("position", []), Vector2.ZERO)
			sprite.z_index = int(entry.get("z_index", int(sprite.position.y)))
			root.add_child(sprite)


func _build_interactions() -> void:
	var root := Node2D.new()
	root.name = "Interactions"
	root.y_sort_enabled = true
	add_child(root)
	for entry_value in definition.get("interactions", []):
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_value
		var area := Area2D.new()
		area.name = str(entry.get("id", "Interaction"))
		area.set_script(InteractionScript)
		area.position = _to_vector2(entry.get("position", []), Vector2.ZERO)
		for property_name in INTERACTION_PROPERTIES:
			if entry.has(property_name):
				if property_name in ["interaction_size", "interaction_padding"]:
					area.set(property_name, _to_vector2(entry[property_name], area.get(property_name)))
				else:
					area.set(property_name, entry[property_name])
		if entry.has("required_flags"):
			area.set("required_flags", PackedStringArray(entry["required_flags"]))
		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var shape := RectangleShape2D.new()
		var authored_size := _to_vector2(entry.get("interaction_size", [44, 36]), Vector2(44, 36))
		var padding := _to_vector2(entry.get("interaction_padding", [24, 20]), Vector2(24, 20))
		shape.size = authored_size + padding * 2.0
		collision.shape = shape
		area.add_child(collision)
		var sprite := _create_actor(entry)
		if sprite != null:
			sprite.name = "Visual"
			sprite.position = _to_vector2(entry.get("visual_offset", [0, 0]), Vector2.ZERO)
			sprite.z_index = int(entry.get("z_index", int(area.position.y)))
			area.add_child(sprite)
		root.add_child(area)


func _build_exits() -> void:
	var root := Node2D.new()
	root.name = "Exits"
	add_child(root)
	for entry_value in definition.get("exits", []):
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_value
		var authored_position := _to_vector2(entry.get("position", []), Vector2.ZERO)
		var exit_position := _edge_aligned_position(entry, authored_position)
		var area := Area2D.new()
		area.name = str(entry.get("id", "Exit"))
		area.set_script(TransitionScript)
		area.position = exit_position
		area.set("transition_id", str(entry.get("id", "exit")))
		area.set("target_level_id", str(entry.get("target_level_id", "")))
		area.set("target_room_id", str(entry.get("target_room_id", "")))
		area.set("target_spawn_id", str(entry.get("target_spawn_id", "default")))
		area.set("locked_objective", str(entry.get("locked_objective", "")))
		area.set("required_flags", PackedStringArray(entry.get("required_flags", [])))
		root.add_child(area)
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		var exit_size := _to_vector2(entry.get("size", [32, 96]), Vector2(32, 96))
		if not _exit_edge(entry).is_empty():
			exit_size.x = EDGE_TRIGGER_WIDTH
		shape.size = exit_size
		collision.shape = shape
		area.add_child(collision)
		var sprite := _create_actor(entry)
		if sprite != null:
			sprite.name = "Visual"
			sprite.position = authored_position - exit_position + _to_vector2(entry.get("visual_offset", [0, 0]), Vector2.ZERO)
			sprite.z_index = int(entry.get("z_index", int(area.position.y)))
			area.add_child(sprite)


func _edge_aligned_position(entry: Dictionary, authored_position: Vector2) -> Vector2:
	var side := _exit_edge(entry)
	if side == "right":
		return Vector2(room_size.x - EDGE_TRIGGER_INSET, authored_position.y)
	if side == "left":
		return Vector2(EDGE_TRIGGER_INSET, authored_position.y)
	return authored_position


func _exit_edge(entry: Dictionary) -> String:
	var explicit_side := str(entry.get("edge", "")).to_lower()
	if explicit_side == "right" or explicit_side == "left":
		return explicit_side
	var exit_id := str(entry.get("id", "")).to_lower()
	if exit_id.begins_with("east_to_"):
		return "right"
	if exit_id.begins_with("west_to_"):
		return "left"
	return ""


func _add_blocker(parent: Node2D, blocker_name: String, rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.name = blocker_name
	body.position = rect.position + rect.size * 0.5
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)


func _create_actor(entry: Dictionary) -> Sprite2D:
	var path := str(entry.get("visual", ""))
	var texture := _load_texture(path)
	if texture == null:
		return null
	var sprite := Sprite2D.new()
	sprite.set_script(ActorScript)
	sprite.texture = texture
	sprite.set("frame_count", int(entry.get("frames", 1)))
	sprite.set("frames_per_second", float(entry.get("fps", 3.0)))
	sprite.set("bob_pixels", float(entry.get("bob_pixels", 0.0)))
	sprite.scale = _to_vector2(entry.get("scale", [1, 1]), Vector2.ONE)
	sprite.flip_h = bool(entry.get("flip_h", false))
	if entry.has("modulate"):
		var values: Array = entry["modulate"]
		if values.size() >= 3:
			sprite.modulate = Color(float(values[0]), float(values[1]), float(values[2]), float(values[3]) if values.size() > 3 else 1.0)
	return sprite


func _load_room_definition() -> Dictionary:
	if definition_path.is_empty() or not FileAccess.file_exists(definition_path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(definition_path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var rooms: Dictionary = parsed.get("rooms", {})
	var room: Dictionary = rooms.get(room_key, {})
	return room.duplicate(true)


func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path, "Texture2D"):
		return ResourceLoader.load(path, "Texture2D") as Texture2D
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	return ImageTexture.create_from_image(image) if image != null and not image.is_empty() else null


func _to_vector2(value, fallback: Vector2) -> Vector2:
	if typeof(value) == TYPE_ARRAY and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return fallback


func _report_diagnostic(key: String, value) -> void:
	var district: Node = get_parent()
	while district != null and not district.has_method("_record_diagnostic"):
		district = district.get_parent()
	if district != null:
		district.call("_record_diagnostic", key, value)
