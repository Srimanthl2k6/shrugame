extends Control

@export var cutin_id: String = ""
@export var frame_count: int = 6
@export var safe_size: Vector2 = Vector2(320, 80)
@export var frame_seconds: float = 0.06

var _elapsed: float = 0.0
var _playing: bool = false
var last_title: String = ""

@onready var _panel: Panel = $Panel
@onready var _label: Label = $Panel/TitleLabel


func _ready() -> void:
	custom_minimum_size = safe_size
	visible = false
	set_process(true)


func _process(delta: float) -> void:
	if not _playing:
		return
	_elapsed += delta
	var duration: float = maxf(frame_seconds, 0.01) * float(maxi(frame_count, 1))
	var t: float = clampf(_elapsed / duration, 0.0, 1.0)
	position.x = lerpf(-safe_size.x, 0.0, minf(t * 2.0, 1.0))
	modulate.a = 1.0 - maxf(0.0, t - 0.72) / 0.28
	if _elapsed >= duration:
		_playing = false
		visible = false
		position.x = 0.0
		modulate.a = 1.0


func play_cut_in(new_cutin_id: String, title: String = "") -> void:
	cutin_id = new_cutin_id
	last_title = title
	if _label != null:
		_label.text = title if not title.is_empty() else new_cutin_id.capitalize()
	_elapsed = 0.0
	_playing = true
	visible = true
	position = Vector2(-safe_size.x, 0.0)
	modulate.a = 1.0


func stop_cut_in() -> void:
	_playing = false
	visible = false


func get_animation_metadata() -> Dictionary:
	return {
		"cutin_id": cutin_id,
		"frame_count": frame_count,
		"safe_size": safe_size
	}
