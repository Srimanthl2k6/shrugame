extends RefCounted

var actor_name := ""
var max_hp := 1
var hp := 1


func setup(new_name: String, new_max_hp: int) -> void:
	actor_name = new_name
	max_hp = max(1, new_max_hp)
	hp = max_hp


func take_damage(amount: int) -> void:
	hp = max(0, hp - max(0, amount))


func is_defeated() -> bool:
	return hp <= 0
