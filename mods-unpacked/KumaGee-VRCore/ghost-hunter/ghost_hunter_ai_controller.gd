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
## Chance per retarget that the ghost heads to an active mischief task instead
## of a random wander spot; standing at the marker channels it to completion.
const TASK_PICK_CHANCE := 0.05

## Index used for the ghost/player-list color (PlayerManager has no entry for AI).
var color_idx: int = 0
var ghost: GhostPlayer = null
## Candidate wander targets inside the house (task/haunt spot positions).
var wander_targets: Array[Vector3] = []
## Returns the Hunter's world position, used for flee steering.
var hunter_position_getter: Callable = Callable()
## Returns the game's task array ([{pos, progress, duration, completed, active}]).
var tasks_getter: Callable = Callable()
## Task dicts already claimed by other AI ghosts (shared array owned by the
## AIManager) so several ghosts don't pile onto the same marker.
var claimed_tasks: Array = []

var _gameplay_active := false
var _target := Vector3.ZERO
var _retarget_timer := 0.0
var _stuck_time := 0.0
var _last_pos := Vector3.ZERO
## The task dict currently being channeled (empty when wandering).
var _task_target: Dictionary = {}

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
	release_task_claim()

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
	release_task_claim()

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
	# While channeling a task the ghost deliberately stands still at the
	# marker, so neither the retarget timer nor the stuck detector may move it.
	_retarget_timer -= delta
	if not _is_channelling_task():
		# Task completed or never picked: free the marker for other ghosts.
		release_task_claim()
		if _retarget_timer <= 0.0:
			_pick_new_target()
	var pos := ghost.global_position
	if pos.distance_squared_to(_last_pos) < STUCK_MOVE_EPS_SQ:
		if not _is_channelling_task():
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
	release_task_claim()
	_retarget_timer = randf_range(RETARGET_MIN, RETARGET_MAX)
	if randf() < TASK_PICK_CHANCE:
		var task := _random_active_task()
		if not task.is_empty():
			_task_target = task
			claimed_tasks.append(task)
			_target = task.pos
			return
	if not wander_targets.is_empty():
		_target = wander_targets[randi() % wander_targets.size()]
	else:
		_target = Vector3(randf_range(FALLBACK_MIN.x, FALLBACK_MAX.x), 0.0, randf_range(FALLBACK_MIN.y, FALLBACK_MAX.y))

## Random active, uncompleted, unclaimed mischief task; empty dict when none
## is available (every open marker is already claimed or none is active).
func _random_active_task() -> Dictionary:
	if not tasks_getter.is_valid():
		return {}
	var candidates: Array = []
	for task in tasks_getter.call():
		if task.get("active", false) and not task.get("completed", false) and not claimed_tasks.has(task):
			candidates.append(task)
	if candidates.is_empty():
		return {}
	return candidates[randi() % candidates.size()]

## Frees the currently claimed task marker, if any.
func release_task_claim() -> void:
	if not _task_target.is_empty():
		claimed_tasks.erase(_task_target)
		_task_target = {}

## True while the ghost is heading to / standing at a still-open task marker.
func _is_channelling_task() -> bool:
	return not _task_target.is_empty() and _task_target.get("active", false) and not _task_target.get("completed", false)
