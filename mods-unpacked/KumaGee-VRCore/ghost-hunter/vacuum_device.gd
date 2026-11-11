@tool
class_name VacuumDevice
extends XRToolsPickable

## GH-7 Ecto-Vacuum for the VR Hunter: a physical pickable (instances
## addons/godot-xr-tools/objects/pickable.tscn) that lives in a snap-zone
## holster on the player's left hip at waist level (group "gh_left_item", see
## ghost_hunter.gd). Grab it out of the holster with the grip — with no hand
## grab point the grab is "precise", so it can be held at any angle — and
## while held, holding the action button (trigger) sucks along the device's
## own forward axis. The suction is a horizontal cone with [member range] and
## a line-of-sight check; a fully revealed ghost inside the cone is captured
## after [member suck_duration] seconds of continuous suction
## ([signal ghost_captured]). Losing the target resets the progress. When
## released, the device snaps back into the holster (ghost_hunter.gd).
##
## GH-10 rescue: a ghost can also possess the vacuum itself (it joins
## [constant GROUP_VACUUM]) — A near it haunts it and holding A channels the
## release of one captured ghost; the Flash Device purge forces the ghost
## back out through GhostPlayer.purge_haunt.
##
## Deliberately no XRToolsGrabPointHand child: without a grab point the grab
## is "precise" (Grab captures the relative transform at pickup), so the
## device can be picked up and held at any angle.

signal suction_started(origin: Vector3)
signal suction_stopped()
signal ghost_captured(ghost: GhostPlayer)
signal suction_progress_changed(progress: float, total: float)

## GH-10: ghosts find the vacuum through this group to haunt it for a rescue.
const GROUP_VACUUM := "gh_vacuum"

@export var cone_angle_deg: float = 40.0
@export var range: float = 3.0
@export var suck_duration: float = 3.0
@export_flags_3d_physics var line_of_sight_mask: int = 1

var ghosts_getter: Callable

## GH-10: the ghost currently possessing the vacuum for a rescue (one at a
## time), mirroring HauntableObject.possessor.
var haunted_by: GhostPlayer = null

var _sucking := false
var _progress := 0.0
var _target: GhostPlayer = null
## Set by debug_suck_at so headless/E2E runs can suck from an explicit
## origin/forward without the device being held.
var _debug_suck := false
var _debug_origin := Vector3.ZERO
var _debug_forward := Vector3.FORWARD


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	add_to_group(GROUP_VACUUM)
	action_pressed.connect(_on_action_pressed)
	action_released.connect(_on_action_released)


## GH-10: only one ghost can haunt the vacuum at a time.
func can_be_haunted() -> bool:
	return haunted_by == null


## GH-10: GhostPlayer calls this when a ghost enters the vacuum.
func possess(ghost: GhostPlayer) -> void:
	if haunted_by != null:
		return
	haunted_by = ghost


## GH-10: GhostPlayer calls this when the ghost leaves (B) or is purged (flash).
func release() -> void:
	haunted_by = null


## Debug/E2E helpers (script vars are not visible to the MCP bridge).
func debug_is_haunted() -> bool:
	return haunted_by != null


func debug_haunted_by_path() -> String:
	return haunted_by.get_path() if is_instance_valid(haunted_by) else ""


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not _sucking:
		return
	if not _debug_suck and not is_picked_up():
		stop_suction()
		return
	var origin := global_position
	var forward := -global_transform.basis.z
	if _debug_suck:
		origin = _debug_origin
		forward = _debug_forward
	if not is_instance_valid(_target) or not _is_valid_target(_target, origin, forward):
		_target = _find_target(origin, forward)
		_progress = 0.0
	if not is_instance_valid(_target):
		suction_progress_changed.emit(0.0, suck_duration)
		return
	_progress += delta
	suction_progress_changed.emit(_progress, suck_duration)
	if _progress >= suck_duration:
		var captured := _target
		_reset_suction()
		ghost_captured.emit(captured)


func set_ghosts_getter(getter: Callable) -> void:
	ghosts_getter = getter


func is_sucking() -> bool:
	return _sucking


func get_suction_progress() -> float:
	return _progress


func get_target() -> GhostPlayer:
	return _target


## Starts suction from the device's current position along its own forward
## vector (the way it is held).
func start_suction() -> void:
	if _sucking:
		return
	_sucking = true
	_progress = 0.0
	_target = null
	suction_started.emit(global_position)


func stop_suction() -> void:
	if not _sucking:
		return
	_reset_suction()
	suction_stopped.emit()


## Debug/E2E helper (the MCP bridge cannot pass Vector3 arguments): sucks
## from an explicit origin/forward without needing the device to be held.
## Returns false when no valid target is in the cone.
func debug_suck_at(ox: float, oy: float, oz: float, fx: float, fy: float, fz: float) -> bool:
	var origin := Vector3(ox, oy, oz)
	var forward := Vector3(fx, fy, fz).normalized()
	var target := _find_target(origin, forward)
	if not is_instance_valid(target):
		return false
	_debug_suck = true
	_debug_origin = origin
	_debug_forward = forward
	_sucking = true
	_progress = 0.0
	_target = target
	suction_started.emit(origin)
	return true


## Debug/E2E helper: per-ghost cone diagnostics (distance, angle, LOS,
## visibility) for the given origin/forward, as plain data the MCP bridge can
## serialize.
func debug_cone_report(ox: float, oy: float, oz: float, fx: float, fy: float, fz: float) -> Array:
	var origin := Vector3(ox, oy, oz)
	var cone_dir := _horizontal(Vector3(fx, fy, fz))
	var half_cone := deg_to_rad(cone_angle_deg * 0.5)
	var report: Array = []
	if not ghosts_getter.is_valid():
		return [{"error": "no ghosts_getter"}]
	for ghost in ghosts_getter.call():
		if not ghost is GhostPlayer or not is_instance_valid(ghost):
			continue
		var gp := ghost as GhostPlayer
		var to_ghost: Vector3 = gp.global_position - origin
		to_ghost.y = 0.0
		var dist: float = to_ghost.length()
		var angle := 0.0
		if dist > 0.01:
			angle = cone_dir.angle_to(to_ghost.normalized())
		report.append({
			"pos": [gp.global_position.x, gp.global_position.y, gp.global_position.z],
			"dist": dist,
			"angle_deg": rad_to_deg(angle),
			"half_cone_deg": rad_to_deg(half_cone),
			"range": range,
			"los": _has_line_of_sight(origin, gp.get_body_center()),
			"visible_to_hunter": gp.is_visible_to_hunter(),
		})
	return report


func _on_action_pressed(_pickable) -> void:
	start_suction()


func _on_action_released(_pickable) -> void:
	stop_suction()


func _reset_suction() -> void:
	_sucking = false
	_progress = 0.0
	_target = null
	_debug_suck = false


## A ghost is a valid suction target only while fully visible to the Hunter
## (flash-revealed, not phasing, not haunting) and inside the cone with LOS.
func _is_valid_target(gp: GhostPlayer, origin: Vector3, forward: Vector3) -> bool:
	if not gp.is_visible_to_hunter():
		return false
	var to_ghost: Vector3 = gp.global_position - origin
	to_ghost.y = 0.0
	var dist: float = to_ghost.length()
	if dist > range or dist < 0.01:
		return false
	var half_cone := deg_to_rad(cone_angle_deg * 0.5)
	if _horizontal(forward).angle_to(to_ghost.normalized()) > half_cone:
		return false
	return _has_line_of_sight(origin, gp.get_body_center())


func _find_target(origin: Vector3, forward: Vector3) -> GhostPlayer:
	if not ghosts_getter.is_valid():
		return null
	var best: GhostPlayer = null
	var best_dist := range
	for ghost in ghosts_getter.call():
		if not ghost is GhostPlayer or not is_instance_valid(ghost):
			continue
		var gp := ghost as GhostPlayer
		if not _is_valid_target(gp, origin, forward):
			continue
		var dist: float = (gp.global_position - origin).length()
		if dist < best_dist:
			best = gp
			best_dist = dist
	return best


## Horizontal projection used for the cone check: the suction cone is
## horizontal, so pitching the device up/down must not narrow it. Falls back
## to the full vector when the device points straight up/down.
func _horizontal(v: Vector3) -> Vector3:
	var h := Vector3(v.x, 0.0, v.z)
	if h.length() < 0.01:
		return v.normalized()
	return h.normalized()


func _has_line_of_sight(origin: Vector3, target: Vector3) -> bool:
	# The house and ghosts always live in the root world (the XR SubViewport's
	# world can be unset in headless runs).
	var space := get_tree().root.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, target, line_of_sight_mask)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	return space.intersect_ray(query).is_empty()
