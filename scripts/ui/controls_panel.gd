extends Control

signal close_requested

const ACTION_LABELS := {
	"move_up": "MOVE UP",
	"move_down": "MOVE DOWN",
	"move_left": "MOVE LEFT",
	"move_right": "MOVE RIGHT",
	"interact": "INTERACT",
	"ui_cancel": "BACK / PAUSE"
}

var _waiting_action := ""
var _buttons: Dictionary = {}

@onready var _rows: VBoxContainer = $Dim/Panel/Rows
@onready var _status: Label = $Dim/Panel/Status


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_rows()
	$Dim/Panel/ResetButton.pressed.connect(_reset)
	$Dim/Panel/BackButton.pressed.connect(close)


func open() -> void:
	_refresh_labels()
	_status.text = "SELECT A BINDING"
	visible = true
	if not _buttons.is_empty():
		(_buttons.values()[0] as Button).grab_focus.call_deferred()


func close() -> void:
	_waiting_action = ""
	visible = false
	close_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not _waiting_action.is_empty() and event.is_pressed() and (event is InputEventKey or event is InputEventJoypadButton):
		var manager := get_node_or_null("/root/InputManager")
		if manager != null and manager.rebind_event(_waiting_action, event):
			_status.text = "%s UPDATED" % str(ACTION_LABELS[_waiting_action])
		_waiting_action = ""
		_refresh_labels()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _build_rows() -> void:
	for action in ACTION_LABELS:
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(210, 15)
		var label := Label.new()
		label.text = str(ACTION_LABELS[action])
		label.custom_minimum_size = Vector2(82, 15)
		label.add_theme_font_size_override("font_size", 6)
		var button := Button.new()
		button.custom_minimum_size = Vector2(124, 15)
		button.add_theme_font_size_override("font_size", 6)
		button.pressed.connect(_begin_rebind.bind(action))
		row.add_child(label)
		row.add_child(button)
		_rows.add_child(row)
		_buttons[action] = button


func _begin_rebind(action: String) -> void:
	_waiting_action = action
	_status.text = "PRESS A KEY OR GAMEPAD BUTTON"


func _refresh_labels() -> void:
	var manager := get_node_or_null("/root/InputManager")
	if manager == null:
		return
	for action in _buttons:
		(_buttons[action] as Button).text = manager.get_binding_label(str(action))


func _reset() -> void:
	var manager := get_node_or_null("/root/InputManager")
	if manager != null:
		manager.reset_bindings()
	_refresh_labels()
	_status.text = "DEFAULT BINDINGS RESTORED"
