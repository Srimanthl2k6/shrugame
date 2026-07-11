class_name CutsceneStep
extends Resource

@export var type: String = "wait"
@export var payload: Dictionary = {}


static func from_dictionary(data: Dictionary) -> CutsceneStep:
	var step := CutsceneStep.new()
	step.type = str(data.get("type", "wait"))
	step.payload = data.duplicate(true)
	step.payload.erase("type")
	return step


func is_valid() -> bool:
	return not type.strip_edges().is_empty()


func to_dictionary() -> Dictionary:
	var data := payload.duplicate(true)
	data["type"] = type
	return data
