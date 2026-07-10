extends SceneTree

const EXPORT_PRESET_PATH := "res://export_presets.cfg"
const README_PATH := "res://README.md"
const WINDOWS_EXE_PATH := "res://builds/windows/Shrugame.exe"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_export_preset(failures)
	_check_readme_status(failures)
	_check_windows_build(failures)

	if failures.is_empty():
		print("PASS: Ishiville Pass 15 smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_export_preset(failures: Array[String]) -> void:
	if not FileAccess.file_exists(EXPORT_PRESET_PATH):
		failures.append("Missing export_presets.cfg")
		return
	var text := FileAccess.get_file_as_string(EXPORT_PRESET_PATH)
	for required_text in [
		"name=\"Windows Desktop\"",
		"platform=\"Windows Desktop\"",
		"export_path=\"builds/windows/Shrugame.exe\"",
		"binary_format/embed_pck=true",
		"application/product_name=\"Shrugame\""
	]:
		if not text.contains(required_text):
			failures.append("export_presets.cfg missing %s" % required_text)
	if text.contains("application/file_version=\"\""):
		failures.append("Windows export file_version must be set")
	if text.contains("application/product_version=\"\""):
		failures.append("Windows export product_version must be set")


func _check_readme_status(failures: Array[String]) -> void:
	if not FileAccess.file_exists(README_PATH):
		failures.append("Missing README.md")
		return
	var text := FileAccess.get_file_as_string(README_PATH)
	for required_text in [
		"Pass 15 release candidate",
		"builds/windows/Shrugame.exe",
		"all smoke tests",
		"Godot 4.7"
	]:
		if not text.contains(required_text):
			failures.append("README missing release candidate note: %s" % required_text)


func _check_windows_build(failures: Array[String]) -> void:
	if not FileAccess.file_exists(WINDOWS_EXE_PATH):
		failures.append("Missing Windows executable %s" % WINDOWS_EXE_PATH)
		return
	var file := FileAccess.open(WINDOWS_EXE_PATH, FileAccess.READ)
	if file == null:
		failures.append("Cannot open Windows executable")
		return
	if file.get_length() < 25_000_000:
		failures.append("Windows executable is unexpectedly small")
