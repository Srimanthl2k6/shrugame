class_name RoomActor
extends Sprite2D

@export var frame_count := 1
@export var frames_per_second := 3.0
@export var bob_pixels := 0.0

var _elapsed := 0.0
var _base_position := Vector2.ZERO


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hframes = maxi(1, frame_count)
	_base_position = position


func _process(delta: float) -> void:
	_elapsed += delta
	if frame_count > 1:
		frame = int(_elapsed * frames_per_second) % frame_count
	if bob_pixels > 0.0:
		position.y = _base_position.y + sin(_elapsed * 2.2) * bob_pixels
