class_name SettingsPanel
extends PanelContainer

signal back_pressed

@onready var _master_slider: HSlider = %MasterSlider
@onready var _master_value_label: Label = %MasterValue
@onready var _sfx_slider: HSlider = %SFXSlider
@onready var _sfx_value_label: Label = %SFXValue
@onready var _music_slider: HSlider = %MusicSlider
@onready var _music_value_label: Label = %MusicValue
@onready var _render_scale_slider: HSlider = %RenderScaleSlider
@onready var _render_scale_value_label: Label = %RenderScaleValue
@onready var _antialiasing_toggle: CheckBox = %AntiAliasingToggle
@onready var _smooth_movement_button: CheckBox = %SmoothMovementButton
@onready var _teleport_movement_button: CheckBox = %TeleportMovementButton
@onready var _vignette_toggle: CheckBox = %VignetteToggle
@onready var _snap_turn_toggle: CheckBox = %SnapTurnToggle
@onready var _player_height_slider: HSlider = %PlayerHeightSlider
@onready var _player_height_value_label: Label = %PlayerHeightValue
@onready var _seated_mode_toggle: CheckBox = %SeatedModeToggle
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	# Initialise from current UserSettings
	_master_slider.value = UserSettings.get_master_volume()
	_sfx_slider.value = UserSettings.get_sfx_volume()
	_music_slider.value = UserSettings.get_music_volume()
	_render_scale_slider.value = UserSettings.get_render_scale()
	_antialiasing_toggle.button_pressed = UserSettings.get_antialiasing()
	if UserSettings.get_movement_mode() == UserSettings.MovementMode.TELEPORT:
		_teleport_movement_button.button_pressed = true
	else:
		_smooth_movement_button.button_pressed = true
	_vignette_toggle.button_pressed = UserSettings.get_vignette_enabled()
	_snap_turn_toggle.button_pressed = XRToolsUserSettings.snap_turning
	_player_height_slider.value = XRToolsUserSettings.player_height
	_seated_mode_toggle.button_pressed = UserSettings.get_seated_mode()
	_update_seated_mode_label(_seated_mode_toggle.button_pressed)

	# Update value labels
	_update_master_label(_master_slider.value)
	_update_sfx_label(_sfx_slider.value)
	_update_music_label(_music_slider.value)
	_update_render_scale_label(_render_scale_slider.value)
	_update_player_height_label(_player_height_slider.value)

	# Connect UI signals → UserSettings
	_master_slider.value_changed.connect(_on_master_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_render_scale_slider.value_changed.connect(_on_render_scale_changed)
	_antialiasing_toggle.toggled.connect(_on_antialiasing_toggled)
	_smooth_movement_button.toggled.connect(_on_smooth_movement_toggled)
	_teleport_movement_button.toggled.connect(_on_teleport_movement_toggled)
	_vignette_toggle.toggled.connect(_on_vignette_toggled)
	_snap_turn_toggle.toggled.connect(_on_snap_turn_toggled)
	_player_height_slider.value_changed.connect(_on_player_height_changed)
	_seated_mode_toggle.toggled.connect(_on_seated_mode_toggled)
	_back_button.pressed.connect(back_pressed.emit)


# ------------------------------------------------------------------------------
# Slider handlers
# ------------------------------------------------------------------------------

func _on_master_changed(value: float) -> void:
	UserSettings.set_master_volume(value)
	_update_master_label(value)


func _update_master_label(value: float) -> void:
	_master_value_label.text = "%d%%" % (value * 100)


func _on_sfx_changed(value: float) -> void:
	UserSettings.set_sfx_volume(value)
	_update_sfx_label(value)


func _update_sfx_label(value: float) -> void:
	_sfx_value_label.text = "%d%%" % (value * 100)


func _on_music_changed(value: float) -> void:
	UserSettings.set_music_volume(value)
	_update_music_label(value)


func _update_music_label(value: float) -> void:
	_music_value_label.text = "%d%%" % (value * 100)


func _on_render_scale_changed(value: float) -> void:
	UserSettings.set_render_scale(value)
	_update_render_scale_label(value)


func _update_render_scale_label(value: float) -> void:
	_render_scale_value_label.text = "×%.1f" % value


func _on_antialiasing_toggled(enabled: bool) -> void:
	UserSettings.set_antialiasing(enabled)


func _on_smooth_movement_toggled(pressed: bool) -> void:
	if pressed:
		UserSettings.set_movement_mode(UserSettings.MovementMode.SMOOTH)


func _on_teleport_movement_toggled(pressed: bool) -> void:
	if pressed:
		UserSettings.set_movement_mode(UserSettings.MovementMode.TELEPORT)


func _on_vignette_toggled(enabled: bool) -> void:
	UserSettings.set_vignette_enabled(enabled)


func _on_snap_turn_toggled(enabled: bool) -> void:
	XRToolsUserSettings.snap_turning = enabled
	XRToolsUserSettings.save()


func _on_player_height_changed(value: float) -> void:
	XRToolsUserSettings.player_height = value
	XRToolsUserSettings.save()
	_update_player_height_label(value)


func _update_player_height_label(value: float) -> void:
	_player_height_value_label.text = "%.2fm" % value


func _on_seated_mode_toggled(enabled: bool) -> void:
	UserSettings.set_seated_mode(enabled)
	_update_seated_mode_label(enabled)


func _update_seated_mode_label(enabled: bool) -> void:
	_seated_mode_toggle.text = "On" if enabled else "Off"
