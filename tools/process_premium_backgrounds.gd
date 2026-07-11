extends SceneTree

const BACKGROUNDS := [
	{
		"source": "res://assets/level_01/backgrounds/divorcee_harbour_master.png",
		"output": "res://assets/level_01/backgrounds/divorcee_harbour_game.png",
		"size": Vector2i(640, 360)
	},
	{
		"source": "res://assets/level_01/backgrounds/divorcee_harbour_intact_master.png",
		"output": "res://assets/level_01/backgrounds/divorcee_harbour_intact_game.png",
		"size": Vector2i(640, 360)
	},
	{
		"source": "res://assets/level_02/backgrounds/banana_burbs_master.png",
		"output": "res://assets/level_02/backgrounds/banana_burbs_game.png",
		"size": Vector2i(640, 360)
	},
	{
		"source": "res://assets/level_03/backgrounds/berry_barks_master.png",
		"output": "res://assets/level_03/backgrounds/berry_barks_game.png",
		"size": Vector2i(640, 360)
	},
	{
		"source": "res://assets/level_04/backgrounds/auticity_master.png",
		"output": "res://assets/level_04/backgrounds/auticity_game.png",
		"size": Vector2i(640, 360)
	},
	{
		"source": "res://assets/level_05/backgrounds/area_111_master.png",
		"output": "res://assets/level_05/backgrounds/area_111_game.png",
		"size": Vector2i(640, 360)
	}
]


func _init() -> void:
	call_deferred("_process_backgrounds")


func _process_backgrounds() -> void:
	var failures: Array[String] = []
	for entry in BACKGROUNDS:
		var source_path := ProjectSettings.globalize_path(str(entry["source"]))
		var image := Image.load_from_file(source_path)
		if image == null or image.is_empty():
			failures.append("Could not load %s" % entry["source"])
			continue
		var target_size: Vector2i = entry["size"]
		image.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
		var error := image.save_png(ProjectSettings.globalize_path(str(entry["output"])))
		if error != OK:
			failures.append("Could not save %s" % entry["output"])
	if failures.is_empty():
		print("PASS: processed premium game backgrounds")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
