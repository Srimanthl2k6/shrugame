extends SceneTree

const ENDING_SCENE := "res://scenes/ending.tscn"
const EXPECTED_MESSAGE := "Happy Birthday Tingu Verma.\n~ Taklu Taklu Chuha."


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var packed := load(ENDING_SCENE) as PackedScene
	if packed == null:
		failures.append("Ending scene failed to load")
	else:
		var ending := packed.instantiate()
		var message := ending.get_node_or_null("BirthdayCard/BirthdayMessage") as Label
		var photo := ending.get_node_or_null("BirthdayPhoto") as TextureRect
		var hint := ending.get_node_or_null("ContinueHint") as Label
		if message == null:
			failures.append("Birthday message label is missing")
		elif message.text != EXPECTED_MESSAGE:
			failures.append("Birthday message does not exactly match the requested text")
		elif not message.visible:
			failures.append("Birthday message is not visible")
		if photo == null or photo.texture == null:
			failures.append("Birthday photograph is missing")
		else:
			if photo.texture.get_width() != 1194 or photo.texture.get_height() != 1600:
				failures.append("Birthday photograph must retain its complete 1194x1600 source")
			if photo.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
				failures.append("Birthday photograph must be shown uncropped")
			if photo.texture_filter != CanvasItem.TEXTURE_FILTER_LINEAR:
				failures.append("Birthday photograph must use smooth filtering")
		if hint == null or hint.text != "ENTER / ESC: TITLE":
			failures.append("Ending title-return hint is incorrect")
		ending.free()
	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("PASS: Premium ending birthday message smoke test")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
