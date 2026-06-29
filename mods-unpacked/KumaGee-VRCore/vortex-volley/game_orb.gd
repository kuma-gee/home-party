class_name GameOrb
extends XRToolsPickable

signal thrown(orb: GameOrb, release_velocity: Vector3)

const ORB_HEIGHT: float = 0.9
const ORB_RADIUS: float = 0.15

var velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	super()
	add_to_group("game_orbs")
	freeze = true
	gravity_scale = 0.0
	linear_damp = 0.0
	angular_damp = 10.0
	_build_mesh()
	_build_collision()
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)

func _build_mesh() -> void:
	if get_node_or_null("MeshInstance3D"):
		return
	var mi := MeshInstance3D.new()
	mi.name = "MeshInstance3D"
	var sphere := SphereMesh.new()
	sphere.radius = ORB_RADIUS
	sphere.height = ORB_RADIUS * 2.0
	mi.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.1)
	mat.emission_energy_multiplier = 3.0
	mi.material_override = mat
	add_child(mi)

func _build_collision() -> void:
	if get_node_or_null("CollisionShape3D"):
		return
	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var sphere := SphereShape3D.new()
	sphere.radius = ORB_RADIUS
	shape.shape = sphere
	add_child(shape)

func _on_picked_up(_orb: XRToolsPickable) -> void:
	velocity = Vector3.ZERO

func _on_dropped(_orb: XRToolsPickable) -> void:
	thrown.emit(self, linear_velocity)
