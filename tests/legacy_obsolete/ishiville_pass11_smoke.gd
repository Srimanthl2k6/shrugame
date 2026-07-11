extends SceneTree

const SHRUBUBU_FORMS := {
	"form_01": "attack_unarmed.png",
	"form_02": "attack_revolver.png",
	"form_03": "attack_banana_gun.png",
	"form_04": "attack_berry_potions.png",
	"form_05": "attack_musical_guitar.png"
}

const BOSS_SPECS := [
	{"level": "level_01", "bosses": ["poojan", "satyaki_tirumal"]},
	{"level": "level_02", "bosses": ["nitin", "deepak_reddy"]},
	{"level": "level_03", "bosses": ["niggesh_nishal", "ankit"]},
	{"level": "level_04", "bosses": ["doctor_sushan", "mitta"]},
	{"level": "level_05", "bosses": ["suhas", "srmt"]}
]

const BOSS_ANIMS := ["intro", "idle", "talk", "attack", "hurt", "defeat"]

const LEVEL_FX := {
	"level_01": {"scene": "res://scenes/levels/level_01.tscn", "nodes": ["RainLoop", "NeonFlicker", "PaperFlutter"], "files": ["fx_rain_loop.png", "fx_neon_flicker.png", "fx_paper_flutter.png"]},
	"level_02": {"scene": "res://scenes/levels/level_02.tscn", "nodes": ["MonkeyLoop", "LabMonitorPulse"], "files": ["fx_monkey_loop.png", "fx_lab_monitor_pulse.png"]},
	"level_03": {"scene": "res://scenes/levels/level_03.tscn", "nodes": ["MistDrift", "BerryGlow"], "files": ["fx_mist_drift.png", "fx_berry_glow.png"]},
	"level_04": {"scene": "res://scenes/levels/level_04.tscn", "nodes": ["FluorescentBuzz", "AeonFireworks"], "files": ["fx_fluorescent_buzz.png", "fx_aeon_fireworks.png"]},
	"level_05": {"scene": "res://scenes/levels/level_05.tscn", "nodes": ["ClubStatic", "MusicalNotes", "ThroneReveal"], "files": ["fx_club_static.png", "fx_musical_notes.png", "fx_throne_reveal.png"]}
}

const CUTIN_FILES := [
	"door_slam.png",
	"weapon_unlocks.png",
	"boss_intro.png",
	"growth_transform.png",
	"srmt_throne_reveal.png",
	"ishiyoga_rescue.png"
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_animation_catalog(failures)
	_check_shrububu_art(failures)
	_check_boss_art(failures)
	_check_environment_fx_assets(failures)
	_check_animation_scripts(failures)
	_check_scene_fx_layers(failures)
	_check_player_growth_wiring(failures)
	_check_battle_cut_in_wiring(failures)

	if failures.is_empty():
		print("PASS: Ishiville Pass 11 smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_animation_catalog(failures: Array[String]) -> void:
	var catalog := _load_dict("res://data/art/animation_catalog.json", failures)
	if catalog.is_empty():
		return
	for key in ["shrububu_forms", "bosses", "environment_fx", "cutins"]:
		if not catalog.has(key):
			failures.append("animation_catalog missing %s" % key)
	if Array(catalog.get("shrububu_forms", [])).size() < 5:
		failures.append("animation_catalog needs 5 Shrububu forms")
	if Array(catalog.get("bosses", [])).size() < 10:
		failures.append("animation_catalog needs 10 boss entries")
	if Array(catalog.get("environment_fx", [])).size() < 11:
		failures.append("animation_catalog needs level environmental FX entries")
	if Array(catalog.get("cutins", [])).size() < 6:
		failures.append("animation_catalog needs major cut-in entries")


func _check_shrububu_art(failures: Array[String]) -> void:
	for form_id in SHRUBUBU_FORMS.keys():
		var base := "res://assets/shared/sprites/shrububu/%s/" % form_id
		for file_name in ["idle_down.png", "walk_down.png", "walk_up.png", "walk_left.png", "walk_right.png", "battle_idle.png", "hurt.png", "victory.png", SHRUBUBU_FORMS[form_id]]:
			_check_png(base + file_name, 16, 18, failures)


func _check_boss_art(failures: Array[String]) -> void:
	for spec in BOSS_SPECS:
		for boss_id in spec["bosses"]:
			for anim_id in BOSS_ANIMS:
				var path := "res://assets/%s/sprites/boss_%s_%s.png" % [spec["level"], boss_id, anim_id]
				_check_png(path, 24, 24, failures)


func _check_environment_fx_assets(failures: Array[String]) -> void:
	for level_id in LEVEL_FX.keys():
		for file_name in LEVEL_FX[level_id]["files"]:
			_check_png("res://assets/%s/sprites/%s" % [level_id, file_name], 16, 16, failures)
	for file_name in CUTIN_FILES:
		_check_png("res://assets/shared/sprites/cutins/%s" % file_name, 64, 32, failures)


func _check_animation_scripts(failures: Array[String]) -> void:
	var fx_script := load("res://scripts/visual/animated_fx.gd")
	if fx_script == null:
		failures.append("Missing AnimatedFx script")
		return
	var fx: Node = fx_script.new()
	if not fx.has_method("get_animation_metadata"):
		failures.append("AnimatedFx script missing get_animation_metadata")
	if not fx.has_method("set_fx"):
		failures.append("AnimatedFx script missing set_fx")
	fx.free()

	var cutin: Control = load("res://scenes/ui/cutins/cut_in_player.tscn").instantiate()
	if not cutin.has_method("play_cut_in"):
		failures.append("Cut-in player scene missing play_cut_in")
	if cutin.get("safe_size") != Vector2(320, 80):
		failures.append("Cut-in player safe_size must be 320x80")
	cutin.free()


func _check_scene_fx_layers(failures: Array[String]) -> void:
	for level_id in LEVEL_FX.keys():
		var scene := load(LEVEL_FX[level_id]["scene"])
		if scene == null:
			failures.append("%s scene failed to load for FX check" % level_id)
			continue
		var level: Node = scene.instantiate()
		for fx_node_name in LEVEL_FX[level_id]["nodes"]:
			var fx_node: Node = level.get_node_or_null("VisualFxLayer/%s" % fx_node_name)
			if fx_node == null:
				failures.append("%s missing VisualFxLayer/%s" % [level_id, fx_node_name])
			elif not fx_node.has_method("get_animation_metadata"):
				failures.append("%s FX node %s missing animation metadata method" % [level_id, fx_node_name])
		level.free()


func _check_player_growth_wiring(failures: Array[String]) -> void:
	var player_scene := load("res://scenes/overworld/player.tscn")
	var player: Node = player_scene.instantiate()
	if not player.has_method("apply_growth_visual"):
		failures.append("Player controller missing apply_growth_visual")
	if not player.has_method("get_growth_sprite_path"):
		failures.append("Player controller missing get_growth_sprite_path")
	else:
		var path: String = player.get_growth_sprite_path(5)
		if not path.contains("form_05"):
			failures.append("Player growth sprite path for stage 5 must use form_05")
	player.free()


func _check_battle_cut_in_wiring(failures: Array[String]) -> void:
	var battle_scene := load("res://scenes/battle/battle_scene.tscn")
	var battle: Node = battle_scene.instantiate()
	var cutin := battle.get_node_or_null("HudLayer/BossCutIn")
	if cutin == null:
		failures.append("Battle scene missing HudLayer/BossCutIn")
	elif not cutin.has_method("play_cut_in"):
		failures.append("Battle BossCutIn missing play_cut_in")
	if not battle.has_method("get_last_cut_in_id"):
		failures.append("BattleManager missing get_last_cut_in_id")
	battle.free()


func _check_png(path: String, min_width: int, min_height: int, failures: Array[String]) -> void:
	if not FileAccess.file_exists(path):
		failures.append("Missing PNG %s" % path)
		return
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		failures.append("PNG failed to load %s" % path)
		return
	if image.get_width() < min_width or image.get_height() < min_height:
		failures.append("PNG too small %s" % path)


func _load_dict(path: String, failures: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(path):
		failures.append("missing data file %s" % path)
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		failures.append("%s must parse as a dictionary" % path)
		return {}
	return data
