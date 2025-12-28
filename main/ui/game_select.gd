extends TextureButton

@export var label: Label
@export var tex: TextureRect

var game: GameResource

func _ready() -> void:
	toggled.connect(func(_on): _update())
	label.text = game.name
	_update()

func _update():
	modulate = Color.WHITE if button_pressed else Color.DIM_GRAY
