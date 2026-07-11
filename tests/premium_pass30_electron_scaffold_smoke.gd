extends SceneTree

const REQUIRED_FILES := [
	"res://electron/package.json",
	"res://electron/electron-builder.yml",
	"res://electron/main.cjs",
	"res://electron/preload.cjs",
	"res://electron/renderer/index.html",
	"res://electron/renderer/styles.css",
	"res://electron/renderer/loading.js",
	"res://electron/scripts/export-godot.cjs",
	"res://electron/scripts/smoke-test.cjs"
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	for path in REQUIRED_FILES:
		if not FileAccess.file_exists(path):
			failures.append("Missing Electron source file: %s" % path)
	var presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	if not presets.contains('name="Web"'):
		failures.append("Web export preset is missing")
	var main_source := FileAccess.get_file_as_string("res://electron/main.cjs")
	for required_security_setting in ["contextIsolation: true", "nodeIntegration: false", "sandbox: true"]:
		if not main_source.contains(required_security_setting):
			failures.append("Electron security setting missing: %s" % required_security_setting)
	_finish(failures, "Premium Pass 30 Electron scaffold smoke test")


func _finish(failures: Array[String], test_name: String) -> void:
	if failures.is_empty():
		print("PASS: %s" % test_name)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
