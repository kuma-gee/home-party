class_name HitBox
extends Area3D

@export var damage := 1
@export var hit_on_enter := true:
	set(v):
		hit_on_enter = v
		if v:
			hit()

var attacker_uuid: String = ""

func _ready() -> void:
	area_entered.connect(func(a):
		if a is HurtBox and hit_on_enter:
			a.hit(damage, attacker_uuid)
	)

func hit(dmg = damage):
	for area in get_overlapping_areas():
		if area is HurtBox:
			area.hit(dmg, attacker_uuid)
