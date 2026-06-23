class_name NpcCharacter
extends CharacterBody3D

## A museum visitor NPC. Walks a patrol circuit of waypoints, pauses at
## paintings (route-defined pause points), and scatters when the Seeker
## wrong-tags nearby.

enum State {
	PATROL,
	SCATTER,
	INTERACT,
}

@export var walk_speed: float = 1.0
@export var scatter_speed_multiplier: float = 1.5
@export var waypoint_tolerance: float = 0.3
@export var turn_speed: float = 6.0

var state: State = State.PATROL

var _route: Array[Marker3D] = []
var _waypoint_index: int = 0
var _scatter_dir: Vector3 = Vector3.ZERO
var _scatter_timer: float = 0.0
var _interact_timer: float = 0.0
var _interact_min: float = 0.0
var _interact_max: float = 0.0
var _idle_timer: float = 0.0


func _ready() -> void:
	# Randomize the first idle check window.
	_reset_idle_timer()


func _physics_process(delta: float) -> void:
	# Apply gravity so the NPC stays grounded on the floor.
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	match state:
		State.PATROL:
			_process_patrol(delta)
		State.SCATTER:
			_process_scatter(delta)
		State.INTERACT:
			_process_interact(delta)

	move_and_slide()


func assign_route(waypoints: Array[Marker3D]) -> void:
	_route = waypoints
	_waypoint_index = 0


func scatter_from(_origin: Vector3, duration: float) -> void:
	var angle := randf() * TAU
	_scatter_dir = Vector3(cos(angle), 0.0, sin(angle)).normalized()
	_scatter_timer = duration
	state = State.SCATTER


func set_interaction_interval(min_s: float, max_s: float) -> void:
	_interact_min = min_s
	_interact_max = max_s
	_reset_idle_timer()


func _process_patrol(delta: float) -> void:
	if _route.is_empty():
		return

	var target: Marker3D = _route[_waypoint_index]
	var to_target: Vector3 = target.global_position - global_position
	to_target.y = 0.0

	if to_target.length() < waypoint_tolerance:
		_arrive_at_waypoint(target)
		return

	var dir: Vector3 = to_target.normalized()
	velocity.x = dir.x * walk_speed
	velocity.z = dir.z * walk_speed
	_face_direction(dir, delta)

	# Occasionally idle to add crowd life when an interval is configured.
	if _interact_max > 0.0:
		_idle_timer -= delta
		if _idle_timer <= 0.0:
			_begin_interact(randf_range(1.0, 2.5))
			_reset_idle_timer()


func _arrive_at_waypoint(waypoint: Marker3D) -> void:
	var pause: float = float(waypoint.get_meta("pause_duration", 0.0))
	if pause > 0.0:
		_begin_interact(pause)
	else:
		_advance_waypoint()


func _begin_interact(duration: float) -> void:
	_interact_timer = duration
	velocity.x = 0.0
	velocity.z = 0.0
	state = State.INTERACT


func _process_interact(delta: float) -> void:
	_interact_timer -= delta
	if _interact_timer <= 0.0:
		_advance_waypoint()
		state = State.PATROL


func _advance_waypoint() -> void:
	if _route.is_empty():
		return
	_waypoint_index = (_waypoint_index + 1) % _route.size()


func _process_scatter(delta: float) -> void:
	_scatter_timer -= delta
	if _scatter_timer <= 0.0:
		state = State.PATROL
		return

	velocity.x = _scatter_dir.x * walk_speed * scatter_speed_multiplier
	velocity.z = _scatter_dir.z * walk_speed * scatter_speed_multiplier
	_face_direction(_scatter_dir, delta)


func _face_direction(dir: Vector3, delta: float) -> void:
	if dir.length_squared() < 0.001:
		return
	var target_yaw: float = atan2(dir.x, dir.z)
	var current_yaw: float = rotation.y
	rotation.y = lerp_angle(current_yaw, target_yaw, turn_speed * delta)


func _reset_idle_timer() -> void:
	if _interact_max > 0.0:
		_idle_timer = randf_range(_interact_min, _interact_max)
	else:
		_idle_timer = INF
