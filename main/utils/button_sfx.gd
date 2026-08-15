class_name ButtonSFX
extends Node

## Reusable SFX component for buttons.
## Attach as child of any BaseButton (Button, CheckBox, etc.).
## Leave hover_sfx / click_sfx empty — fill via inspector later.
const HOVER = preload("uid://fiear3pmqncr")
const CLICK = preload("uid://byp8x7dpxcw6o")

@export var hover_sfx: AudioStream = HOVER
@export var click_sfx: AudioStream = CLICK
@export var volume_db := -10.0

var _button: BaseButton


func _ready() -> void:
	_button = get_parent() as BaseButton
	if not _button:
		push_error("ButtonSFX must be a child of a BaseButton, got: ", get_parent())
		return

	# Connect only if a stream is assigned (no-op if null).
	if hover_sfx:
		_button.mouse_entered.connect(_on_hover)
	if click_sfx:
		_button.pressed.connect(_on_click)


func _on_hover() -> void:
	AudioManager.play_sfx(hover_sfx, volume_db)


func _on_click() -> void:
	AudioManager.play_sfx(click_sfx, volume_db)
