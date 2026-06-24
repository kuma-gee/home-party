@tool
class_name XRToolsHighlightMaterial
extends Node


## Mesh to highlight
@export var highlight_mesh_instance : NodePath

## Material to set
@export var highlight_material : Resource


var _original_materials = Array()
var _highlight_mesh_instance: MeshInstance3D


func is_xr_class(xr_name:  String) -> bool:
	return xr_name == "XRToolsHighlightMaterial"


func _ready():
	if highlight_mesh_instance:
		_highlight_mesh_instance = get_node(highlight_mesh_instance)
		save_surface_materials()

	get_parent().connect("highlight_updated", _on_highlight_updated)

func save_surface_materials():
	_original_materials.clear()
	
	if _highlight_mesh_instance:
		for i in range(0, _highlight_mesh_instance.get_surface_override_material_count()):
			_original_materials.push_back(_highlight_mesh_instance.get_surface_override_material(i))

func _on_highlight_updated(_pickable, enable: bool) -> void:
	# Set the materials
	if _highlight_mesh_instance:
		for i in range(0, _highlight_mesh_instance.get_surface_override_material_count()):
			if enable:
				_highlight_mesh_instance.set_surface_override_material(i, highlight_material)
			else:
				_highlight_mesh_instance.set_surface_override_material(i, _original_materials[i])


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	var parent := get_parent()
	if not parent or not parent.has_signal("highlight_updated"):
		warnings.append("Parent does not support highlighting")

	return warnings
