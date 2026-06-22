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

	# Update value labels
	_update_master_label(_master_slider.value)
	_update_sfx_label(_sfx_slider.value)
	_update_music_label(_music_slider.value)
	_update_render_scale_label(_render_scale_slider.value)

	# Connect UI signals → UserSettings
	_master_slider.value_changed.connect(_on_master_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_render_scale_slider.value_changed.connect(_on_render_scale_changed)
	_antialiasing_toggle.toggled.connect(_on_antialiasing_toggled)
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
