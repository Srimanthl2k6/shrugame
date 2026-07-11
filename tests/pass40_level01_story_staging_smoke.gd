extends SceneTree


func _init() -> void:
	var dialogue = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue/level_01_dialogue.json"))
	_assert(typeof(dialogue) == TYPE_DICTIONARY, "Level 1 dialogue must parse")
	for dialogue_id in [
		"divorcee_lantern_woman",
		"divorcee_boathouse_woman",
		"divorcee_raincoat_woman",
		"divorcee_radio_woman",
		"divorcee_dock_woman_intro",
		"poojan_intro",
		"poojan_after",
		"satyaki_intro",
		"satyaki_defeat"
	]:
		_assert(dialogue.has(dialogue_id), "Missing authored dialogue: %s" % dialogue_id)

	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/cutscenes/index.json"))
	_assert(catalog.has("poojan_challenge") and catalog.has("poojan_aftermath"), "Poojan must have intro and aftermath cutscenes")
	_assert(catalog.has("satyaki_reveal") and catalog.has("satyaki_aftermath"), "Satyaki must have intro and aftermath cutscenes")

	var level_scene := load("res://scenes/levels/level_01.tscn") as PackedScene
	var level := level_scene.instantiate()
	for npc_name in ["HarbourResident", "LanternWoman", "BoathouseWoman", "RaincoatWoman", "RadioWoman", "DockWoman"]:
		var npc := level.get_node_or_null("World/%s" % npc_name)
		_assert(npc != null, "Level 1 must stage NPC %s" % npc_name)
		var sprite := npc.get_node_or_null("ReadableSprite") as Sprite2D
		_assert(sprite != null and sprite.texture != null, "%s needs authored foreground art" % npc_name)

	_assert(str(level.get_node("World/SheriffPoojan").get("cutscene_id")) == "poojan_challenge", "Poojan interaction must trigger the challenge cutscene")
	_assert(str(level.get_node("World/SatyakiBoss").get("cutscene_id")) == "satyaki_reveal", "Satyaki interaction must trigger the reveal cutscene")
	level.free()
	print("PASS: Level 1 NPC density, dialogue, and boss staging")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
