class_name ColorRing
extends Sprite3D

@export var color_rect: ColorRect
@onready var sub_viewport: SubViewport = $SubViewport

func _ready() -> void:
	texture = sub_viewport.get_texture()

func set_color(color: Color):
	color_rect.color = color
