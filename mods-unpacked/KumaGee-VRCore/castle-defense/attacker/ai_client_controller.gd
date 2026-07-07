class_name AIClientController
extends ClientController

const ARRIVED_SQ := 0.25

# "Static World" (1) + "Wall Walking" (4) — the layers FPSPlayer itself collides with.
const AVOID_MASK := 9
const AVOID_RAY_LEN := 1.2
const STUCK_TIME_LIMIT := 1.0
const STUCK_MOVE_EPS_SQ := 0.01

var target: Vector3 = Vector3.ZERO
var _player: FPSPlayer = null
var firepower := 3

var _wall_side := 1.0
var _stuck_time := 0.0
var _last_pos := Vector3.ZERO

func bind_player(player: FPSPlayer) -> void:
	clear_player()
	_player = player
	if not is_instance_valid(_player):
		return
	_player.game_client = self
	_player.firepower = firepower
	target = _player.position
	_wall_side = 1.0 if randf() < 0.5 else -1.0
	_stuck_time = 0.0
	_last_pos = _player.global_position
	if not _player.reached_gate.is_connected(_on_player_reached_gate):
		_player.reached_gate.connect(_on_player_reached_gate)

func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	var pos := _player.global_position
	if pos.distance_squared_to(_last_pos) < STUCK_MOVE_EPS_SQ:
		_stuck_time += delta
		if _stuck_time > STUCK_TIME_LIMIT:
			_wall_side *= -1.0
			_stuck_time = 0.0
	else:
		_stuck_time = 0.0
	_last_pos = pos

func clear_player() -> void:
	if is_instance_valid(_player) and _player.reached_gate.is_connected(_on_player_reached_gate):
		_player.reached_gate.disconnect(_on_player_reached_gate)
	_player = null

func _on_player_reached_gate() -> void:
	firepower += 1
	if is_instance_valid(_player):
		_player.firepower = firepower

func get_move() -> Vector2:
	if not is_instance_valid(_player):
		return Vector2.ZERO

	var diff := target - _player.global_position
	diff.y = 0.0
	if diff.length_squared() < ARRIVED_SQ:
		return Vector2.ZERO

	var n := _avoid_walls(diff.normalized())
	var world_dir := Vector2(n.x, n.z)
	var up := _player.camera_up_axis
	var right := Vector2(-up.y, up.x)

	return Vector2(
		world_dir.x * right.x - world_dir.y * up.x,
		world_dir.x * right.y - world_dir.y * up.y
	)

func _avoid_walls(dir: Vector3) -> Vector3:
	var space := _player.get_world_3d().direct_space_state
	var origin := _player.global_position + Vector3.UP * 0.5
	var query := PhysicsRayQueryParameters3D.create(origin, origin + dir * AVOID_RAY_LEN)
	query.collision_mask = AVOID_MASK
	query.exclude = [_player.get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return dir

	var normal: Vector3 = hit.normal
	var slid := dir - normal * dir.dot(normal)
	slid.y = 0.0
	if slid.length_squared() < 0.01:
		# heading straight into the wall — pick a side to strafe along it
		slid = Vector3(-normal.z, 0.0, normal.x) * _wall_side
	return slid.normalized()

func trigger_skill() -> void:
	primary_action_pressed.emit()
