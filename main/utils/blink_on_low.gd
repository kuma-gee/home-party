extends Node

@export var blink_color := Color.RED
@export var blink_threshold := 0.2
@export var blink_speed := 2.0

@onready var bar: ProgressBar = get_parent()

var original_modulate: Color
var time: float = 0.0

func _ready():
	original_modulate = bar.modulate

func _process(delta):
	var ratio = bar.value / bar.max_value if bar.max_value > 0 else 0.0
	if ratio > 0 and ratio <= blink_threshold:
		time += delta
		var t = (sin(time * blink_speed * TAU) + 1.0) * 0.5
		bar.modulate = original_modulate.lerp(blink_color, t)
	else:
		time = 0.0
		bar.modulate = original_modulate
