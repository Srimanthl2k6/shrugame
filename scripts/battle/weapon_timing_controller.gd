class_name WeaponTimingController
extends Control

signal timing_resolved(multiplier: float, grade: String)
signal timing_cancelled

const PROFILES := {
	"unarmed": {"speed": 0.72, "targets": [0.5], "window": 0.24},
	"precision": {"speed": 0.92, "targets": [0.5], "window": 0.14},
	"spread": {"speed": 0.78, "targets": [0.35, 0.65], "window": 0.22},
	"support": {"speed": 0.65, "targets": [0.5], "window": 0.32},
	"music": {"speed": 0.86, "targets": [0.22, 0.5, 0.78], "window": 0.16}
}

var active := false
var weapon_type := "unarmed"
var progress := 0.0
var direction := 1.0
var hit_scores: Array[float] = []
var target_index := 0
var _profile: Dictionary = {}

@onready var marker: ColorRect = $Panel/Track/Marker
@onready var target: ColorRect = $Panel/Track/Target
@onready var prompt: Label = $Panel/Prompt


func _ready() -> void:
	visible = false
	set_process(false)
	set_process_unhandled_input(true)


func start_attack(next_weapon_type: String, display_name: String = "Attack") -> void:
	weapon_type = next_weapon_type if PROFILES.has(next_weapon_type) else "unarmed"
	_profile = PROFILES[weapon_type].duplicate(true)
	progress = 0.0
	direction = 1.0
	hit_scores.clear()
	target_index = 0
	active = true
	visible = true
	set_process(true)
	prompt.text = "%s  |  Confirm on the gold mark" % display_name
	_update_visuals()


func _process(delta: float) -> void:
	if not active:
		return
	progress += direction * float(_profile.get("speed", 0.8)) * delta
	if progress >= 1.0:
		progress = 1.0
		direction = -1.0
	elif progress <= 0.0:
		progress = 0.0
		direction = 1.0
	_update_visuals()


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		submit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		cancel()
		get_viewport().set_input_as_handled()


func submit() -> void:
	if not active:
		return
	var targets: Array = _profile.get("targets", [0.5])
	var target_value := float(targets[target_index])
	var window := maxf(0.01, float(_profile.get("window", 0.2)))
	var distance := absf(progress - target_value)
	hit_scores.append(clampf(1.0 - distance / window, 0.0, 1.0))
	target_index += 1
	if target_index >= targets.size():
		_finish()
	else:
		progress = 0.0
		direction = 1.0
		_update_visuals()


func resolve_at(test_progress: float) -> void:
	progress = clampf(test_progress, 0.0, 1.0)
	submit()


func cancel() -> void:
	if not active:
		return
	active = false
	visible = false
	set_process(false)
	timing_cancelled.emit()


func _finish() -> void:
	var average := 0.0
	for score in hit_scores:
		average += score
	average /= maxf(1.0, float(hit_scores.size()))
	var multiplier := lerpf(0.55, 1.75, average)
	var grade := "PERFECT" if average >= 0.92 else ("GREAT" if average >= 0.68 else ("GOOD" if average >= 0.38 else "GLANCE"))
	active = false
	visible = false
	set_process(false)
	timing_resolved.emit(multiplier, grade)


func _update_visuals() -> void:
	if marker == null or target == null:
		return
	var track_width := 176.0
	marker.position.x = progress * track_width - marker.size.x * 0.5
	var targets: Array = _profile.get("targets", [0.5])
	var target_value := float(targets[mini(target_index, targets.size() - 1)])
	var window := float(_profile.get("window", 0.2))
	target.size.x = maxf(6.0, track_width * window)
	target.position.x = target_value * track_width - target.size.x * 0.5
