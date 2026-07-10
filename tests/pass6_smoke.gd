extends SceneTree

const REQUIRED_FILES := [
	"res://assets/shared/sprites/player_idle.png",
	"res://assets/shared/sprites/player_walk_sheet.png",
	"res://assets/shared/sprites/soul_cursor.png",
	"res://assets/shared/sprites/common_bullet.png",
	"res://assets/shared/sprites/ui_panel.png",
	"res://assets/shared/tilesets/graybox_tiles.png",
	"res://assets/shared/audio/ui_select.wav",
	"res://assets/shared/audio/encounter_start.wav",
	"res://assets/shared/audio/save_chime.wav"
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []

	_check_files(failures)
	_check_player_scene(failures)
	_check_soul_scene(failures)
	_check_bullet_script(failures)
	_check_ui_scenes(failures)
	_check_project_pixel_defaults(failures)

	if failures.is_empty():
		print("PASS: Pass 6 smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_files(failures: Array[String]) -> void:
	for path in REQUIRED_FILES:
		if not FileAccess.file_exists(path):
			failures.append("Missing shared asset: %s" % path)


func _check_player_scene(failures: Array[String]) -> void:
	var scene := load("res://scenes/overworld/player.tscn")
	if scene == null:
		failures.append("player.tscn did not load")
		return
	var player: Node = scene.instantiate()
	var sprite := player.get_node_or_null("Sprite")
	if sprite == null:
		failures.append("Player missing Sprite node")
	elif not sprite is Sprite2D:
		failures.append("Player Sprite must be Sprite2D")
	elif sprite.texture == null or sprite.texture.resource_path != "res://assets/shared/sprites/player_idle.png":
		failures.append("Player Sprite must use shared player_idle.png")
	player.free()


func _check_soul_scene(failures: Array[String]) -> void:
	var scene := load("res://scenes/battle/soul_cursor.tscn")
	if scene == null:
		failures.append("soul_cursor.tscn did not load")
		return
	var soul: Node = scene.instantiate()
	var visual := soul.get_node_or_null("Visual")
	if visual == null:
		failures.append("SoulCursor missing Visual node")
	elif not visual is Sprite2D:
		failures.append("SoulCursor Visual must be Sprite2D")
	elif visual.texture == null or visual.texture.resource_path != "res://assets/shared/sprites/soul_cursor.png":
		failures.append("SoulCursor Visual must use shared soul_cursor.png")
	soul.free()


func _check_bullet_script(failures: Array[String]) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/battle/bullet_pattern_base.gd")
	if not source.contains("res://assets/shared/sprites/common_bullet.png"):
		failures.append("Bullet pattern must reference shared common_bullet.png")


func _check_ui_scenes(failures: Array[String]) -> void:
	for path in ["res://scenes/ui/dialogue_box.tscn", "res://scenes/ui/battle_hud.tscn"]:
		var text := FileAccess.get_file_as_string(path)
		if not text.contains("StyleBoxFlat"):
			failures.append("%s must define shared-style panel resources" % path)


func _check_project_pixel_defaults(failures: Array[String]) -> void:
	if not ProjectSettings.has_setting("rendering/textures/canvas_textures/default_texture_filter"):
		failures.append("Project missing default texture filter setting")
