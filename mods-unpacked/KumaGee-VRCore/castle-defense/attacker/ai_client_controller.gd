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
	return Vector2(n.x, n.z)

func trigger_skill() -> void:
	primary_action_pressed.emit()
