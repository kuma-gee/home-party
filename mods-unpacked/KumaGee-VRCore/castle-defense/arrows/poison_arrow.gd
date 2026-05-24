extends Node3D

@onready var poison_area: Area3D = $PoisonArea

func hit():
	for body in poison_area.get_overlapping_bodies():
		if body is FPSPlayer:
			body.poison()
