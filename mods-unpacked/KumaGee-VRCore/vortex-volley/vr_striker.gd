class_name VRStriker
extends Node

signal orb_hit(orb: GameOrb, new_velocity: Vector3)

const HIT_RADIUS: float = 0.3
const MIN_SWING_SPEED: float = 0.5
const STRIKE_SPEED: float = 7.0
const HIT_COOLDOWN: float = 0.3

var _left: XRController3D
var _right: XRController3D
var _left_prev: Vector3
var _right_prev: Vector3
var _initialized: bool = false
var _cooldown: float = 0.0

func setup(left: XRController3D, right: XRController3D) -> void:
	_left = left
	_right = right

func _process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)

	if not _initialized:
		if _left:
			_left_prev = _left.global_position
		if _right:
			_right_prev = _right.global_position
		_initialized = true
		return

	var left_vel := Vector3.ZERO
	var right_vel := Vector3.ZERO

	if _left:
		left_vel = (_left.global_position - _left_prev) / delta
		_left_prev = _left.global_position
	if _right:
		right_vel = (_right.global_position - _right_prev) / delta
		_right_prev = _right.global_position

	if _cooldown > 0.0:
		return

	for orb_node in get_tree().get_nodes_in_group("game_orbs"):
		var orb := orb_node as GameOrb
		if not is_instance_valid(orb):
			continue
		if orb.is_picked_up():
			continue
		if _left and _left.global_position.distance_to(orb.global_position) <= HIT_RADIUS:
			if left_vel.length() >= MIN_SWING_SPEED:
				var flat := Vector3(left_vel.x, 0.0, left_vel.z).normalized()
				if flat != Vector3.ZERO:
					orb_hit.emit(orb, flat * STRIKE_SPEED)
				_cooldown = HIT_COOLDOWN
				return
		if _right and _right.global_position.distance_to(orb.global_position) <= HIT_RADIUS:
			if right_vel.length() >= MIN_SWING_SPEED:
				var flat := Vector3(right_vel.x, 0.0, right_vel.z).normalized()
				if flat != Vector3.ZERO:
					orb_hit.emit(orb, flat * STRIKE_SPEED)
				_cooldown = HIT_COOLDOWN
				return
