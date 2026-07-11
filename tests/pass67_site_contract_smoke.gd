extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var html := FileAccess.get_file_as_string("res://site/index.html")
	var css := FileAccess.get_file_as_string("res://site/src/styles.css")
	_assert(html.contains("<h1 id=\"hero-title\">SHRUGAME</h1>"), "Landing page must lead with the game name")
	for section_id in ["story", "districts", "difficulty", "accessibility"]:
		_assert(html.contains("id=\"%s\"" % section_id), "Landing page is missing %s" % section_id)
	for level_number in range(1, 6):
		var media := "res://site/public/media/district-%02d.png" % level_number
		_assert(FileAccess.file_exists(media), "Landing page media is missing %s" % media)
		_assert(html.contains("district-%02d.png" % level_number), "Landing page must show district %02d" % level_number)
	for screenshot_number in range(1, 4):
		_assert(FileAccess.file_exists("res://site/public/media/gameplay-%02d.png" % screenshot_number), "Actual gameplay screenshot %02d is missing" % screenshot_number)
	var lowercase_html := html.to_lower()
	_assert(lowercase_html.contains("shrububu") and lowercase_html.contains("srmt") and lowercase_html.contains("extremely easy") and lowercase_html.contains("extremely hard"), "Landing page must explain both modes")
	_assert(html.contains("releases/latest"), "Landing page must link to the current GitHub release")
	_assert(css.contains("@media (max-width: 520px)"), "Landing page needs mobile layout rules")
	_assert(not html.contains("placeholder") and not html.contains("TODO"), "Landing page cannot ship placeholder copy")
	_assert(FileAccess.file_exists("res://site/public/media/app-icon.png"), "Landing page app icon is missing")
	_finish("Pass 67 landing page and media contract")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish(label: String) -> void:
	if failures.is_empty():
		print("PASS: %s" % label)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
