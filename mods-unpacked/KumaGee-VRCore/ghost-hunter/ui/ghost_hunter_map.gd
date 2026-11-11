class_name GhostHunterMap
extends Control

## GH-4 shared-screen map layer on the desktop canvas: draws every ghost as a
## colored marker at its position projected through the active camera (the
## house scene camera), and draws the Hunter marker only while the Hunter is
## within HUNTER_REVEAL_RANGE of any ghost. GH-6: when the Hunter fires the
## Flash Device, [method ping_hunter] forces the Hunter marker visible for
## FLASH_PING_DURATION in a bright color, revealing his location to ghosts.
## GH-8: [method ping_ripple] draws a brief expanding ripple when a ghost
## phases through a wall. GH-9: draws the active mischief-task markers (ring
## plus channel-progress arc, fed through [method set_tasks_getter]) and a brief
## burst on task completion ([method ping_task_completed]). GH-10: a brief
## green burst on the shared screen when a captured ghost is rescued from the
## vacuum ([method ping_rescue]). Task markers are
## ghost-only info: this layer lives on the shared desktop screen and the
## Flash Device display never draws them.

const HUNTER_REVEAL_RANGE := 10.0
const GHOST_MARKER_RADIUS := 9.0
const HUNTER_MARKER_RADIUS := 12.0
const HUNTER_MARKER_COLOR := Color(0.07, 0.07, 0.1)
const MARKER_OUTLINE := Color(1, 1, 1, 0.9)
const FLASH_PING_DURATION := 4.0
const FLASH_PING_COLOR := Color(1.0, 0.95, 0.4)
const FLASH_PING_EXTRA_RADIUS := 4.0
const RIPPLE_DURATION := 1.5
const RIPPLE_START_RADIUS := 6.0
const RIPPLE_MAX_RADIUS := 30.0
const RIPPLE_COLOR := Color(0.45, 0.8, 1.0)
## GH-9 mischief-task markers.
const TASK_MARKER_RADIUS := 10.0
const TASK_MARKER_COLOR := Color(1.0, 0.55, 0.15)
const TASK_PROGRESS_COLOR := Color(1.0, 0.9, 0.35)
const TASK_BURST_DURATION := 1.5
const TASK_BURST_START_RADIUS := 8.0
const TASK_BURST_MAX_RADIUS := 34.0
const TASK_BURST_COLOR := Color(1.0, 0.85, 0.3)
## GH-10 rescue burst.
const RESCUE_PING_DURATION := 1.5
const RESCUE_PING_START_RADIUS := 8.0
const RESCUE_PING_MAX_RADIUS := 34.0
const RESCUE_PING_COLOR := Color(0.4, 1.0, 0.5)

var ghosts_getter: Callable
var hunter_position_getter: Callable
var tasks_getter: Callable

var _ping_position := Vector3.ZERO
var _ping_timer := 0.0
var _ripples: Array = [] ## [{pos: Vector3, age: float, duration: float}]
var _ripple_total := 0
var _task_bursts: Array = [] ## [{pos: Vector3, age: float, duration: float}]
var _task_burst_total := 0
var _rescue_pings: Array = [] ## [{pos: Vector3, age: float, duration: float}]
var _rescue_ping_total := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## GH-6: ping the Hunter's location on the shared screen when he flashes.
func ping_hunter(pos: Vector3, duration: float = FLASH_PING_DURATION) -> void:
	_ping_position = pos
	_ping_timer = duration


## GH-8: brief ripple on the shared screen when a ghost phases through a wall
## (visible to the other ghosts).
func ping_ripple(pos: Vector3, duration: float = RIPPLE_DURATION) -> void:
	_ripple_total += 1
	_ripples.append({"pos": pos, "age": 0.0, "duration": duration})
	queue_redraw()


## Debug/E2E helper.
func get_ripple_count() -> int:
	return _ripples.size()


## Debug/E2E helper: total ripples ever pinged (survives TTL expiry).
func debug_ripple_total() -> int:
	return _ripple_total


## GH-9: mischief-task markers are drawn from this getter (ghost-only info —
## the Flash Device display deliberately never draws them).
func set_tasks_getter(getter: Callable) -> void:
	tasks_getter = getter


## GH-9: brief burst on the shared screen when a mischief task completes.
func ping_task_completed(pos: Vector3, duration: float = TASK_BURST_DURATION) -> void:
	_task_burst_total += 1
	_task_bursts.append({"pos": pos, "age": 0.0, "duration": duration})
	queue_redraw()


## Debug/E2E helper.
func get_task_burst_count() -> int:
	return _task_bursts.size()


## Debug/E2E helper: total task-completion bursts ever pinged (survives TTL expiry).
func debug_task_burst_total() -> int:
	return _task_burst_total


## GH-10: brief green burst on the shared screen when a captured ghost is
## rescued from the vacuum.
func ping_rescue(pos: Vector3, duration: float = RESCUE_PING_DURATION) -> void:
	_rescue_ping_total += 1
	_rescue_pings.append({"pos": pos, "age": 0.0, "duration": duration})
	queue_redraw()


## Debug/E2E helper: total rescue pings ever drawn (survives TTL expiry).
func debug_rescue_ping_total() -> int:
	return _rescue_ping_total


func is_ping_active() -> bool:
	return _ping_timer > 0.0


func set_ghosts_getter(getter: Callable) -> void:
	ghosts_getter = getter


func set_hunter_position_getter(getter: Callable) -> void:
	hunter_position_getter = getter


func _process(delta: float) -> void:
	if _ping_timer > 0.0:
		_ping_timer = maxf(0.0, _ping_timer - delta)
	for ripple in _ripples:
		ripple.age += delta
	while not _ripples.is_empty() and _ripples[0].age > _ripples[0].duration:
		_ripples.pop_front()
	for burst in _task_bursts:
		burst.age += delta
	while not _task_bursts.is_empty() and _task_bursts[0].age > _task_bursts[0].duration:
		_task_bursts.pop_front()
	for ping in _rescue_pings:
		ping.age += delta
	while not _rescue_pings.is_empty() and _rescue_pings[0].age > _rescue_pings[0].duration:
		_rescue_pings.pop_front()
	queue_redraw()


func _draw() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return

	var ghosts: Array = ghosts_getter.call() if ghosts_getter.is_valid() else []
	for ghost in ghosts:
		if not is_instance_valid(ghost):
			continue
		var pos := cam.unproject_position(ghost.global_position)
		draw_circle(pos, GHOST_MARKER_RADIUS, ghost.color)
		draw_arc(pos, GHOST_MARKER_RADIUS, 0.0, TAU, 20, MARKER_OUTLINE, 2.0)

	# GH-8: phase-walk ripples.
	for ripple in _ripples:
		var t: float = clampf(ripple.age / ripple.duration, 0.0, 1.0)
		var alpha := 1.0 - t
		var sp := cam.unproject_position(ripple.pos)
		draw_arc(sp, lerpf(RIPPLE_START_RADIUS, RIPPLE_MAX_RADIUS, t), 0.0, TAU, 32,
			Color(RIPPLE_COLOR.r, RIPPLE_COLOR.g, RIPPLE_COLOR.b, alpha * 0.9), 2.0)

	# GH-9: mischief-task markers with channel progress; completed tasks clear
	# and pending (not yet spawned) tasks stay hidden until they activate.
	var tasks: Array = tasks_getter.call() if tasks_getter.is_valid() else []
	for task in tasks:
		if task.completed or not task.active:
			continue
		var sp := cam.unproject_position(task.pos)
		draw_arc(sp, TASK_MARKER_RADIUS, 0.0, TAU, 32, TASK_MARKER_COLOR, 2.5)
		var frac: float = clampf(task.progress / maxf(task.duration, 0.001), 0.0, 1.0)
		if frac > 0.0:
			draw_arc(sp, TASK_MARKER_RADIUS, -PI / 2.0, -PI / 2.0 + TAU * frac, 32, TASK_PROGRESS_COLOR, 4.0)
		draw_circle(sp, 3.0, TASK_MARKER_COLOR)

	# GH-9: task-completion bursts.
	for burst in _task_bursts:
		var t: float = clampf(burst.age / burst.duration, 0.0, 1.0)
		var alpha := 1.0 - t
		var sp := cam.unproject_position(burst.pos)
		draw_arc(sp, lerpf(TASK_BURST_START_RADIUS, TASK_BURST_MAX_RADIUS, t), 0.0, TAU, 32,
			Color(TASK_BURST_COLOR.r, TASK_BURST_COLOR.g, TASK_BURST_COLOR.b, alpha * 0.9), 2.5)
		draw_circle(sp, TASK_BURST_START_RADIUS * alpha + 3.0,
			Color(TASK_BURST_COLOR.r, TASK_BURST_COLOR.g, TASK_BURST_COLOR.b, alpha))

	# GH-10: rescue bursts.
	for ping in _rescue_pings:
		var t: float = clampf(ping.age / ping.duration, 0.0, 1.0)
		var alpha := 1.0 - t
		var sp := cam.unproject_position(ping.pos)
		draw_arc(sp, lerpf(RESCUE_PING_START_RADIUS, RESCUE_PING_MAX_RADIUS, t), 0.0, TAU, 32,
			Color(RESCUE_PING_COLOR.r, RESCUE_PING_COLOR.g, RESCUE_PING_COLOR.b, alpha * 0.9), 2.5)
		draw_circle(sp, RESCUE_PING_START_RADIUS * alpha + 3.0,
			Color(RESCUE_PING_COLOR.r, RESCUE_PING_COLOR.g, RESCUE_PING_COLOR.b, alpha))

	if not hunter_position_getter.is_valid():
		return
	var hunter_pos: Vector3 = hunter_position_getter.call()
	var pinged := _ping_timer > 0.0
	if pinged or _hunter_near_any_ghost(hunter_pos, ghosts):
		var marker_pos := _ping_position if pinged else hunter_pos
		var radius := HUNTER_MARKER_RADIUS + (FLASH_PING_EXTRA_RADIUS if pinged else 0.0)
		var color := FLASH_PING_COLOR if pinged else HUNTER_MARKER_COLOR
		var pos := cam.unproject_position(marker_pos)
		draw_circle(pos, radius, color)
		draw_arc(pos, radius, 0.0, TAU, 24, Color.WHITE, 2.5)


func _hunter_near_any_ghost(hunter_pos: Vector3, ghosts: Array) -> bool:
	var hunter_xz := Vector2(hunter_pos.x, hunter_pos.z)
	for ghost in ghosts:
		if not is_instance_valid(ghost):
			continue
		var ghost_xz := Vector2(ghost.global_position.x, ghost.global_position.z)
		if hunter_xz.distance_to(ghost_xz) <= HUNTER_REVEAL_RANGE:
			return true
	return false
