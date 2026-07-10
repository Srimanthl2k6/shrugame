extends SceneTree

const TUNING_PATH := "res://data/tuning/gameplay_tuning.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var tuning := _load_tuning(failures)
	if not tuning.is_empty():
		_check_tuning_ranges(tuning, failures)
		_check_player_tuning(tuning, failures)
		_check_interaction_tuning(tuning, failures)
		_check_battle_tuning(tuning, failures)
		_check_bullet_tuning(tuning, failures)

	if failures.is_empty():
		print("PASS: Pass 9 smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _load_tuning(failures: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(TUNING_PATH):
		failures.append("Missing gameplay tuning file at %s" % TUNING_PATH)
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(TUNING_PATH))
	if typeof(data) != TYPE_DICTIONARY:
		failures.append("Gameplay tuning file must parse as a dictionary")
		return {}
	return data


func _check_tuning_ranges(tuning: Dictionary, failures: Array[String]) -> void:
	var player_speed := float(_get_nested(tuning, ["overworld", "player_speed"], 0.0))
	if player_speed < 65.0 or player_speed > 95.0:
		failures.append("Player speed should stay in a controllable pixel-RPG range")

	var enemy_phase_seconds := float(_get_nested(tuning, ["battle", "enemy_phase_seconds"], 0.0))
	if enemy_phase_seconds < 0.75 or enemy_phase_seconds > 1.5:
		failures.append("Enemy phase duration should stay short enough for prototype pacing")

	var damage := int(_get_nested(tuning, ["battle", "enemy_phase_damage"], 0))
	if damage < 1 or damage > 3:
		failures.append("Enemy phase damage should stay readable for prototype HP totals")

	var bullet_count := int(_get_nested(tuning, ["battle", "bullet_count"], 0))
	if bullet_count < 3 or bullet_count > 5:
		failures.append("Bullet count should stay readable in the 160x96 arena")


func _check_player_tuning(tuning: Dictionary, failures: Array[String]) -> void:
	var scene := load("res://scenes/overworld/player.tscn")
	if scene == null:
		failures.append("Player scene must load")
		return
	var player: Node = scene.instantiate()
	root.add_child(player)
	await process_frame

	var expected_speed := float(_get_nested(tuning, ["overworld", "player_speed"], -1.0))
	if not is_equal_approx(player.get("speed"), expected_speed):
		failures.append("Player speed must apply gameplay tuning")

	var shape_node: CollisionShape2D = player.get_node_or_null("CollisionShape2D")
	var expected_size := _vector2_from_array(_get_nested(tuning, ["overworld", "player_collision_size"], []))
	if shape_node == null or shape_node.shape == null or shape_node.shape.get("size") != expected_size:
		failures.append("Player collision size must apply gameplay tuning")

	var camera: Camera2D = player.get_node_or_null("Camera2D")
	var expected_smoothing := float(_get_nested(tuning, ["overworld", "camera_smoothing_speed"], -1.0))
	if camera == null or not is_equal_approx(camera.position_smoothing_speed, expected_smoothing):
		failures.append("Player camera smoothing must apply gameplay tuning")

	player.free()


func _check_interaction_tuning(tuning: Dictionary, failures: Array[String]) -> void:
	var area: Area2D = load("res://scripts/overworld/interaction_area.gd").new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2.ONE
	collision.shape = shape
	area.add_child(collision)
	root.add_child(area)
	await process_frame

	var expected_size := _vector2_from_array(_get_nested(tuning, ["overworld", "interaction_size"], []))
	if shape.size != expected_size:
		failures.append("Interaction areas must apply gameplay tuning range")

	area.free()


func _check_battle_tuning(tuning: Dictionary, failures: Array[String]) -> void:
	var scene := load("res://scenes/battle/battle_scene.tscn")
	if scene == null:
		failures.append("Battle scene must load")
		return
	var battle: Node = scene.instantiate()
	root.add_child(battle)
	await process_frame

	var expected_seconds := float(_get_nested(tuning, ["battle", "enemy_phase_seconds"], -1.0))
	var expected_damage := int(_get_nested(tuning, ["battle", "enemy_phase_damage"], -1))
	if not is_equal_approx(battle.get("enemy_phase_seconds"), expected_seconds):
		failures.append("BattleManager must apply tuned enemy phase duration")
	if int(battle.get("enemy_phase_damage")) != expected_damage:
		failures.append("BattleManager must apply tuned enemy phase damage")

	battle.free()


func _check_bullet_tuning(tuning: Dictionary, failures: Array[String]) -> void:
	var pattern: Node2D = load("res://scripts/battle/bullet_pattern_base.gd").new()
	root.add_child(pattern)
	pattern.start_pattern()
	await process_frame

	var expected_count := int(_get_nested(tuning, ["battle", "bullet_count"], -1))
	var expected_radius := float(_get_nested(tuning, ["battle", "bullet_radius"], -1.0))
	if pattern.get_child_count() != expected_count:
		failures.append("Bullet pattern must apply tuned bullet count")
	for child in pattern.get_children():
		var collision: CollisionShape2D = child.get_node_or_null("CollisionShape2D")
		if collision == null or collision.shape == null or not is_equal_approx(collision.shape.get("radius"), expected_radius):
			failures.append("Bullet pattern must apply tuned bullet hitbox radius")
			break

	pattern.free()


func _get_nested(data: Dictionary, path: Array, fallback):
	var current = data
	for key in path:
		if typeof(current) != TYPE_DICTIONARY or not current.has(key):
			return fallback
		current = current[key]
	return current


func _vector2_from_array(value) -> Vector2:
	if typeof(value) != TYPE_ARRAY or value.size() < 2:
		return Vector2.ZERO
	return Vector2(float(value[0]), float(value[1]))
