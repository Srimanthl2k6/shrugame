extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var all_story_text := ""
	for level_number in range(1, 6):
		var path := "res://data/dialogue/level_%02d_dialogue.json" % level_number
		var dialogue := _load_json(path)
		_assert(not dialogue.is_empty(), "%s must parse" % path)
		var minor_npcs := 0
		for entry_value in dialogue.values():
			if typeof(entry_value) != TYPE_DICTIONARY:
				continue
			var entry: Dictionary = entry_value
			var tags: Array = entry.get("tags", [])
			if tags.has("minor_npc"):
				minor_npcs += 1
			var lines: Array = entry.get("lines", [])
			_assert(lines.size() >= 2, "%s dialogue entries need at least two authored lines" % path)
		all_story_text += FileAccess.get_file_as_string(path)
		_assert(minor_npcs >= 5, "Level %d needs at least five minor NPC dialogue voices" % level_number)

	var catalog := _load_json("res://data/cutscenes/index.json")
	_assert(catalog.size() >= 28, "Production needs at least 28 authored cutscenes")
	for cutscene_id in catalog:
		var cutscene_path := str(catalog[cutscene_id])
		var data := _load_json(cutscene_path)
		_assert(str(data.get("id", "")) == str(cutscene_id), "%s must have a matching cutscene ID" % cutscene_id)
		_assert(data.get("steps", []).size() >= 2, "%s must contain authored staging" % cutscene_id)
		all_story_text += FileAccess.get_file_as_string(cutscene_path)

	_assert(all_story_text.count("Unprovoked") == 2, "Unprovoked must appear only after the building incident and Suhas accusation")
	_assert(all_story_text.count("Ek Bihari, Sab pe Bhaari") == 2, "Strength declaration must appear only at Nishal and the SRMT climax")
	_assert(all_story_text.count("ehehehe") == 1, "ehehehe must be reserved for the KFC rescue reward")
	_assert(not all_story_text.contains("Autinjection"), "Public story mechanics must use fictional Pattern Serum")
	_assert(not all_story_text.contains("Shruti"), "Production dialogue must use canonical Shrububu unless an intentional mistake is authored")

	var ending := FileAccess.get_file_as_string("res://scenes/ending.tscn")
	_assert(ending.contains("Happy Birthday Tingu Verma.\\n~ Taklu Taklu Chuha."), "Ending must preserve the exact birthday card")
	_finish("Pass 62 narrative editorial contract")


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
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
