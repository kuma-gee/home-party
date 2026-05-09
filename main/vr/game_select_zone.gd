class_name GameSelectZone
extends Node3D

signal selected_game(game: GameResource)

@onready var snap_zone: XRToolsSnapZone = $SnapZone

func _ready() -> void:
	snap_zone.has_picked_up.connect(_on_pickup)
	snap_zone.has_dropped.connect(_on_dropped)

func _on_dropped():
	selected_game.emit(null)

func _on_pickup(body: XRToolsPickable):
	if body is GameSelectArea:
		selected_game.emit(body.game)
