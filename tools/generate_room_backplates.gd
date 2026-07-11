extends SceneTree

const DISTRICTS := {
	"level_01": {
		"source": "res://assets/level_01/backgrounds/divorcee_harbour_intact_master.png",
		"rooms": ["arrival", "harbour_square", "residences_docks", "records_alley", "satyaki_waterfront"]
	},
	"level_02": {
		"source": "res://assets/level_02/backgrounds/banana_burbs_master.png",
		"rooms": ["suburb", "monkey_plaza", "lab_approach", "laboratory", "mayor_complex"]
	},
	"level_03": {
		"source": "res://assets/level_03/backgrounds/berry_barks_master.png",
		"rooms": ["forest_entrance", "berry_paths", "chef_hut", "sharing_clearing", "ankit_gate"]
	},
	"level_04": {
		"source": "res://assets/level_04/backgrounds/auticity_master.png",
		"rooms": ["pun_street", "hospital_reception", "serum_ward", "festival_plaza", "mayor_stage"]
	},
	"level_05": {
		"source": "res://assets/level_05/backgrounds/area_111_master.png",
		"rooms": ["ruined_boulevard", "gummies_pub", "hooligan_alley", "bike_route", "mansion_foyer", "clue_chambers", "ruined_court"]
	}
}

const TARGET_SIZE := Vector2i(640, 360)
const CROP_SIZE := Vector2i(1080, 608)

const CROP_POSITIONS := [
	Vector2i(0, 0),
	Vector2i(296, 0),
	Vector2i(592, 0),
	Vector2i(0, 166),
	Vector2i(296, 166),
	Vector2i(0, 333),
	Vector2i(592, 333)
]

const CUSTOM_ROOM_SOURCES := {
	"level_01/arrival": "res://source_art/level_01_arrival_room_v2.png",
	"level_02/laboratory": "res://source_art/level_02_laboratory_room_v2.png",
	"level_04/serum_ward": "res://source_art/level_04_serum_ward_room_v2.png",
	"level_05/gummies_pub": "res://source_art/level_05_gummies_pub_room_v2.png",
	"level_05/clue_chambers": "res://source_art/level_05_clue_chambers_room_v2.png"
}


func _init() -> void:
	call_deferred("_generate")


func _generate() -> void:
	var written := 0
	for level_id in DISTRICTS:
		var definition: Dictionary = DISTRICTS[level_id]
		var source := Image.load_from_file(ProjectSettings.globalize_path(str(definition["source"])))
		if source == null or source.is_empty():
			push_error("Missing room source for %s" % level_id)
			quit(1)
			return
		var rooms: Array = definition["rooms"]
		for index in range(rooms.size()):
			var room_name := str(rooms[index])
			var custom_key := "%s/%s" % [level_id, room_name]
			var room_image: Image
			if CUSTOM_ROOM_SOURCES.has(custom_key):
				room_image = Image.load_from_file(ProjectSettings.globalize_path(str(CUSTOM_ROOM_SOURCES[custom_key])))
				if room_image == null or room_image.is_empty():
					push_error("Missing custom room source: %s" % CUSTOM_ROOM_SOURCES[custom_key])
					quit(1)
					return
			else:
				var position: Vector2i = CROP_POSITIONS[index]
				position.x = mini(position.x, source.get_width() - CROP_SIZE.x)
				position.y = mini(position.y, source.get_height() - CROP_SIZE.y)
				room_image = source.get_region(Rect2i(position, CROP_SIZE))
			room_image.resize(TARGET_SIZE.x, TARGET_SIZE.y, Image.INTERPOLATE_LANCZOS)
			_apply_room_grade(room_image, index, level_id)
			var path := "res://assets/%s/backgrounds/rooms/%s.png" % [level_id, room_name]
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
			if room_image.save_png(ProjectSettings.globalize_path(path)) != OK:
				push_error("Could not save room backplate: %s" % path)
				quit(1)
				return
			written += 1
	print("PASS: generated %d native 640x360 district room backplates" % written)
	quit(0)


func _apply_room_grade(image: Image, room_index: int, level_id: String) -> void:
	var brightness: float = float([0.9, 1.02, 0.82, 0.94, 0.78, 0.86, 0.72][room_index])
	var accent: Color = {
		"level_01": Color(0.82, 0.94, 1.08),
		"level_02": Color(1.06, 1.02, 0.82),
		"level_03": Color(0.88, 1.02, 0.9),
		"level_04": Color(0.86, 1.02, 1.08),
		"level_05": Color(1.08, 0.84, 1.04)
	}.get(level_id, Color.WHITE)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			color.r = clampf(color.r * brightness * accent.r, 0.0, 1.0)
			color.g = clampf(color.g * brightness * accent.g, 0.0, 1.0)
			color.b = clampf(color.b * brightness * accent.b, 0.0, 1.0)
			image.set_pixel(x, y, color)
