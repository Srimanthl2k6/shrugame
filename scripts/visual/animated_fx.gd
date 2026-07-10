extends Node2D

@export var fx_id: String = ""
@export var frame_count: int = 4
@export var loop_seconds: float = 0.8
@export var pulse_color_a: Color = Color(1, 1, 1, 0.6)
@export var pulse_color_b: Color = Color(1, 1, 1, 1)
@export var motion_axis: Vector2 = Vector2.ZERO
@export var motion_pixels: float = 0.0

var _elapsed: float = 0.0
var _base_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	_base_position = position
	_ensure_visual()
	set_process(true)


func _process(delta: float) -> void:
	_elapsed += delta
	var loop: float = maxf(0.05, loop_seconds)
	var t: float = fmod(_elapsed, loop) / loop
	var wave: float = 0.5 + sin(t * TAU) * 0.5
	modulate = pulse_color_a.lerp(pulse_color_b, wave)
	if motion_axis != Vector2.ZERO and motion_pixels != 0.0:
		position = _base_position + motion_axis.normalized() * motion_pixels * wave


func set_fx(new_fx_id: String, frames: int = 4) -> void:
	fx_id = new_fx_id
	frame_count = maxi(1, frames)


func get_animation_metadata() -> Dictionary:
	return {
		"fx_id": fx_id,
		"frame_count": frame_count,
		"loop_seconds": loop_seconds,
		"motion_pixels": motion_pixels
	}


func _ensure_visual() -> void:
	if get_child_count() > 0:
		return
	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.color = Color(1, 1, 1, 0.35)
	visual.polygon = PackedVector2Array([
		Vector2(-8, -8),
		Vector2(8, -8),
		Vector2(8, 8),
		Vector2(-8, 8)
	])
	add_child(visual)
