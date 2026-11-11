@tool
class_name FlashDevice
extends XRToolsPickable

## GH-6 Flash Device for the VR Hunter: a physical pickable (instances
## addons/godot-xr-tools/objects/pickable.tscn) that lives in a snap-zone
## holster on the player's right hip (see ghost_hunter.gd). Grab it out of the
## holster with the grip — with no hand grab point the grab is "precise", so
## it can be held at any angle — and while held, the right trigger fires a
## bright pulse along the device's own forward axis. When released, it snaps
## back into the holster. The pulse is a 45 deg cone with a 2 m range and a
## line-of-sight check. Ghosts inside the cone get a revealed highlight for
## ~4 s (GhostPlayer adds the Hunter's render layer to its meshes while
## revealed), a ghost haunting an object in range is purged out of it and
## then revealed (GH-8 hook), and every flash pings the Hunter's location to
## the shared screen (GH-4)
## through [signal flash_fired]. Refiring is blocked for the 3 s recharge;
## [signal recharge_changed] feeds the GH-5 device-display charge bar.
##
## GH-5 (device-display variant): the device carries a small screen (the
## [Sprite3D] showing the [DisplayViewport] SubViewport whose [%UI] draws
## the content) that the Hunter reads while holding the device — house map,
## last-known ghost interaction pings ([method add_interaction_ping]), his
## own position, and the flash charge. The sprite sits on render layer 19
## (VR-only UI layer) so the display's own map camera (cull_mask=1) never
## renders it — that would be a viewport sampling its own output texture.
##
## Deliberately no XRToolsGrabPointHand child: without a grab point the grab
## is "precise" (Grab captures the relative transform at pickup), so the
## device can be picked up and held at any angle.

signal flash_fired(origin: Vector3)
signal ghost_revealed(ghost: GhostPlayer)
signal haunt_purged(ghost: GhostPlayer)
signal recharge_changed(remaining: float, total: float)

const FLASH_LIGHT_ENERGY := 6.0
const FLASH_LIGHT_RANGE := 3.0
const FLASH_VISUAL_DURATION := 0.4

## GH-11 Haunt Glitch tuning: per glitch level the recharge grows by
## GLITCH_RECHARGE_PER_LEVEL (capped at GLITCH_RECHARGE_MAX) and the reveal
## shrinks by GLITCH_REVEAL_PER_LEVEL (floored at GLITCH_REVEAL_MIN); from
## GLITCH_FLICKER_LEVEL the device display flickers (map + pings drop out).
const GLITCH_RECHARGE_PER_LEVEL := 1.0
const GLITCH_RECHARGE_MAX := 6.0
const GLITCH_REVEAL_PER_LEVEL := 0.5
const GLITCH_REVEAL_MIN := 2.0
const GLITCH_FLICKER_LEVEL := 3

@export var cone_angle_deg: float = 45.0
@export var range: float = 2.0
@export var reveal_duration: float = 4.0
@export var recharge_duration: float = 3.0
@export_flags_3d_physics var line_of_sight_mask: int = 1

var ghosts_getter: Callable
var house_camera_getter: Callable
var hunter_position_getter: Callable
## GH-11: Haunt Glitch level (= completed mischief tasks), pushed by GhostHunter.
var glitch_level := 0

@onready var _display: FlashDeviceDisplay = %UI

var _cooldown := 0.0


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	action_pressed.connect(_on_action_pressed)
	recharge_changed.connect(_on_recharge_changed)
	_on_recharge_changed(_cooldown, get_effective_recharge())
	if house_camera_getter.is_valid():
		_display.set_house_camera_getter(house_camera_getter)
	if hunter_position_getter.is_valid():
		_display.set_hunter_position_getter(hunter_position_getter)


func set_house_camera_getter(getter: Callable) -> void:
	house_camera_getter = getter
	if _display:
		_display.set_house_camera_getter(getter)


func set_hunter_position_getter(getter: Callable) -> void:
	hunter_position_getter = getter
	if _display:
		_display.set_hunter_position_getter(getter)


## GH-5: a ghost interaction (haunt trigger, phase ripple, purge) pings the
## device display at the ghost's last known position.
func add_interaction_ping(pos: Vector3, kind: String = "") -> void:
	if _display:
		_display.add_ping(pos, kind)


func _on_recharge_changed(remaining: float, total: float) -> void:
	if _display:
		_display.set_charge(remaining, total)


## Debug/E2E helpers (the MCP bridge cannot pass Vector3 arguments).
func debug_add_ping(x: float, y: float, z: float, kind: String = "") -> void:
	add_interaction_ping(Vector3(x, y, z), kind)


func debug_display_ping_count() -> int:
	return _display.get_ping_count() if _display else -1


func debug_display_charge() -> float:
	return _display.get_charge() if _display else -1.0


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)
	recharge_changed.emit(_cooldown, get_effective_recharge())


## GH-11: GhostHunter pushes the current Haunt Glitch level here whenever a
## mischief task completes.
func set_glitch_level(level: int) -> void:
	glitch_level = maxi(0, level)
	if _display:
		_display.set_glitch_level(glitch_level)


## GH-11: recharge grows 3s + 1s per glitch level, capped at 6s.
func get_effective_recharge() -> float:
	return minf(recharge_duration + GLITCH_RECHARGE_PER_LEVEL * glitch_level, GLITCH_RECHARGE_MAX)


## GH-11: reveal shrinks 4s - 0.5s per glitch level, floored at 2s.
func get_effective_reveal() -> float:
	return maxf(reveal_duration - GLITCH_REVEAL_PER_LEVEL * glitch_level, GLITCH_REVEAL_MIN)


## Debug/E2E helper (script vars are not visible to the MCP bridge).
func debug_glitch() -> Dictionary:
	return {
		"level": glitch_level,
		"recharge": get_effective_recharge(),
		"reveal": get_effective_reveal(),
		"flickering": _display.debug_is_flickering() if _display else false,
	}


func set_ghosts_getter(getter: Callable) -> void:
	ghosts_getter = getter


func is_on_cooldown() -> bool:
	return _cooldown > 0.0


func is_ready() -> bool:
	return _cooldown <= 0.0


func get_recharge_remaining() -> float:
	return _cooldown


func _on_action_pressed(_pickable) -> void:
	fire()


## Fires the flash pulse from the device's position along its own forward
## vector (the way it is held). Returns false when the recharge blocks refiring.
func fire() -> bool:
	if is_on_cooldown():
		return false
	return _fire_from(global_position, -global_transform.basis.z)


## Debug/E2E helper (same pattern as BaseGame._debug_advance): like
## [method fire] but with an explicit origin/forward, because the MCP bridge
## cannot pass Vector3 arguments.
func debug_fire_at(ox: float, oy: float, oz: float, fx: float, fy: float, fz: float) -> bool:
	if is_on_cooldown():
		return false
	return _fire_from(Vector3(ox, oy, oz), Vector3(fx, fy, fz).normalized())


func _fire_from(origin: Vector3, forward: Vector3) -> bool:
	_perform_flash(origin, forward)
	_cooldown = get_effective_recharge()
	flash_fired.emit(origin)
	_spawn_flash_visual(origin, forward)
	return true


## Debug/E2E helper: per-ghost cone diagnostics (distance, angle, LOS) for the
## given origin/forward, as plain data the MCP bridge can serialize.
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
			"haunting": gp.is_haunting(),
			"phasing": gp.is_phasing,
		})
	return report


func _perform_flash(origin: Vector3, forward: Vector3) -> void:
	if not ghosts_getter.is_valid():
		return
	var half_cone := deg_to_rad(cone_angle_deg * 0.5)
	var cone_dir := _horizontal(forward)
	var ghosts: Array = ghosts_getter.call()
	for ghost in ghosts:
		if not ghost is GhostPlayer or not is_instance_valid(ghost):
			continue
		var gp := ghost as GhostPlayer
		var to_ghost: Vector3 = gp.global_position - origin
		to_ghost.y = 0.0
		var dist: float = to_ghost.length()
		if dist > range or dist < 0.01:
			continue
		if cone_dir.angle_to(to_ghost.normalized()) > half_cone:
			continue
		if not _has_line_of_sight(origin, gp.get_body_center()):
			continue
		if gp.is_haunting():
			# Purge the haunting ghost out of the object, then reveal it:
			# it is flung out into the open, so the Hunter sees it.
			gp.purge_haunt()
			haunt_purged.emit(gp)
			gp.set_revealed(get_effective_reveal())
			ghost_revealed.emit(gp)
			continue
		if gp.is_phasing:
			continue
		gp.set_revealed(get_effective_reveal())
		ghost_revealed.emit(gp)


## Horizontal projection used for the cone check: the pulse is a horizontal
## cone, so pitching the device up/down must not narrow it. Falls back to the
## full vector when the device points straight up/down.
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


func _spawn_flash_visual(origin: Vector3, forward: Vector3) -> void:
	var root := get_tree().root

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.98, 0.9)
	light.light_energy = FLASH_LIGHT_ENERGY
	light.omni_range = FLASH_LIGHT_RANGE
	root.add_child(light)
	light.global_position = origin
	var light_tw := light.create_tween()
	light_tw.tween_property(light, "light_energy", 0.0, FLASH_VISUAL_DURATION)
	light_tw.finished.connect(func() -> void:
		if is_instance_valid(light):
			light.queue_free()
	)

	var half_cone := deg_to_rad(cone_angle_deg * 0.5)
	var cone := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.02
	cyl.bottom_radius = tan(half_cone) * range
	cyl.height = range
	cyl.radial_segments = 24
	cone.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.98, 0.85, 0.35)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.98, 0.85)
	mat.emission_energy_multiplier = 2.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cone.material_override = mat
	cone.cast_shadow = 0
	root.add_child(cone)
	cone.global_position = origin + forward * (range * 0.5)
	cone.look_at(origin + forward * range, Vector3.UP)
	cone.rotate_object_local(Vector3.RIGHT, -PI / 2.0)
	cone.scale = Vector3(0.1, 0.1, 0.1)
	var cone_tw := cone.create_tween()
	cone_tw.parallel().tween_property(cone, "scale", Vector3.ONE, FLASH_VISUAL_DURATION)
	cone_tw.parallel().tween_property(mat, "albedo_color:a", 0.0, FLASH_VISUAL_DURATION)
	cone_tw.finished.connect(func() -> void:
		if is_instance_valid(cone):
			cone.queue_free()
	)
