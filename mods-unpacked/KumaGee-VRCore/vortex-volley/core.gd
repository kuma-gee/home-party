class_name VortexCore
extends Node3D

signal core_destroyed()
signal core_health_changed(current: int, max: int)

const MAX_HEALTH: int = 20

@onready var hurtbox: HurtBox = $HurtBox

var health: int = MAX_HEALTH
var max_health: int = MAX_HEALTH

func _ready() -> void:
	hurtbox.set_max_health(MAX_HEALTH)
	hurtbox.health_changed.connect(_on_health_changed)
	hurtbox.died.connect(_on_died)

func _on_health_changed() -> void:
	health = hurtbox.current_health
	core_health_changed.emit(health, max_health)

func _on_died() -> void:
	core_destroyed.emit()

func reset() -> void:
	hurtbox.enabled = true
	hurtbox.set_max_health(MAX_HEALTH)
