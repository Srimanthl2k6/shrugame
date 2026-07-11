extends Control

@onready var _top_bar: ColorRect = $TopBar
@onready var _bottom_bar: ColorRect = $BottomBar
@onready var _caption: Label = $Caption
@onready var _skip_label: Label = $SkipLabel
@onready var _fade: ColorRect = $Fade


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_fade.color.a = 0.0


func show_frame(caption: String = "", skippable: bool = true) -> void:
	visible = true
	_caption.text = caption
	_caption.visible = not caption.is_empty()
	_skip_label.visible = skippable
	_top_bar.position.y = -18.0
	_bottom_bar.position.y = 18.0
	var tween := create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_top_bar, "position:y", 0.0, 0.18)
	tween.tween_property(_bottom_bar, "position:y", 0.0, 0.18)


func hide_frame() -> void:
	visible = false
	_caption.text = ""
	_fade.color.a = 0.0


func set_caption(caption: String) -> void:
	_caption.text = caption
	_caption.visible = not caption.is_empty()


func fade_to(alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_fade, "color:a", clampf(alpha, 0.0, 1.0), maxf(duration, 0.01))
	await tween.finished
