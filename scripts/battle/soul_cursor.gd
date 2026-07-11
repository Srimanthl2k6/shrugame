extends Area2D

signal hit_received

@export var move_speed := 92.0
@export var arena_bounds := Rect2(6.0, 6.0, 180.0, 64.0)
@export var invulnerability_seconds := 0.7

var active := false
var _invulnerable_for := 0.0
var _pulse_time := 0.0

@onready var visual: Sprite2D = $Visual


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	area_entered.connect(_on_area_entered)
	set_active(false)


func _physics_process(delta: float) -> void:
	_pulse_time += delta
	if _invulnerable_for > 0.0:
		_invulnerable_for = maxf(0.0, _invulnerable_for - delta)
		visual.visible = int(_invulnerable_for * 18.0) % 2 == 0
	else:
		visual.visible = true
	if not active:
		visual.scale = Vector2.ONE
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	position += direction * move_speed * delta
	position.x = clampf(position.x, arena_bounds.position.x, arena_bounds.end.x)
	position.y = clampf(position.y, arena_bounds.position.y, arena_bounds.end.y)
	var pulse := 1.0 + sin(_pulse_time * 8.0) * 0.045
	visual.scale = Vector2.ONE * pulse


func configure(speed: float, invulnerability: float, bounds: Rect2 = arena_bounds) -> void:
	move_speed = speed
	invulnerability_seconds = invulnerability
	arena_bounds = bounds


func set_active(value: bool, reset_position := false) -> void:
	active = value
	monitoring = value
	monitorable = value
	if reset_position:
		position = arena_bounds.get_center()
	if not value:
		_invulnerable_for = 0.0
		if is_instance_valid(visual):
			visual.visible = true


func grant_invulnerability(seconds: float = invulnerability_seconds) -> void:
	_invulnerable_for = maxf(_invulnerable_for, seconds)


func is_invulnerable() -> bool:
	return _invulnerable_for > 0.0


func _on_area_entered(area: Area2D) -> void:
	if not active or is_invulnerable() or not area.is_in_group("battle_bullet"):
		return
	grant_invulnerability()
	hit_received.emit()
