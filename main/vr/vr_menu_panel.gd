@tool
class_name VRMenuPanel
extends Node3D

signal resume_pressed
signal settings_pressed
signal quit_pressed

enum ButtonType {
	RESUME,
	SETTINGS,
	QUIT
}

@export var _button_resume: XRMenuButton
@export var _button_settings: XRMenuButton
@export var _button_quit: XRMenuButton

var _button_hover_states := {}
var _button_materials := {}

func _ready() -> void:
	if _button_resume:
		_button_resume.pointer_event.connect(_on_button_pointer_event.bind(ButtonType.RESUME))
		_setup_button_visuals(_button_resume)
	
	if _button_settings:
		_button_settings.pointer_event.connect(_on_button_pointer_event.bind(ButtonType.SETTINGS))
		_setup_button_visuals(_button_settings)
	
	if _button_quit:
		_button_quit.pointer_event.connect(_on_button_pointer_event.bind(ButtonType.QUIT))
		_setup_button_visuals(_button_quit)


func _setup_button_visuals(button: XRMenuButton) -> void:
	var mesh_instance := button.mesh
	if mesh_instance:
		var material := mesh_instance.get_surface_override_material(0)
		if not material:
			material = mesh_instance.mesh.surface_get_material(0)
		_button_materials[button] = material
	
	_button_hover_states[button] = false


# Handle pointer events on buttons
func _on_button_pointer_event(event: XRToolsPointerEvent, button_type: ButtonType) -> void:
	match event.event_type:
		XRToolsPointerEvent.Type.ENTERED:
			_on_button_hover_start(event.target)
		
		XRToolsPointerEvent.Type.EXITED:
			_on_button_hover_end(event.target)
		
		XRToolsPointerEvent.Type.PRESSED:
			_on_button_pressed(button_type)

func _on_button_hover_start(button: Node3D) -> void:
	_button_hover_states[button] = true
	
	var mesh_instance := button.mesh as MeshInstance3D
	if mesh_instance:
		var hover_material = _button_materials.get(button)
		if hover_material:
			var highlighted: Material = hover_material.duplicate()
			if highlighted is StandardMaterial3D:
				highlighted.emission_enabled = true
				highlighted.emission = Color(0.3, 0.6, 1.0)
				highlighted.emission_energy_multiplier = 2.0
			mesh_instance.set_surface_override_material(0, highlighted)

func _on_button_hover_end(button: Node3D) -> void:
	_button_hover_states[button] = false
	
	var mesh_instance := button.mesh as MeshInstance3D
	if mesh_instance:
		var original_material = _button_materials.get(button)
		if original_material:
			mesh_instance.set_surface_override_material(0, original_material)

func _on_button_pressed(button_type: ButtonType) -> void:
	match button_type:
		ButtonType.RESUME:
			resume_pressed.emit()
		ButtonType.SETTINGS:
			settings_pressed.emit()
		ButtonType.QUIT:
			quit_pressed.emit()
