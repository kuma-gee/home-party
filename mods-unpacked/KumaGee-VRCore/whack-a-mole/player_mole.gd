class_name PlayerMole
extends Node

signal activate(idx: int)
signal moved(idx: int)

@export var max_mole := 6

var mole_index := 0
var game_client: GameClient

func _ready() -> void:
	game_client.input_received.connect(_input_received)

func _input_received(action: String, value):
	if action == "move" and value.length() > 0:
		_move_mole_index(value)
	elif action == "action" and value == true:
		activate.emit(mole_index)
	
func _move_mole_index(dir: Vector2):
	if dir.x > 0.5:
		mole_index = (mole_index + 1) % max_mole
	elif dir.x < -0.5:
		mole_index = (mole_index - 1 + max_mole) % max_mole
	elif dir.y > 0.5:
		mole_index = (mole_index + 3) % max_mole
	elif dir.y < -0.5:
		mole_index = (mole_index - 3 + max_mole) % max_mole

	moved.emit(mole_index)
