class_name HitBox
extends Area3D

@export var damage := 1
@export var hit_on_enter := true

func _ready() -> void:
	if hit_on_enter:
		area_entered.connect(func(a):
			if a is HurtBox:
				a.hit(damage)
		)

func hit(dmg = damage):
	for area in get_overlapping_areas():
		if area is HurtBox:
			area.hit(dmg)
