extends SceneTree

func _init() -> void:
	var failures: Array[String] = []

	var main_scene := load("res://scenes/main.tscn")
	if main_scene == null:
		failures.append("scenes/main.tscn did not load")
	else:
		var main: Node = main_scene.instantiate()
		var level: Node = main.get_node_or_null("Level01")
		if level == null:
			failures.append("Main scene does not instance Level01")
		main.queue_free()

	var level_scene := load("res://scenes/levels/level_01.tscn")
	if level_scene == null:
		failures.append("scenes/levels/level_01.tscn did not load")
	else:
		var level: Node = level_scene.instantiate()
		_require_node(level, "World/Bounds", failures)
		_require_node(level, "World/Player", failures)
		_require_node(level, "World/NoticeSign", failures)
		_require_node(level, "World/TransitionDoor", failures)

		var player: Node = level.get_node_or_null("World/Player")
		if player == null:
			failures.append("Player instance is missing from Level01")
		else:
			_require_node(player, "CollisionShape2D", failures)
			_require_node(player, "Camera2D", failures)
			_require_node(player, "Sprite", failures)
			if player.get_script() == null:
				failures.append("Player has no controller script")

		level.queue_free()

	if failures.is_empty():
		print("PASS: Pass 2 smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _require_node(root: Node, path: NodePath, failures: Array[String]) -> void:
	if root.get_node_or_null(path) == null:
		failures.append("Missing node: %s" % path)
