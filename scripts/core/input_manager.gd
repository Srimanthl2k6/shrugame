extends Node

signal input_device_changed(device_id: String)
signal bindings_changed

const ACTIONS := ["move_left", "move_right", "move_up", "move_down", "interact", "ui_accept", "ui_cancel"]
const DEFAULT_BINDINGS_PATH := "user://input_bindings.json"
const DEFAULT_BINDINGS_TEMP_PATH := "user://input_bindings.tmp.json"
const DEFAULT_BINDINGS_BACKUP_PATH := "user://input_bindings.backup.json"

var last_device_id := "keyboard"
var _default_events: Dictionary = {}
var bindings_path := DEFAULT_BINDINGS_PATH
var bindings_temporary_path := DEFAULT_BINDINGS_TEMP_PATH
var bindings_backup_path := DEFAULT_BINDINGS_BACKUP_PATH


func _ready() -> void:
	_install_default_controller_bindings()
	_capture_defaults()
	load_bindings()


func _input(event: InputEvent) -> void:
	var next_device := last_device_id
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		next_device = "controller"
	elif event is InputEventKey or event is InputEventMouse:
		next_device = "keyboard"
	if next_device != last_device_id:
		last_device_id = next_device
		input_device_changed.emit(last_device_id)


func get_last_device_id() -> String:
	return last_device_id


func get_interact_prompt() -> String:
	return "A" if last_device_id == "controller" else "E/ENTER"


func get_cancel_prompt() -> String:
	return "B" if last_device_id == "controller" else "ESC"


func get_action_prompt(action: String) -> String:
	if not InputMap.has_action(action):
		return "-"
	var wants_controller := last_device_id == "controller"
	for event in InputMap.action_get_events(action):
		if wants_controller and event is InputEventJoypadButton:
			return _joy_button_name(int((event as InputEventJoypadButton).button_index))
		if wants_controller and event is InputEventJoypadMotion:
			return "LEFT STICK"
		if not wants_controller and event is InputEventKey:
			var key := (event as InputEventKey).physical_keycode
			if key == 0:
				key = (event as InputEventKey).keycode
			var label := OS.get_keycode_string(key).to_upper()
			if not label.is_empty():
				return label
	return get_binding_label(action)


func get_movement_prompt() -> String:
	if last_device_id == "controller":
		return "LEFT STICK / D-PAD"
	var defaults := {
		"move_up": "W",
		"move_left": "A",
		"move_down": "S",
		"move_right": "D"
	}
	var uses_defaults := true
	for action in defaults:
		if get_action_prompt(action) != defaults[action]:
			uses_defaults = false
			break
	if uses_defaults:
		return "WASD / ARROW KEYS"
	return "UP %s  LEFT %s  DOWN %s  RIGHT %s" % [
		get_action_prompt("move_up"),
		get_action_prompt("move_left"),
		get_action_prompt("move_down"),
		get_action_prompt("move_right")
	]


func rebind_key(action: String, keycode: Key) -> bool:
	if not InputMap.has_action(action):
		return false
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	var key_event := InputEventKey.new()
	key_event.physical_keycode = keycode
	InputMap.action_add_event(action, key_event)
	save_bindings()
	bindings_changed.emit()
	return true


func rebind_event(action: String, input_event: InputEvent) -> bool:
	if not InputMap.has_action(action) or not (input_event is InputEventKey or input_event is InputEventJoypadButton or input_event is InputEventJoypadMotion):
		return false
	for existing in InputMap.action_get_events(action):
		if (input_event is InputEventKey and existing is InputEventKey) or (input_event is InputEventJoypadButton and existing is InputEventJoypadButton) or (input_event is InputEventJoypadMotion and existing is InputEventJoypadMotion):
			InputMap.action_erase_event(action, existing)
	InputMap.action_add_event(action, input_event.duplicate())
	save_bindings()
	bindings_changed.emit()
	return true


func get_binding_label(action: String) -> String:
	var keyboard := "-"
	var controller := "-"
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and keyboard == "-":
			var key := (event as InputEventKey).physical_keycode
			if key == 0:
				key = (event as InputEventKey).keycode
			keyboard = OS.get_keycode_string(key)
		elif event is InputEventJoypadButton and controller == "-":
			controller = _joy_button_name(int((event as InputEventJoypadButton).button_index))
		elif event is InputEventJoypadMotion and controller == "-":
			controller = _joy_motion_name(event as InputEventJoypadMotion)
	return "%s / %s" % [keyboard, controller]


func save_bindings() -> bool:
	var serialized: Dictionary = {}
	for action in ACTIONS:
		serialized[action] = []
		for event in InputMap.action_get_events(action):
			var event_data := _serialize_event(event)
			if not event_data.is_empty():
				serialized[action].append(event_data)
	var file := FileAccess.open(bindings_temporary_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(serialized, "\t"))
	file.flush()
	file = null
	return _commit_bindings()


func load_bindings() -> bool:
	var parsed = _load_binding_dictionary(bindings_path)
	if parsed.is_empty():
		parsed = _load_binding_dictionary(bindings_backup_path)
	if parsed.is_empty():
		return false
	for action in ACTIONS:
		if typeof(parsed.get(action, null)) != TYPE_ARRAY:
			continue
		InputMap.action_erase_events(action)
		for event_data in parsed[action]:
			var event := _deserialize_event(event_data)
			if event != null:
				InputMap.action_add_event(action, event)
	bindings_changed.emit()
	return true


func reset_bindings() -> void:
	for action in ACTIONS:
		InputMap.action_erase_events(action)
		for event in _default_events.get(action, []):
			InputMap.action_add_event(action, event.duplicate())
	for path in [bindings_path, bindings_temporary_path, bindings_backup_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	bindings_changed.emit()


func _commit_bindings() -> bool:
	var target := ProjectSettings.globalize_path(bindings_path)
	var temporary := ProjectSettings.globalize_path(bindings_temporary_path)
	var backup := ProjectSettings.globalize_path(bindings_backup_path)
	if FileAccess.file_exists(bindings_backup_path):
		DirAccess.remove_absolute(backup)
	if FileAccess.file_exists(bindings_path) and DirAccess.rename_absolute(target, backup) != OK:
		return false
	if DirAccess.rename_absolute(temporary, target) == OK:
		return true
	if FileAccess.file_exists(bindings_backup_path):
		DirAccess.rename_absolute(backup, target)
	return false


func _load_binding_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var parsed = parser.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _capture_defaults() -> void:
	_default_events.clear()
	for action in ACTIONS:
		_default_events[action] = []
		for event in InputMap.action_get_events(action):
			_default_events[action].append(event.duplicate())


func _serialize_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {"type": "key", "keycode": int((event as InputEventKey).keycode), "physical_keycode": int((event as InputEventKey).physical_keycode)}
	if event is InputEventJoypadButton:
		return {"type": "joy_button", "button": int((event as InputEventJoypadButton).button_index)}
	if event is InputEventJoypadMotion:
		return {"type": "joy_axis", "axis": int((event as InputEventJoypadMotion).axis), "value": float((event as InputEventJoypadMotion).axis_value)}
	return {}


func _deserialize_event(data) -> InputEvent:
	if typeof(data) != TYPE_DICTIONARY:
		return null
	match str(data.get("type", "")):
		"key":
			var event := InputEventKey.new()
			event.keycode = int(data.get("keycode", 0))
			event.physical_keycode = int(data.get("physical_keycode", 0))
			return event
		"joy_button":
			var event := InputEventJoypadButton.new()
			event.button_index = int(data.get("button", 0))
			return event
		"joy_axis":
			var event := InputEventJoypadMotion.new()
			event.axis = int(data.get("axis", 0))
			event.axis_value = float(data.get("value", 0.0))
			return event
	return null


func _install_default_controller_bindings() -> void:
	_add_axis_binding("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_axis_binding("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_axis_binding("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_axis_binding("move_down", JOY_AXIS_LEFT_Y, 1.0)
	_add_button_binding("interact", JOY_BUTTON_A)
	_add_button_binding("ui_accept", JOY_BUTTON_A)
	_add_button_binding("ui_cancel", JOY_BUTTON_B)


func _add_axis_binding(action: String, axis: JoyAxis, value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for existing in InputMap.action_get_events(action):
		if existing is InputEventJoypadMotion and existing.axis == axis and is_equal_approx(existing.axis_value, value):
			return
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	InputMap.action_add_event(action, event)


func _add_button_binding(action: String, button: JoyButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for existing in InputMap.action_get_events(action):
		if existing is InputEventJoypadButton and existing.button_index == button:
			return
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)


func _joy_button_name(button_index: int) -> String:
	var names := {
		JOY_BUTTON_A: "A",
		JOY_BUTTON_B: "B",
		JOY_BUTTON_X: "X",
		JOY_BUTTON_Y: "Y",
		JOY_BUTTON_LEFT_SHOULDER: "LB",
		JOY_BUTTON_RIGHT_SHOULDER: "RB",
		JOY_BUTTON_BACK: "BACK",
		JOY_BUTTON_START: "START",
		JOY_BUTTON_DPAD_UP: "D-PAD UP",
		JOY_BUTTON_DPAD_DOWN: "D-PAD DOWN",
		JOY_BUTTON_DPAD_LEFT: "D-PAD LEFT",
		JOY_BUTTON_DPAD_RIGHT: "D-PAD RIGHT"
	}
	return str(names.get(button_index, "PAD %d" % button_index))


func _joy_motion_name(motion: InputEventJoypadMotion) -> String:
	if motion.axis == JOY_AXIS_LEFT_X:
		return "LEFT STICK RIGHT" if motion.axis_value > 0 else "LEFT STICK LEFT"
	if motion.axis == JOY_AXIS_LEFT_Y:
		return "LEFT STICK DOWN" if motion.axis_value > 0 else "LEFT STICK UP"
	return "STICK AXIS %d%s" % [int(motion.axis), "+" if motion.axis_value > 0 else "-"]
