@tool
class_name DrawingColorPalette
extends XRToolsPickable

@export var palette_mesh: MeshInstance3D

var pen: VR3DPen = null:
	set(value):
		if pen and pen.color_changed.is_connected(_on_pen_color_changed):
			pen.color_changed.disconnect(_on_pen_color_changed)
		pen = value
		if pen:
			pen.color_changed.connect(_on_pen_color_changed)
			_on_pen_color_changed(pen.line_color)

var swatches: Array[DrawingColorSwatch] = []

func _ready():
	for child in get_children():
		if child is DrawingColorSwatch:
			swatches.append(child)
	
	if swatches.is_empty():
		return
	
	_update_palette_materials()

func _update_palette_materials():
	if not palette_mesh or not palette_mesh.mesh:
		return
	var surface_count = palette_mesh.mesh.get_surface_count()
	for i in min(swatches.size(), surface_count):
		var mat = StandardMaterial3D.new()
		mat.albedo_color = swatches[i].swatch_color
		mat.metallic = 0.3
		mat.roughness = 0.4
		palette_mesh.set_surface_override_material(i, mat)

func _on_pen_color_changed(_color: Color):
	pass
