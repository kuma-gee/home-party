class_name AIClientController
extends ClientController

const ARRIVED_SQ := 0.25

var target: Vector3 = Vector3.ZERO
var _player: FPSPlayer = null
var firepower := 1

func bind_player(player: FPSPlayer) -> void:
	clear_player()
	_player = player
	if not is_instance_valid(_player):
		return
	_player.game_client = self
	_player.firepower = firepower
	target = _player.position
	if not _player.reached_gate.is_connected(_on_player_reached_gate):
		_player.reached_gate.connect(_on_player_reached_gate)

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

	var n := diff.normalized()
	var world_dir := Vector2(n.x, n.z)
	var up := _player.camera_up_axis
	var right := Vector2(-up.y, up.x)

	return Vector2(
		world_dir.x * right.x - world_dir.y * up.x,
		world_dir.x * right.y - world_dir.y * up.y
	)

func trigger_skill() -> void:
	primary_action_pressed.emit()
