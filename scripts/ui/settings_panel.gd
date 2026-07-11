extends Control

signal close_requested

var _syncing := false

@onready var _master: HSlider = $Dim/Panel/MasterSlider
@onready var _music: HSlider = $Dim/Panel/MusicSlider
@onready var _sfx: HSlider = $Dim/Panel/SfxSlider
@onready var _fullscreen: CheckButton = $Dim/Panel/FullscreenToggle
@onready var _screen_shake: CheckButton = $Dim/Panel/ShakeToggle
@onready var _flash_reduction: CheckButton = $Dim/Panel/FlashToggle
@onready var _objectives: CheckButton = $Dim/Panel/ObjectivesToggle
@onready var _high_contrast: CheckButton = $Dim/Panel/ContrastToggle
@onready var _text_speed: HSlider = $Dim/Panel/TextSpeedSlider


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_master.value_changed.connect(_set_float.bind("master_volume"))
	_music.value_changed.connect(_set_float.bind("music_volume"))
	_sfx.value_changed.connect(_set_float.bind("sfx_volume"))
	_fullscreen.toggled.connect(_set_bool.bind("fullscreen"))
	_screen_shake.toggled.connect(_set_bool.bind("screen_shake"))
	_flash_reduction.toggled.connect(_set_bool.bind("flash_reduction"))
	_objectives.toggled.connect(_set_bool.bind("show_objectives"))
	_high_contrast.toggled.connect(_set_bool.bind("high_contrast_bullets"))
	_text_speed.value_changed.connect(_set_text_speed)
	$Dim/Panel/ResetButton.pressed.connect(_reset_defaults)
	$Dim/Panel/BackButton.pressed.connect(close)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	_sync_from_manager()
	visible = true
	$Dim/Panel/BackButton.grab_focus.call_deferred()


func close() -> void:
	visible = false
	close_requested.emit()


func _sync_from_manager() -> void:
	var manager := get_node_or_null("/root/SettingsManager")
	if manager == null:
		return
	_syncing = true
	_master.value = float(manager.get_setting("master_volume", 0.85)) * 100.0
	_music.value = float(manager.get_setting("music_volume", 0.72)) * 100.0
	_sfx.value = float(manager.get_setting("sfx_volume", 0.9)) * 100.0
	_fullscreen.button_pressed = bool(manager.get_setting("fullscreen", false))
	_screen_shake.button_pressed = bool(manager.get_setting("screen_shake", true))
	_flash_reduction.button_pressed = bool(manager.get_setting("flash_reduction", false))
	_objectives.button_pressed = bool(manager.get_setting("show_objectives", true))
	_high_contrast.button_pressed = bool(manager.get_setting("high_contrast_bullets", false))
	_text_speed.value = float(manager.get_setting("text_speed", 1.0))
	_syncing = false


func _set_float(value: float, key: String) -> void:
	if _syncing:
		return
	var manager := get_node_or_null("/root/SettingsManager")
	if manager != null:
		manager.set_setting(key, value / 100.0)


func _set_bool(value: bool, key: String) -> void:
	if _syncing:
		return
	var manager := get_node_or_null("/root/SettingsManager")
	if manager != null:
		manager.set_setting(key, value)


func _set_text_speed(value: float) -> void:
	if _syncing:
		return
	var manager := get_node_or_null("/root/SettingsManager")
	if manager != null:
		manager.set_setting("text_speed", value)


func _reset_defaults() -> void:
	var manager := get_node_or_null("/root/SettingsManager")
	if manager != null:
		manager.reset_defaults()
	_sync_from_manager()
