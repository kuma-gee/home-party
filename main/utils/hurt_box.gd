class_name HurtBox
extends Area3D

signal health_changed()
signal died()

@export var health := 1
@onready var current_health := health:
	set(v):
		current_health = v
		health_changed.emit()
		
		if current_health <= 0:
			died.emit()

func hit(dmg = 1):
	current_health -= dmg
