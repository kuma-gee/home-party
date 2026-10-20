class_name VortexHUD
extends Control

@onready var timer_label: Label = %TimerLabel
@onready var core_health_bar: ProgressBar = %CoreHealthBar

func _ready() -> void:
	set_state("Waiting...")
	if core_health_bar:
		core_health_bar.max_value = 20
		core_health_bar.value = 20
	if timer_label:
		timer_label.text = "3:00"

func set_state(text: String) -> void:
	pass

func update_speed(speed: float) -> void:
	pass

func update_core_health(hp: int) -> void:
	if core_health_bar:
		core_health_bar.value = hp

func update_time(remaining: float) -> void:
	if not timer_label:
		return
	var minutes := int(remaining) / 60
	var seconds := int(remaining) % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]
