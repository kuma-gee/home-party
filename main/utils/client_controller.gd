class_name ClientController
extends Node

signal primary_action_pressed()
signal secondary_action_pressed()
signal moved(dir: Vector2)
signal active_changed()

var uuid: String
var active := true:
	set(v):
		active = v
		active_changed.emit()

## Held state of the primary (A) button, updated on every press/release
## message. Games poll this for hold-to-activate interactions (GH-10 rescue).
var _primary_held := false

func get_move() -> Vector2:
	return Vector2.ZERO

func is_primary_action_held() -> bool:
	return _primary_held

## Debug/E2E helper: force the A-button held state (the MCP bridge cannot
## press phone buttons).
func debug_set_primary_held(v: bool) -> void:
	_primary_held = v

func get_display_data() -> Dictionary:
	return {"client_id": uuid}

## Palette index used for this controller's color (player icon, paddle tint).
## AI controllers override this since they have no PlayerManager entry.
func get_color_idx() -> int:
	return PlayerManager.get_player_idx(uuid)

func reset():
	active = false

func initialize():
	active = true
