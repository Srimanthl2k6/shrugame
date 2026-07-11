extends Node2D

const TuningLoader := preload("res://scripts/core/tuning_loader.gd")
const BULLET_TEXTURE := preload("res://assets/shared/sprites/common_bullet.png")
const BULLET_VISUAL_PATHS := {
	"badge": "res://assets/level_01/sprites/bullet_badge_warning.png",
	"legal_paper": "res://assets/level_01/sprites/bullet_legal_paper.png",
	"broken_ring": "res://assets/level_01/sprites/bullet_broken_ring.png"
}

const SUPPORTED_PATTERN_TYPES := [
	"straight_lanes",
	"rings",
	"falling_objects",
	"sweeping_beams",
	"arcs",
	"ricochets",
	"environmental_hazards",
	"musical_notes",
	"rhythm_notes",
	"callback_mix"
]

var bullet_count := 3
var bullet_radius := 3.0
var bullet_start_x := 48.0
var bullet_start_y := 20.0
var bullet_spacing := 32.0
var bullet_speed := 42.0
var pattern_telegraph_seconds := 0.0
var active_pattern_type := "straight_lanes"
var active_safe_hint := ""
var active_visual_id := ""
var last_pattern_metadata: Dictionary = {}
var telegraphing := false
@export var arena_size := Vector2(192.0, 76.0)

var _pending_pattern_config: Dictionary = {}
var _pattern_token := 0


func _ready() -> void:
	_apply_tuning()
	set_process(true)


func _process(delta: float) -> void:
	for child in get_children():
		var bullet := child as Area2D
		if bullet == null or bullet.is_queued_for_deletion():
			continue
		var velocity: Vector2 = bullet.get_meta("velocity", Vector2.ZERO)
		if active_pattern_type in ["musical_notes", "rhythm_notes"]:
			var phase := float(bullet.get_meta("wave_phase", 0.0)) + delta * 5.0
			bullet.set_meta("wave_phase", phase)
			bullet.position += velocity * delta
			bullet.position.y += sin(phase) * 12.0 * delta
		elif active_pattern_type == "arcs":
			velocity.y += 34.0 * delta
			bullet.set_meta("velocity", velocity)
			bullet.position += velocity * delta
		else:
			bullet.position += velocity * delta
		if active_pattern_type == "ricochets":
			_bounce_bullet(bullet)
		else:
			_wrap_bullet(bullet)


func get_supported_pattern_types() -> Array[String]:
	return SUPPORTED_PATTERN_TYPES.duplicate()


func start_pattern(pattern_config: Dictionary = {}) -> void:
	_apply_tuning()
	clear_pattern()
	last_pattern_metadata = pattern_config.duplicate(true)
	active_pattern_type = str(pattern_config.get("type", active_pattern_type))
	active_safe_hint = str(pattern_config.get("safe_hint", "Watch the pattern."))
	active_visual_id = str(pattern_config.get("visual_id", active_pattern_type))
	var telegraph_seconds := float(pattern_config.get("telegraph_seconds", pattern_telegraph_seconds))
	if telegraph_seconds > 0.0:
		telegraphing = true
		_pending_pattern_config = pattern_config.duplicate(true)
		_spawn_telegraph(pattern_config)
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
	_clear_telegraph()
	_spawn_pattern(_pending_pattern_config)
	_pending_pattern_config = {}


func _spawn_pattern(pattern_config: Dictionary) -> void:
	telegraphing = false
	active_pattern_type = str(pattern_config.get("type", active_pattern_type))
	var count := int(pattern_config.get("count", bullet_count))
	bullet_speed = float(pattern_config.get("speed", bullet_speed))
	for index in range(max(1, count)):
		add_child(_create_bullet(index, active_pattern_type, count))


func _create_bullet(index: int, pattern_type: String, count: int) -> Area2D:
	var bullet := Area2D.new()
	bullet.name = "Bullet%s_%s" % [index, pattern_type]
	bullet.add_to_group("battle_bullet")
	bullet.collision_layer = 2
	bullet.collision_mask = 4
	bullet.position = _get_pattern_position(index, pattern_type, count)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = bullet_radius
	shape.shape = circle
	bullet.add_child(shape)

	var visual := Sprite2D.new()
	visual.name = "Visual"
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.texture = _get_bullet_texture()
	var settings_manager := get_node_or_null("/root/SettingsManager")
	if settings_manager != null and bool(settings_manager.get_setting("high_contrast_bullets", false)):
		var outline := Polygon2D.new()
		outline.name = "ContrastOutline"
		outline.color = Color(0.0, 0.0, 0.0, 0.95)
		outline.polygon = PackedVector2Array([Vector2(0, -6), Vector2(6, 0), Vector2(0, 6), Vector2(-6, 0)])
		bullet.add_child(outline)
		visual.modulate = Color(1.0, 0.95, 0.2, 1.0)
		visual.z_index = 1
	bullet.add_child(visual)
	bullet.set_meta("velocity", _get_pattern_velocity(index, pattern_type, count))
	bullet.set_meta("wave_phase", float(index))
	return bullet


func _get_pattern_position(index: int, pattern_type: String, count: int) -> Vector2:
	match pattern_type:
		"rings":
			var angle := TAU * float(index) / float(max(1, count))
			return arena_size * 0.5 + Vector2(cos(angle), sin(angle)) * 20.0
		"falling_objects":
			return Vector2((float(index) + 0.5) * arena_size.x / float(max(1, count)), -6.0)
		"sweeping_beams":
			return Vector2((float(index) + 0.5) * arena_size.x / float(max(1, count)), arena_size.y * 0.5)
		"musical_notes":
			return Vector2(-6.0, 12.0 + (float(index) + 0.5) * (arena_size.y - 24.0) / float(max(1, count)))
		"rhythm_notes":
			return Vector2(-6.0, 12.0 + (float(index) + 0.5) * (arena_size.y - 24.0) / float(max(1, count)))
		"arcs":
			return Vector2(-6.0 if index % 2 == 0 else arena_size.x + 6.0, arena_size.y - 10.0)
		"ricochets":
			return arena_size * 0.5 + Vector2((index % 3 - 1) * 12.0, (index % 2) * 10.0 - 5.0)
		"environmental_hazards":
			return Vector2((float(index) + 0.5) * arena_size.x / float(max(1, count)), -8.0 - float(index % 3) * 12.0)
		"callback_mix":
			return Vector2((float(index) + 0.5) * arena_size.x / float(max(1, count)), 12.0 + (index % 3) * 18.0)
		_:
			return Vector2((float(index) + 0.5) * arena_size.x / float(max(1, count)), -6.0)


func _get_pattern_velocity(index: int, pattern_type: String, count: int) -> Vector2:
	match pattern_type:
		"rings":
			var angle := TAU * float(index) / float(max(1, count))
			return Vector2(cos(angle), sin(angle)) * bullet_speed
		"sweeping_beams":
			return Vector2(bullet_speed * (-1.0 if index % 2 == 0 else 1.0), 0.0)
		"musical_notes":
			return Vector2(bullet_speed, bullet_speed * 0.18)
		"rhythm_notes":
			return Vector2(bullet_speed * 1.15, bullet_speed * (0.12 if index % 2 == 0 else -0.12))
		"arcs":
			return Vector2(bullet_speed * (0.8 if index % 2 == 0 else -0.8), -bullet_speed * (0.72 + float(index % 3) * 0.12))
		"ricochets":
			var angle := 0.35 + float(index) * 0.71
			return Vector2(cos(angle), sin(angle)) * bullet_speed
		"environmental_hazards":
			return Vector2(0.0, bullet_speed * (0.75 + float(index % 3) * 0.18))
		"callback_mix":
			return Vector2(bullet_speed * (0.55 if index % 2 == 0 else -0.55), bullet_speed)
		_:
			return Vector2(0.0, bullet_speed)


func _wrap_bullet(bullet: Area2D) -> void:
	var next_position := bullet.position
	if next_position.x < -10.0:
		next_position.x = arena_size.x + 10.0
	elif next_position.x > arena_size.x + 10.0:
		next_position.x = -10.0
	if next_position.y < -10.0:
		next_position.y = arena_size.y + 10.0
	elif next_position.y > arena_size.y + 10.0:
		next_position.y = -10.0
	bullet.position = next_position


func _bounce_bullet(bullet: Area2D) -> void:
	var velocity: Vector2 = bullet.get_meta("velocity", Vector2.ZERO)
	var next_position := bullet.position
	if next_position.x <= 0.0 or next_position.x >= arena_size.x:
		velocity.x *= -1.0
		next_position.x = clampf(next_position.x, 0.0, arena_size.x)
	if next_position.y <= 0.0 or next_position.y >= arena_size.y:
		velocity.y *= -1.0
		next_position.y = clampf(next_position.y, 0.0, arena_size.y)
	bullet.position = next_position
	bullet.set_meta("velocity", velocity)


func _spawn_telegraph(pattern_config: Dictionary) -> void:
	var telegraph := Node2D.new()
	telegraph.name = "Telegraph"
	add_child(telegraph)
	var count := maxi(1, int(pattern_config.get("count", bullet_count)))
	for index in range(count):
		var marker := Polygon2D.new()
		marker.name = "Warning%s" % index
		var marker_position := _get_pattern_position(index, str(pattern_config.get("type", active_pattern_type)), count)
		marker_position.x = clampf(marker_position.x, 4.0, arena_size.x - 4.0)
		marker_position.y = clampf(marker_position.y, 4.0, arena_size.y - 4.0)
		marker.position = marker_position
		var settings_manager := get_node_or_null("/root/SettingsManager")
		marker.color = Color(0.2, 1.0, 1.0, 0.82) if settings_manager != null and bool(settings_manager.get_setting("high_contrast_bullets", false)) else Color(1.0, 0.72, 0.2, 0.58)
		marker.polygon = PackedVector2Array([Vector2(0, -4), Vector2(4, 0), Vector2(0, 4), Vector2(-4, 0)])
		telegraph.add_child(marker)


func _clear_telegraph() -> void:
	var telegraph := get_node_or_null("Telegraph")
	if telegraph != null:
		telegraph.queue_free()


func _get_bullet_texture() -> Texture2D:
	var path := str(BULLET_VISUAL_PATHS.get(active_visual_id, ""))
	if not path.is_empty() and ResourceLoader.exists(path, "Texture2D"):
		return ResourceLoader.load(path, "Texture2D") as Texture2D
	return BULLET_TEXTURE


func _apply_tuning() -> void:
	bullet_count = int(TuningLoader.get_value(["battle", "bullet_count"], bullet_count))
	bullet_radius = float(TuningLoader.get_value(["battle", "bullet_radius"], bullet_radius))
	bullet_start_x = float(TuningLoader.get_value(["battle", "bullet_start_x"], bullet_start_x))
	bullet_start_y = float(TuningLoader.get_value(["battle", "bullet_start_y"], bullet_start_y))
	bullet_spacing = float(TuningLoader.get_value(["battle", "bullet_spacing"], bullet_spacing))
	bullet_speed = float(TuningLoader.get_value(["battle", "bullet_speed"], bullet_speed))
	pattern_telegraph_seconds = float(TuningLoader.get_value(["battle", "pattern_telegraph_seconds"], pattern_telegraph_seconds))
