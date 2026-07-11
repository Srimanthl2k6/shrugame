extends SceneTree

const BATTLE_MANAGER := preload("res://scripts/battle/battle_manager.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var manager = BATTLE_MANAGER.new()
	var easy: Dictionary = manager.get_effective_encounter_stats("satyaki_tirumal_boss", "shrububu")
	var hard: Dictionary = manager.get_effective_encounter_stats("satyaki_tirumal_boss", "srmt")
	if easy.is_empty() or hard.is_empty():
		failures.append("Could not calculate difficulty-aware encounter stats")
	else:
		if int(easy.get("player_hp", 0)) <= int(hard.get("player_hp", 0)):
			failures.append("Shrububu mode does not grant higher player HP")
		if int(easy.get("enemy_hp", 0)) >= int(hard.get("enemy_hp", 0)):
			failures.append("SRMT mode does not grant higher enemy HP")
		if int(easy.get("enemy_damage", 99)) >= int(hard.get("enemy_damage", 0)):
			failures.append("SRMT mode does not grant higher enemy damage")
		if float(easy.get("bullet_count_multiplier", 99.0)) >= float(hard.get("bullet_count_multiplier", 0.0)):
			failures.append("SRMT mode does not increase bullet count")
		if float(easy.get("telegraph_multiplier", 0.0)) <= float(hard.get("telegraph_multiplier", 99.0)):
			failures.append("Shrububu mode does not provide longer telegraphs")
	manager.free()
	_finish(failures)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("PASS: Premium difficulty-aware battle tuning smoke test")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
