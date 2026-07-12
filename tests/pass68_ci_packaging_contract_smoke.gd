extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ci := FileAccess.get_file_as_string("res://.github/workflows/ci.yml")
	var pages := FileAccess.get_file_as_string("res://.github/workflows/pages.yml")
	var release := FileAccess.get_file_as_string("res://.github/workflows/release.yml")
	_assert(ci.contains("run_release_tests.ps1") and ci.contains("Godot_v4.7-stable"), "CI must parse and test with Godot 4.7")
	_assert(pages.contains("actions/deploy-pages@v4") and pages.contains("site/dist"), "Pages workflow must deploy the built site")
	for requirement in ["electron-builder", "--mac", "--x64", "--arm64", "windows-builds", "macos-builds", "SHA256SUMS.txt", "gh release"]:
		_assert(release.contains(requirement), "Release workflow is missing %s" % requirement)
	var builder := FileAccess.get_file_as_string("res://electron/electron-builder.yml")
	_assert(builder.contains("Setup.${ext}") and builder.contains("Portable.${ext}"), "Windows artifacts need non-colliding names")
	_assert(builder.contains("identity: null"), "Initial macOS build must remain explicitly unsigned")
	var version := _load_json("res://version.json")
	_assert(str(version.get("version", "")) == "1.0.2", "Release version source must be 1.0.2")
	_finish("Pass 68 CI and desktop packaging contract")


func _load_json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


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
