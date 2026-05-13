@tool
extends GeometryInstance3D

@export var highlight_thickness := 1.1:
	set(v):
		highlight_thickness = v
		#_update_highlight(true)

@export var pickable: XRToolsPickable

func _ready() -> void:
	if pickable:
		pickable.highlight_updated.connect(func(_p, enable): _update_highlight(enable))
	_update_highlight(false)

func _update_highlight(enable: bool, mat = material_overlay):
	if mat is StandardMaterial3D and mat.next_pass:
		_update_highlight(enable, mat.next_pass)
	elif mat is ShaderMaterial:
		var shader = mat as ShaderMaterial
		var size = shader.get_shader_parameter("outline_size")
		if size != null:
			shader.set_shader_parameter("outline_size", highlight_thickness if enable else 1.0)
		elif shader.next_pass:
			_update_highlight(enable, shader.next_pass)
	elif material_override != null:
		_update_highlight(enable, material_override)
