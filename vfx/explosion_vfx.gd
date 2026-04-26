extends Node3D

signal finished()

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	animation_player.animation_finished.connect(func(_a):
		finished.emit()
	)
