class_name VortexHUD
extends Control

@onready var lives_container: VBoxContainer = %LivesContainer
@onready var state_label: Label = %StateLabel
@onready var timer_label: Label = %TimerLabel
@onready var core_health_bar: ProgressBar = %CoreHealthBar
@onready var speed_bar: ProgressBar = %SpeedBar

func _ready() -> void:
	set_state("Waiting...")
	_clear_lives()
	if core_health_bar:
		core_health_bar.max_value = 20
		core_health_bar.value = 20
	if speed_bar:
		speed_bar.max_value = 10.0
		speed_bar.value = 5.0
	if timer_label:
		timer_label.text = "3:00"

func update_lives(data: Array[Dictionary]) -> void:
	_clear_lives()
	for entry in data:
		var pname := str(entry.get("name", "?"))
		var lives := int(entry.get("lives", 0))
		var label := Label.new()
		label.text = "%s  %s" % [pname, "♥".repeat(lives) + "♡".repeat(maxi(0, 3 - lives))]
		label.theme_type_variation = &"LabelMedium"
		if lives <= 0:
			label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		lives_container.add_child(label)

func set_state(text: String) -> void:
	if state_label:
		state_label.text = text

func _clear_lives() -> void:
	if not lives_container:
		return
	for child in lives_container.get_children():
		child.queue_free()

func update_speed(speed: float) -> void:
	if speed_bar:
		speed_bar.value = speed

func update_core_health(hp: int) -> void:
	if core_health_bar:
		core_health_bar.value = hp

func update_time(remaining: float) -> void:
	if not timer_label:
		return
	var minutes := int(remaining) / 60
	var seconds := int(remaining) % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]
