extends CanvasLayer

signal confirmed
signal skipped

var _cancel_hold_seconds := 0.0
var _confirm_enabled := false

@onready var _root: Control = $Root
@onready var _dim: ColorRect = $Root/Dim
@onready var _card: Panel = $Root/Card
@onready var _card_title: Label = $Root/Card/Title
@onready var _card_body: Label = $Root/Card/Body
@onready var _card_hint: Label = $Root/Card/Hint
@onready var _context: Panel = $Root/ContextPanel
@onready var _context_title: Label = $Root/ContextPanel/Title
@onready var _context_body: Label = $Root/ContextPanel/Body


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.visible = false


func show_card(title: String, body: String, hint: String) -> void:
	_root.visible = true
	_dim.visible = true
	_card.visible = true
	_context.visible = false
	_card_title.text = title
	_card_body.text = body
	_card_hint.text = hint
	_confirm_enabled = true
	_cancel_hold_seconds = 0.0


func show_context(title: String, body: String) -> void:
	_root.visible = true
	_dim.visible = false
	_card.visible = false
	_context.visible = true
	_context_title.text = title
	_context_body.text = body
	_confirm_enabled = false
	_cancel_hold_seconds = 0.0


func hide_overlay() -> void:
	_root.visible = false
	_confirm_enabled = false
	_cancel_hold_seconds = 0.0


func is_open() -> bool:
	return _root.visible


func _process(delta: float) -> void:
	if not _root.visible:
		_cancel_hold_seconds = 0.0
		return
	if Input.is_action_pressed("ui_cancel"):
		_cancel_hold_seconds += delta
		if _cancel_hold_seconds >= 1.0:
			_cancel_hold_seconds = 0.0
			skipped.emit()
	else:
		_cancel_hold_seconds = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if not _root.visible or not _confirm_enabled:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		confirmed.emit()
		get_viewport().set_input_as_handled()
