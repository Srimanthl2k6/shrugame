extends Node2D

@export var particle_count: int = 8
@export var default_color: Color = Color(1, 0.9, 0.45, 0.9)

var _active_seconds: float = 0.0


func _ready() -> void:
	set_process(true)


func play(origin: Vector2 = Vector2.ZERO, color_override: Color = Color.TRANSPARENT) -> void:
	position = origin
	_active_seconds = 0.22
	for child in get_children():
		child.queue_free()
	var color := default_color if color_override == Color.TRANSPARENT else color_override
	for index in range(maxi(1, particle_count)):
		var particle := Polygon2D.new()
		particle.name = "JuiceParticle%s" % index
		particle.color = color
		particle.polygon = PackedVector2Array([
			Vector2(-1, -1),
			Vector2(1, -1),
			Vector2(1, 1),
			Vector2(-1, 1)
		])
		var angle: float = TAU * float(index) / float(maxi(1, particle_count))
		particle.position = Vector2(cos(angle), sin(angle)) * 8.0
		add_child(particle)


func _process(delta: float) -> void:
	if _active_seconds <= 0.0:
		return
	_active_seconds -= delta
	if _active_seconds <= 0.0:
		for child in get_children():
			child.queue_free()
