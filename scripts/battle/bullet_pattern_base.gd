extends Node2D

const TuningLoader := preload("res://scripts/core/tuning_loader.gd")
const BULLET_TEXTURE := preload("res://assets/shared/sprites/common_bullet.png")

const SUPPORTED_PATTERN_TYPES := [
	"straight_lanes",
	"rings",
	"falling_objects",
	"sweeping_beams",
	"musical_notes",
	"callback_mix"
]

var bullet_count := 3
var bullet_radius := 3.0
var bullet_start_x := 48.0
var bullet_start_y := 20.0
var bullet_spacing := 32.0
var pattern_telegraph_seconds := 0.0
var active_pattern_type := "straight_lanes"
var active_safe_hint := ""
var active_visual_id := ""
var last_pattern_metadata: Dictionary = {}
var telegraphing := false

var _pending_pattern_config: Dictionary = {}
var _pattern_token := 0


func _ready() -> void:
	_apply_tuning()


func get_supported_pattern_types() -> Array[String]:
	return SUPPORTED_PATTERN_TYPES.duplicate()


func start_pattern(pattern_config: Dictionary = {}) -> void:
	_apply_tuning()
	clear_pattern()
	last_pattern_metadata = pattern_config.duplicate(true)
	active_pattern_type = str(pattern_config.get("type", active_pattern_type))
	active_safe_hint = str(pattern_config.get("safe_hint", "Watch the pattern."))
	active_visual_id = str(pattern_config.get("visual_id", active_pattern_type))
	var telegraph_seconds := float(pattern_config.get("telegraph_seconds", 0.0))
	if telegraph_seconds > 0.0:
		telegraphing = true
		_pending_pattern_config = pattern_config.duplicate(true)
		_pattern_token += 1
		var current_token := _pattern_token
		if is_inside_tree() and not Engine.is_editor_hint():
			get_tree().create_timer(telegraph_seconds).timeout.connect(_spawn_pending_pattern.bind(current_token))
		return
	_spawn_pattern(pattern_config)


func is_telegraphing() -> bool:
	return telegraphing


func get_active_telegraph_text() -> String:
	return active_safe_hint


func get_last_pattern_metadata() -> Dictionary:
	return last_pattern_metadata.duplicate(true)


func clear_pattern() -> void:
	_pattern_token += 1
	telegraphing = false
	_pending_pattern_config = {}
	for child in get_children():
		child.queue_free()


func _spawn_pending_pattern(token: int) -> void:
	if token != _pattern_token:
		return
	if _pending_pattern_config.is_empty():
		return
	_spawn_pattern(_pending_pattern_config)
	_pending_pattern_config = {}


func _spawn_pattern(pattern_config: Dictionary) -> void:
	telegraphing = false
	active_pattern_type = str(pattern_config.get("type", active_pattern_type))
	var count := int(pattern_config.get("count", bullet_count))
	for index in range(max(1, count)):
		add_child(_create_bullet(index, active_pattern_type, count))


func _create_bullet(index: int, pattern_type: String, count: int) -> Area2D:
	var bullet := Area2D.new()
	bullet.name = "Bullet%s_%s" % [index, pattern_type]
	bullet.position = _get_pattern_position(index, pattern_type, count)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = bullet_radius
	shape.shape = circle
	bullet.add_child(shape)

	var visual := Sprite2D.new()
	visual.name = "Visual"
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.texture = BULLET_TEXTURE
	bullet.add_child(visual)
	return bullet


func _get_pattern_position(index: int, pattern_type: String, count: int) -> Vector2:
	match pattern_type:
		"rings":
			var angle := TAU * float(index) / float(max(1, count))
			return Vector2(80.0, 48.0) + Vector2(cos(angle), sin(angle)) * 28.0
		"falling_objects":
			return Vector2(24.0 + index * 24.0, -8.0)
		"sweeping_beams":
			return Vector2(20.0 + index * 34.0, 48.0)
		"musical_notes":
			return Vector2(28.0 + index * 24.0, 26.0 + sin(float(index)) * 12.0)
		"callback_mix":
			return Vector2(24.0 + index * 20.0, 22.0 + (index % 3) * 18.0)
		_:
			return Vector2(bullet_start_x + index * bullet_spacing, bullet_start_y)


func _apply_tuning() -> void:
	bullet_count = int(TuningLoader.get_value(["battle", "bullet_count"], bullet_count))
	bullet_radius = float(TuningLoader.get_value(["battle", "bullet_radius"], bullet_radius))
	bullet_start_x = float(TuningLoader.get_value(["battle", "bullet_start_x"], bullet_start_x))
	bullet_start_y = float(TuningLoader.get_value(["battle", "bullet_start_y"], bullet_start_y))
	bullet_spacing = float(TuningLoader.get_value(["battle", "bullet_spacing"], bullet_spacing))
	pattern_telegraph_seconds = float(TuningLoader.get_value(["battle", "pattern_telegraph_seconds"], pattern_telegraph_seconds))
