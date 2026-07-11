extends SceneTree

const LEVEL_PATH := "res://scenes/levels/level_01.tscn"


func _init() -> void:
	var scene := load(LEVEL_PATH) as PackedScene
	_assert(scene != null, "Level 1 scene must load")
	var level := scene.instantiate()
	root.add_child(level)
	await process_frame

	for path in [
		"World/SceneArt/HarbourBackplate",
		"World/HarbourResident/ReadableSprite",
		"World/SheriffPoojan/ReadableSprite",
		"World/SatyakiBoss/ReadableSprite",
		"World/SavePoint/ReadableSprite"
	]:
		var sprite := level.get_node_or_null(path) as Sprite2D
		_assert(sprite != null and sprite.texture != null, "%s must have final art" % path)

	for path in [
		"World/NoticeSign/ReadableSprite",
		"World/SatyakiApproach/ReadableSprite",
		"World/TransitionDoor/ReadableSprite"
	]:
		var obsolete := level.get_node_or_null(path) as CanvasItem
		_assert(obsolete != null and not obsolete.visible, "%s must not expose label-style blockout art" % path)

	var kfc_door := level.get_node_or_null("World/KfcDoor")
	_assert(kfc_door != null and bool(kfc_door.get("one_shot")), "Door slam interaction must be one-shot")
	print("PASS: Level 1 foreground art and interaction cleanup")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
