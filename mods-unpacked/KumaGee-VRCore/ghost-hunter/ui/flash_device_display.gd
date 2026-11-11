class_name FlashDeviceDisplay
extends Control

## GH-5 (device-display variant): the screen on the back of the Flash Device
## (GH-6). While the Hunter holds the device, the screen shows the current
## house map (a live render of the loaded house variant through a copy of the
## shared screen's house camera, but without the ghost render layer), the
## last-known ghost interaction pings (haunt triggers / phase ripples /
## purges, fed through [method FlashDevice.add_interaction_ping]), the
## Hunter's own position, and the flash charge bar fed by
## [signal FlashDevice.recharge_changed]. Mischief-task markers are
## deliberately NOT drawn (ghost-only info per the GH-5 decision).
##
## The screen lives in a SubViewport child of the device (see
## flash_device.tscn): [member _map_camera] renders the world top-down and
## this Control draws the markers/charge on top of it.

const PING_TTL := 6.0
const PING_RADIUS := 5.0
const PING_KIND_COLORS := {
	"haunt": Color(1.0, 0.65, 0.25),
	"phase": Color(0.45, 0.8, 1.0),
	"purge": Color(1.0, 0.35, 0.35),
}
const PING_DEFAULT_COLOR := Color.WHITE
const HUNTER_MARKER_COLOR := Color.WHITE
const HUNTER_MARKER_RADIUS := 4.0
const CHARGE_BAR_HEIGHT := 14.0
const CHARGE_BAR_MARGIN := 6.0
const LABEL_FONT_SIZE := 12
## Fallback map pose when no house camera exists yet: straight top-down over
## the house floor (variants are ~24 x 18 m centered at the origin).
const FALLBACK_CAM_HEIGHT := 25.0
const FALLBACK_CAM_SIZE := 26.0
## GH-11: from this glitch level the screen flickers — the house map and the
## interaction pings drop out for short windows (the charge bar stays readable).
const GLITCH_FLICKER_LEVEL := 3
const FLICKER_PERIOD_MIN := 2.0
const FLICKER_PERIOD_MAX := 4.0
const FLICKER_DURATION := 0.45

var house_camera_getter: Callable
var hunter_position_getter: Callable

@onready var _map_camera: Camera3D = %MapCamera

var _pings: Array = [] ## [{pos: Vector3, age: float, kind: String}]
var _charge := 1.0 ## 1.0 = flash ready, 0.0 = just fired
## GH-11 Haunt Glitch state (pushed by FlashDevice.set_glitch_level).
var _glitch_level := 0
var _flicker_timer := 0.0
var _flicker_interval := FLICKER_PERIOD_MIN
var _flicker_remaining := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_house_camera_getter(getter: Callable) -> void:
	house_camera_getter = getter


func set_hunter_position_getter(getter: Callable) -> void:
	hunter_position_getter = getter


## Fed by [signal FlashDevice.recharge_changed] every frame.
func set_charge(remaining: float, total: float) -> void:
	_charge = 1.0 if total <= 0.0 else clampf(1.0 - remaining / total, 0.0, 1.0)
	queue_redraw()


func add_ping(pos: Vector3, kind: String = "") -> void:
	_pings.append({"pos": pos, "age": 0.0, "kind": kind})
	queue_redraw()


## GH-11: FlashDevice pushes the Haunt Glitch level here; from
## GLITCH_FLICKER_LEVEL the map and pings flicker (drop out briefly).
func set_glitch_level(level: int) -> void:
	_glitch_level = maxi(0, level)
	if _glitch_level < GLITCH_FLICKER_LEVEL and _flicker_remaining > 0.0:
		_flicker_remaining = 0.0
		_flicker_timer = 0.0


func is_flickering() -> bool:
	return _flicker_remaining > 0.0


## Debug/E2E helpers (script vars are not visible to the MCP bridge).
func debug_is_flickering() -> bool:
	return is_flickering()


func debug_glitch_level() -> int:
	return _glitch_level


## Debug/E2E helpers (script vars are not visible to the MCP bridge).
func get_ping_count() -> int:
	return _pings.size()


func get_charge() -> float:
	return _charge


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	for ping in _pings:
		ping.age += delta
	while not _pings.is_empty() and _pings[0].age > PING_TTL:
		_pings.pop_front()
	_update_flicker(delta)
	_sync_map_camera()
	queue_redraw()


## GH-11: at glitch level >= GLITCH_FLICKER_LEVEL the screen drops the map and
## pings for FLICKER_DURATION, repeating every random FLICKER_PERIOD_MIN..MAX s.
func _update_flicker(delta: float) -> void:
	if _glitch_level < GLITCH_FLICKER_LEVEL:
		return
	if _flicker_remaining > 0.0:
		_flicker_remaining -= delta
		if _flicker_remaining <= 0.0:
			_flicker_remaining = 0.0
			_flicker_interval = randf_range(FLICKER_PERIOD_MIN, FLICKER_PERIOD_MAX)
		return
	_flicker_timer += delta
	if _flicker_timer >= _flicker_interval:
		_flicker_timer = 0.0
		_flicker_remaining = FLICKER_DURATION


## The map camera is a child of this SubViewport, which is a child of the
## held device, so its transform would follow the hand; pin it to the house
## camera's pose every frame instead so the map matches the shared screen.
func _sync_map_camera() -> void:
	if house_camera_getter.is_valid():
		var house_cam := house_camera_getter.call() as Camera3D
		if house_cam != null:
			_map_camera.global_transform = house_cam.global_transform
			_map_camera.projection = house_cam.projection
			_map_camera.fov = house_cam.fov
			_map_camera.size = house_cam.size
			_map_camera.near = house_cam.near
			_map_camera.far = house_cam.far
			return
	_map_camera.global_transform = Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3(0.0, FALLBACK_CAM_HEIGHT, 0.001))
	_map_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_map_camera.size = FALLBACK_CAM_SIZE


func _draw() -> void:
	if is_flickering():
		# GH-11 flicker: the house map and the pings drop out; the charge bar
		# stays on screen so the Hunter still reads the flash state.
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.02, 0.03, 0.92))
	else:
		_draw_pings()
		_draw_hunter()
	_draw_charge_bar()


func _draw_pings() -> void:
	for ping in _pings:
		var alpha: float = 1.0 - ping.age / PING_TTL
		var color: Color = PING_KIND_COLORS.get(ping.kind, PING_DEFAULT_COLOR)
		var sp := _map_camera.unproject_position(ping.pos)
		draw_circle(sp, PING_RADIUS + (1.0 - alpha) * 10.0, Color(color.r, color.g, color.b, alpha * 0.3))
		draw_circle(sp, PING_RADIUS, Color(color.r, color.g, color.b, alpha))
		draw_arc(sp, PING_RADIUS, 0.0, TAU, 16, Color(1.0, 1.0, 1.0, alpha * 0.9), 1.5)


func _draw_hunter() -> void:
	if not hunter_position_getter.is_valid():
		return
	var hunter_pos: Vector3 = hunter_position_getter.call()
	var sp := _map_camera.unproject_position(hunter_pos)
	draw_circle(sp, HUNTER_MARKER_RADIUS, HUNTER_MARKER_COLOR)
	draw_arc(sp, HUNTER_MARKER_RADIUS, 0.0, TAU, 16, Color(0.0, 0.0, 0.0, 0.8), 1.5)


func _draw_charge_bar() -> void:
	var bar := Rect2(
		Vector2(CHARGE_BAR_MARGIN, size.y - CHARGE_BAR_HEIGHT - CHARGE_BAR_MARGIN),
		Vector2(size.x - 2.0 * CHARGE_BAR_MARGIN, CHARGE_BAR_HEIGHT))
	draw_rect(bar, Color(0.0, 0.0, 0.0, 0.55))
	var inner := Rect2(bar.position + Vector2(2.0, 2.0), Vector2((bar.size.x - 4.0) * _charge, bar.size.y - 4.0))
	draw_rect(inner, Color(1.0 - _charge, 0.25 + 0.75 * _charge, 0.2))
	var label := "FLASH READY" if _charge >= 1.0 else "FLASH %d%%" % int(_charge * 100.0)
	draw_string(ThemeDB.fallback_font, Vector2(CHARGE_BAR_MARGIN, bar.position.y - 3.0), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, LABEL_FONT_SIZE, Color(1.0, 1.0, 1.0, 0.9))
