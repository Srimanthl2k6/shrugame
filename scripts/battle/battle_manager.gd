extends Node2D

const TuningLoader := preload("res://scripts/core/tuning_loader.gd")

const ENCOUNTER_FILES := [
	"res://data/encounters/level_01_encounters.json",
	"res://data/encounters/level_02_encounters.json",
	"res://data/encounters/level_03_encounters.json",
	"res://data/encounters/level_04_encounters.json",
	"res://data/encounters/level_05_encounters.json"
]
const DEFAULT_COMMANDS := ["act", "item", "gear", "guard"]
const DEFAULT_WEAPON_DAMAGE := {
	"": 1,
	"revolver": 3,
	"banana_gun": 2,
	"berry_potions": 1,
	"musical_guitar": 4
}
const WEAPON_AUDIO_IDS := {
	"revolver": "revolver",
	"banana_gun": "banana_gun",
	"berry_potions": "berry_potion",
	"musical_guitar": "guitar_note"
}
const DEFAULT_BATTLE_BACKPLATE := "res://assets/level_01/sprites/battle_bg_divorcee_harbour.png"
const DEFAULT_ENEMY_VISUALS := {
	"poojan_strength_test": "res://assets/level_01/sprites/battle_poojan_strength_test.png",
	"satyaki_tirumal_boss": "res://assets/level_01/sprites/battle_satyaki_tirumal.png"
}
const DEFAULT_BULLET_LEGENDS := {
	"poojan_strength_test": "Badge warnings and rainy revolver lanes.",
	"satyaki_tirumal_boss": "Dodge legal papers, broken rings, and property deeds."
}
const BattleActorScript := preload("res://scripts/battle/battle_actor.gd")

var phase := "idle"
var active_encounter_id := "marn_practice"
var active_encounter: Dictionary = {}
var enemy_name := ""
var player_hp := 1
var player_max_hp := 1
var enemy_hp := 1
var enemy_max_hp := 1
var resonance := 0
var resonance_goal := 1
var return_scene_path := "res://scenes/levels/level_01.tscn"
var enemy_phase_seconds := 1.0
var enemy_phase_damage := 2
var available_commands: Array[String] = []
var phases: Array = []
var current_phase_index := 0
var reward_gear_id := ""
var growth_stage_reward := 0
var required_weapon_id := ""
var defeated_flag := ""
var boss_type := "standard"
var last_command := ""
var last_cut_in_id := ""
var guarding := false
var current_pattern_readability_text := ""
var current_phase_readability_hint := ""

var _state_machine = preload("res://scripts/battle/encounter_state_machine.gd").new()
var _player_actor
var _enemy_actor

@onready var _hud: Control = $HudLayer/BattleHud
@onready var _bullet_pattern: Node = $Arena/BulletPattern
@onready var _boss_cut_in: Control = get_node_or_null("HudLayer/BossCutIn")
@onready var _screen_shake: Node = get_node_or_null("JuiceLayer/ScreenShake")
@onready var _hit_flash: Node = get_node_or_null("JuiceLayer/HitFlash")
@onready var _juice_particles: Node = get_node_or_null("JuiceLayer/JuiceParticles")
@onready var _scene_transition: Node = get_node_or_null("HudLayer/SceneTransition")
@onready var _enemy_nameplate: Label = get_node_or_null("BattleReadabilityLayer/EnemyNameplate") as Label
@onready var _arena_instruction: Label = get_node_or_null("BattleReadabilityLayer/ArenaInstruction") as Label
@onready var _command_hint_strip: Label = get_node_or_null("BattleReadabilityLayer/CommandHintStrip") as Label
@onready var _battle_backplate: Sprite2D = get_node_or_null("BattleBackplate") as Sprite2D
@onready var _enemy_sprite: Sprite2D = get_node_or_null("EnemySprite") as Sprite2D
@onready var _enemy_placeholder: CanvasItem = get_node_or_null("EnemyPlaceholder") as CanvasItem
@onready var _bullet_legend: Label = get_node_or_null("BattleReadabilityLayer/BulletLegend") as Label


func _ready() -> void:
	_apply_tuning()
	if phase == "idle":
		var encounter_id := "marn_practice"
		var game_state := get_tree().root.get_node_or_null("GameState")
		if game_state != null and not game_state.pending_encounter_id.is_empty():
			encounter_id = game_state.pending_encounter_id
		start_encounter(encounter_id)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and phase == "player_command":
		choose_act()
		get_viewport().set_input_as_handled()


func start_encounter(encounter_id: String) -> bool:
	var encounter := _find_encounter(encounter_id)
	if encounter.is_empty():
		return false

	active_encounter_id = encounter_id
	active_encounter = encounter.duplicate(true)
	enemy_name = str(encounter.get("enemy_name", "Enemy"))
	player_max_hp = int(encounter.get("player_hp", 20))
	player_hp = player_max_hp
	enemy_hp = int(encounter.get("enemy_hp", 5))
	enemy_max_hp = enemy_hp
	resonance = 0
	resonance_goal = int(encounter.get("resonance_goal", 2))
	return_scene_path = str(encounter.get("return_scene", return_scene_path))
	available_commands = _to_string_array(encounter.get("commands", DEFAULT_COMMANDS))
	if available_commands.is_empty():
		available_commands = _to_string_array(DEFAULT_COMMANDS)
	phases = encounter.get("phases", [])
	if phases.is_empty():
		phases = [{
			"id": "opening",
			"intro_dialogue": "",
			"patterns": [{"type": "straight_lanes", "count": 3}],
			"clear_threshold": 0
		}]
	current_phase_index = 0
	reward_gear_id = str(encounter.get("reward_gear", ""))
	growth_stage_reward = int(encounter.get("growth_stage_reward", 0))
	required_weapon_id = str(encounter.get("required_weapon", ""))
	if not _has_required_weapon(required_weapon_id):
		return false
	defeated_flag = str(encounter.get("defeated_flag", "%s_cleared" % encounter_id))
	boss_type = str(encounter.get("boss_type", "standard"))
	last_command = ""
	current_pattern_readability_text = ""
	current_phase_readability_hint = ""
	guarding = false

	_player_actor = BattleActorScript.new()
	_player_actor.setup("Shru", player_max_hp)
	_enemy_actor = BattleActorScript.new()
	_enemy_actor.setup(enemy_name, enemy_hp)

	_state_machine.start()
	phase = _state_machine.get_state()
	apply_encounter_visuals(active_encounter_id)
	_play_boss_cut_in()
	_update_hud()
	return true


func choose_act() -> void:
	choose_command("act")


func choose_command(command_id: String, payload: Dictionary = {}) -> bool:
	if phase != "player_command":
		return false
	if not available_commands.has(command_id):
		return false
	last_command = command_id
	var audio_manager := get_tree().root.get_node_or_null("AudioManager")
	if audio_manager != null:
		audio_manager.play_ui_select()
	match command_id:
		"act":
			_apply_weapon_attack()
		"item":
			var item_id := str(payload.get("item_id", "kfc_popcorn_box"))
			if not use_item(item_id):
				return false
		"gear":
			var weapon_id := str(payload.get("weapon_id", ""))
			if not equip_weapon(weapon_id):
				return false
		"guard":
			guarding = true
	if enemy_hp <= 0 or resonance >= resonance_goal:
		resolve_battle(true)
		return true
	_start_enemy_phase()
	return true


func get_available_commands() -> Array[String]:
	return available_commands.duplicate()


func get_current_phase_id() -> String:
	var phase_data := _get_current_phase()
	return str(phase_data.get("id", "opening"))


func get_last_cut_in_id() -> String:
	return last_cut_in_id


func get_enemy_visual_path(encounter_id: String = "") -> String:
	var resolved_id := encounter_id
	if resolved_id.is_empty():
		resolved_id = active_encounter_id
	var encounter := active_encounter
	if encounter.is_empty() or resolved_id != active_encounter_id:
		encounter = _find_encounter(resolved_id)
	var visual_path := str(encounter.get("battle_visual", ""))
	if not visual_path.is_empty():
		return visual_path
	return str(DEFAULT_ENEMY_VISUALS.get(resolved_id, ""))


func get_battle_backplate_path(encounter_id: String = "") -> String:
	var resolved_id := encounter_id
	if resolved_id.is_empty():
		resolved_id = active_encounter_id
	var encounter := active_encounter
	if encounter.is_empty() or resolved_id != active_encounter_id:
		encounter = _find_encounter(resolved_id)
	var backplate_path := str(encounter.get("battle_backplate", ""))
	if not backplate_path.is_empty():
		return backplate_path
	return DEFAULT_BATTLE_BACKPLATE


func get_bullet_legend_text(encounter_id: String = "") -> String:
	var resolved_id := encounter_id
	if resolved_id.is_empty():
		resolved_id = active_encounter_id
	var encounter := active_encounter
	if encounter.is_empty() or resolved_id != active_encounter_id:
		encounter = _find_encounter(resolved_id)
	var legend := str(encounter.get("bullet_legend", ""))
	if not legend.is_empty():
		return legend
	return str(DEFAULT_BULLET_LEGENDS.get(resolved_id, "Watch the bullet pattern."))


func get_current_pattern_readability_text() -> String:
	if not current_pattern_readability_text.is_empty():
		return current_pattern_readability_text
	var phase_data := _get_current_phase()
	var patterns: Array = phase_data.get("patterns", [])
	if not patterns.is_empty() and typeof(patterns[0]) == TYPE_DICTIONARY:
		return str(patterns[0].get("safe_hint", get_bullet_legend_text()))
	return get_bullet_legend_text()


func get_phase_readability_hint() -> String:
	if not current_phase_readability_hint.is_empty():
		return current_phase_readability_hint
	var phase_data := _get_current_phase()
	return str(phase_data.get("readability_hint", "Dodge inside the box."))


func apply_encounter_visuals(encounter_id: String = "") -> void:
	var visual_path := get_enemy_visual_path(encounter_id)
	var backplate_path := get_battle_backplate_path(encounter_id)
	if _enemy_placeholder != null:
		_enemy_placeholder.visible = false
	if _enemy_sprite != null and not visual_path.is_empty():
		var enemy_texture := _load_texture_from_path(visual_path)
		if enemy_texture != null:
			_enemy_sprite.texture = enemy_texture
		_enemy_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if _battle_backplate != null and not backplate_path.is_empty():
		var backplate_texture := _load_texture_from_path(backplate_path)
		if backplate_texture != null:
			_battle_backplate.texture = backplate_texture
		_battle_backplate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if _bullet_legend != null:
		_bullet_legend.text = "Pattern: %s" % get_bullet_legend_text(encounter_id)


func get_weapon_behavior(weapon_id: String) -> Dictionary:
	var gear_data := _load_json_dict("res://data/gear/gear.json")
	var entry: Dictionary = gear_data.get(weapon_id, {})
	if entry.is_empty():
		return {
			"display_name": weapon_id,
			"weapon_type": "unarmed",
			"damage": DEFAULT_WEAPON_DAMAGE.get(weapon_id, 1),
			"battle_use": "Basic attack."
		}
	entry["damage"] = int(DEFAULT_WEAPON_DAMAGE.get(weapon_id, 1))
	return entry


func use_item(item_id: String) -> bool:
	var game_state := _get_game_state()
	if game_state == null or not game_state.has_method("consume_item"):
		return false
	if not game_state.consume_item(item_id, 1):
		return false
	var item_data := _load_json_dict("res://data/items/items.json")
	var item: Dictionary = item_data.get(item_id, {})
	var heal_amount := int(item.get("heal_amount", 6))
	player_hp = min(player_max_hp, player_hp + heal_amount)
	if _player_actor != null:
		_player_actor.hp = player_hp
	return true


func equip_weapon(weapon_id: String) -> bool:
	var game_state := _get_game_state()
	if game_state == null or not game_state.has_method("equip_weapon"):
		return false
	return game_state.equip_weapon(weapon_id)


func _apply_weapon_attack() -> void:
	var game_state := _get_game_state()
	var weapon_id := ""
	if game_state != null:
		weapon_id = str(game_state.current_weapon)
	_play_weapon_audio(weapon_id)
	var behavior := get_weapon_behavior(weapon_id)
	var damage := int(behavior.get("damage", 1))
	enemy_hp = max(0, enemy_hp - damage)
	if _enemy_actor != null:
		_enemy_actor.take_damage(damage)
	_play_boss_hurt_feedback()
	resonance += 1
	_advance_phase_if_needed()


func _start_enemy_phase() -> void:
	_state_machine.set_state("enemy_phase")
	phase = _state_machine.get_state()
	_play_phase_feedback()
	var phase_data := _get_current_phase()
	var patterns: Array = phase_data.get("patterns", [])
	var pattern_config := {"type": "straight_lanes", "count": 3}
	if not patterns.is_empty() and typeof(patterns[0]) == TYPE_DICTIONARY:
		pattern_config = patterns[0]
	current_phase_readability_hint = str(phase_data.get("readability_hint", "Dodge inside the box."))
	current_pattern_readability_text = str(pattern_config.get("safe_hint", current_phase_readability_hint))
	if _bullet_legend != null:
		_bullet_legend.text = "Pattern: %s" % current_pattern_readability_text
	_bullet_pattern.start_pattern(pattern_config)
	_update_hud()
	if is_inside_tree() and not Engine.is_editor_hint():
		var telegraph_seconds := float(pattern_config.get("telegraph_seconds", TuningLoader.get_value(["battle", "pattern_telegraph_seconds"], 0.0)))
		get_tree().create_timer(enemy_phase_seconds + telegraph_seconds).timeout.connect(finish_enemy_phase)


func finish_enemy_phase() -> void:
	if phase != "enemy_phase":
		return
	_bullet_pattern.clear_pattern()
	var damage := enemy_phase_damage
	if guarding:
		damage = int(max(0, floor(float(damage) * 0.5)))
	guarding = false
	_player_actor.take_damage(damage)
	player_hp = _player_actor.hp
	_play_player_hit_feedback()
	if _player_actor.is_defeated():
		resolve_battle(true)
		return
	_state_machine.set_state("player_command")
	phase = _state_machine.get_state()
	_update_hud()


func resolve_battle(return_to_overworld: bool = true) -> void:
	_bullet_pattern.clear_pattern()
	_state_machine.set_state("resolved")
	phase = _state_machine.get_state()
	_update_hud()
	_play_boss_defeat_feedback()
	var game_state := _get_game_state()
	if game_state != null:
		game_state.set_flag("%s_cleared" % active_encounter_id, true)
		if not defeated_flag.is_empty():
			game_state.set_flag(defeated_flag, true)
		if not reward_gear_id.is_empty() and game_state.has_method("unlock_gear"):
			game_state.unlock_gear(reward_gear_id)
		if growth_stage_reward > 0 and game_state.has_method("set_growth_stage"):
			game_state.set_growth_stage(growth_stage_reward)
			_play_growth_feedback()
	if return_to_overworld and not return_scene_path.is_empty():
		_play_transition_feedback()
		call_deferred("_return_to_overworld")


func _return_to_overworld() -> void:
	get_tree().change_scene_to_file(return_scene_path)


func _update_hud() -> void:
	if _hud != null:
		_hud.update_hud(enemy_name, player_hp, player_max_hp, phase, resonance, resonance_goal)
	if _enemy_nameplate != null:
		_enemy_nameplate.text = enemy_name
	if _arena_instruction != null:
		if phase == "enemy_phase":
			_arena_instruction.text = get_current_pattern_readability_text()
		elif phase == "player_command":
			_arena_instruction.text = "Choose a command below"
		else:
			_arena_instruction.text = "Battle resolving"
	if _command_hint_strip != null:
		_command_hint_strip.text = "Act builds RES | Item heals | Gear swaps | Guard halves damage"


func _get_current_phase() -> Dictionary:
	if phases.is_empty():
		return {}
	var index: int = clamp(current_phase_index, 0, phases.size() - 1)
	var phase_data = phases[index]
	if typeof(phase_data) != TYPE_DICTIONARY:
		return {}
	return phase_data


func _advance_phase_if_needed() -> void:
	if phases.size() <= 1:
		return
	var next_index: int = min(current_phase_index + 1, phases.size() - 1)
	if next_index == current_phase_index:
		return
	var next_phase: Dictionary = phases[next_index]
	var threshold := int(next_phase.get("clear_threshold", 0))
	if threshold <= 0:
		threshold = int(floor(float(enemy_max_hp) * 0.5))
	if enemy_hp <= threshold:
		current_phase_index = next_index


func _find_encounter(encounter_id: String) -> Dictionary:
	for file_path in ENCOUNTER_FILES:
		var encounters = JSON.parse_string(FileAccess.get_file_as_string(file_path))
		if typeof(encounters) == TYPE_DICTIONARY and encounters.has(encounter_id):
			return encounters[encounter_id]
	return {}


func _to_string_array(value) -> Array[String]:
	var output: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return output
	for entry in value:
		output.append(str(entry))
	return output


func _load_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data


func _load_texture_from_path(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path, "Texture2D"):
		return ResourceLoader.load(path, "Texture2D") as Texture2D
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


func _get_game_state() -> Node:
	if is_inside_tree():
		return get_tree().root.get_node_or_null("GameState")
	return null


func _has_required_weapon(weapon_id: String) -> bool:
	if weapon_id.is_empty():
		return true
	var game_state := _get_game_state()
	if game_state == null or not game_state.has_method("has_gear"):
		return false
	if not game_state.has_gear(weapon_id):
		return false
	if game_state.has_method("equip_weapon") and game_state.current_weapon != weapon_id:
		return game_state.equip_weapon(weapon_id)
	return true


func _apply_tuning() -> void:
	enemy_phase_seconds = float(TuningLoader.get_value(["battle", "enemy_phase_seconds"], enemy_phase_seconds))
	enemy_phase_damage = int(TuningLoader.get_value(["battle", "enemy_phase_damage"], enemy_phase_damage))


func _play_boss_cut_in() -> void:
	if boss_type == "practice":
		last_cut_in_id = ""
		return
	last_cut_in_id = active_encounter_id
	if _boss_cut_in != null and _boss_cut_in.has_method("play_cut_in"):
		_boss_cut_in.play_cut_in(active_encounter_id, enemy_name)


func _play_weapon_audio(weapon_id: String) -> void:
	var audio_manager := get_tree().root.get_node_or_null("AudioManager")
	if audio_manager != null and audio_manager.has_method("play_weapon_sfx"):
		audio_manager.play_weapon_sfx(weapon_id)
	elif audio_manager != null and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx(str(WEAPON_AUDIO_IDS.get(weapon_id, "ui_select")))


func _play_phase_feedback() -> void:
	var audio_manager := get_tree().root.get_node_or_null("AudioManager")
	if audio_manager != null:
		audio_manager.play_sfx("battle_phase")
	if _screen_shake != null and _screen_shake.has_method("play"):
		_screen_shake.play(1.2, 0.1) # ScreenShake phase cue.


func _play_boss_hurt_feedback() -> void:
	var audio_manager := get_tree().root.get_node_or_null("AudioManager")
	if audio_manager != null and audio_manager.has_method("play_boss_hurt"):
		audio_manager.play_boss_hurt()
	if _hit_flash != null and _hit_flash.has_method("play"):
		_hit_flash.play(0.1) # HitFlash boss impact.
	if _juice_particles != null and _juice_particles.has_method("play"):
		_juice_particles.play(Vector2(160, 46), Color(1.0, 0.86, 0.35, 0.9)) # JuiceParticles burst.


func _play_player_hit_feedback() -> void:
	if _screen_shake != null and _screen_shake.has_method("play"):
		_screen_shake.play(2.0, 0.14) # ScreenShake player damage.
	if _hit_flash != null and _hit_flash.has_method("play"):
		_hit_flash.play(0.12) # HitFlash player damage.


func _play_boss_defeat_feedback() -> void:
	var audio_manager := get_tree().root.get_node_or_null("AudioManager")
	if audio_manager != null and audio_manager.has_method("play_boss_defeat"):
		audio_manager.play_boss_defeat()
	if _screen_shake != null and _screen_shake.has_method("play"):
		_screen_shake.play(3.0, 0.24) # ScreenShake boss defeat.
	if _juice_particles != null and _juice_particles.has_method("play"):
		_juice_particles.play(Vector2(160, 46), Color(1.0, 0.35, 0.52, 0.95)) # JuiceParticles defeat burst.


func _play_growth_feedback() -> void:
	var audio_manager := get_tree().root.get_node_or_null("AudioManager")
	if audio_manager != null and audio_manager.has_method("play_growth_transform"):
		audio_manager.play_growth_transform()


func _play_transition_feedback() -> void:
	if _scene_transition != null and _scene_transition.has_method("play"):
		_scene_transition.play(0.2)
