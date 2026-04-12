extends RayCast3D

@export var pickupable: XRToolsPickable
@onready var firerate: Timer = $Firerate

var _laser_mesh: ImmediateMesh
var _laser_material: StandardMaterial3D
var _laser_instance: MeshInstance3D

func _ready() -> void:
	pickupable.action_pressed.connect(_on_action_pressed)
	_setup_laser()
	_update_laser()

func _process(_delta: float) -> void:
	_update_laser()

func _setup_laser() -> void:
	_laser_mesh = ImmediateMesh.new()
	_laser_material = StandardMaterial3D.new()
	_laser_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_laser_material.albedo_color = Color(1.0, 0.1, 0.1, 1.0)
	_laser_material.emission_enabled = true
	_laser_material.emission = Color(1.0, 0.1, 0.1)
	_laser_material.emission_energy_multiplier = 2.0

	_laser_instance = MeshInstance3D.new()
	_laser_instance.mesh = _laser_mesh
	_laser_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_laser_instance)

func _update_laser() -> void:
	if _laser_mesh == null:
		return

	_laser_mesh.clear_surfaces()
	_laser_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _laser_material)
	_laser_mesh.surface_add_vertex(Vector3.ZERO)
	_laser_mesh.surface_add_vertex(target_position)
	_laser_mesh.surface_end()

func _on_action_pressed(_p: XRToolsPickable) -> void:
	if not firerate.is_stopped():
		return

	if is_colliding():
		var collider = get_collider()
		if collider is HurtBox:
			collider.hit(1)
	
	firerate.start()
