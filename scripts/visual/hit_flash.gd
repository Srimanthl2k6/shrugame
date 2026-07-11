extends ColorRect

@export var default_duration: float = 0.12
@export var flash_color: Color = Color(1, 1, 1, 0.48)

var _elapsed: float = 0.0
var _duration: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color(0, 0, 0, 0)
	set_process(true)


func play(duration: float = -1.0) -> void:
	_duration = default_duration if duration < 0.0 else duration
	_elapsed = 0.0
	color = flash_color
	var settings_manager := get_node_or_null("/root/SettingsManager")
	if settings_manager != null and bool(settings_manager.get_setting("flash_reduction", false)):
		color.a *= 0.28


func _process(delta: float) -> void:
	if _duration <= 0.0:
		return
	_elapsed += delta
	var progress: float = clampf(_elapsed / _duration, 0.0, 1.0)
	color = flash_color
	color.a = flash_color.a * (1.0 - progress)
	if progress >= 1.0:
		_duration = 0.0
		color.a = 0.0
