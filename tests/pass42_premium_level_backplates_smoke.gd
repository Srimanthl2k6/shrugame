extends SceneTree

const LEVELS := {
	"level_02": "res://assets/level_02/backgrounds/banana_burbs_game.png",
	"level_03": "res://assets/level_03/backgrounds/berry_barks_game.png",
	"level_04": "res://assets/level_04/backgrounds/auticity_game.png",
	"level_05": "res://assets/level_05/backgrounds/area_111_game.png"
}


func _init() -> void:
	for level_id in LEVELS.keys():
		var image := Image.load_from_file(ProjectSettings.globalize_path(str(LEVELS[level_id])))
		_assert(image != null and image.get_size() == Vector2i(640, 360), "%s premium background must be 640x360" % level_id)
		var scene := load("res://scenes/levels/%s.tscn" % level_id) as PackedScene
		_assert(scene != null, "%s scene must load" % level_id)
		var level := scene.instantiate()
		var backplate := level.get_node_or_null("World/PremiumBackplate") as Sprite2D
		_assert(backplate != null and backplate.texture != null, "%s must use its premium backplate" % level_id)
		var frame := level.get_node_or_null("World/PlayableFrame") as CanvasItem
		_assert(frame != null and not frame.visible, "%s must not display the old diagnostic frame" % level_id)
		level.free()
	print("PASS: premium environment backplates replace Levels 2-5 blockout worlds")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
