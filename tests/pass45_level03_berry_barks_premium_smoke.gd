extends SceneTree

const REQUIRED_IMAGES := {
	"res://assets/level_03/sprites/npc_fir_grandmother_idle.png": Vector2i(34, 50),
	"res://assets/level_03/sprites/npc_berry_picker_idle.png": Vector2i(32, 46),
	"res://assets/level_03/sprites/npc_mist_ranger_idle.png": Vector2i(34, 50),
	"res://assets/level_03/sprites/npc_berry_apothecary_idle.png": Vector2i(34, 50),
	"res://assets/level_03/sprites/boss_niggesh_nishal_overworld.png": Vector2i(40, 56),
	"res://assets/level_03/sprites/boss_ankit_overworld.png": Vector2i(42, 58),
	"res://assets/level_03/sprites/prop_berry_cluster.png": Vector2i(34, 42),
	"res://assets/level_03/sprites/prop_berry_contract.png": Vector2i(32, 36),
	"res://assets/level_03/sprites/prop_berry_share_table.png": Vector2i(58, 42),
	"res://assets/level_03/sprites/prop_berry_watch_save.png": Vector2i(30, 42),
	"res://assets/level_03/sprites/prop_auticity_exit_arch.png": Vector2i(46, 54)
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	for path in REQUIRED_IMAGES.keys():
		_check_image(path, REQUIRED_IMAGES[path], failures)
	_check_scene(failures)
	_check_cutscenes(failures)
	_check_bosses(failures)
	_finish(failures)


func _check_image(path: String, expected: Vector2i, failures: Array[String]) -> void:
	if not FileAccess.file_exists(path):
		failures.append("Missing Berry Barks premium image: %s" % path)
		return
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty() or image.get_size() != expected:
		failures.append("Invalid Berry Barks image dimensions: %s" % path)


func _check_scene(failures: Array[String]) -> void:
	var packed := load("res://scenes/levels/level_03.tscn") as PackedScene
	if packed == null:
		failures.append("Berry Barks scene failed to load")
		return
	var level := packed.instantiate()
	var cluster_paths := ["World/BerryClusters", "World/BerryCluster02", "World/BerryCluster03", "World/BerryCluster04"]
	for index in range(cluster_paths.size()):
		var cluster := level.get_node_or_null(cluster_paths[index])
		if cluster == null:
			failures.append("Missing 250-berry cluster: %s" % cluster_paths[index])
			continue
		if int(cluster.get("item_amount")) != 250:
			failures.append("%s must award 250 berries" % cluster_paths[index])
		if str(cluster.get("flag_on_interact")) != "berry_cluster_%02d" % (index + 1):
			failures.append("%s has the wrong one-shot flag" % cluster_paths[index])
	for npc_path in ["World/FirGrandmother", "World/BerryPicker", "World/MistRanger", "World/BerryApothecary", "World/BarkChoir"]:
		if level.get_node_or_null(npc_path) == null:
			failures.append("Berry Barks needs authored NPC: %s" % npc_path)
	for legacy_path in ["World/Tickroot", "World/Objective", "World/PracticeEncounter"]:
		var legacy := level.get_node_or_null(legacy_path) as CanvasItem
		if legacy != null and legacy.visible:
			failures.append("Legacy Berry Barks prototype node remains visible: %s" % legacy_path)
	var ankit := level.get_node_or_null("World/AnkitBoss") as Area2D
	if ankit == null or str(ankit.get("cutscene_id")) != "ankit_confrontation":
		failures.append("Ankit must enter through the confrontation cutscene")
	level.free()


func _check_cutscenes(failures: Array[String]) -> void:
	var catalog := _load_json("res://data/cutscenes/index.json", failures)
	for id in ["false_chicken_promise", "berry_sharing", "nishal_aftermath", "ankit_confrontation", "ankit_aftermath"]:
		if not catalog.has(id):
			failures.append("Cutscene catalog missing Berry Barks scene: %s" % id)
	var sharing := _load_json("res://data/cutscenes/berry_sharing.json", failures)
	if not _has_step(sharing, "unlock_gear", "berry_potions"):
		failures.append("Berry sharing must unlock berry_potions")
	var ankit_intro := _load_json("res://data/cutscenes/ankit_confrontation.json", failures)
	if not _has_step(ankit_intro, "start_battle", "ankit_boss"):
		failures.append("Ankit confrontation must start ankit_boss")
	var director_source := FileAccess.get_file_as_string("res://scripts/cutscenes/cutscene_director.gd")
	if director_source.count('"start_battle"') < 2:
		failures.append("Cutscene skip state must preserve terminal battle transitions")


func _check_bosses(failures: Array[String]) -> void:
	var encounters := _load_json("res://data/encounters/level_03_encounters.json", failures)
	for encounter_id in ["niggesh_nishal_boss", "ankit_boss"]:
		var encounter: Dictionary = encounters.get(encounter_id, {})
		if (encounter.get("phases", []) as Array).size() < 3:
			failures.append("%s must have three phases" % encounter_id)
		if int(encounter.get("battle_frames", 0)) != 4:
			failures.append("%s must use a four-frame authored visual" % encounter_id)
		if not encounter.has("difficulty_overrides"):
			failures.append("%s lacks Shrububu/SRMT tuning" % encounter_id)


func _has_step(data: Dictionary, step_type: String, id: String) -> bool:
	for raw_step in data.get("steps", []):
		if typeof(raw_step) == TYPE_DICTIONARY and str(raw_step.get("type", "")) == step_type:
			if str(raw_step.get("id", raw_step.get("encounter_id", ""))) == id:
				return true
	return false


func _load_json(path: String, failures: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(path):
		failures.append("Missing JSON file: %s" % path)
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		failures.append("Invalid JSON object: %s" % path)
		return {}
	return parsed


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("PASS: Berry Barks premium cast, props, clustered collection, cutscenes, and bosses")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
