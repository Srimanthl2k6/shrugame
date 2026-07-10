extends CharacterBody2D

const TuningLoader := preload("res://scripts/core/tuning_loader.gd")

@export var speed: float = 90.0
@export var collision_size: Vector2 = Vector2(12.0, 18.0)
@export var camera_smoothing_speed: float = 8.0


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


func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()


func get_growth_sprite_path(stage: int) -> String:
	var safe_stage: int = clamp(stage, 1, 5)
	return "res://assets/shared/sprites/shrububu/form_%02d/idle_down.png" % safe_stage


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
	var sprite: Sprite2D = get_node_or_null("Sprite") as Sprite2D
	if sprite != null:
		var texture: Texture2D = _load_texture_from_path(get_growth_sprite_path(safe_stage))
		if texture != null:
			sprite.texture = texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scale = Vector2.ONE * (1.0 + float(safe_stage - 1) * 0.08)


func _load_texture_from_path(path: String) -> Texture2D:
	if ResourceLoader.exists(path, "Texture2D"):
		return ResourceLoader.load(path, "Texture2D") as Texture2D
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)
