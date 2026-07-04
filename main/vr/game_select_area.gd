@tool
class_name GameSelectArea
extends XRToolsPickable

@export var icon_viewport: SubViewport
@export var label: Label
@export var demo_indicator: Control

var game: GameResource

func _ready() -> void:
	super()
	if game.icon:
		var node = game.icon.instantiate()
		icon_viewport.add_child(node)
	label.text = game.name
	if demo_indicator:
		demo_indicator.visible = Env.is_demo() and not Env.is_game_available(game)
