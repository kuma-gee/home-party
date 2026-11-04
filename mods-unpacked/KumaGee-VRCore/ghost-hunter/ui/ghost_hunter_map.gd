class_name GhostHunterMap
extends Control

## GH-4 shared-screen map layer on the desktop canvas: draws every ghost as a
## colored marker at its position projected through the top-down camera, and
## draws the Hunter marker only while the Hunter is within
## HUNTER_REVEAL_RANGE of any ghost.

const HUNTER_REVEAL_RANGE := 10.0
const GHOST_MARKER_RADIUS := 9.0
const HUNTER_MARKER_RADIUS := 12.0
const HUNTER_MARKER_COLOR := Color(0.07, 0.07, 0.1)
const MARKER_OUTLINE := Color(1, 1, 1, 0.9)

var ghosts_getter: Callable
var hunter_position_getter: Callable


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_ghosts_getter(getter: Callable) -> void:
	ghosts_getter = getter


func set_hunter_position_getter(getter: Callable) -> void:
	hunter_position_getter = getter


func _process(_delta: float) -> void:
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
	if _hunter_near_any_ghost(hunter_pos, ghosts):
		var pos := cam.unproject_position(hunter_pos)
		draw_circle(pos, HUNTER_MARKER_RADIUS, HUNTER_MARKER_COLOR)
		draw_arc(pos, HUNTER_MARKER_RADIUS, 0.0, TAU, 24, Color.WHITE, 2.5)


func _hunter_near_any_ghost(hunter_pos: Vector3, ghosts: Array) -> bool:
	var hunter_xz := Vector2(hunter_pos.x, hunter_pos.z)
	for ghost in ghosts:
		if not is_instance_valid(ghost):
			continue
		var ghost_xz := Vector2(ghost.global_position.x, ghost.global_position.z)
		if hunter_xz.distance_to(ghost_xz) <= HUNTER_REVEAL_RANGE:
			return true
	return false
