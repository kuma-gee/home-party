class_name GamepadController
extends ClientController

var device_id: int
var player_name: String
var uuid: String

var _prev_primary := false
var _prev_secondary := false
var _prev_move := Vector2.ZERO

static func get_uuid_for_device(device: int) -> String:
	var id = Input.get_joy_guid(device)
	return "gamepad-%s" % id

func _process(_delta: float) -> void:
	var primary := Input.is_joy_button_pressed(device_id, JOY_BUTTON_A)
	if primary and not _prev_primary:
		primary_action_pressed.emit()
	_prev_primary = primary

	var secondary := Input.is_joy_button_pressed(device_id, JOY_BUTTON_B)
	if secondary and not _prev_secondary:
		secondary_action_pressed.emit()
	_prev_secondary = secondary

	var move := get_move()
	if move != Vector2.ZERO and _prev_move == Vector2.ZERO:
		moved.emit(move)
	_prev_move = move

func get_move() -> Vector2:
	var x := Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X)
	var y := Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y)
	var vec := Vector2(x, y)
	if vec.length() < 0.15:
		return Vector2.ZERO
	return vec

func get_display_data() -> Dictionary:
	return { "client_id": uuid, "name": player_name, "icon": "ea28" }
