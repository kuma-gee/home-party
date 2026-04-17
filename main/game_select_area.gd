class_name GameSelectArea
extends Node3D

signal hovered()
signal unhovered()
signal start_game()

@export var start_timer: Timer
@export var label: Label3D
@export var interact_area: Area3D

var game: GameResource

func _ready() -> void:
	interact_area.area_entered.connect(_on_area_entered)
	interact_area.area_exited.connect(_on_area_exited)
	
	start_timer.timeout.connect(func(): start_game.emit())
	var node = game.icon.instantiate()
	add_child(node)

func _process(_delta: float) -> void:
	if start_timer.is_stopped():
		label.hide()
		return
	
	label.show()
	label.text = "Start in %ss" % [int(start_timer.time_left)]

func _on_area_entered(_a):
	hovered.emit()
	start_timer.start()

func _on_area_exited(_a):
	unhovered.emit()
	start_timer.stop()
