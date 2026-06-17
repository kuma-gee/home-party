class_name SettingsPanel
extends Node3D

signal back_pressed

@onready var _viewport_2d: XRToolsViewport2DIn3D = $Viewport2Din3D

# UI element references
var _master_slider: HSlider
var _master_value_label: Label
var _sfx_slider: HSlider
var _sfx_value_label: Label
var _music_slider: HSlider
var _music_value_label: Label
var _render_scale_slider: HSlider
var _render_scale_value_label: Label
var _antialiasing_toggle: CheckBox
var _back_button: Button


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	var ui: Control = _viewport_2d.get_scene_instance()
	if ui == null:
		push_error("SettingsPanel: could not get viewport scene instance")
		return

	var vbox := ui.get_node("MarginContainer/VBoxContainer") as VBoxContainer
	if vbox == null:
		push_error("SettingsPanel: could not find VBoxContainer in UI")
		return

	_master_slider = vbox.get_node("MasterRow/MasterSlider") as HSlider
	_master_value_label = vbox.get_node("MasterRow/MasterValue") as Label
	_sfx_slider = vbox.get_node("SFXRow/SFXSlider") as HSlider
	_sfx_value_label = vbox.get_node("SFXRow/SFXValue") as Label
	_music_slider = vbox.get_node("MusicRow/MusicSlider") as HSlider
	_music_value_label = vbox.get_node("MusicRow/MusicValue") as Label
	_render_scale_slider = vbox.get_node("RenderScaleRow/RenderScaleSlider") as HSlider
	_render_scale_value_label = vbox.get_node("RenderScaleRow/RenderScaleValue") as Label
	_antialiasing_toggle = vbox.get_node("AntiAliasingRow/AntiAliasingToggle") as CheckBox
	_back_button = vbox.get_node("BackButton") as Button

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
