extends Node3D

@onready var area_3d: Area3D = $Area3D
@onready var block: CSGBox3D = $Block

var current_color := Color.WHITE:
	set(v):
		current_color = v
		var mat = block.material as StandardMaterial3D
		mat.albedo_color = current_color

func _ready() -> void:
	area_3d.area_entered.connect(func(a): current_color = a.color)

func get_size() -> Vector2:
	return Vector2(block.size.x, block.size.z)
