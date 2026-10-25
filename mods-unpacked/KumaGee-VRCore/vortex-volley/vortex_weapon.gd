class_name VortexWeapon
extends XRToolsPickable

## Base class for the VR defender's held weapons (shield and saber). Tracks the
## swing speed of the held object and reports overlapping orbs to subclasses via
## _try_handle_orb, which emits the game signal for that weapon (orb_hit for the
## shield, orb_sliced for the saber).

enum Weapon { SHIELD, SABER }

signal orb_hit(orb: GameOrb, reflect_dir: Vector3, active: bool)
signal orb_sliced(orb: GameOrb, slice_dir: Vector3)

const MIN_SWING_SPEED: float = 0.3
const ORB_COLLISION_LAYER: int = 1024

## Area3D child used to detect overlapping orbs. Its mask is set to the orb layer
## in _ready so it keeps detecting while the pickable body is held (which clears
## the body's own collision mask).
@export var hit_area: Area3D

var _prev_position: Vector3
var _initialized: bool = false
var _cooldown: float = 0.0

func _ready() -> void:
	super()
	if hit_area:
		hit_area.collision_layer = 0
		hit_area.collision_mask = ORB_COLLISION_LAYER
		hit_area.monitoring = true

func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if not _initialized:
		_prev_position = global_position
		_initialized = true
		return
	var swing_velocity := (global_position - _prev_position) / delta
	_prev_position = global_position
	if _cooldown > 0.0 or not is_picked_up():
		return
	if not is_instance_valid(hit_area):
		return
	var active := swing_velocity.length() >= MIN_SWING_SPEED
	for body in hit_area.get_overlapping_bodies():
		var orb := body as GameOrb
		if not orb or orb.is_resolved():
			continue
		if _try_handle_orb(orb, active):
			return

## Subclass hook. Process one overlapping orb; return true to consume the hit.
func _try_handle_orb(_orb: GameOrb, _active: bool) -> bool:
	return false

func _start_cooldown(duration: float) -> void:
	_cooldown = duration

## Horizontal facing direction of the holding controller's palm.
func _get_palm_direction() -> Vector3:
	var controller := get_picked_up_by_controller()
	if not controller:
		return Vector3.ZERO
	var basis := controller.global_transform.basis
	return Vector3(-basis.z.x, 0.0, -basis.z.z).normalized()
