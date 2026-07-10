extends SceneTree

const MUSIC_IDS := [
	"level_01_rainy_harbor_noir",
	"level_02_uncanny_suburb_jingle",
	"level_03_forest_mystery",
	"level_04_hospital_festival_synth",
	"level_05_ruined_club_court_finale"
]

const SFX_IDS := [
	"door_slam",
	"building_break",
	"revolver",
	"banana_gun",
	"berry_potion",
	"guitar_note",
	"boss_hurt",
	"boss_defeat",
	"clue_pickup",
	"growth_transform",
	"battle_phase",
	"transition_wipe"
]

const WEAPON_TO_SFX := {
	"revolver": "revolver",
	"banana_gun": "banana_gun",
	"berry_potions": "berry_potion",
	"musical_guitar": "guitar_note"
}

const LEVEL_SCENES := {
	"level_01": "res://scenes/levels/level_01.tscn",
	"level_02": "res://scenes/levels/level_02.tscn",
	"level_03": "res://scenes/levels/level_03.tscn",
	"level_04": "res://scenes/levels/level_04.tscn",
	"level_05": "res://scenes/levels/level_05.tscn"
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_audio_catalog(failures)
	_check_audio_assets(failures)
	_check_audio_manager(failures)
	_check_battle_audio_and_juice(failures)
	_check_interaction_audio_hooks(failures)
	_check_feedback_scripts_and_scenes(failures)
	_check_level_music_wiring(failures)

	if failures.is_empty():
		print("PASS: Ishiville Pass 13 smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_audio_catalog(failures: Array[String]) -> void:
	var catalog := _load_dict("res://data/audio/audio_catalog.json", failures)
	if catalog.is_empty():
		return
	for id in MUSIC_IDS:
		var entry: Dictionary = catalog.get(id, {})
		if entry.get("type", "") != "music":
			failures.append("audio_catalog missing music id %s" % id)
	for id in SFX_IDS:
		var entry: Dictionary = catalog.get(id, {})
		if entry.get("type", "") != "sfx":
			failures.append("audio_catalog missing sfx id %s" % id)


func _check_audio_assets(failures: Array[String]) -> void:
	for id in MUSIC_IDS:
		_check_wav("res://assets/shared/audio/music/%s.wav" % id, failures)
	for id in SFX_IDS:
		_check_wav("res://assets/shared/audio/sfx/%s.wav" % id, failures)


func _check_audio_manager(failures: Array[String]) -> void:
	var audio_manager: Node = load("res://scripts/core/audio_manager.gd").new()
	for method_name in ["play_music", "stop_music", "play_weapon_sfx", "play_boss_hurt", "play_boss_defeat", "play_clue_pickup", "play_growth_transform", "get_audio_catalog"]:
		if not audio_manager.has_method(method_name):
			failures.append("AudioManager missing %s()" % method_name)
	if audio_manager.has_method("get_audio_catalog"):
		var catalog: Dictionary = audio_manager.get_audio_catalog()
		for id in MUSIC_IDS + SFX_IDS:
			if not catalog.has(id):
				failures.append("AudioManager catalog missing %s" % id)
	if audio_manager.has_method("play_sfx"):
		for id in SFX_IDS:
			if not audio_manager.play_sfx(id):
				failures.append("AudioManager should play known SFX id %s" % id)
	if audio_manager.has_method("play_music"):
		for id in MUSIC_IDS:
			if not audio_manager.play_music(id):
				failures.append("AudioManager should play known music id %s" % id)
	audio_manager.free()


func _check_battle_audio_and_juice(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/battle/battle_manager.gd")
	for weapon_id in WEAPON_TO_SFX.keys():
		if not source.contains(WEAPON_TO_SFX[weapon_id]):
			failures.append("BattleManager missing weapon SFX hook %s" % WEAPON_TO_SFX[weapon_id])
	for required_text in ["play_boss_hurt", "play_boss_defeat", "play_growth_transform", "ScreenShake", "HitFlash", "JuiceParticles"]:
		if not source.contains(required_text):
			failures.append("BattleManager missing juice/audio reference %s" % required_text)
	var battle_scene := load("res://scenes/battle/battle_scene.tscn")
	var battle: Node = battle_scene.instantiate()
	for node_path in ["JuiceLayer/ScreenShake", "JuiceLayer/HitFlash", "JuiceLayer/JuiceParticles", "HudLayer/SceneTransition"]:
		if battle.get_node_or_null(node_path) == null:
			failures.append("Battle scene missing %s" % node_path)
	battle.free()


func _check_interaction_audio_hooks(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/overworld/interaction_area.gd")
	for required_text in ["play_clue_pickup", "play_growth_transform", "door_slam", "building_break", "transition_wipe"]:
		if not source.contains(required_text):
			failures.append("InteractionArea missing audio hook %s" % required_text)


func _check_feedback_scripts_and_scenes(failures: Array[String]) -> void:
	for script_path in [
		"res://scripts/visual/screen_shake.gd",
		"res://scripts/visual/hit_flash.gd",
		"res://scripts/visual/juice_particles.gd",
		"res://scripts/visual/scene_transition.gd"
	]:
		var script := load(script_path)
		if script == null:
			failures.append("Missing feedback script %s" % script_path)
			continue
		var node: Node = script.new()
		if not node.has_method("play"):
			failures.append("%s missing play()" % script_path)
		node.free()
	var transition_scene := load("res://scenes/ui/scene_transition.tscn")
	if transition_scene == null:
		failures.append("Missing scene transition scene")
	else:
		var transition: Node = transition_scene.instantiate()
		if not transition.has_method("play"):
			failures.append("Scene transition scene missing play()")
		transition.free()


func _check_level_music_wiring(failures: Array[String]) -> void:
	for level_id in LEVEL_SCENES.keys():
		var scene := load(LEVEL_SCENES[level_id])
		var level: Node = scene.instantiate()
		var music_trigger := level.get_node_or_null("MusicTrigger")
		if music_trigger == null:
			failures.append("%s missing MusicTrigger" % level_id)
		elif not str(music_trigger.get("music_id")).begins_with(level_id):
			failures.append("%s MusicTrigger has wrong music_id" % level_id)
		level.free()


func _check_wav(path: String, failures: Array[String]) -> void:
	if not FileAccess.file_exists(path):
		failures.append("Missing WAV %s" % path)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() < 48:
		failures.append("Invalid WAV %s" % path)
		return
	var header := file.get_buffer(12)
	if header.size() < 12 or header.slice(0, 4).get_string_from_ascii() != "RIFF" or header.slice(8, 12).get_string_from_ascii() != "WAVE":
		failures.append("WAV header invalid %s" % path)


func _load_dict(path: String, failures: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(path):
		failures.append("missing data file %s" % path)
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		failures.append("%s must parse as a dictionary" % path)
		return {}
	return data
