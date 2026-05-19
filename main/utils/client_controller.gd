class_name ClientController
extends Node

signal primary_action_pressed()
signal secondary_action_pressed()
signal moved(dir: Vector2)

var active := true

func get_move() -> Vector2:
	return Vector2.ZERO

func get_display_data() -> Dictionary:
	return {}

func reset():
	active = false

func initialize():
	active = true
