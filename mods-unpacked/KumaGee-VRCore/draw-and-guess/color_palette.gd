@tool
class_name DrawingColorPalette
extends XRToolsPickable

@export var palette_mesh: MeshInstance3D
@onready var xr_tools_highlight_material: XRToolsHighlightMaterial = $XRToolsHighlightMaterial

var swatches: Array[DrawingColorSwatch] = []

func _ready():
	for child in get_children():
		if child is DrawingColorSwatch:
			swatches.append(child)
	
	if swatches.is_empty():
		return
	
	_update_palette_materials()
	xr_tools_highlight_material.save_surface_materials()

func _update_palette_materials():
	if not palette_mesh or not palette_mesh.mesh:
		return
	
	var surface_count = palette_mesh.get_surface_override_material_count()
	for i in min(swatches.size(), surface_count):
		var mat = StandardMaterial3D.new()
		mat.albedo_color = swatches[i].swatch_color
		mat.metallic = 0.3
		mat.roughness = 0.4
		palette_mesh.set_surface_override_material(i, mat)
