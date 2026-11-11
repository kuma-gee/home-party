class_name StaticInterference
extends Node3D

## GH-11 Haunt Glitch: fullscreen static-noise overlay pinned in front of the
## VR camera (render layer 19, VR-only, same as the vignette). GhostHunter
## drives [method set_intensity] from the glitch level: 0 = off, short pulses
## from level 2, persistent at Full Haunt.

const LAYER_VR_ONLY := 262144 # render layer 19
const MESH_DISTANCE := -1.0

@export var intensity := 0.0:
	set(v):
		intensity = clampf(v, 0.0, 1.0)
		_apply_intensity()

var _mesh_instance: MeshInstance3D = null
var _material: ShaderMaterial = null


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_material = ShaderMaterial.new()
	_material.shader = preload("res://mods-unpacked/KumaGee-VRCore/ghost-hunter/ui/static_interference.gdshader")
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	quad.custom_aabb = AABB(Vector3(-1.0, -1.0, -0.1), Vector3(1.0, 1.0, 0.1))
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = quad
	_mesh_instance.cast_shadow = 0
	_mesh_instance.ignore_occlusion_culling = true
	_mesh_instance.layers = LAYER_VR_ONLY
	_mesh_instance.material_override = _material
	_mesh_instance.transform.origin.z = MESH_DISTANCE
	add_child(_mesh_instance)
	_apply_intensity()


func set_intensity(v: float) -> void:
	intensity = v


func get_intensity() -> float:
	return intensity


func _apply_intensity() -> void:
	if _material:
		_material.set_shader_parameter("intensity", intensity)
	if _mesh_instance:
		_mesh_instance.visible = intensity > 0.0
