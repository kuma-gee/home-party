class_name VortexAIController
extends ClientController

## AI-controlled mobile player for Vortex Volley. Simulates a phone player
## without a GameClient: returns movement input to slide its paddle along the
## arena wall and periodically emits a launch action.
##
## Mirrors AIClientController's role for castle-defense: it overrides
## ClientController.get_move() so DeflectorPlayer drives the paddle from AI
## input instead of network input.

const MOVE_GAIN := 0.5
const MAX_MOVE := 1.0
const LAUNCH_MIN_INTERVAL := 2.5
const LAUNCH_MAX_INTERVAL := 7.0

## Index used for the paddle/player-list color (PlayerManager has no entry for AI).
var color_idx: int = 0
var arena: VortexArena = null
var spawn: PlayerSpawn = null

var _gameplay_active := false
var _launch_timer := 0.0

var logger := KumaLog.new("VortexAIController")

## Called when this controller is assigned to a spawn slot.
func bind_spawn(s: PlayerSpawn, a: VortexArena) -> void:
	spawn = s
	arena = a
	_launch_timer = randf_range(LAUNCH_MIN_INTERVAL, LAUNCH_MAX_INTERVAL)

## Called when this controller is released from its spawn slot.
func unbind_spawn() -> void:
	spawn = null
	arena = null

## Enables AI movement/launching for the play phase.
func start_gameplay() -> void:
	_gameplay_active = true
	_launch_timer = randf_range(LAUNCH_MIN_INTERVAL, LAUNCH_MAX_INTERVAL)

## Disables AI movement/launching (prepare phase, round over).
func stop_gameplay() -> void:
	_gameplay_active = false

func get_color_idx() -> int:
	return color_idx

func _process(delta: float) -> void:
	if not _gameplay_active or not is_instance_valid(spawn):
		return
	_launch_timer -= delta
	if _launch_timer > 0.0:
		return
	_launch_timer = randf_range(LAUNCH_MIN_INTERVAL, LAUNCH_MAX_INTERVAL)
	if spawn.can_launch():
		secondary_action_pressed.emit()

## Steering input toward the nearest moving orb so the paddle stays in its path
## (blocking returns). Returns Vector2(input_x, 0) in the paddle's tangent space.
func get_move() -> Vector2:
	if not is_instance_valid(spawn) or not arena:
		return Vector2.ZERO
	var paddle := spawn.deflector
	var tangent := paddle._tangent()
	var side_center := paddle._side_center()
	var offset := (paddle.global_position - side_center).dot(tangent)
	var target := _target_offset(tangent, side_center)
	var delta := target - offset
	return Vector2(clampf(delta * MOVE_GAIN, -MAX_MOVE, MAX_MOVE), 0.0)

func _target_offset(tangent: Vector3, side_center: Vector3) -> float:
	var best_orb: GameOrb = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("game_orbs"):
		var orb := node as GameOrb
		if not orb or orb.is_resolved():
			continue
		if orb.velocity.length_squared() < 0.01:
			continue
		var d := orb.global_position.distance_squared_to(spawn.deflector.global_position)
		if d < best_dist:
			best_dist = d
			best_orb = orb
	if best_orb == null:
		return 0.0
	return (best_orb.global_position - side_center).dot(tangent)
