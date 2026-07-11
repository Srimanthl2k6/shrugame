class_name ForegroundOccluder
extends Area2D

@export var target_path: NodePath
@export_range(0.1, 1.0, 0.05) var occupied_alpha := 0.35
@export var fade_seconds := 0.18

var _target: CanvasItem


func _ready() -> void:
	_target = get_node_or_null(target_path) as CanvasItem
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_fade_to(occupied_alpha)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_fade_to(1.0)


func _fade_to(alpha: float) -> void:
	if _target == null:
		return
	var tween := create_tween()
	tween.tween_property(_target, "modulate:a", alpha, fade_seconds)
