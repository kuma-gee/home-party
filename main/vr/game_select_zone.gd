class_name GameSelectZone
extends Node3D

signal selected_game(game: GameResource)
signal start_game()

@onready var xr_tools_snap_zone: XRToolsSnapZone = $XRToolsSnapZone
@onready var interactable_area_button: XRToolsInteractableAreaButton = $InteractableAreaButton

func _ready() -> void:
	interactable_area_button.button_pressed.connect(func(): start_game.emit())
	xr_tools_snap_zone.has_picked_up.connect(_on_pickup)
	xr_tools_snap_zone.has_dropped.connect(_on_dropped)

func _on_dropped():
	selected_game.emit(null)

func _on_pickup(body: XRToolsPickable):
	if body is GameSelectArea:
		selected_game.emit(body.game)
