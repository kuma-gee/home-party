class_name HiderCharacter
extends CharacterBody3D

## A mobile-player hider in the museum. Visually identical to NPCs. Moves with
## the left joystick, performs context actions at interactive locations, and
## records a 3-second position trail for the Seeker's Scan mechanic.

signal found()

const TRAIL_SAMPLE_INTERVAL: float = 0.5
const TRAIL_MAX_SAMPLES: int = 6

@export var speed: float = 1.2
@export var acceleration: float = 8.0
@export var turn_speed: float = 10.0

var controller: ClientController
var player_name: String = ""
var is_found: bool = false
var frozen: bool = true

var _move_input: Vector2 = Vector2.ZERO
var _trail_samples: Array[Vector3] = []
var _trail_timer: float = 0.0
var _near_location: InteractiveLocation = null
var _interacting: bool = false
var _interact_timer: float = 0.0
var _mesh_base_scale: Vector3 = Vector3(0.45, 0.45, 0.45)

@onready var _character_mesh: Node3D = %CharacterMesh
@onready var _identity_marker: Label3D = %IdentityMarker

@export var animation: AnimationPlayer

func _ready() -> void:
	_set_identity_marker_visible(false)
	if _character_mesh:
		_mesh_base_scale = _character_mesh.scale
	
	var idx = PlayerManager.get_player_idx(controller.uuid)
	_identity_marker.text = "P%d" % idx
	_identity_marker.modulate = PlayerList.get_color(idx)


func reset_for_round(spawn_pos: Vector3) -> void:
	is_found = false
	_interacting = false
	_move_input = Vector2.ZERO
	velocity = Vector3.ZERO
	frozen = true
	collision_layer = 2
	collision_mask = 2
	_trail_samples.clear()
	if _character_mesh:
		_character_mesh.visible = true
		_character_mesh.scale = _mesh_base_scale
	global_position = spawn_pos
	_set_identity_marker_visible(false)


func _physics_process(delta: float) -> void:
	if is_found:
		return

	# Gravity keeps the hider grounded on the floor.
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	# Record trail samples for the Scan mechanic.
	_trail_timer -= delta
	if _trail_timer <= 0.0:
		_record_trail_sample()
		_trail_timer = TRAIL_SAMPLE_INTERVAL

	# Handle interaction timer (context action in progress).
	if _interacting:
		_interact_timer -= delta
		if _interact_timer <= 0.0:
			_interacting = false
		# Moving cancels the in-progress context action.
		if _current_move_input().length() > 0.2:
			_interacting = false
		# Standing still while performing the action.
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	if frozen:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	# Camera-relative movement (top-down camera, forward = -Z). Poll the live
	# joystick value so continuous/zero input is handled correctly.
	var input: Vector2 = _current_move_input()
	var target_vel := Vector3(input.x, 0.0, input.y) * speed
	velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta)
	
	var anim = "Walk_B" if velocity.length() > 0.01 else "Idle_A"
	animation.play(anim)

	var horiz := Vector3(velocity.x, 0.0, velocity.z)
	if horiz.length() > 0.05:
		_face_direction(horiz.normalized(), delta)

	move_and_slide()


func mark_found() -> void:
	if is_found:
		return
	is_found = true
	_move_input = Vector2.ZERO
	velocity = Vector3.ZERO
	_interacting = false
	_set_identity_marker_visible(false)

	# Disable collisions so the eliminated hider no longer blocks the crowd.
	collision_layer = 0
	collision_mask = 0

	# Brief elimination VFX: scale down then hide the mesh.
	if _character_mesh:
		var tw := create_tween()
		tw.tween_property(_character_mesh, "scale", Vector3.ZERO, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.finished.connect(func() -> void:
			if _character_mesh:
				_character_mesh.visible = false
		)

	found.emit()


func get_trail_samples() -> Array[Vector3]:
	return _trail_samples.duplicate()


func set_identity_marker_visible(v: bool) -> void:
	_set_identity_marker_visible(v)


func register_locations(locations: Array[InteractiveLocation]) -> void:
	for loc in locations:
		if not is_instance_valid(loc):
			continue
		loc.player_entered.connect(_on_location_entered.bind(loc))
		loc.player_exited.connect(_on_location_exited.bind(loc))


func _on_moved(dir: Vector2) -> void:
	if is_found:
		return
	_move_input = dir
	# Moving cancels any in-progress context action.
	if _interacting and dir.length() > 0.2:
		_interacting = false


func _current_move_input() -> Vector2:
	# Poll the live joystick value from the controller (handles continuous
	# input and release-to-zero); fall back to the moved-signal value.
	var input: Vector2 = controller.get_move() if controller else _move_input
	if input.length() < 0.15:
		return Vector2.ZERO
	return input


func _on_action_pressed() -> void:
	if is_found or frozen or _interacting:
		return
	if not is_instance_valid(_near_location):
		return
	_interacting = true
	_interact_timer = _near_location.duration
	_near_location.perform_action(self)


func _on_location_entered(character: CharacterBody3D, loc: InteractiveLocation) -> void:
	if character == self:
		_near_location = loc


func _on_location_exited(character: CharacterBody3D, loc: InteractiveLocation) -> void:
	if character == self and _near_location == loc:
		_near_location = null
		if _interacting:
			_interacting = false


func _record_trail_sample() -> void:
	_trail_samples.append(global_position)
	if _trail_samples.size() > TRAIL_MAX_SAMPLES:
		_trail_samples.pop_front()


func _face_direction(dir: Vector3, delta: float) -> void:
	var target_yaw: float = atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)


func _set_identity_marker_visible(v: bool) -> void:
	if _identity_marker:
		_identity_marker.visible = v
