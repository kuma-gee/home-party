class_name StrikerHand
extends Area3D

## Per-hand deflection bumper. Attached to an XRController3D. Detects orbs
## through physics overlap (Area3D), not manual distance checks. Always reflects
## an overlapping orb; swinging at or above MIN_SWING_SPEED makes the block active.

signal orb_hit(orb: GameOrb, reflect_dir: Vector3, active: bool)

const MIN_SWING_SPEED: float = 0.3
const COOLDOWN: float = 0.2

var _controller: Node3D
var _prev_position: Vector3
var _initialized: bool = false
var _cooldown: float = 0.0

func _ready() -> void:
	if get_parent() is Node3D:
		_controller = get_parent() as Node3D

func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if not _initialized:
		_prev_position = global_position
		_initialized = true
		return
	var swing_velocity := (global_position - _prev_position) / delta
	_prev_position = global_position
	if _cooldown > 0.0:
		return
	var active := swing_velocity.length() >= MIN_SWING_SPEED
	for body in get_overlapping_bodies():
		var orb := body as GameOrb
		if not orb or orb.is_resolved():
			continue
		var reflect_dir := _get_palm_direction()
		if reflect_dir != Vector3.ZERO:
			orb_hit.emit(orb, reflect_dir, active)
			_cooldown = COOLDOWN
			return

func _get_palm_direction() -> Vector3:
	if not _controller:
		return Vector3.ZERO
	var basis := _controller.global_transform.basis
	return Vector3(-basis.z.x, 0.0, -basis.z.z).normalized()
