class_name GhostHunterAIController
extends ClientController

## AI-controlled ghost for Ghost Hunter. Simulates a phone player without a
## GameClient: while gameplay is active it returns wandering movement input so
## its GhostPlayer roams the house, steering between random interior spots and
## fleeing when the Hunter gets close.
##
## Mirrors VortexAIController: GhostPlayer drives itself from get_move() the
## same way a real phone's joystick does.

const ARRIVE_DIST_SQ := 0.5
const RETARGET_MIN := 2.0
const RETARGET_MAX := 6.0
const STUCK_TIME_LIMIT := 1.5
const STUCK_MOVE_EPS_SQ := 0.01
## Hunter distance at which the ghost turns away from him.
const FLEE_RANGE := 6.0
## Interior fallback (x/z) when the house exposes no wander markers.
const FALLBACK_MIN := Vector2(-10.0, -7.0)
const FALLBACK_MAX := Vector2(10.0, 7.0)

## Index used for the ghost/player-list color (PlayerManager has no entry for AI).
var color_idx: int = 0
var ghost: GhostPlayer = null
## Candidate wander targets inside the house (task/haunt spot positions).
var wander_targets: Array[Vector3] = []
## Returns the Hunter's world position, used for flee steering.
var hunter_position_getter: Callable = Callable()

var _gameplay_active := false
var _target := Vector3.ZERO
var _retarget_timer := 0.0
var _stuck_time := 0.0
var _last_pos := Vector3.ZERO

var logger := KumaLog.new("GhostHunterAIController")

## Called when this controller is assigned to a spawned ghost.
func bind_ghost(g: GhostPlayer) -> void:
	ghost = g
	_target = g.global_position
	_last_pos = g.global_position
	_retarget_timer = randf_range(RETARGET_MIN, RETARGET_MAX)

## Called when the ghost is freed; get_move() guards on validity regardless.
func unbind_ghost() -> void:
	ghost = null

func set_wander_targets(targets: Array[Vector3]) -> void:
	wander_targets = targets

## Enables AI wandering for the game phase.
func start_gameplay() -> void:
	_gameplay_active = true
	if is_instance_valid(ghost):
		_pick_new_target()

## Disables AI movement (prepare phase, round over).
func stop_gameplay() -> void:
	_gameplay_active = false

func get_color_idx() -> int:
	return color_idx

## GhostPlayer maps this straight onto world XZ (input.x -> X, input.y -> Z),
## same as the phone joystick mapping.
func get_move() -> Vector2:
	if not _gameplay_active or not is_instance_valid(ghost):
		return Vector2.ZERO
	var dir := _current_direction()
	if dir.length_squared() < 0.01:
		return Vector2.ZERO
	return Vector2(dir.x, dir.z).normalized()

func _process(delta: float) -> void:
	if not _gameplay_active or not is_instance_valid(ghost):
		return
	_retarget_timer -= delta
	if _retarget_timer <= 0.0:
		_pick_new_target()
	var pos := ghost.global_position
	if pos.distance_squared_to(_last_pos) < STUCK_MOVE_EPS_SQ:
		_stuck_time += delta
		if _stuck_time > STUCK_TIME_LIMIT:
			_pick_new_target()
			_stuck_time = 0.0
	else:
		_stuck_time = 0.0
	_last_pos = pos

func _current_direction() -> Vector3:
	var flee := _flee_direction()
	if flee.length_squared() > 0.0:
		return flee
	var diff := _target - ghost.global_position
	diff.y = 0.0
	if diff.length_squared() < ARRIVE_DIST_SQ:
		return Vector3.ZERO
	return diff.normalized()

## Steer directly away from the Hunter while he is inside FLEE_RANGE.
func _flee_direction() -> Vector3:
	if not hunter_position_getter.is_valid():
		return Vector3.ZERO
	var hunter_pos: Vector3 = hunter_position_getter.call()
	var diff := ghost.global_position - hunter_pos
	diff.y = 0.0
	if diff.length() > FLEE_RANGE:
		return Vector3.ZERO
	return diff.normalized()

func _pick_new_target() -> void:
	_retarget_timer = randf_range(RETARGET_MIN, RETARGET_MAX)
	if not wander_targets.is_empty():
		_target = wander_targets[randi() % wander_targets.size()]
	else:
		_target = Vector3(randf_range(FALLBACK_MIN.x, FALLBACK_MAX.x), 0.0, randf_range(FALLBACK_MIN.y, FALLBACK_MAX.y))
