extends Node

signal dialogue_started(speaker: String, line: String)
signal dialogue_advanced(speaker: String, line: String)
signal dialogue_finished(flag_name: String)

var _entries: Dictionary = {}
var _active_entry: Dictionary = {}
var _active_lines: Array = []
var _active_index := 0
var _active_flag := ""


func load_dialogue_file(path: String) -> bool:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return false
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return false
	_entries = data
	return true


func start_dialogue(dialogue_id: String, flag_on_complete: String = "") -> bool:
	if not _entries.has(dialogue_id):
		return false
	var entry = _entries[dialogue_id]
	if typeof(entry) != TYPE_DICTIONARY:
		return false
	var lines = entry.get("lines", [])
	if typeof(lines) != TYPE_ARRAY or lines.is_empty():
		return false

	_active_entry = entry
	_active_lines = lines
	_active_index = 0
	_active_flag = flag_on_complete
	if _active_flag.is_empty():
		_active_flag = entry.get("complete_flag", "")

	dialogue_started.emit(_active_entry.get("speaker", ""), str(_active_lines[_active_index]))
	return true


func start_inline_dialogue(speaker: String, lines: Array, flag_on_complete: String = "") -> bool:
	if lines.is_empty():
		return false
	_active_entry = {"speaker": speaker}
	_active_lines = lines.duplicate(true)
	_active_index = 0
	_active_flag = flag_on_complete
	dialogue_started.emit(speaker, str(_active_lines[0]))
	return true


func cancel_dialogue(emit_finished: bool = true) -> void:
	if not is_active():
		return
	_active_entry = {}
	_active_lines = []
	_active_index = 0
	_active_flag = ""
	if emit_finished:
		dialogue_finished.emit("")


func advance() -> bool:
	if not is_active():
		return false

	_active_index += 1
	if _active_index < _active_lines.size():
		dialogue_advanced.emit(_active_entry.get("speaker", ""), str(_active_lines[_active_index]))
		return true

	var completed_flag := _active_flag
	_active_entry = {}
	_active_lines = []
	_active_index = 0
	_active_flag = ""

	if not completed_flag.is_empty() and is_inside_tree():
		var game_state := get_tree().root.get_node_or_null("GameState")
		if game_state != null:
			game_state.set_flag(completed_flag, true)
	dialogue_finished.emit(completed_flag)
	return false


func is_active() -> bool:
	return not _active_lines.is_empty()
