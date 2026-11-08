class_name GhostPlayer
extends CharacterBody3D

## GH-4: a phone-controlled ghost inside the haunted house. Moves with the
## phone joystick (screen up = world -Z, same mapping as the hide-and-seek
## hiders). GH-8 abilities on A/B: Phase Walk (B against a wall) and Haunt
## (A enter / A effect / B exit); A near the Hunter's vacuum is reserved for
## the GH-10 rescue. Visual meshes live on render layer 20, which only the
## desktop shared-screen cameras render, so the Hunter's VR camera cannot
## see ghosts with the naked eye. GH-6: the Flash Device briefly adds the
## Hunter's render layer (layer 1) plus a bright highlight while the ghost
## is revealed.

signal primary_action_pressed()
signal secondary_action_pressed()
signal revealed(ghost: GhostPlayer)
signal haunt_purged(ghost: GhostPlayer)
## GH-8: emitted when a phasing ghost enters a wall, so the shared screen can
## draw a ripple at that spot.
signal phase_rippled(pos: Vector3)

const MOVE_DEADZONE: float = 0.15
const LAYER_SHARED := 1 << 19 # layer 20: shared-screen cameras only
const LAYER_HUNTER := 1 # layer 1: also rendered by the Hunter's VR camera
const REVEAL_EMISSION_ENERGY := 2.5
## Height of the body center above the feet (matches the capsule/mesh offset
## in ghost_player.tscn).
const BODY_CENTER_HEIGHT := 0.6
## GH-8 Phase Walk / Haunt tuning.
const COLLISION_MASK_WORLD := 1
const PHASE_SPEED_MULT := 0.5
const HAUNT_RANGE := 1.5
const WALL_RAY_LENGTH := 0.6
const WALL_RAY_COUNT := 8
const SHIMMER_INTERVAL := 0.08
const SHIMMER_LIFETIME := 0.6
const SHIMMER_ALPHA := 0.3

@export var speed: float = 2.5
@export var acceleration: float = 10.0
@export var turn_speed: float = 12.0

var controller: ClientController

## GH-8 states: a phasing ghost (inside a wall) and a haunting ghost (inside
## an object) stay invisible to the Hunter even while flash-revealed.
var is_phasing := false
var haunted_object: Node3D = null

var _was_inside_wall := false
var _shimmer_timer := 0.0
var _ripple_emissions := 0
var _phase_shape: CapsuleShape3D

var color: Color = Color.WHITE:
	set(v):
		color = v
		_apply_color()

@onready var _body_mesh: MeshInstance3D = %BodyMesh

var _reveal_timer := 0.0
var _meshes: Array[MeshInstance3D] = []


func _ready() -> void:
	for child in get_children():
		if child is MeshInstance3D:
			_meshes.append(child)
	_phase_shape = CapsuleShape3D.new()
	_phase_shape.radius = 0.35
	_phase_shape.height = 1.2
	_apply_color()
	_apply_hunter_visibility()


func _process(delta: float) -> void:
	if _reveal_timer > 0.0:
		_reveal_timer = maxf(0.0, _reveal_timer - delta)
		if _reveal_timer == 0.0:
			_apply_hunter_visibility()


## Wires the owning phone/gamepad controller, assigns the player color, and
## places the ghost at the given interior spawn point.
func setup(p_controller: ClientController, p_color: Color, spawn_pos: Vector3) -> void:
	controller = p_controller
	color = p_color
	global_position = spawn_pos
	if controller:
		controller.primary_action_pressed.connect(_on_primary_action)
		controller.secondary_action_pressed.connect(_on_secondary_action)


func _exit_tree() -> void:
	if controller:
		if controller.primary_action_pressed.is_connected(_on_primary_action):
			controller.primary_action_pressed.disconnect(_on_primary_action)
		if controller.secondary_action_pressed.is_connected(_on_secondary_action):
			controller.secondary_action_pressed.disconnect(_on_secondary_action)
	if is_instance_valid(haunted_object) and haunted_object is HauntableObject:
		(haunted_object as HauntableObject).release()
	haunted_object = null


func _physics_process(delta: float) -> void:
	if is_haunting():
		# Frozen inside the possessed object.
		velocity = Vector3.ZERO
		return
	if not is_on_floor() and not is_phasing:
		velocity.y -= 9.8 * delta

	var input := _current_move_input()
	# GH-8: Phase Walk slows the ghost to 50% while it is inside a wall.
	var effective_speed := speed * PHASE_SPEED_MULT if is_phasing else speed
	var target_vel := Vector3(input.x, 0.0, input.y) * effective_speed
	velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta)

	var horiz := Vector3(velocity.x, 0.0, velocity.z)
	if horiz.length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(horiz.x, horiz.z), turn_speed * delta)

	move_and_slide()

	if is_phasing:
		_update_phasing(delta)


func _current_move_input() -> Vector2:
	# Poll the live joystick value so continuous input and release-to-zero work.
	var input: Vector2 = controller.get_move() if controller else Vector2.ZERO
	if input.length() < MOVE_DEADZONE:
		return Vector2.ZERO
	return input


## GH-6: marks the ghost revealed to the Hunter for [duration] seconds.
func set_revealed(duration: float) -> void:
	_reveal_timer = maxf(_reveal_timer, duration)
	_apply_hunter_visibility()
	revealed.emit(self)


func is_revealed() -> bool:
	return _reveal_timer > 0.0


func is_haunting() -> bool:
	return haunted_object != null


## Center of the ghost body in world space. Flash line-of-sight rays target
## this instead of the feet, which sit exactly on the floor plane.
func get_body_center() -> Vector3:
	return global_position + Vector3.UP * BODY_CENTER_HEIGHT


## GH-6 purge hook: the Flash Device forces the ghost out of the object it
## is possessing (GH-8) and places it at the object's position.
func purge_haunt() -> void:
	if haunted_object == null:
		return
	if is_instance_valid(haunted_object):
		global_position = haunted_object.global_position
		if haunted_object is HauntableObject:
			(haunted_object as HauntableObject).release()
	haunted_object = null
	haunt_purged.emit(self)
	_apply_hunter_visibility()


## GH-8 Phase Walk: B while against a wall. Disables wall collision so the
## ghost can move through walls at 50% speed with a shimmer trail. Returns
## false when not against a wall (or already phasing/haunting).
func start_phase_walk() -> bool:
	if is_phasing or is_haunting():
		return false
	if not _is_against_wall():
		return false
	is_phasing = true
	collision_mask = 0
	_was_inside_wall = _is_inside_wall()
	_shimmer_timer = 0.0
	_apply_hunter_visibility()
	return true


## GH-8: B while phasing cancels the Phase Walk and restores wall collision.
func stop_phase_walk() -> void:
	if not is_phasing:
		return
	is_phasing = false
	collision_mask = COLLISION_MASK_WORLD
	_apply_hunter_visibility()


## GH-8 Haunt: A near a hauntable object possesses it. Returns the possessed
## object, or null when nothing hauntable is in range.
func try_haunt() -> HauntableObject:
	if is_haunting() or is_phasing:
		return null
	var obj := _nearest_hauntable()
	if obj == null:
		return null
	_haunt(obj)
	return obj


## GH-8: A while haunting triggers the possessed object's effect.
func trigger_haunt_effect() -> void:
	if is_haunting() and is_instance_valid(haunted_object) and haunted_object is HauntableObject:
		(haunted_object as HauntableObject).trigger_effect()


## GH-8: B while haunting leaves the object voluntarily (ghost stays at the
## object's position).
func exit_haunt() -> void:
	if not is_haunting():
		return
	var obj := haunted_object
	haunted_object = null
	if is_instance_valid(obj) and obj is HauntableObject:
		(obj as HauntableObject).release()
	_apply_hunter_visibility()


func _haunt(obj: HauntableObject) -> void:
	haunted_object = obj
	global_position = obj.global_position
	velocity = Vector3.ZERO
	obj.possess(self)
	_apply_hunter_visibility()


func _nearest_hauntable() -> HauntableObject:
	var best: HauntableObject = null
	var best_dist := HAUNT_RANGE
	for node in get_tree().get_nodes_in_group(HauntableObject.GROUP_HAUNTABLE):
		if not node is HauntableObject or not is_instance_valid(node):
			continue
		var obj := node as HauntableObject
		if not obj.can_be_haunted():
			continue
		var dist := global_position.distance_to(obj.global_position)
		if dist <= best_dist:
			best = obj
			best_dist = dist
	return best


## Per-frame Phase Walk upkeep: shimmer trail puffs and a shared-screen
## ripple each time the ghost enters a wall.
func _update_phasing(delta: float) -> void:
	_shimmer_timer -= delta
	if _shimmer_timer <= 0.0:
		_shimmer_timer = SHIMMER_INTERVAL
		_spawn_shimmer()
	var inside := _is_inside_wall()
	if inside and not _was_inside_wall:
		_ripple_emissions += 1
		phase_rippled.emit(global_position)
	_was_inside_wall = inside


## True when a short horizontal ray from the body center hits a wall — i.e.
## the ghost is pressed against one and B can start Phase Walk.
func _is_against_wall() -> bool:
	var space := get_world_3d().direct_space_state
	var origin := get_body_center()
	for i in range(WALL_RAY_COUNT):
		var angle := TAU * float(i) / float(WALL_RAY_COUNT)
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		var query := PhysicsRayQueryParameters3D.create(origin, origin + dir * WALL_RAY_LENGTH, COLLISION_MASK_WORLD)
		var hit := space.intersect_ray(query)
		if not hit.is_empty() and _is_wall_body(hit.get("collider")):
			return true
	return false


## True while the body capsule overlaps a wall (only detectable while phasing,
## when wall collision is disabled).
func _is_inside_wall() -> bool:
	var space := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _phase_shape
	query.transform = global_transform.translated(Vector3.UP * BODY_CENTER_HEIGHT)
	query.collision_mask = COLLISION_MASK_WORLD
	for hit in space.intersect_shape(query):
		if _is_wall_body(hit.get("collider")):
			return true
	return false


## House walls (incl. door posts) are the StaticBody3D children of the house's
## "Walls" node; furniture and the floor live under other parents.
func _is_wall_body(collider: Object) -> bool:
	return collider is StaticBody3D and collider.get_parent() != null and collider.get_parent().name == "Walls"


## GH-8: faint shimmer puff left while phasing. Rendered on the Hunter's layer
## too, so he can spot a phasing ghost if looking closely.
func _spawn_shimmer() -> void:
	var puff := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	puff.mesh = sphere
	puff.layers = LAYER_SHARED | LAYER_HUNTER
	puff.cast_shadow = 0
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(color.r, color.g, color.b, SHIMMER_ALPHA)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.8
	puff.material_override = mat
	get_tree().root.add_child(puff)
	puff.global_position = get_body_center()
	var tw := puff.create_tween()
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, SHIMMER_LIFETIME)
	tw.parallel().tween_property(puff, "scale", Vector3.ONE * 0.4, SHIMMER_LIFETIME)
	tw.finished.connect(func() -> void:
		if is_instance_valid(puff):
			puff.queue_free()
	)


func is_visible_to_hunter() -> bool:
	return is_revealed() and not is_phasing and not is_haunting()


## Debug/E2E helper: teleport the ghost (the MCP bridge cannot pass Vector3).
## Also resets velocity so a falling ghost doesn't plummet right back down.
func debug_teleport(x: float, y: float, z: float) -> void:
	global_position = Vector3(x, y, z)
	velocity = Vector3.ZERO


## Debug/E2E helper: possess the hauntable object at [object_path] (full GH-8
## haunt path when the node is a HauntableObject).
func debug_set_haunting(object_path: String) -> void:
	var obj := get_node_or_null(object_path)
	if obj is HauntableObject and (obj as HauntableObject).can_be_haunted():
		_haunt(obj as HauntableObject)
	else:
		haunted_object = obj
		_apply_hunter_visibility()


## Debug/E2E helper: force the phase state without the wall check.
func debug_set_phasing(v: bool) -> void:
	if v == is_phasing:
		return
	if v:
		is_phasing = true
		collision_mask = 0
		_was_inside_wall = _is_inside_wall()
	else:
		is_phasing = false
		collision_mask = COLLISION_MASK_WORLD
	_apply_hunter_visibility()


## Debug/E2E helper: state snapshot as plain data for the MCP bridge.
func debug_state() -> Dictionary:
	return {
		"phasing": is_phasing,
		"haunting": is_haunting(),
		"haunted_path": haunted_object.get_path() if is_instance_valid(haunted_object) else "",
		"pos": [global_position.x, global_position.y, global_position.z],
		"collision_mask": collision_mask,
		"speed": speed,
		"inside_wall": _is_inside_wall(),
		"against_wall": _is_against_wall(),
		"ripple_emissions": _ripple_emissions,
	}


func _apply_color() -> void:
	if not _body_mesh:
		return
	var mat := _body_mesh.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = Color(color.r, color.g, color.b, 0.85)
		mat.emission = color
		mat.emission_energy_multiplier = 0.4


## Ghosts render on the shared-screen layer only, unless flash-revealed (and
## not phasing/haunting), in which case the Hunter's VR layer is added and
## the body gets a bright highlight. A haunting ghost is hidden everywhere —
## it is inside the possessed object (GH-8).
func _apply_hunter_visibility() -> void:
	var visible := is_visible_to_hunter()
	var shown := not is_haunting()
	for mesh in _meshes:
		mesh.visible = shown
		if visible:
			mesh.layers = LAYER_SHARED | LAYER_HUNTER
		else:
			mesh.layers = LAYER_SHARED
	if _body_mesh:
		var mat := _body_mesh.material_override as StandardMaterial3D
		if mat:
			if visible:
				mat.emission = color
				mat.emission_energy_multiplier = REVEAL_EMISSION_ENERGY
			else:
				_apply_color()


func _on_primary_action() -> void:
	# GH-8: A near a hauntable object possesses it; A while haunting triggers
	# the object's effect. (A near the Hunter's vacuum is reserved for the
	# GH-10 rescue.)
	if is_haunting():
		trigger_haunt_effect()
	else:
		try_haunt()
	primary_action_pressed.emit()


func _on_secondary_action() -> void:
	# GH-8: B while haunting exits the object; B while phasing cancels the
	# Phase Walk; B against a wall starts it.
	if is_haunting():
		exit_haunt()
	elif is_phasing:
		stop_phase_walk()
	else:
		start_phase_walk()
	secondary_action_pressed.emit()
