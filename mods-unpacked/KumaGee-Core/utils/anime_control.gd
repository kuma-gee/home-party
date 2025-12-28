class_name AnimeControl
extends Control

signal focused(f)
signal selected()
signal disabled(d)

@export var disabled_modulate := Color.DIM_GRAY

var move_tw: Tween
var scale_tw: Tween
var is_focused = false
var is_disabled = false

func move_position(pos: Vector2, delay := 0.0):
	if move_tw and move_tw.is_running():
		move_tw.kill()
	move_tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	move_tw.tween_property(self, "position", pos - Vector2(0, size.y)/2, 0.5).set_delay(delay)
	return move_tw

func scale_to(s: Vector2, delay := 0.0):
	if scale_tw and scale_tw.is_running():
		scale_tw.kill()
	scale_tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	scale_tw.tween_property(self, "scale", s, 0.5).set_delay(delay)
	return scale_tw

func set_focus(focus: bool):
	is_focused = focus
	focused.emit(is_focused)

func set_disabled(v: bool):
	is_disabled = v
	disabled.emit(v)
	modulate = disabled_modulate if v else Color.WHITE

func select():
	if is_disabled: return
	selected.emit()
