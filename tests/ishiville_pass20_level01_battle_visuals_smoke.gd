extends SceneTree

const BATTLE_SCENE := "res://scenes/battle/battle_scene.tscn"

const REQUIRED_BATTLE_ART := {
	"res://assets/level_01/sprites/battle_bg_divorcee_harbour.png": Vector2i(320, 180),
	"res://assets/level_01/sprites/battle_poojan_strength_test.png": Vector2i(72, 72),
	"res://assets/level_01/sprites/battle_satyaki_tirumal.png": Vector2i(88, 80),
	"res://assets/level_01/sprites/bullet_badge_warning.png": Vector2i(16, 16),
	"res://assets/level_01/sprites/bullet_legal_paper.png": Vector2i(18, 16),
	"res://assets/level_01/sprites/bullet_broken_ring.png": Vector2i(16, 16)
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_battle_art_files(failures)
	_check_battle_scene_nodes(failures)
	_check_battle_manager_visual_api(failures)
	_check_readme(failures)

	if failures.is_empty():
		print("PASS: Ishiville Pass 20 Level 1 battle visuals smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_battle_art_files(failures: Array[String]) -> void:
	for path in REQUIRED_BATTLE_ART.keys():
		var min_size: Vector2i = REQUIRED_BATTLE_ART[path]
		if not FileAccess.file_exists(path):
			failures.append("Missing battle art %s" % path)
			continue
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if image == null or image.is_empty():
			failures.append("Battle art failed to load %s" % path)
			continue
		if image.get_width() < min_size.x or image.get_height() < min_size.y:
			failures.append("%s too small: got %sx%s expected at least %sx%s" % [path, image.get_width(), image.get_height(), min_size.x, min_size.y])


func _check_battle_scene_nodes(failures: Array[String]) -> void:
	var scene := load(BATTLE_SCENE)
	if scene == null:
		failures.append("Battle scene failed to load")
		return
	var battle: Node = scene.instantiate()
	for node_path in [
		"BattleBackplate",
		"EnemySprite",
		"BattleReadabilityLayer/BulletLegend"
	]:
		if battle.get_node_or_null(node_path) == null:
			failures.append("Battle scene missing %s" % node_path)
	var placeholder := battle.get_node_or_null("EnemyPlaceholder") as CanvasItem
	if placeholder == null:
		failures.append("Battle scene missing EnemyPlaceholder")
	elif placeholder.visible:
		failures.append("EnemyPlaceholder should be hidden after boss sprite replacement")
	var enemy_sprite := battle.get_node_or_null("EnemySprite") as Sprite2D
	if enemy_sprite != null and enemy_sprite.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		failures.append("EnemySprite must use nearest filtering")
	battle.free()


func _check_battle_manager_visual_api(failures: Array[String]) -> void:
	var scene := load(BATTLE_SCENE)
	if scene == null:
		return
	var battle: Node = scene.instantiate()
	for method_name in [
		"get_enemy_visual_path",
		"get_battle_backplate_path",
		"get_bullet_legend_text",
		"apply_encounter_visuals"
	]:
		if not battle.has_method(method_name):
			failures.append("BattleManager missing %s" % method_name)
	if battle.has_method("get_enemy_visual_path"):
		var poojan_path := str(battle.get_enemy_visual_path("poojan_strength_test"))
		var satyaki_path := str(battle.get_enemy_visual_path("satyaki_tirumal_boss"))
		if not poojan_path.ends_with("battle_poojan_strength_test.png"):
			failures.append("Poojan visual path incorrect: %s" % poojan_path)
		if not satyaki_path.ends_with("battle_satyaki_tirumal.png"):
			failures.append("Satyaki visual path incorrect: %s" % satyaki_path)
	if battle.has_method("get_bullet_legend_text"):
		var legend := str(battle.get_bullet_legend_text("satyaki_tirumal_boss"))
		if not legend.contains("legal papers") or not legend.contains("rings"):
			failures.append("Satyaki bullet legend should mention legal papers and rings")
	battle.free()


func _check_readme(failures: Array[String]) -> void:
	var readme := FileAccess.get_file_as_string("res://README.md")
	for required_text in [
		"Pass 20 Level 1 boss battle visual replacement",
		"Poojan battle sprite",
		"Satyaki battle sprite",
		"thematic bullet visuals"
	]:
		if not readme.contains(required_text):
			failures.append("README missing Pass 20 note: %s" % required_text)
