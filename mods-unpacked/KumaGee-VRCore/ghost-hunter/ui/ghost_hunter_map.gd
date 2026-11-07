class_name GhostHunterMap
extends Control

## GH-4 shared-screen map layer on the desktop canvas: draws every ghost as a
## colored marker at its position projected through the active camera (the
## house scene camera), and draws the Hunter marker only while the Hunter is
## within HUNTER_REVEAL_RANGE of any ghost. GH-6: when the Hunter fires the
## Flash Device, [method ping_hunter] forces the Hunter marker visible for
## FLASH_PING_DURATION in a bright color, revealing his location to ghosts.

const HUNTER_REVEAL_RANGE := 10.0
const GHOST_MARKER_RADIUS := 9.0
const HUNTER_MARKER_RADIUS := 12.0
const HUNTER_MARKER_COLOR := Color(0.07, 0.07, 0.1)
const MARKER_OUTLINE := Color(1, 1, 1, 0.9)
const FLASH_PING_DURATION := 4.0
const FLASH_PING_COLOR := Color(1.0, 0.95, 0.4)
const FLASH_PING_EXTRA_RADIUS := 4.0

var ghosts_getter: Callable
var hunter_position_getter: Callable

var _ping_position := Vector3.ZERO
var _ping_timer := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## GH-6: ping the Hunter's location on the shared screen when he flashes.
func ping_hunter(pos: Vector3, duration: float = FLASH_PING_DURATION) -> void:
	_ping_position = pos
	_ping_timer = duration


func is_ping_active() -> bool:
	return _ping_timer > 0.0


func set_ghosts_getter(getter: Callable) -> void:
	ghosts_getter = getter


func set_hunter_position_getter(getter: Callable) -> void:
	hunter_position_getter = getter


func _process(delta: float) -> void:
	if _ping_timer > 0.0:
		_ping_timer = maxf(0.0, _ping_timer - delta)
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
