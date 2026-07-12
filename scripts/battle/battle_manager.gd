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
	"": 2,
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
const DEFAULT_BATTLE_BACKPLATE := "res://assets/level_01/backgrounds/rooms/harbour_square.png"
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
var return_scene_path := "res://scenes/levels/districts/level_01.tscn"
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
var difficulty_id := "shrububu"
var difficulty_data: Dictionary = {}
var last_command := ""
var last_cut_in_id := ""
var guarding := false
var current_pattern_readability_text := ""
var current_phase_readability_hint := ""
var battle_resolution := ""
var phase_checkpoint_hp := 1
var automatic_recovery_used := false
var player_status_effects: Dictionary = {}
var _pattern_cursor_by_phase: Dictionary = {}

var _state_machine = preload("res://scripts/battle/encounter_state_machine.gd").new()
var _player_actor
var _enemy_actor
var _enemy_animation_time := 0.0
var _enemy_animation_frames := 1

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
@onready var _soul_cursor: Area2D = get_node_or_null("Arena/SoulCursor") as Area2D
@onready var _weapon_timing: Control = get_node_or_null("HudLayer/WeaponTiming") as Control


func _ready() -> void:
	_apply_tuning()
	if _soul_cursor != null and _soul_cursor.has_signal("hit_received"):
		_soul_cursor.hit_received.connect(_on_soul_hit)
	if _hud != null and _hud.has_signal("command_selected"):
		_hud.command_selected.connect(_on_hud_command_selected)
	if _hud != null and _hud.has_signal("item_selected"):
		_hud.item_selected.connect(_on_item_selected)
	if _hud != null and _hud.has_signal("gear_selected"):
		_hud.gear_selected.connect(_on_gear_selected)
	if _weapon_timing != null:
		_weapon_timing.timing_resolved.connect(_on_weapon_timing_resolved)
		_weapon_timing.timing_cancelled.connect(_on_weapon_timing_cancelled)
	if phase == "idle":
		var encounter_id := "marn_practice"
		var game_state := get_tree().root.get_node_or_null("GameState")
		if game_state != null and not game_state.pending_encounter_id.is_empty():
			encounter_id = game_state.pending_encounter_id
		start_encounter(encounter_id)


func _process(delta: float) -> void:
	if _enemy_sprite == null or _enemy_animation_frames <= 1:
		return
	_enemy_animation_time += delta
	_enemy_sprite.frame = int(_enemy_animation_time * 4.0) % _enemy_animation_frames


func _unhandled_input(event: InputEvent) -> void:
	if phase == "defeated":
		if event.is_action_pressed("interact"):
			start_encounter(active_encounter_id)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_cancel"):
			call_deferred("_return_to_overworld")
			get_viewport().set_input_as_handled()
		return
	if phase != "player_command":
		return
	if event.is_action_pressed("interact"):
		choose_act()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				choose_act()
			KEY_2:
				_choose_item_command()
			KEY_3:
				_choose_gear_command()
			KEY_4:
				choose_command("guard")
			_:
				return
		get_viewport().set_input_as_handled()


func start_encounter(encounter_id: String) -> bool:
	var encounter := _find_encounter(encounter_id)
	if encounter.is_empty():
		return false

	active_encounter_id = encounter_id
	active_encounter = encounter.duplicate(true)
	difficulty_id = _resolve_difficulty_id()
	difficulty_data = _get_difficulty_data(difficulty_id, encounter)
	enemy_name = str(encounter.get("enemy_name", "Enemy"))
	player_max_hp = TuningLoader.scale_int(
		int(encounter.get("player_hp", 20)),
		float(difficulty_data.get("player_hp_multiplier", 1.0))
	)
	player_hp = player_max_hp
	enemy_hp = TuningLoader.scale_int(
		int(encounter.get("enemy_hp", 5)),
		float(difficulty_data.get("enemy_hp_multiplier", 1.0))
	)
	enemy_max_hp = enemy_hp
	enemy_phase_damage = TuningLoader.scale_int(
		int(TuningLoader.get_value(["battle", "enemy_phase_damage"], 1)),
		float(difficulty_data.get("enemy_damage_multiplier", 1.0)),
		0
	)
	resonance = 0
	resonance_goal = int(encounter.get("resonance_goal", 2))
	return_scene_path = str(encounter.get("return_scene", return_scene_path))
	if return_scene_path.begins_with("res://scenes/levels/level_"):
		return_scene_path = return_scene_path.replace("res://scenes/levels/", "res://scenes/levels/districts/")
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
	battle_resolution = ""
	phase_checkpoint_hp = player_max_hp
	automatic_recovery_used = false
	player_status_effects.clear()
	_pattern_cursor_by_phase.clear()
	_configure_soul_cursor()

	_player_actor = BattleActorScript.new()
	_player_actor.setup("Shru", player_max_hp)
	_enemy_actor = BattleActorScript.new()
	_enemy_actor.setup(enemy_name, enemy_hp)

	_state_machine.start()
	phase = _state_machine.get_state()
	apply_encounter_visuals(active_encounter_id)
	_play_boss_cut_in()
	_update_hud()
	var tutorial_manager := get_node_or_null("/root/TutorialManager")
	if tutorial_manager != null and tutorial_manager.has_method("begin_battle_command_tutorial"):
		tutorial_manager.begin_battle_command_tutorial(active_encounter_id)
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
			return _begin_active_attack(payload)
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
		battle_resolution = "resonance" if resonance >= resonance_goal and enemy_hp > 0 else "strength"
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


func get_effective_encounter_stats(encounter_id: String, selected_difficulty_id: String) -> Dictionary:
	var encounter := _find_encounter(encounter_id)
	if encounter.is_empty():
		return {}
	var selected_data := _get_difficulty_data(selected_difficulty_id, encounter)
	return {
		"difficulty_id": selected_difficulty_id,
		"player_hp": TuningLoader.scale_int(
			int(encounter.get("player_hp", 20)),
			float(selected_data.get("player_hp_multiplier", 1.0))
		),
		"enemy_hp": TuningLoader.scale_int(
			int(encounter.get("enemy_hp", 5)),
			float(selected_data.get("enemy_hp_multiplier", 1.0))
		),
		"enemy_damage": TuningLoader.scale_int(
			int(TuningLoader.get_value(["battle", "enemy_phase_damage"], 1)),
			float(selected_data.get("enemy_damage_multiplier", 1.0)),
			0
		),
		"bullet_speed_multiplier": float(selected_data.get("bullet_speed_multiplier", 1.0)),
		"bullet_count_multiplier": float(selected_data.get("bullet_count_multiplier", 1.0)),
		"telegraph_multiplier": float(selected_data.get("telegraph_multiplier", 1.0))
	}


func apply_encounter_visuals(encounter_id: String = "") -> void:
	var visual_path := get_enemy_visual_path(encounter_id)
	var backplate_path := get_battle_backplate_path(encounter_id)
	var encounter_data := active_encounter
	if not encounter_id.is_empty() and encounter_id != active_encounter_id:
		encounter_data = _find_encounter(encounter_id)
	if _enemy_placeholder != null:
		_enemy_placeholder.visible = false
	if _enemy_sprite != null and not visual_path.is_empty():
		var enemy_texture := _load_texture_from_path(visual_path)
		if enemy_texture != null:
			_enemy_sprite.texture = enemy_texture
			_enemy_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			_enemy_animation_frames = maxi(1, int(encounter_data.get("battle_frames", 1)))
			_enemy_sprite.hframes = _enemy_animation_frames
			_enemy_sprite.frame = 0
			_enemy_animation_time = 0.0
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


func _begin_active_attack(payload: Dictionary = {}) -> bool:
	var game_state := _get_game_state()
	var weapon_id := str(game_state.current_weapon) if game_state != null else ""
	var behavior := get_weapon_behavior(weapon_id)
	var weapon_type := str(behavior.get("weapon_type", "unarmed"))
	if payload.has("timing_multiplier"):
		_resolve_active_attack(float(payload["timing_multiplier"]), "TEST")
		return true
	_state_machine.set_state("weapon_timing")
	phase = _state_machine.get_state()
	_update_hud()
	if DisplayServer.get_name() == "headless" or _weapon_timing == null:
		_resolve_active_attack(1.25, "GREAT")
		return true
	_weapon_timing.start_attack(weapon_type, str(behavior.get("display_name", "Attack")))
	return true


func _resolve_active_attack(timing_multiplier: float, grade: String) -> void:
	var game_state := _get_game_state()
	var weapon_id := str(game_state.current_weapon) if game_state != null else ""
	var behavior := get_weapon_behavior(weapon_id)
	_play_weapon_audio(weapon_id)
	var base_damage := int(behavior.get("damage", 1))
	var damage := maxi(1, int(round(float(base_damage) * timing_multiplier)))
	if str(behavior.get("weapon_type", "")) == "support":
		player_hp = mini(player_max_hp, player_hp + maxi(2, damage * 2))
		if _player_actor != null:
			_player_actor.hp = player_hp
		player_status_effects["berry_shield"] = 1
	enemy_hp = max(0, enemy_hp - damage)
	if _enemy_actor != null:
		_enemy_actor.take_damage(damage)
	_play_boss_hurt_feedback()
	var resonance_gain := 2 if timing_multiplier >= 1.45 else 1
	resonance += resonance_gain
	if _hud != null and _hud.has_method("show_message"):
		_hud.show_message("%s  %d damage  RES +%d" % [grade, damage, resonance_gain])
	_advance_phase_if_needed()
	if enemy_hp <= 0 or resonance >= resonance_goal:
		battle_resolution = "resonance" if resonance >= resonance_goal and enemy_hp > 0 else "strength"
		resolve_battle(true)
		return
	_start_enemy_phase()


func _start_enemy_phase() -> void:
	_state_machine.set_state("enemy_phase")
	phase = _state_machine.get_state()
	_play_phase_feedback()
	var phase_data := _get_current_phase()
	var patterns: Array = phase_data.get("patterns", [])
	var pattern_config := {"type": "straight_lanes", "count": 3}
	if not patterns.is_empty():
		var phase_id := get_current_phase_id()
		var cursor := int(_pattern_cursor_by_phase.get(phase_id, 0))
		var pattern_value = patterns[cursor % patterns.size()]
		_pattern_cursor_by_phase[phase_id] = cursor + 1
		if typeof(pattern_value) == TYPE_DICTIONARY:
			pattern_config = pattern_value.duplicate(true)
	pattern_config = _apply_difficulty_to_pattern(pattern_config)
	current_phase_readability_hint = str(phase_data.get("readability_hint", "Dodge inside the box."))
	current_pattern_readability_text = str(pattern_config.get("safe_hint", current_phase_readability_hint))
	if _bullet_legend != null:
		_bullet_legend.text = "Pattern: %s" % current_pattern_readability_text
	_bullet_pattern.start_pattern(pattern_config)
	if _soul_cursor != null and _soul_cursor.has_method("set_active"):
		_soul_cursor.set_active(true, true)
	_update_hud()
	var tutorial_manager := get_node_or_null("/root/TutorialManager")
	if tutorial_manager != null and tutorial_manager.has_method("begin_battle_enemy_tutorial"):
		tutorial_manager.begin_battle_enemy_tutorial(active_encounter_id, _soul_cursor)
	if is_inside_tree() and not Engine.is_editor_hint():
		var telegraph_seconds := float(pattern_config.get("telegraph_seconds", TuningLoader.get_value(["battle", "pattern_telegraph_seconds"], 0.0)))
		get_tree().create_timer(enemy_phase_seconds + telegraph_seconds, false).timeout.connect(finish_enemy_phase)


func finish_enemy_phase() -> void:
	if phase != "enemy_phase":
		return
	_bullet_pattern.clear_pattern()
	if _soul_cursor != null and _soul_cursor.has_method("set_active"):
		_soul_cursor.set_active(false)
	guarding = false
	_state_machine.set_state("player_command")
	phase = _state_machine.get_state()
	_update_hud()


func resolve_battle(return_to_overworld: bool = true) -> void:
	_bullet_pattern.clear_pattern()
	if _soul_cursor != null and _soul_cursor.has_method("set_active"):
		_soul_cursor.set_active(false)
	_state_machine.set_state("resolved")
	phase = _state_machine.get_state()
	_update_hud()
	_play_boss_defeat_feedback()
	var game_state := _get_game_state()
	if game_state != null:
		game_state.set_flag("%s_cleared" % active_encounter_id, true)
		game_state.set_flag("%s_%s" % [active_encounter_id, battle_resolution if not battle_resolution.is_empty() else "strength"], true)
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


func resolve_defeat() -> void:
	_bullet_pattern.clear_pattern()
	if _soul_cursor != null and _soul_cursor.has_method("set_active"):
		_soul_cursor.set_active(false)
	if difficulty_id == "shrububu" and not automatic_recovery_used:
		automatic_recovery_used = true
		player_hp = maxi(phase_checkpoint_hp, maxi(1, int(ceil(float(player_max_hp) * 0.5))))
		if _player_actor != null:
			_player_actor.hp = player_hp
		_state_machine.set_state("player_command")
		phase = _state_machine.get_state()
		if _hud != null and _hud.has_method("show_message"):
			_hud.show_message("Shrububu refuses to fall. Phase recovery restored half HP.")
		_update_hud()
		return
	_state_machine.set_state("defeated")
	phase = _state_machine.get_state()
	guarding = false
	_update_hud()
	if _hud != null and _hud.has_method("show_message"):
		_hud.show_message("Shrububu fell. Press E to retry or Esc to retreat.")


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
			_arena_instruction.text = "Choose a command"
		elif phase == "defeated":
			_arena_instruction.text = "E retry   Esc retreat"
		else:
			_arena_instruction.text = "Battle resolving"
	if _command_hint_strip != null:
		_command_hint_strip.text = "Act builds RES | Item heals | Gear swaps | Guard halves damage"
	if _hud != null and _hud.has_method("set_commands_enabled"):
		_hud.set_commands_enabled(phase == "player_command")


func _on_soul_hit() -> void:
	if phase != "enemy_phase" or _player_actor == null:
		return
	var damage := maxi(1, enemy_phase_damage)
	if int(player_status_effects.get("berry_shield", 0)) > 0:
		damage = maxi(0, damage - 1)
		player_status_effects["berry_shield"] = int(player_status_effects["berry_shield"]) - 1
	if guarding:
		damage = int(floor(float(damage) * 0.5))
	_player_actor.take_damage(damage)
	player_hp = _player_actor.hp
	_play_player_hit_feedback()
	_update_hud()
	if _player_actor.is_defeated():
		resolve_defeat()


func _on_hud_command_selected(command_id: String) -> void:
	match command_id:
		"item":
			_choose_item_command()
		"gear":
			_choose_gear_command()
		_:
			choose_command(command_id)


func _on_item_selected(item_id: String) -> void:
	choose_command("item", {"item_id": item_id})


func _on_gear_selected(gear_id: String) -> void:
	choose_command("gear", {"weapon_id": gear_id})


func _on_weapon_timing_resolved(multiplier: float, grade: String) -> void:
	if phase == "weapon_timing":
		_resolve_active_attack(multiplier, grade)


func _on_weapon_timing_cancelled() -> void:
	if phase != "weapon_timing":
		return
	_state_machine.set_state("player_command")
	phase = _state_machine.get_state()
	_update_hud()


func _choose_item_command() -> bool:
	var game_state := _get_game_state()
	if game_state == null:
		return false
	var item_ids: Array[String] = []
	for key in game_state.inventory.keys():
		if int(game_state.inventory[key]) > 0:
			item_ids.append(str(key))
	item_ids.sort()
	if item_ids.is_empty():
		if _hud != null and _hud.has_method("show_message"):
			_hud.show_message("The bag is empty.")
		return false
	if _hud != null and _hud.has_method("show_item_menu"):
		var item_data := _load_json_dict("res://data/items/items.json")
		var entries: Array[Dictionary] = []
		for item_id in item_ids:
			var data: Dictionary = item_data.get(item_id, {})
			entries.append({
				"id": item_id,
				"label": "%s x%d" % [str(data.get("display_name", item_id)), int(game_state.inventory[item_id])],
				"description": str(data.get("description", ""))
			})
		_hud.show_item_menu(entries)
		return true
	return choose_command("item", {"item_id": item_ids[0]})


func _choose_gear_command() -> bool:
	var game_state := _get_game_state()
	if game_state == null:
		return false
	var gear_ids: Array[String] = []
	for key in game_state.gear.keys():
		if bool(game_state.gear[key]):
			gear_ids.append(str(key))
	gear_ids.sort()
	if gear_ids.is_empty():
		if _hud != null and _hud.has_method("show_message"):
			_hud.show_message("No weapon has been unlocked yet.")
		return false
	if _hud != null and _hud.has_method("show_gear_menu"):
		var gear_data := _load_json_dict("res://data/gear/gear.json")
		var entries: Array[Dictionary] = []
		for gear_id in gear_ids:
			var data: Dictionary = gear_data.get(gear_id, {})
			var equipped := " [EQUIPPED]" if str(game_state.current_weapon) == gear_id else ""
			entries.append({
				"id": gear_id,
				"label": "%s%s" % [str(data.get("display_name", gear_id)), equipped],
				"description": str(data.get("battle_use", ""))
			})
		_hud.show_gear_menu(entries)
		return true
	var current_index := gear_ids.find(str(game_state.current_weapon))
	return choose_command("gear", {"weapon_id": gear_ids[(current_index + 1) % gear_ids.size()]})


func _configure_soul_cursor() -> void:
	if _soul_cursor == null or not _soul_cursor.has_method("configure"):
		return
	var cursor_speed := 104.0 if difficulty_id == "shrububu" else 88.0
	var invulnerability := 1.1 if difficulty_id == "shrububu" else 0.32
	_soul_cursor.configure(cursor_speed, invulnerability, Rect2(6.0, 6.0, 180.0, 64.0))
	_soul_cursor.set_active(false, true)


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
		_pattern_cursor_by_phase.clear()
		if difficulty_id == "shrububu":
			phase_checkpoint_hp = player_hp
			automatic_recovery_used = false


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


func _resolve_difficulty_id() -> String:
	var game_state := _get_game_state()
	if game_state != null:
		return str(game_state.difficulty_id)
	return "shrububu"


func _get_difficulty_data(selected_difficulty_id: String, encounter: Dictionary = {}) -> Dictionary:
	var data := TuningLoader.get_difficulty(selected_difficulty_id)
	var all_overrides = encounter.get("difficulty_overrides", {})
	if typeof(all_overrides) == TYPE_DICTIONARY:
		var mode_overrides = all_overrides.get(selected_difficulty_id, {})
		if typeof(mode_overrides) == TYPE_DICTIONARY:
			data.merge(mode_overrides, true)
	return data


func _apply_difficulty_to_pattern(pattern_config: Dictionary) -> Dictionary:
	var adjusted := pattern_config.duplicate(true)
	var base_count := int(adjusted.get("count", TuningLoader.get_value(["battle", "bullet_count"], 4)))
	var base_speed := float(adjusted.get("speed", TuningLoader.get_value(["battle", "bullet_speed"], 42.0)))
	var base_telegraph := float(adjusted.get("telegraph_seconds", TuningLoader.get_value(["battle", "pattern_telegraph_seconds"], 0.6)))
	adjusted["count"] = TuningLoader.scale_int(base_count, float(difficulty_data.get("bullet_count_multiplier", 1.0)))
	adjusted["speed"] = TuningLoader.scale_float(base_speed, float(difficulty_data.get("bullet_speed_multiplier", 1.0)), 8.0)
	adjusted["telegraph_seconds"] = TuningLoader.scale_float(base_telegraph, float(difficulty_data.get("telegraph_multiplier", 1.0)), 0.1)
	adjusted["difficulty_id"] = difficulty_id
	return adjusted


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
