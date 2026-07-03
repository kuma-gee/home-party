class_name HideSeekHUD
extends Control

signal start_pressed()

@onready var intruders_label: Label = %IntrudersLabel
@onready var ready_section: VBoxContainer = %ReadySection
@onready var ready_count_label: Label = %ReadyCountLabel
@onready var start_button: Button = %StartButton

var hider_count: int = -1:
	set(v):
		hider_count = v
		if intruders_label:
			intruders_label.text = "Find the %d intruders" % hider_count

func _ready() -> void:
	start_button.pressed.connect(func(): start_pressed.emit())


func update_ready(ready: int, total: int) -> void:
	var _mobile_ready := ready == total
	if _mobile_ready:
		start_button.text = "Start game"
	else:
		start_button.text = "mobile ready %s / %s" % [ready, total]

	start_button.disabled = total == 0 or ready < total
	
	if hider_count < 0:
		hider_count = total


func set_game_active(active: bool) -> void:
	if ready_section:
		ready_section.visible = not active
