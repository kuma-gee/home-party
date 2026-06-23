class_name SeekerTag
extends Node

## VR Seeker tag mechanic. On right trigger press, raycasts along the right-hand
## FunctionPointer forward vector and tags the nearest hider or NPC.

signal hider_tagged(hider: HiderCharacter)
signal wrong_tag(npc: NpcCharacter)

@export var max_range: float = 15.0
@export var cooldown_duration: float = 3.0
@export_flags_3d_physics var tag_collision_mask: int = 2

var function_pointer: XRToolsFunctionPointer
var controller: XRController3D
var cooldown_time: float = 0.0

var _cooldown: float = 0.0


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
		if _cooldown < 0.0:
			_cooldown = 0.0
	cooldown_time = _cooldown


func set_cooldown(seconds: float) -> void:
	_cooldown = maxf(_cooldown, seconds)


func is_on_cooldown() -> bool:
	return _cooldown > 0.0


func setup(p_controller: XRController3D, p_function_pointer: XRToolsFunctionPointer) -> void:
	controller = p_controller
	function_pointer = p_function_pointer
	if controller:
		controller.button_pressed.connect(_on_button_pressed)


func _on_button_pressed(button: String) -> void:
	if button != "trigger_click":
		return
	if is_on_cooldown() or not function_pointer:
		return
	_perform_tag()


func _perform_tag() -> void:
	var origin: Vector3 = function_pointer.global_position
	var forward: Vector3 = -function_pointer.global_transform.basis.z
	var end: Vector3 = origin + forward * max_range

	var space := get_viewport().get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, end, tag_collision_mask)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var result: Dictionary = space.intersect_ray(query)
	if result.is_empty():
		return

	var collider = result.collider
	if collider is HiderCharacter:
		_spawn_taser_beam(origin, result.position)
		hider_tagged.emit(collider as HiderCharacter)
	elif collider is NpcCharacter:
		_spawn_taser_beam(origin, result.position)
		wrong_tag.emit(collider as NpcCharacter)
		set_cooldown(cooldown_duration)


func _spawn_taser_beam(from: Vector3, to: Vector3) -> void:
	var mid := (from + to) * 0.5
	var diff := to - from
	var length := diff.length()
	if length < 0.001:
		return

	var beam := MeshInstance3D.new()
	beam.mesh = BoxMesh.new()
	(beam.mesh as BoxMesh).size = Vector3(0.02, 0.02, length)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 1.0, 1.0)
	mat.emission_energy_multiplier = 2.0
	mat.emission = Color(0.2, 0.8, 1.0, 1.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam.material_override = mat

	var parent := get_parent()
	if parent:
		parent.add_child(beam)
	else:
		add_child(beam)
	beam.global_position = mid
	beam.look_at(to, Vector3.UP)

	var tw := create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.25)
	tw.finished.connect(func() -> void:
		if is_instance_valid(beam):
			beam.queue_free()
	)
