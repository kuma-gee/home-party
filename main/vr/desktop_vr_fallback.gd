@tool
class_name DesktopVRFallback
extends XRToolsMovementProvider

## Desktop fallback locomotion for XR player when XR session inactive.

const MIN_INPUT_LENGTH := 0.1
const DESKTOP_CROUCH_KEY := &"desktop_crouch"

@export var order: int = 4
@export var max_speed: float = 1.0
@export var mouse_sensitivity: float = 0.0025
@export_range(0.0, 89.0, 0.1) var max_pitch_degrees := 80.0
@export var crouch_height := 1.0
@export var pause_menu: Control
@export var settings_viewport: Node3D

var _pending_yaw := 0.0
var _pitch := 0.0
var _is_crouching := false

@onready var _camera: XRCamera3D = XRHelpers.get_xr_camera(self)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pitch = _camera.rotation.x


func _process(_delta: float) -> void:
	if _should_block_input() and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		release_mouse_capture()
		return

	if _should_block_input():
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			capture_mouse()
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		apply_mouse_motion(event.relative)
		get_viewport().set_input_as_handled()


func capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func release_mouse_capture() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func apply_mouse_motion(relative: Vector2) -> void:
	_pending_yaw += relative.x * mouse_sensitivity
	_pitch = clamp(
		_pitch - relative.y * mouse_sensitivity,
		deg_to_rad(-max_pitch_degrees),
		deg_to_rad(max_pitch_degrees)
	)
	_camera.rotation.x = _pitch


func physics_movement(_delta: float, player_body: XRToolsPlayerBody, _disabled: bool):
	if _should_block_input():
		player_body.override_player_height(self)
		return

	if Input.is_action_just_pressed(DESKTOP_CROUCH_KEY):
		_is_crouching = !_is_crouching

	if _is_crouching:
		player_body.override_player_height(self, crouch_height)
	else:
		player_body.override_player_height(self)

	if absf(_pending_yaw) > 0.0:
		player_body.rotate_player(_pending_yaw)
		_pending_yaw = 0.0

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input.length() < MIN_INPUT_LENGTH:
		return

	player_body.ground_control_velocity += Vector2(input.x, -input.y) * max_speed

	var length := player_body.ground_control_velocity.length()
	if length > max_speed:
		player_body.ground_control_velocity *= max_speed / length


func _should_block_input() -> bool:
	var pause_open := pause_menu != null and pause_menu.visible
	var settings_open := settings_viewport != null and settings_viewport.visible
	return XRToolsStartXR.is_xr_active() or pause_open or settings_open
