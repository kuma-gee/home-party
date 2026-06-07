@tool
class_name DrawingClearSwatch
extends Area3D

signal cleared()

const HOLD_DURATION := 3.0

@export var progress_mesh: MeshInstance3D
@export var progress_viewport: SubViewport
@export var progress_ring: ColorRect

var _hold_progress := 0.0
var _is_held := false
var _shader_material: ShaderMaterial

func _ready():
	collision_layer = 0
	collision_layer = 1 << 9

	if progress_viewport and progress_ring:
		var shader := preload("res://shader/circle_inner.gdshader")
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("radius", 0.95)
		mat.set_shader_parameter("inner_radius", 0.55)
		mat.set_shader_parameter("fill", 0.0)
		mat.set_shader_parameter("blur", 0.005)
		mat.set_shader_parameter("bg_color", Color(0.2, 0.2, 0.2, 0.6))
		mat.set_shader_parameter("inner_color", Color.TRANSPARENT)
		mat.set_shader_parameter("outline_width", 0.0)
		progress_ring.material = mat
		progress_ring.color = Color(0.2, 0.8, 0.2)
		_shader_material = mat

	if progress_mesh and progress_viewport:
		var mesh_mat := StandardMaterial3D.new()
		mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh_mat.albedo_texture = progress_viewport.get_texture()
		mesh_mat.albedo_texture_force_srgb = true
		progress_mesh.material_override = mesh_mat

	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	_update_progress_visual()

func _on_area_entered(_area: Area3D):
	_is_held = true
	_hold_progress = 0.0

func _on_area_exited(_area: Area3D):
	_is_held = false
	_hold_progress = 0.0
	_update_progress_visual()

func _process(delta: float):
	if not _is_held:
		return
	_hold_progress += delta
	_update_progress_visual()
	if _hold_progress >= HOLD_DURATION:
		cleared.emit()
		_is_held = false
		_hold_progress = 0.0
		_update_progress_visual()

func _update_progress_visual():
	var t := clampf(_hold_progress / HOLD_DURATION, 0.0, 1.0)
	if _shader_material:
		_shader_material.set_shader_parameter("fill", t)
