class_name VortexArena
extends Node3D

const RADIUS: float = 4.5
const HEIGHT: float = 2.5

func _ready() -> void:
	_build_floor()
	_build_wall()
	_build_center_platform()

func _build_floor() -> void:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = RADIUS
	mesh.bottom_radius = RADIUS
	mesh.height = 0.1
	mesh.radial_segments = 48
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.07, 0.04, 0.12)
	mat.roughness = 0.9
	mi.material_override = mat
	mi.position.y = -0.05
	add_child(mi)

	var sb := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(RADIUS * 2.2, 0.1, RADIUS * 2.2)
	col.shape = shape
	sb.add_child(col)
	add_child(sb)

func _build_wall() -> void:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = RADIUS
	mesh.bottom_radius = RADIUS
	mesh.height = HEIGHT
	mesh.radial_segments = 48
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.12, 0.35, 0.25)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.2, 0.65)
	mat.emission_energy_multiplier = 0.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_FRONT
	mi.material_override = mat
	mi.position.y = HEIGHT * 0.5
	add_child(mi)

func _build_center_platform() -> void:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.85
	mesh.bottom_radius = 0.85
	mesh.height = 0.12
	mesh.radial_segments = 24
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.08, 0.28)
	mat.emission_enabled = true
	mat.emission = Color(0.45, 0.2, 0.65)
	mat.emission_energy_multiplier = 0.45
	mi.material_override = mat
	mi.position.y = 0.06
	add_child(mi)
