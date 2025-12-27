class_name AnimeContainer
extends Control

@export var child_size := Vector2(0, 40)

@export_category("Animation Settings")
@export var max_delay := 0.2
@export var delay_increase := 0.05
@export var dir := Vector2.DOWN
@export var item_offset := Vector2.ZERO
@export var fade_increase := 0.2
@export var initial_dir := Vector2.LEFT

var focused_index := 0

func init():
	_initial_children_positions()
	_update_children_offsets(true)

func _initial_children_positions():
	var pos := -focused_index * child_size * dir

	for c in _get_visible_children():
		c.position = pos + initial_dir * 400
		pos += child_size * dir

func _update_children_offsets(use_delay := false):
	var pos := -focused_index * child_size * dir
	
	var children = _get_visible_children()
	for i in children.size():
		var child = children[i]
		var diff = i - focused_index
		child.move_position(pos + item_offset * diff, _get_delay(diff) if use_delay else 0.0)
		child.set_focus(diff == 0)
		pos += child_size * dir
		
		var v = _get_fade(diff)
		child.modulate = Color(v, v, v, 1.0 if v > 0 else 0.0)

func _get_delay(idx: int):
	return min(max_delay, delay_increase * abs(idx))

func _get_fade(idx: int):
	return max(0.0, 1.0 - abs(idx) * fade_increase)

func _get_visible_children() -> Array[AnimeControl]:
	var result: Array[AnimeControl] = []
	for i in get_child_count():
		var c = get_child(i) as Control
		if !c or c.top_level or not c.is_visible_in_tree(): continue
		result.append(c)
	return result

func get_focused_child() -> AnimeControl:
	var children = _get_visible_children()
	for i in children.size():
		if i == focused_index:
			return children[i]
	return null
