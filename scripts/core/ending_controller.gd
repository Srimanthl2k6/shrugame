extends Control

var _input_ready := false
var _returning_to_title := false
var _input_events_received := 0
var _last_input_event := ""
var _web_return_callback


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.stop_story_music()
		audio_manager.play_birthday_cheer()
	if OS.has_feature("web"):
		_web_return_callback = JavaScriptBridge.create_callback(_on_web_title_request)
		var window = JavaScriptBridge.get_interface("window")
		window.__shrugameReturnToTitle = _web_return_callback
	_publish_web_diagnostics(false)


func _process(_delta: float) -> void:
	if _input_ready:
		if not _returning_to_title and (
			Input.is_action_just_pressed("interact")
			or Input.is_action_just_pressed("ui_accept")
			or Input.is_action_just_pressed("ui_cancel")
		):
			_returning_to_title = true
			_return_to_title.call_deferred()
		return
	if not Input.is_action_pressed("interact") \
		and not Input.is_action_pressed("ui_accept") \
		and not Input.is_action_pressed("ui_cancel"):
		_input_ready = true
		_publish_web_diagnostics(false)


func _input(event: InputEvent) -> void:
	_input_events_received += 1
	_last_input_event = event.as_text()
	_publish_web_diagnostics(false)
	if not _input_ready or _returning_to_title or event.is_echo():
		return
	if _is_title_return_event(event):
		_returning_to_title = true
		get_viewport().set_input_as_handled()
		_return_to_title.call_deferred()


func _return_to_title() -> void:
	_publish_web_diagnostics(true)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_web_title_request(_arguments: Array) -> void:
	if not _input_ready or _returning_to_title:
		return
	_returning_to_title = true
	_return_to_title.call_deferred()


func _is_title_return_event(event: InputEvent) -> bool:
	if event is InputEventKey and event.is_pressed():
		var key_event := event as InputEventKey
		var keycode := key_event.keycode if key_event.keycode != 0 else key_event.physical_keycode
		if keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_E, KEY_ESCAPE]:
			return true
	return event.is_action_pressed("interact") \
		or event.is_action_pressed("ui_accept") \
		or event.is_action_pressed("ui_cancel")


func _publish_web_diagnostics(returned_to_title: bool) -> void:
	if not OS.has_feature("web"):
		return
	var photo := get_node_or_null("BirthdayPhoto") as TextureRect
	var texture := photo.texture if photo != null else null
	var payload := JSON.stringify({
		"scene": "title" if returned_to_title else "ending",
		"returnedToTitle": returned_to_title,
		"photoWidth": texture.get_width() if texture != null else 0,
		"photoHeight": texture.get_height() if texture != null else 0,
		"photoStretchMode": photo.stretch_mode if photo != null else -1,
		"inputReady": _input_ready,
		"inputEventsReceived": _input_events_received,
		"lastInputEvent": _last_input_event
	})
	JavaScriptBridge.eval("window.__shrugameEndingDiagnostics = %s" % payload, true)
