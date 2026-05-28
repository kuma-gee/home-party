@tool
class_name VRMenuPanel
extends Node3D

signal resume_pressed
signal reset_space_pressed
signal settings_pressed
signal quit_pressed

@onready var _viewport_2d: XRToolsViewport2DIn3D = $Viewport2Din3D

var _button_resume: Button
var _button_reset_space: Button
var _button_settings: Button
var _button_quit: Button

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	var screen := _viewport_2d.get_node("Screen") as MeshInstance3D
	if screen:
		var mat := screen.get_surface_override_material(0) as StandardMaterial3D
		if mat:
			mat.render_priority = 100

	var ui: Control = _viewport_2d.get_scene_instance()
	if ui == null:
		push_error("VRMenuPanel: could not get viewport scene instance")
		return

	_button_resume = ui.get_node("MarginContainer/VBoxContainer/ResumeButton") as Button
	_button_reset_space = ui.get_node("MarginContainer/VBoxContainer/ResetSpaceButton") as Button
	_button_settings = ui.get_node("MarginContainer/VBoxContainer/SettingsButton") as Button
	_button_quit = ui.get_node("MarginContainer/VBoxContainer/HomeButton") as Button

	if _button_resume:
		_button_resume.pressed.connect(resume_pressed.emit)
	if _button_reset_space:
		_button_reset_space.pressed.connect(reset_space_pressed.emit)
	if _button_settings:
		_button_settings.pressed.connect(settings_pressed.emit)
	if _button_quit:
		_button_quit.pressed.connect(quit_pressed.emit)


func set_resume_visible(visible: bool) -> void:
	if _button_resume:
		_button_resume.visible = visible
