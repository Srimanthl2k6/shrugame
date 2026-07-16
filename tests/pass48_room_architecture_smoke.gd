extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert(int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)) == 640, "Internal width must be 640")
	_assert(int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)) == 360, "Internal height must be 360")
	_assert(int(ProjectSettings.get_setting("display/window/size/min_width", 0)) == 960, "Minimum window width must be 960")
	_assert(int(ProjectSettings.get_setting("display/window/size/min_height", 0)) == 540, "Minimum window height must be 540")

	var fixture := load("res://tests/fixtures/technical_district.tscn") as PackedScene
	_assert(fixture != null, "Technical district fixture must load")
	var district = fixture.instantiate()
	root.add_child(district)
	await process_frame
	_assert(str(district.get_current_room_id()) == "technical_a", "District must open its start room")
	var player := district.get_node_or_null("Player") as CharacterBody2D
	_assert(player != null, "District must preserve a persistent player")
	_assert(player.global_position.distance_to(Vector2(96, 180)) < 1.0, "Start spawn must be applied")
	_assert(district.request_room_change("technical_b", "from_a"), "Room change request must succeed")
	await process_frame
	_assert(str(district.get_current_room_id()) == "technical_b", "District must switch rooms")
	_assert(player.global_position.distance_to(Vector2(72, 180)) < 1.0, "Target spawn must be applied")
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	_assert(camera != null and camera.limit_right == 640 and camera.limit_bottom == 360, "Room must configure camera limits")

	var game_state := root.get_node_or_null("GameState")
	_assert(game_state != null and str(game_state.current_room_id) == "technical_b", "Room identity must persist in GameState")
	_test_legacy_save_migration()
	_test_controller_bindings()

	district.queue_free()
	if failures.is_empty():
		print("PASS: Pass 48 640x360 room architecture, spawn persistence, camera limits, and save migration")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _test_legacy_save_migration() -> void:
	var save_system := root.get_node_or_null("SaveSystem")
	if save_system == null:
		failures.append("SaveSystem autoload must exist")
		return
	var original_save: String = save_system.save_path
	var original_backup: String = save_system.backup_path
	var original_temporary: String = save_system.temporary_path
	save_system.save_path = "user://pass48_legacy_save.json"
	save_system.backup_path = "user://pass48_legacy_save.backup.json"
	save_system.temporary_path = "user://pass48_legacy_save.tmp.json"
	save_system.clear_save()
	var file := FileAccess.open(save_system.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"level_id": "level_02", "spawn_point": "start", "story_flags": {}}))
	file = null
	var migrated: Dictionary = save_system.load_game()
	_assert(int(migrated.get("schema_version", 0)) == 4, "Legacy save must migrate to schema 4")
	_assert(str(migrated.get("room_id", "")) == "suburb", "Legacy Level 2 save must recover to its default room")
	save_system.clear_save()
	save_system.save_path = original_save
	save_system.backup_path = original_backup
	save_system.temporary_path = original_temporary


func _test_controller_bindings() -> void:
	var has_controller_interact := false
	for event in InputMap.action_get_events("interact"):
		if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_A:
			has_controller_interact = true
	_assert(has_controller_interact, "Interact must include the controller A button")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
