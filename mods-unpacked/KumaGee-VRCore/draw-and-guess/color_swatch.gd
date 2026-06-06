@tool
class_name DrawingColorSwatch
extends Area3D

@export var swatch_color: Color = Color.BLACK:
	set(value):
		swatch_color = value

func _ready():
	collision_layer = 0
	collision_layer = 1 << 9  # layer 10 (Color Swatch)
