extends ColorRect

@export var default_duration: float = 0.24

var _elapsed: float = 0.0
var _duration: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color(0, 0, 0, 0)
	set_process(true)


func play(duration: float = -1.0) -> void:
	_duration = default_duration if duration < 0.0 else duration
	_elapsed = 0.0
	color = Color(0, 0, 0, 0.0)
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.play_sfx("transition_wipe")


func _process(delta: float) -> void:
	if _duration <= 0.0:
		return
	_elapsed += delta
	var progress: float = clampf(_elapsed / _duration, 0.0, 1.0)
	color.a = sin(progress * PI) * 0.72
	if progress >= 1.0:
		_duration = 0.0
		color.a = 0.0
