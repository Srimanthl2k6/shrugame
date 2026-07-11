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
		if message == null:
			failures.append("Birthday message label is missing")
		elif message.text != EXPECTED_MESSAGE:
			failures.append("Birthday message does not exactly match the requested text")
		elif not message.visible:
			failures.append("Birthday message is not visible")
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
