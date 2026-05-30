class_name AIClientController
extends ClientController

## Direction returned when the player is within this distance of the target.
const ARRIVED_SQ := 0.25  # 0.5 m threshold squared

## World-space position the AI agent should move toward.
var target: Vector3 = Vector3.ZERO

## Set by AISpawner after instantiation — avoids tree-walk every frame.
var _player: FPSPlayer = null

## Firepower level for this AI — increases when AI reaches gate
var firepower := 1

## Movement variation state
var _wander_angle: float = 0.0
var _wander_timer: float = 0.0
var _hesitation_timer: float = 0.0
var _is_hesitating: bool = false
var _last_move: Vector2 = Vector2.ZERO
var _move_smooth: Vector2 = Vector2.ZERO

func bind_player(player: FPSPlayer) -> void:
	clear_player()
	_player = player
	if not is_instance_valid(_player):
		return
	_player.game_client = self
	_player.firepower = firepower
	target = _player.position
	_wander_timer = randf_range(0.3, 0.8)
	_hesitation_timer = randf_range(2.0, 6.0)
	_last_move = Vector2.ZERO
	_move_smooth = Vector2.ZERO
	if not _player.reached_gate.is_connected(_on_player_reached_gate):
		_player.reached_gate.connect(_on_player_reached_gate)

func clear_player() -> void:
	if is_instance_valid(_player) and _player.reached_gate.is_connected(_on_player_reached_gate):
		_player.reached_gate.disconnect(_on_player_reached_gate)
	_player = null
	_is_hesitating = false
	_last_move = Vector2.ZERO
	_move_smooth = Vector2.ZERO

func _on_player_reached_gate() -> void:
	firepower += 1
	if is_instance_valid(_player):
		_player.firepower = firepower

func get_move() -> Vector2:
	if not is_instance_valid(_player):
		return Vector2.ZERO

	var diff := target - _player.global_position
	diff.y = 0.0
	var dist_sq := diff.length_squared()

	if dist_sq < ARRIVED_SQ:
		_move_smooth = _move_smooth.lerp(Vector2.ZERO, 0.2)
		return _move_smooth

	_update_hesitation()
	if _is_hesitating:
		_move_smooth = _move_smooth.lerp(Vector2.ZERO, 0.15)
		return _move_smooth

	var n := diff.normalized()
	var world_dir := Vector2(n.x, n.z)
	var up := _player.camera_up_axis
	var right := Vector2(-up.y, up.x)

	var wobble := _get_wobble(dist_sq)
	var adjusted_dir := world_dir + wobble
	adjusted_dir = adjusted_dir.normalized()

	var raw_move := Vector2(
		adjusted_dir.x * right.x - adjusted_dir.y * up.x,
		adjusted_dir.x * right.y - adjusted_dir.y * up.y
	)

	_move_smooth = _move_smooth.lerp(raw_move, 0.25)
	_last_move = _move_smooth
	return _move_smooth

func _update_hesitation() -> void:
	_hesitation_timer -= get_process_delta_time()
	if _hesitation_timer <= 0.0:
		if _is_hesitating:
			_is_hesitating = false
			_hesitation_timer = randf_range(3.0, 8.0)
		elif randf() < 0.15:
			_is_hesitating = true
			_hesitation_timer = randf_range(0.2, 0.6)
		else:
			_hesitation_timer = randf_range(2.0, 5.0)

func _get_wobble(dist_sq: float) -> Vector2:
	_wander_timer -= get_process_delta_time()
	if _wander_timer <= 0.0:
		_wander_angle += randf_range(-0.8, 0.8)
		_wander_timer = randf_range(0.2, 0.5)

	var wobble_strength := clampf(1.0 - dist_sq / 25.0, 0.0, 1.0) * 0.15
	return Vector2(cos(_wander_angle), sin(_wander_angle)) * wobble_strength

func trigger_skill() -> void:
	primary_action_pressed.emit()
