class_name HurtBox
extends Area3D

signal health_changed()
signal died()

@export var health := 1:
	set(v):
		health = v
		health_changed.emit()
		
		if health <= 0:
			died.emit()

func hit(dmg = 1):
	health -= dmg
