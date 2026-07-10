extends SceneTree

const LEVEL_01_SCENE := "res://scenes/levels/level_01.tscn"
const INTERACTION_SCRIPT := "res://scripts/overworld/interaction_area.gd"
const BATTLE_SCENE := "res://scenes/battle/battle_scene.tscn"
const BATTLE_HUD_SCENE := "res://scenes/ui/battle_hud.tscn"

const NAMED_LEVEL_01_INTERACTIONS := [
	"World/KfcDoor",
	"World/HarbourResident",
	"World/SheriffPoojan",
	"World/DivorceRecords",
	"World/SatyakiBoss",
	"World/SavePoint",
	"World/TransitionDoor"
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check_interaction_prompt_api(failures)
	_check_level_01_named_interactions(failures)
	_check_battle_scene_readability(failures)
	_check_battle_hud_readability(failures)
	_check_readme(failures)

	if failures.is_empty():
		print("PASS: Ishiville Pass 19 interaction/battle readability smoke test")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_interaction_prompt_api(failures: Array[String]) -> void:
	if not ResourceLoader.exists(INTERACTION_SCRIPT, "Script"):
		failures.append("Interaction script missing")
		return
	var interaction_script: Script = load(INTERACTION_SCRIPT)
	var interaction: Node = interaction_script.new()
	if not interaction.has_method("get_focus_prompt"):
		failures.append("InteractionArea must expose get_focus_prompt")
	if not interaction.has_method("get_display_name"):
		failures.append("InteractionArea must expose get_display_name")
	if interaction.get("display_name") == null:
		failures.append("InteractionArea must export display_name")
	interaction.free()


func _check_level_01_named_interactions(failures: Array[String]) -> void:
	var scene := load(LEVEL_01_SCENE)
	if scene == null:
		failures.append("Level 1 scene failed to load")
		return
	var level: Node = scene.instantiate()
	for node_path in NAMED_LEVEL_01_INTERACTIONS:
		var interaction := level.get_node_or_null(node_path)
		if interaction == null:
			failures.append("Level 1 missing interaction %s" % node_path)
			continue
		var display_name := str(interaction.get("display_name"))
		if display_name.is_empty():
			failures.append("%s needs display_name" % node_path)
		if interaction.has_method("get_focus_prompt"):
			var prompt := str(interaction.get_focus_prompt())
			if not prompt.contains(display_name):
				failures.append("%s focus prompt should include display name" % node_path)
			if not prompt.contains("E/Enter"):
				failures.append("%s focus prompt should include E/Enter" % node_path)
	level.free()


func _check_battle_scene_readability(failures: Array[String]) -> void:
	var scene := load(BATTLE_SCENE)
	if scene == null:
		failures.append("Battle scene failed to load")
		return
	var battle: Node = scene.instantiate()
	for node_path in [
		"BattleReadabilityLayer",
		"BattleReadabilityLayer/EnemyNameplate",
		"BattleReadabilityLayer/ArenaInstruction",
		"BattleReadabilityLayer/CommandHintStrip"
	]:
		if battle.get_node_or_null(node_path) == null:
			failures.append("Battle scene missing %s" % node_path)
	var arena_instruction := battle.get_node_or_null("BattleReadabilityLayer/ArenaInstruction") as Label
	if arena_instruction != null and not arena_instruction.text.contains("Dodge"):
		failures.append("ArenaInstruction must tell player to dodge")
	var hint_strip := battle.get_node_or_null("BattleReadabilityLayer/CommandHintStrip") as Label
	if hint_strip != null and not hint_strip.text.contains("Guard"):
		failures.append("CommandHintStrip must mention Guard")
	battle.free()


func _check_battle_hud_readability(failures: Array[String]) -> void:
	var scene := load(BATTLE_HUD_SCENE)
	if scene == null:
		failures.append("Battle HUD scene failed to load")
		return
	var hud: Node = scene.instantiate()
	for node_path in [
		"Panel/PlayerStatusLabel",
		"Panel/BossStatusLabel",
		"Panel/PhaseLabel",
		"Panel/CommandLabel"
	]:
		if hud.get_node_or_null(node_path) == null:
			failures.append("Battle HUD missing %s" % node_path)
	if not hud.has_method("format_phase_label"):
		failures.append("Battle HUD missing format_phase_label")
	if not hud.has_method("format_command_hint"):
		failures.append("Battle HUD missing format_command_hint")
	else:
		var hint := str(hud.format_command_hint("player_command"))
		for required_text in ["Act", "Item", "Gear", "Guard"]:
			if not hint.contains(required_text):
				failures.append("Player command hint missing %s" % required_text)
	hud.free()


func _check_readme(failures: Array[String]) -> void:
	var readme := FileAccess.get_file_as_string("res://README.md")
	for required_text in [
		"Pass 19 interaction and battle readability",
		"focus prompts",
		"battle nameplate",
		"command hints"
	]:
		if not readme.contains(required_text):
			failures.append("README missing Pass 19 note: %s" % required_text)
