class_name AIClientController
extends ClientController

## Direction returned when the player is within this distance of the target.
const ARRIVED_SQ := 0.25  # 0.5 m threshold squared

## World-space position the AI agent should move toward.
var target: Vector3 = Vector3.ZERO

## Set by AISpawner after instantiation — avoids tree-walk every frame.
var _player: Node3D

func get_move() -> Vector2:
	if not is_instance_valid(_player):
		return Vector2.ZERO
	var diff := target - _player.global_position
	diff.y = 0.0
	if diff.length_squared() < ARRIVED_SQ:
		return Vector2.ZERO
	var n := diff.normalized()
	return Vector2(n.x, n.z)
