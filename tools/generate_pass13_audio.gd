extends SceneTree

const SAMPLE_RATE := 22050

const MUSIC_SPECS := [
	{"id": "level_01_rainy_harbor_noir", "freq": 146.83, "accent": 220.0, "seconds": 2.4, "description": "Rainy harbour noir loop for Divorcee Harbour."},
	{"id": "level_02_uncanny_suburb_jingle", "freq": 196.0, "accent": 392.0, "seconds": 2.0, "description": "Too-happy suburb jingle loop for Banana-burbs."},
	{"id": "level_03_forest_mystery", "freq": 174.61, "accent": 261.63, "seconds": 2.6, "description": "Misty forest mystery loop for Berry Barks."},
	{"id": "level_04_hospital_festival_synth", "freq": 233.08, "accent": 466.16, "seconds": 2.2, "description": "Hospital-to-festival synth loop for Auticity."},
	{"id": "level_05_ruined_club_court_finale", "freq": 110.0, "accent": 329.63, "seconds": 2.4, "description": "Ruined club and final court loop for Area 111."}
]

const SFX_SPECS := [
	{"id": "door_slam", "freq": 70.0, "seconds": 0.22, "shape": "thud", "description": "Heavy door slam cue."},
	{"id": "building_break", "freq": 55.0, "seconds": 0.45, "shape": "noise", "description": "Building collapse crunch cue."},
	{"id": "revolver", "freq": 900.0, "seconds": 0.12, "shape": "snap", "description": "Poojan revolver shot cue."},
	{"id": "banana_gun", "freq": 520.0, "seconds": 0.18, "shape": "arc", "description": "Banana gun curved shot cue."},
	{"id": "berry_potion", "freq": 660.0, "seconds": 0.28, "shape": "bubble", "description": "Berry potion splash/heal cue."},
	{"id": "guitar_note", "freq": 784.0, "seconds": 0.24, "shape": "pluck", "description": "Musical guitar note cue."},
	{"id": "boss_hurt", "freq": 180.0, "seconds": 0.2, "shape": "hurt", "description": "Boss hurt impact cue."},
	{"id": "boss_defeat", "freq": 130.0, "seconds": 0.55, "shape": "fall", "description": "Boss defeat collapse cue."},
	{"id": "clue_pickup", "freq": 880.0, "seconds": 0.18, "shape": "spark", "description": "Clue pickup cue."},
	{"id": "growth_transform", "freq": 247.0, "seconds": 0.65, "shape": "rise", "description": "Shrububu growth transformation cue."},
	{"id": "battle_phase", "freq": 330.0, "seconds": 0.2, "shape": "pulse", "description": "Battle phase change cue."},
	{"id": "transition_wipe", "freq": 210.0, "seconds": 0.3, "shape": "wipe", "description": "Scene transition wipe cue."}
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/shared/audio/music/"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/shared/audio/sfx/"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://data/audio/"))
	var catalog := {}
	for spec in MUSIC_SPECS:
		var id := str(spec["id"])
		var path := "res://assets/shared/audio/music/%s.wav" % id
		_write_music(path, float(spec["freq"]), float(spec["accent"]), float(spec["seconds"]))
		catalog[id] = {
			"type": "music",
			"path": path,
			"loop": true,
			"description": spec["description"]
		}
	for spec in SFX_SPECS:
		var id := str(spec["id"])
		var path := "res://assets/shared/audio/sfx/%s.wav" % id
		_write_sfx(path, float(spec["freq"]), float(spec["seconds"]), str(spec["shape"]))
		catalog[id] = {
			"type": "sfx",
			"path": path,
			"loop": false,
			"description": spec["description"]
		}
	var file := FileAccess.open("res://data/audio/audio_catalog.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(catalog, "\t"))
	print("Generated Pass 13 audio assets")
	quit(0)


func _write_music(path: String, freq: float, accent: float, seconds: float) -> void:
	var sample_count := int(SAMPLE_RATE * seconds)
	var samples: Array[float] = []
	for index in range(sample_count):
		var t := float(index) / float(SAMPLE_RATE)
		var beat := 0.35 + 0.65 * _pulse(t, 0.5)
		var rain := _noise(index) * 0.025
		var value := sin(TAU * freq * t) * 0.18 + sin(TAU * accent * t) * 0.06
		samples.append((value * beat + rain) * 0.55)
	_write_wav(path, samples)


func _write_sfx(path: String, freq: float, seconds: float, shape: String) -> void:
	var sample_count := int(SAMPLE_RATE * seconds)
	var samples: Array[float] = []
	for index in range(sample_count):
		var t := float(index) / float(SAMPLE_RATE)
		var progress := float(index) / float(maxi(1, sample_count - 1))
		var env := 1.0 - progress
		var value := 0.0
		match shape:
			"noise":
				value = _noise(index) * env + sin(TAU * freq * t) * env * 0.4
			"snap":
				value = sin(TAU * freq * t) * pow(env, 3.0)
			"arc":
				value = sin(TAU * (freq + 120.0 * progress) * t) * env
			"bubble":
				value = sin(TAU * (freq + sin(progress * TAU * 4.0) * 80.0) * t) * env * _pulse(t, 0.055)
			"pluck":
				value = (sin(TAU * freq * t) + sin(TAU * freq * 1.5 * t) * 0.35) * pow(env, 1.8)
			"hurt":
				value = sin(TAU * (freq - 80.0 * progress) * t) * env + _noise(index) * env * 0.2
			"fall":
				value = sin(TAU * (freq * (1.0 - progress * 0.6)) * t) * env + _noise(index) * env * 0.1
			"spark":
				value = sin(TAU * freq * t) * env + sin(TAU * freq * 1.5 * t) * env * 0.5
			"rise":
				value = sin(TAU * (freq + progress * 520.0) * t) * (0.2 + progress * 0.8) * env
			"pulse":
				value = sin(TAU * freq * t) * env * _pulse(t, 0.07)
			"wipe":
				value = sin(TAU * (freq + progress * 140.0) * t) * env + _noise(index) * env * 0.12
			_:
				value = sin(TAU * freq * t) * env
		samples.append(value * 0.65)
	_write_wav(path, samples)


func _write_wav(path: String, samples: Array[float]) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	var data_size := samples.size() * 2
	_write_ascii(file, "RIFF")
	file.store_32(36 + data_size)
	_write_ascii(file, "WAVE")
	_write_ascii(file, "fmt ")
	file.store_32(16)
	file.store_16(1)
	file.store_16(1)
	file.store_32(SAMPLE_RATE)
	file.store_32(SAMPLE_RATE * 2)
	file.store_16(2)
	file.store_16(16)
	_write_ascii(file, "data")
	file.store_32(data_size)
	for sample in samples:
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		if value < 0:
			value = 65536 + value
		file.store_16(value)


func _write_ascii(file: FileAccess, text: String) -> void:
	for index in range(text.length()):
		file.store_8(text.unicode_at(index))


func _pulse(t: float, period: float) -> float:
	return 1.0 if fmod(t, period) < period * 0.5 else 0.35


func _noise(seed: int) -> float:
	var value := int((seed * 1103515245 + 12345) & 0x7fffffff)
	return float(value % 2000) / 1000.0 - 1.0
