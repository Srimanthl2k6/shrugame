extends SceneTree

const LEVEL_DIALOGUE := {
	"level_01": "res://data/dialogue/level_01_dialogue.json",
	"level_02": "res://data/dialogue/level_02_dialogue.json",
	"level_03": "res://data/dialogue/level_03_dialogue.json",
	"level_04": "res://data/dialogue/level_04_dialogue.json",
	"level_05": "res://data/dialogue/level_05_dialogue.json"
}

const REQUIRED_TAG_COUNTS := {
	"minor_npc": 5,
	"clue_object": 3,
	"post_clear": 2
}

const REQUIRED_BOSS_TAGS := [
	"mini_boss_intro",
	"mini_boss_defeat",
	"main_boss_intro",
	"main_boss_defeat"
]

const SHRUBUBU_PHRASE_LIMITS := {
	"Unprovoked": {"min": 1, "max": 1, "ids": ["opening_not_kfc"]},
	"Ek Bihari, Sab pe Bhaari": {"min": 1, "max": 1, "ids": ["popcorn_reveal"]},
	"ehehehe": {"min": 1, "max": 2, "ids": ["guitar_reward", "ishiyoga_rescue"]}
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var phrase_counts: Dictionary = {}
	for phrase in SHRUBUBU_PHRASE_LIMITS.keys():
		phrase_counts[phrase] = 0

	for level_id in LEVEL_DIALOGUE.keys():
		var dialogue := _load_dict(LEVEL_DIALOGUE[level_id], failures)
		if dialogue.is_empty():
			continue
		_check_level_dialogue(level_id, dialogue, phrase_counts, failures)

	_check_phrase_counts(phrase_counts, failures)
	_check_clue_journal(failures)
	_check_item_flavor_text(failures)

	if failures.is_empty():
		print("PASS: Ishiville Pass 12 smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_level_dialogue(level_id: String, dialogue: Dictionary, phrase_counts: Dictionary, failures: Array[String]) -> void:
	var tag_counts: Dictionary = {}
	for tag in REQUIRED_TAG_COUNTS.keys():
		tag_counts[tag] = 0
	for tag in REQUIRED_BOSS_TAGS:
		tag_counts[tag] = 0
	var kfc_mentions := 0
	var srmt_mentions := 0

	for dialogue_id in dialogue.keys():
		var entry: Dictionary = dialogue[dialogue_id]
		var lines: Array = entry.get("lines", [])
		if not entry.has("speaker"):
			failures.append("%s/%s missing speaker" % [level_id, dialogue_id])
		if lines.is_empty():
			failures.append("%s/%s needs dialogue lines" % [level_id, dialogue_id])
		var tags := _to_string_array(entry.get("tags", []))
		for tag in tag_counts.keys():
			if tags.has(tag):
				tag_counts[tag] = int(tag_counts[tag]) + 1
		for line_value in lines:
			var line := str(line_value)
			if line.contains("KFC"):
				kfc_mentions += 1
			if line.contains("SRMT"):
				srmt_mentions += 1
			_check_shrububu_phrase(level_id, dialogue_id, entry, line, phrase_counts, failures)

	for tag in REQUIRED_TAG_COUNTS.keys():
		if int(tag_counts[tag]) < int(REQUIRED_TAG_COUNTS[tag]):
			failures.append("%s needs at least %d %s entries" % [level_id, REQUIRED_TAG_COUNTS[tag], tag])
	for tag in REQUIRED_BOSS_TAGS:
		if int(tag_counts[tag]) < 1:
			failures.append("%s missing %s dialogue tag" % [level_id, tag])
	if kfc_mentions < 2:
		failures.append("%s needs KFC motivation visible in at least two lines" % level_id)
	if srmt_mentions < 1:
		failures.append("%s needs SRMT pressure or foreshadowing" % level_id)


func _check_shrububu_phrase(level_id: String, dialogue_id: String, entry: Dictionary, line: String, phrase_counts: Dictionary, failures: Array[String]) -> void:
	for phrase in SHRUBUBU_PHRASE_LIMITS.keys():
		if not line.contains(phrase):
			continue
		phrase_counts[phrase] = int(phrase_counts[phrase]) + 1
		if str(entry.get("speaker", "")) != "Shrububu":
			failures.append("%s phrase '%s' must be spoken by Shrububu" % [level_id, phrase])
		var allowed_ids := _to_string_array(SHRUBUBU_PHRASE_LIMITS[phrase]["ids"])
		if not allowed_ids.has(dialogue_id):
			failures.append("%s uses '%s' in unapproved context %s" % [level_id, phrase, dialogue_id])


func _check_phrase_counts(phrase_counts: Dictionary, failures: Array[String]) -> void:
	for phrase in SHRUBUBU_PHRASE_LIMITS.keys():
		var count := int(phrase_counts[phrase])
		var min_count := int(SHRUBUBU_PHRASE_LIMITS[phrase]["min"])
		var max_count := int(SHRUBUBU_PHRASE_LIMITS[phrase]["max"])
		if count < min_count:
			failures.append("Shrububu phrase '%s' appears %d times; expected at least %d" % [phrase, count, min_count])
		if count > max_count:
			failures.append("Shrububu phrase '%s' appears %d times; expected no more than %d" % [phrase, count, max_count])


func _check_clue_journal(failures: Array[String]) -> void:
	var clues := _load_dict("res://data/clues/clues.json", failures)
	for clue_id in clues.keys():
		var clue: Dictionary = clues[clue_id]
		var journal_text := str(clue.get("journal_text", ""))
		if journal_text.length() < 80:
			failures.append("clue %s needs journal_text with story prose" % clue_id)


func _check_item_flavor_text(failures: Array[String]) -> void:
	var items := _load_dict("res://data/items/items.json", failures)
	for item_id in items.keys():
		var item: Dictionary = items[item_id]
		if str(item.get("flavor_text", "")).length() < 30:
			failures.append("item %s needs flavor_text" % item_id)


func _to_string_array(value) -> Array[String]:
	var output: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return output
	for entry in value:
		output.append(str(entry))
	return output


func _load_dict(path: String, failures: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(path):
		failures.append("missing data file %s" % path)
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		failures.append("%s must parse as a dictionary" % path)
		return {}
	return data
