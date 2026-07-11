extends SceneTree

const REQUIRED_IMAGES := {
	"res://assets/level_04/sprites/npc_pun_vendor_idle.png": Vector2i(34, 48),
	"res://assets/level_04/sprites/npc_clinic_receptionist_idle.png": Vector2i(32, 48),
	"res://assets/level_04/sprites/npc_festival_drummer_idle.png": Vector2i(34, 50),
	"res://assets/level_04/sprites/npc_neon_patient_idle.png": Vector2i(34, 48),
	"res://assets/level_04/sprites/boss_doctor_sushan_overworld.png": Vector2i(40, 56),
	"res://assets/level_04/sprites/boss_mitta_overworld.png": Vector2i(42, 58),
	"res://assets/level_04/sprites/prop_pun_vendor_cart.png": Vector2i(58, 46),
	"res://assets/level_04/sprites/prop_hospital_records_terminal.png": Vector2i(38, 46),
	"res://assets/level_04/sprites/prop_pattern_serum_lab.png": Vector2i(58, 44),
	"res://assets/level_04/sprites/prop_aeon_stage.png": Vector2i(64, 50),
	"res://assets/level_04/sprites/prop_save_kiosk.png": Vector2i(30, 44),
	"res://assets/level_04/sprites/prop_area111_exit.png": Vector2i(48, 56)
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	for path in REQUIRED_IMAGES.keys():
		_check_image(path, REQUIRED_IMAGES[path], failures)
	_check_scene(failures)
	_check_cutscenes(failures)
	_check_encounters(failures)
	_finish(failures)


func _check_image(path: String, size: Vector2i, failures: Array[String]) -> void:
	if not FileAccess.file_exists(path):
		failures.append("Missing Auticity premium image: %s" % path)
		return
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty() or image.get_size() != size:
		failures.append("Invalid Auticity premium image: %s" % path)


func _check_scene(failures: Array[String]) -> void:
	var packed := load("res://scenes/levels/level_04.tscn") as PackedScene
	if packed == null:
		failures.append("Auticity scene failed to load")
		return
	var level := packed.instantiate()
	for npc_path in ["World/PunStreet", "World/ClinicReceptionist", "World/FestivalDrummer", "World/NeonPatient", "World/AeonMaskMaker"]:
		if level.get_node_or_null(npc_path) == null:
			failures.append("Auticity missing authored NPC: %s" % npc_path)
	for legacy_path in ["World/JudgeLuma", "World/Objective", "World/PracticeEncounter"]:
		var legacy := level.get_node_or_null(legacy_path) as CanvasItem
		if legacy != null and legacy.visible:
			failures.append("Legacy Auticity prototype remains visible: %s" % legacy_path)
	var doctor := level.get_node_or_null("World/DoctorSushan")
	var mitta := level.get_node_or_null("World/MittaBoss")
	if doctor == null or str(doctor.get("cutscene_id")) != "sushan_injection_failure":
		failures.append("Doctor Sushan must use the injection-failure cutscene")
	if mitta == null or str(mitta.get("cutscene_id")) != "mitta_confrontation":
		failures.append("Mitta must use the festival confrontation cutscene")
	level.free()


func _check_cutscenes(failures: Array[String]) -> void:
	var catalog := _load_json("res://data/cutscenes/index.json", failures)
	for id in ["sushan_injection_failure", "sushan_aftermath", "aeon_festival", "mitta_confrontation", "mitta_aftermath"]:
		if not catalog.has(id):
			failures.append("Auticity cutscene missing from catalog: %s" % id)
	var injection_text := FileAccess.get_file_as_string("res://data/cutscenes/sushan_injection_failure.json")
	if injection_text.contains("Autinjection"):
		failures.append("Auticity implementation must use fictional Pattern Serum terminology")
	if not injection_text.contains("Pattern Serum"):
		failures.append("Sushan cutscene must identify Pattern Serum")
	var finale := _load_json("res://data/cutscenes/mitta_aftermath.json", failures)
	if not _has_step(finale, "unlock_gear", "festival_clearance") or not _has_growth_stage(finale, 5):
		failures.append("Mitta aftermath must grant clearance and Form 5 growth")


func _check_encounters(failures: Array[String]) -> void:
	var encounters := _load_json("res://data/encounters/level_04_encounters.json", failures)
	for encounter_id in ["doctor_sushan_boss", "mitta_boss"]:
		var encounter: Dictionary = encounters.get(encounter_id, {})
		if (encounter.get("phases", []) as Array).size() < 3:
			failures.append("%s must have at least three phases" % encounter_id)
		if int(encounter.get("battle_frames", 0)) != 4:
			failures.append("%s must use four-frame authored art" % encounter_id)
		if not encounter.has("difficulty_overrides"):
			failures.append("%s lacks difficulty overrides" % encounter_id)


func _has_step(data: Dictionary, type: String, id: String) -> bool:
	for raw_step in data.get("steps", []):
		if typeof(raw_step) != TYPE_DICTIONARY or str(raw_step.get("type", "")) != type:
			continue
		var value := str(raw_step.get("stage", "")) if type == "set_growth_stage" else str(raw_step.get("id", ""))
		if value == id:
			return true
	return false


func _has_growth_stage(data: Dictionary, stage: int) -> bool:
	for raw_step in data.get("steps", []):
		if typeof(raw_step) == TYPE_DICTIONARY and str(raw_step.get("type", "")) == "set_growth_stage" and int(raw_step.get("stage", 0)) == stage:
			return true
	return false


func _load_json(path: String, failures: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(path):
		failures.append("Missing JSON: %s" % path)
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		failures.append("Invalid JSON object: %s" % path)
		return {}
	return data


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("PASS: Auticity premium cast, props, staged cutscenes, and three-phase bosses")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
