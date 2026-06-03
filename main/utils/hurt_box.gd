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

@export var enabled := true

func hit(dmg = 1, attacker_uuid: String = ""):
	if not enabled: return
	if attacker_uuid != "" and Engine.has_singleton("StatsManager"):
		StatsManager.record_damage(attacker_uuid, dmg)
	current_health -= dmg

func set_max_health(v: int) -> void:
	health = v
	current_health = v

func invulnerable(duration: float):
	enabled = false
	await get_tree().create_timer(duration).timeout
	enabled = true
