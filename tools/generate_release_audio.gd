extends SceneTree

const SAMPLE_RATE := 22050
const DURATION := 12.0

const TRACKS := [
	{"id": "title_theme", "roots": [146.83, 130.81, 174.61, 123.47], "lead": [293.66, 261.63, 349.23, 246.94], "bpm": 72.0, "noise": 0.035, "description": "Ishiville title theme: rain, mystery, and an unreasonable appetite."},
	{"id": "level_01_rainy_harbor_noir", "roots": [146.83, 174.61, 130.81, 110.0], "lead": [220.0, 261.63, 196.0, 164.81], "bpm": 68.0, "noise": 0.055, "description": "Rainy harbour noir loop for Divorcee Harbour."},
	{"id": "level_02_uncanny_suburb_jingle", "roots": [196.0, 246.94, 220.0, 174.61], "lead": [392.0, 493.88, 440.0, 349.23], "bpm": 104.0, "noise": 0.008, "description": "Too-happy suburb jingle with an unstable municipal pulse."},
	{"id": "level_03_forest_mystery", "roots": [174.61, 146.83, 196.0, 130.81], "lead": [261.63, 220.0, 293.66, 196.0], "bpm": 76.0, "noise": 0.045, "description": "Misty forest mystery loop for Berry Barks."},
	{"id": "level_04_hospital_festival_synth", "roots": [233.08, 196.0, 261.63, 174.61], "lead": [466.16, 392.0, 523.25, 349.23], "bpm": 116.0, "noise": 0.012, "description": "Clinical pulse turning into Aeon Festival synth."},
	{"id": "level_05_ruined_club_court_finale", "roots": [110.0, 130.81, 98.0, 146.83], "lead": [329.63, 392.0, 293.66, 440.0], "bpm": 122.0, "noise": 0.025, "description": "Ruined club and final court loop for Area 111."},
	{"id": "boss_confrontation", "roots": [98.0, 116.54, 87.31, 130.81], "lead": [392.0, 349.23, 466.16, 293.66], "bpm": 138.0, "noise": 0.018, "description": "Ten-boss confrontation theme."},
	{"id": "srmt_finale", "roots": [82.41, 98.0, 73.42, 110.0], "lead": [329.63, 392.0, 293.66, 440.0], "bpm": 154.0, "noise": 0.024, "description": "Five-movement SRMT final battle counterpoint."},
	{"id": "ending_feast", "roots": [174.61, 220.0, 196.0, 261.63], "lead": [349.23, 440.0, 392.0, 523.25], "bpm": 84.0, "noise": 0.012, "description": "IshiYoga rescue and birthday feast theme."}
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog: Dictionary = {}
	var catalog_path := "res://data/audio/audio_catalog.json"
	if FileAccess.file_exists(catalog_path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(catalog_path))
		if typeof(parsed) == TYPE_DICTIONARY:
			catalog = parsed
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/shared/audio/music"))
	for track in TRACKS:
		var id := str(track["id"])
		var path := "res://assets/shared/audio/music/%s.wav" % id
		_write_track(path, track)
		catalog[id] = {"type": "music", "path": path, "loop": true, "description": str(track["description"])}
	var file := FileAccess.open(catalog_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(catalog, "\t"))
	print("PASS: generated %d layered release music tracks" % TRACKS.size())
	quit(0)


func _write_track(path: String, track: Dictionary) -> void:
	var roots: Array = track["roots"]
	var leads: Array = track["lead"]
	var bpm := float(track["bpm"])
	var beat_seconds := 60.0 / bpm
	var sample_count := int(SAMPLE_RATE * DURATION)
	var samples := PackedFloat32Array()
	samples.resize(sample_count)
	for index in range(sample_count):
		var t := float(index) / SAMPLE_RATE
		var beat_index := int(floor(t / beat_seconds))
		var bar_index := int(floor(float(beat_index) / 4.0)) % roots.size()
		var beat_phase := fmod(t, beat_seconds) / beat_seconds
		var root := float(roots[bar_index])
		var lead := float(leads[(beat_index + bar_index) % leads.size()])
		var pad := sin(TAU * root * t) * 0.12 + sin(TAU * root * 1.5 * t) * 0.055
		var bass := sin(TAU * root * 0.5 * t) * 0.16
		var lead_gate := exp(-beat_phase * 5.2)
		var melody := (sin(TAU * lead * t) + sin(TAU * lead * 2.0 * t) * 0.18) * lead_gate * 0.085
		var kick := sin(TAU * (72.0 - beat_phase * 34.0) * t) * exp(-beat_phase * 18.0) * 0.14
		var hat := _noise(index + beat_index * 97) * exp(-fmod(beat_phase * 2.0, 1.0) * 25.0) * 0.025
		var ambience := _noise(index * 3 + 17) * float(track["noise"])
		var pulse := 0.76 + 0.24 * sin(TAU * t / (beat_seconds * 4.0))
		var edge_fade := minf(1.0, minf(t / 0.025, (DURATION - t) / 0.025))
		samples[index] = clampf((pad + bass + melody + kick + hat + ambience) * pulse * edge_fade, -0.92, 0.92)
	_write_wav(path, samples)


func _write_wav(path: String, samples: PackedFloat32Array) -> void:
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
		file.store_16(value + 65536 if value < 0 else value)


func _write_ascii(file: FileAccess, value: String) -> void:
	for index in range(value.length()):
		file.store_8(value.unicode_at(index))


func _noise(seed: int) -> float:
	var value := int((seed * 1103515245 + 12345) & 0x7fffffff)
	return float(value % 2000) / 1000.0 - 1.0
