extends Node2D

@export var default_strength: float = 2.0
@export var default_duration: float = 0.18

var _elapsed: float = 0.0
var _duration: float = 0.0
var _strength: float = 0.0
var _base_position: Vector2 = Vector2.ZERO
var _target: Node2D


func _ready() -> void:
	_base_position = position
	_target = get_parent() as Node2D
	set_process(true)


func play(strength: float = -1.0, duration: float = -1.0) -> void:
	_strength = default_strength if strength < 0.0 else strength
	_duration = default_duration if duration < 0.0 else duration
	_elapsed = 0.0
	if _target == null:
		_target = get_parent() as Node2D


func _process(delta: float) -> void:
	if _duration <= 0.0:
		return
	_elapsed += delta
	var progress: float = clampf(_elapsed / _duration, 0.0, 1.0)
	var amount: float = _strength * (1.0 - progress)
	var offset := Vector2(sin(_elapsed * 80.0), cos(_elapsed * 91.0)) * amount
	if _target != null:
		_target.position = _base_position + offset
	if progress >= 1.0:
		_duration = 0.0
		if _target != null:
			_target.position = _base_position
