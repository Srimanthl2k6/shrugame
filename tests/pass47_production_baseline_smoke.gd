extends SceneTree

const MANIFEST_PATH := "res://docs/PRODUCTION_MANIFEST.json"
const PLAN_PATH := "res://docs/REMAINING_EXECUTION_PLAN.md"
const SCORECARD_PATH := "res://docs/MODERN_INDIE_GAP_SCORECARD.md"

var failures: Array[String] = []
var status_counts := {
	"blockout": 0,
	"draft": 0,
	"curated": 0,
	"final": 0
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var manifest := _load_json(MANIFEST_PATH)
	_assert(not manifest.is_empty(), "Production manifest must parse")
	_assert(FileAccess.file_exists(PLAN_PATH), "Approved remaining-production plan must be saved")
	_assert(FileAccess.file_exists(SCORECARD_PATH), "Modern-indie gap scorecard must exist")
	_assert(FileAccess.file_exists("res://docs/PRODUCTION_MANIFEST.md"), "Human-readable manifest must exist")

	var statuses: Dictionary = manifest.get("status_definitions", {})
	for status_id in ["blockout", "draft", "curated", "final"]:
		_assert(statuses.has(status_id), "Manifest missing status definition: %s" % status_id)

	var rules: Array = manifest.get("rules", [])
	var covered_paths: Array[String] = []
	for coverage_value in manifest.get("coverage", []):
		if typeof(coverage_value) != TYPE_DICTIONARY:
			failures.append("Manifest coverage entry must be a dictionary")
			continue
		var coverage: Dictionary = coverage_value
		var root := str(coverage.get("root", ""))
		var extensions := _to_string_array(coverage.get("extensions", []))
		_collect_files(root, extensions, covered_paths)

	for path in covered_paths:
		var classification := _classify(path, rules)
		if classification.is_empty():
			failures.append("Unclassified production file: %s" % path)
			continue
		var status := str(classification.get("status", ""))
		if not status_counts.has(status):
			failures.append("Invalid status '%s' for %s" % [status, path])
			continue
		status_counts[status] = int(status_counts[status]) + 1

	var baseline: Dictionary = manifest.get("baseline_counts", {})
	_assert(covered_paths.size() >= int(baseline.get("total_covered", 0)), "Manifest coverage regressed below the Pass 47 baseline")
	_assert(int(status_counts["blockout"]) > 0, "Baseline must honestly identify remaining blockout content")
	_assert(int(status_counts["curated"]) > 0, "Baseline must identify reviewed production content")
	_assert(int(status_counts["final"]) > 0, "Baseline must identify at least one release-approved family")

	var gitignore := FileAccess.get_file_as_string("res://.gitignore")
	_assert(gitignore.contains("shrububu- child/"), "Child reference folder must remain Git-ignored")
	_assert(gitignore.contains("shrububu- older/"), "Adult reference folder must remain Git-ignored")
	_assert(FileAccess.file_exists("res://shrububu- child/.gdignore"), "Child reference folder must remain Godot-ignored")
	_assert(FileAccess.file_exists("res://shrububu- older/.gdignore"), "Adult reference folder must remain Godot-ignored")

	if failures.is_empty():
		print("PASS: Pass 47 production baseline covers %d files: %s" % [covered_paths.size(), status_counts])
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _collect_files(root: String, extensions: Array[String], output: Array[String]) -> void:
	var directory := DirAccess.open(root)
	if directory == null:
		failures.append("Could not scan manifest root: %s" % root)
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry == "." or entry == "..":
			entry = directory.get_next()
			continue
		var path := root.path_join(entry)
		if directory.current_is_dir():
			_collect_files(path, extensions, output)
		elif extensions.has(entry.get_extension().to_lower()):
			output.append(path)
		entry = directory.get_next()
	directory.list_dir_end()


func _classify(path: String, rules: Array) -> Dictionary:
	for rule_value in rules:
		if typeof(rule_value) != TYPE_DICTIONARY:
			continue
		var rule: Dictionary = rule_value
		if rule.has("exact") and path == str(rule["exact"]):
			return rule
		if rule.has("prefix") and path.begins_with(str(rule["prefix"])):
			return rule
	return {}


func _to_string_array(value) -> Array[String]:
	var result: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for item in value:
		result.append(str(item).to_lower())
	return result


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
