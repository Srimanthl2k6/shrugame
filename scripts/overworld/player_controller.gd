extends CharacterBody2D

const TuningLoader := preload("res://scripts/core/tuning_loader.gd")

@export var speed: float = 90.0
@export var acceleration: float = 720.0
@export var deceleration: float = 900.0
@export var collision_size: Vector2 = Vector2(12.0, 18.0)
@export var camera_smoothing_speed: float = 8.0

var facing_direction := "down"
var current_animation := "idle_down"
var _animation_elapsed := 0.0
var _current_texture_path := ""
var movement_locked := false

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	speed = float(TuningLoader.get_value(["overworld", "player_speed"], speed))
	collision_size = TuningLoader.get_vector2(["overworld", "player_collision_size"], collision_size)
	camera_smoothing_speed = float(TuningLoader.get_value(["overworld", "camera_smoothing_speed"], camera_smoothing_speed))

	var collision: CollisionShape2D = get_node_or_null("CollisionShape2D")
	if collision != null and collision.shape is RectangleShape2D:
		var rect: RectangleShape2D = collision.shape as RectangleShape2D
		rect.size = collision_size

	var camera: Camera2D = get_node_or_null("Camera2D")
	if camera != null:
		camera.position_smoothing_speed = camera_smoothing_speed
	apply_growth_visual()


func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO if movement_locked else Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var target_velocity := direction * speed
	var rate := acceleration if not direction.is_zero_approx() else deceleration
	velocity = velocity.move_toward(target_velocity, rate * delta)
	move_and_slide()
	_update_facing(direction)
	_update_animation(direction, delta)


func set_movement_locked(locked: bool) -> void:
	movement_locked = locked
	if locked:
		velocity = Vector2.ZERO


func configure_room_bounds(bounds: Rect2) -> void:
	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)


func get_growth_sprite_path(stage: int) -> String:
	var safe_stage: int = clamp(stage, 1, 5)
	return "res://assets/shared/sprites/shrububu/form_%02d/idle_down.png" % safe_stage


func get_animation_sprite_path(stage: int, animation_name: String) -> String:
	var safe_stage: int = clamp(stage, 1, 5)
	return "res://assets/shared/sprites/shrububu/form_%02d/%s.png" % [safe_stage, animation_name]


func get_animation_frame_count(animation_name: String) -> int:
	if animation_name.begins_with("walk_") or animation_name in ["battle_idle", "victory", "interact"]:
		return 4
	if animation_name.begins_with("attack_") or animation_name == "door_slam":
		return 6
	if animation_name == "growth_transform":
		return 8
	return 2


func apply_growth_visual(stage: int = -1) -> void:
	var resolved_stage: int = stage
	if resolved_stage <= 0:
		resolved_stage = 1
		var game_state: Node = null
		if is_inside_tree():
			game_state = get_tree().root.get_node_or_null("GameState")
		if game_state != null and game_state.has_method("get_growth_stage"):
			resolved_stage = int(game_state.get_growth_stage())
	var safe_stage: int = clamp(resolved_stage, 1, 5)
	_current_texture_path = ""
	_set_animation_texture("idle_%s" % facing_direction, safe_stage)
	_apply_growth_collision(safe_stage)
	scale = Vector2.ONE


func play_action(animation_name: String, fps: float = 12.0) -> void:
	var stage := _get_growth_stage()
	_set_animation_texture(animation_name, stage)
	var frame_count := get_animation_frame_count(animation_name)
	for frame_index in range(frame_count):
		_sprite.frame = frame_index
		await get_tree().create_timer(1.0 / maxf(fps, 1.0)).timeout
	_set_animation_texture("idle_%s" % facing_direction, stage)


func _update_facing(direction: Vector2) -> void:
	if direction.is_zero_approx():
		return
	if absf(direction.x) > absf(direction.y):
		facing_direction = "right" if direction.x > 0.0 else "left"
	else:
		facing_direction = "down" if direction.y > 0.0 else "up"


func _update_animation(direction: Vector2, delta: float) -> void:
	var moving := not direction.is_zero_approx()
	var next_animation := ("walk_" if moving else "idle_") + facing_direction
	var stage := _get_growth_stage()
	_set_animation_texture(next_animation, stage)
	var frame_count := get_animation_frame_count(next_animation)
	var frame_seconds := 0.11 if moving else 0.42
	_animation_elapsed += delta
	if _animation_elapsed >= frame_seconds:
		_animation_elapsed = fmod(_animation_elapsed, frame_seconds)
		_sprite.frame = (_sprite.frame + 1) % frame_count


func _set_animation_texture(animation_name: String, stage: int) -> void:
	var path := get_animation_sprite_path(stage, animation_name)
	if path == _current_texture_path:
		return
	var texture := _load_texture_from_path(path)
	if texture == null:
		return
	_current_texture_path = path
	current_animation = animation_name
	_sprite.texture = texture
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.hframes = get_animation_frame_count(animation_name)
	_sprite.vframes = 1
	_sprite.frame = 0
	_sprite.position.y = -float(texture.get_height()) * 0.5 + 9.0
	_animation_elapsed = 0.0


func _get_growth_stage() -> int:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and game_state.has_method("get_growth_stage"):
		return int(game_state.get_growth_stage())
	return 1


func _apply_growth_collision(stage: int) -> void:
	var sizes := {
		1: Vector2(12, 18),
		2: Vector2(13, 19),
		3: Vector2(14, 20),
		4: Vector2(15, 22),
		5: Vector2(16, 24)
	}
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision != null and collision.shape is RectangleShape2D:
		var shape := collision.shape.duplicate() as RectangleShape2D
		shape.size = sizes.get(stage, collision_size)
		collision.shape = shape


func _load_texture_from_path(path: String) -> Texture2D:
	if ResourceLoader.exists(path, "Texture2D"):
		return ResourceLoader.load(path, "Texture2D") as Texture2D
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)
