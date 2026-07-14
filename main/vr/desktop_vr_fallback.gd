@tool
class_name DesktopVRFallback
extends XRToolsMovementProvider

## Desktop fallback locomotion for XR player when XR session inactive.

const MIN_INPUT_LENGTH := 0.1
const DESKTOP_CROUCH_KEY := &"desktop_crouch"
const LEFT_HAND_OFFSET := Vector3(-0.22, -0.28, -0.45)
const RIGHT_HAND_OFFSET := Vector3(0.22, -0.28, -0.45)
const RANGED_COLLIDER_ROTATION := Basis(Vector3.RIGHT, PI / 2.0)

@export var order: int = 4
@export var max_speed: float = 1.0
@export var mouse_sensitivity: float = 0.0025
@export_range(0.0, 89.0, 0.1) var max_pitch_degrees := 80.0
@export var crouch_height := 1.0
@export var pause_menu: Control
@export var settings_viewport: XRToolsViewport2DIn3D

var _pending_yaw := 0.0
var _pitch := 0.0
var _is_crouching := false
var _right_pickup_grip_pressed := false
var _left_mouse_pressed := false
var _right_pickup_toggle_requested := false
var _right_action_requested := false
var _right_action_pressed := false

@onready var _camera: XRCamera3D = XRHelpers.get_xr_camera(self)
@export var _left_hand: XRController3D
@export var _right_hand: XRController3D
@export var _left_pickup: XRToolsFunctionPickup
@export var _right_pickup: XRToolsFunctionPickup


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pitch = _camera.rotation.x


func _process(delta: float) -> void:
	if _should_block_input() and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if XRToolsStartXR.is_xr_active():
		return

	_poll_desktop_pickup_input()
	_update_desktop_hands()
	_process_desktop_pickup(_right_pickup, _right_pickup_grip_pressed, delta)
	if _right_pickup_toggle_requested:
		_right_pickup_toggle_requested = false
		_toggle_right_pickup()
	_set_action_pressed(_right_pickup, _right_action_requested)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		release_mouse_capture()
		return

	if _should_block_input():
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			capture_mouse()
			get_viewport().set_input_as_handled()
			return

		if event.button_index == MOUSE_BUTTON_RIGHT:
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
	_update_desktop_hands()


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


func _update_desktop_hands() -> void:
	if _camera == null:
		return

	if _left_hand != null:
		_left_hand.global_transform = _camera.global_transform.translated_local(LEFT_HAND_OFFSET)

	if _right_hand != null:
		_right_hand.global_transform = _camera.global_transform.translated_local(RIGHT_HAND_OFFSET)


func _poll_desktop_pickup_input() -> void:
	if _should_block_input():
		_left_mouse_pressed = false
		_right_pickup_grip_pressed = false
		_right_pickup_toggle_requested = false
		_right_action_requested = false
		return

	var left_pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var right_pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if left_pressed and not _left_mouse_pressed:
		_right_pickup_toggle_requested = true

	if (left_pressed and not _left_mouse_pressed) or (right_pressed and not _right_action_requested):
		capture_mouse()

	_left_mouse_pressed = left_pressed
	_right_action_requested = right_pressed


func _process_desktop_pickup(
		pickup: XRToolsFunctionPickup,
		grip_pressed: bool,
		delta: float) -> void:
	if pickup == null or not pickup.enabled:
		return

	_refresh_pickup_candidates(pickup)
	pickup._update_closest_object()
	_set_grip_pressed(pickup, grip_pressed)
	_update_pickup_velocity(pickup, delta)
	pickup._update_copied_collisions()


func _refresh_pickup_candidates(pickup: XRToolsFunctionPickup) -> void:
	pickup._object_in_grab_area = _query_pickup_grab_area(pickup)
	pickup._object_in_ranged_area = _query_pickup_ranged_area(pickup)


func _query_pickup_grab_area(pickup: XRToolsFunctionPickup) -> Array:
	var shape := SphereShape3D.new()
	shape.radius = pickup.grab_distance

	return _query_pickup_area(
		pickup,
		shape,
		pickup.global_transform,
		pickup.grab_collision_mask,
		Callable(self, "_is_grabbable_target"))


func _query_pickup_ranged_area(pickup: XRToolsFunctionPickup) -> Array:
	if not pickup.ranged_enable:
		return []

	var shape := CylinderShape3D.new()
	shape.radius = tan(deg_to_rad(pickup.ranged_angle)) * pickup.ranged_distance
	shape.height = pickup.ranged_distance

	var local_transform := Transform3D(RANGED_COLLIDER_ROTATION, Vector3(0.0, 0.0, -pickup.ranged_distance * 0.5))
	return _query_pickup_area(
		pickup,
		shape,
		pickup.global_transform * local_transform,
		pickup.ranged_collision_mask,
		Callable(self, "_is_ranged_grabbable_target"))


func _query_pickup_area(
		pickup: XRToolsFunctionPickup,
		shape: Shape3D,
		shape_transform: Transform3D,
		collision_mask: int,
		filter: Callable) -> Array:
	var world := pickup.get_world_3d()
	if world == null:
		return []

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = shape_transform
	query.collision_mask = collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var results := world.direct_space_state.intersect_shape(query)
	var targets := []
	for result in results:
		var target := result.get("collider") as Node3D
		if target == null or targets.has(target) or not filter.call(target):
			continue

		targets.push_back(target)

	return targets


func _is_grabbable_target(target: Node3D) -> bool:
	return target.has_method("pick_up")


func _is_ranged_grabbable_target(target: Node3D) -> bool:
	return "can_ranged_grab" in target and target.can_ranged_grab


func _update_pickup_velocity(pickup: XRToolsFunctionPickup, delta: float) -> void:
	if is_instance_valid(pickup.picked_up_object) \
			and pickup.picked_up_object.has_method("is_picked_up") \
			and pickup.picked_up_object.is_picked_up():
		pickup._velocity_averager.add_transform(delta, pickup.picked_up_object.global_transform)
	else:
		pickup._velocity_averager.add_transform(delta, pickup.global_transform)


func _toggle_right_pickup() -> void:
	if _right_pickup == null:
		return

	if is_instance_valid(_right_pickup.picked_up_object):
		_right_pickup.drop_object()
		_right_pickup_grip_pressed = false
		_right_pickup.grip_pressed = false
		return

	if _right_pickup.grip_pressed:
		_right_pickup_grip_pressed = false
		_set_grip_pressed(_right_pickup, false)

	_right_pickup_grip_pressed = true
	_set_grip_pressed(_right_pickup, true)
	if not is_instance_valid(_right_pickup.picked_up_object):
		_right_pickup_grip_pressed = false
		_right_pickup.grip_pressed = false


func _set_grip_pressed(pickup: XRToolsFunctionPickup, pressed: bool) -> void:
	if pickup == null or pickup.grip_pressed == pressed:
		return

	pickup.grip_pressed = pressed
	pickup._update_closest_object()

	if pressed:
		pickup._on_grip_pressed()
	else:
		pickup._on_grip_release()


func _set_action_pressed(pickup: XRToolsFunctionPickup, pressed: bool) -> void:
	if pickup == null or _right_action_pressed == pressed:
		return

	_right_action_pressed = pressed
	if pressed:
		pickup._on_button_pressed(pickup.action_button_action)
	else:
		pickup._on_button_released(pickup.action_button_action)
