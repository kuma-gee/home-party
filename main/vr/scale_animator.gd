class_name ScaleAnimator
extends Node

## Reusable scale-in/scale-out animation for Control or Node3D targets.
## Works when SceneTree is paused because parent VRSpace has PROCESS_MODE_ALWAYS.
##
## Usage:
##   var anim := ScaleAnimator.new()
##   anim.fade_duration = 0.15
##   add_child(anim)
##   anim.scale_in(target_node)
##   ...
##   anim.finished.connect(_on_out_done)
##   anim.scale_out()

signal finished

@export var fade_duration: float = 0.15
@export var start_scale: float = 0.01
@export var end_scale: float = 1.0

var _is_scaling_in: bool = false
var _is_scaling_out: bool = false
var _scale_anim_t: float = 0.0
var _target: Node = null


func set_target(node: Node) -> void:
	_target = node


func is_animating() -> bool:
	return _is_scaling_in or _is_scaling_out


func scale_in(target_node: Node = _target) -> void:
	if target_node:
		_target = target_node
	
	_is_scaling_in = true
	_is_scaling_out = false
	_scale_anim_t = 0.0
	
	# Control nodes scale from top-left by default; pivot_offset centers it.
	# Use call_deferred so layout is resolved before reading size.
	if _target is Control:
		_update_pivot_offset.call_deferred()
	
	_apply_scale(start_scale)


func scale_out() -> void:
	if not _target:
		return
	
	_is_scaling_in = false
	_is_scaling_out = true
	_scale_anim_t = 0.0


func _update_pivot_offset() -> void:
	if _target is Control:
		var c := _target as Control
		if c.size != Vector2.ZERO:
			c.pivot_offset = c.size / 2.0


func _process(delta: float) -> void:
	if not _target:
		return
	
	# Ensure pivot offset is set once layout is resolved
	if (_is_scaling_in or _is_scaling_out) and _target is Control:
		var c := _target as Control
		if c.pivot_offset == Vector2.ZERO and c.size != Vector2.ZERO:
			c.pivot_offset = c.size / 2.0
	
	if _is_scaling_in:
		_scale_anim_t += delta / fade_duration
		if _scale_anim_t >= 1.0:
			_scale_anim_t = 1.0
			_is_scaling_in = false
		var t := _ease_out_back(clampf(_scale_anim_t, 0.0, 1.0))
		_apply_scale(lerpf(start_scale, end_scale, t))
	
	if _is_scaling_out:
		_scale_anim_t += delta / fade_duration
		if _scale_anim_t >= 1.0:
			_scale_anim_t = 1.0
			_is_scaling_out = false
			_apply_scale(start_scale)
			finished.emit()
			return
		var t := _ease_in_back(clampf(_scale_anim_t, 0.0, 1.0))
		_apply_scale(lerpf(end_scale, start_scale, t))


func _apply_scale(s: float) -> void:
	if _target is Control:
		_target.scale = Vector2(s, s)
	elif _target is Node3D:
		_target.scale = Vector3(s, s, s)


static func _ease_out_back(t: float) -> float:
	const c1 := 1.70158
	const c3 := c1 + 1.0
	return 1.0 + c3 * pow(t - 1.0, 3) + c1 * pow(t - 1.0, 2)


static func _ease_in_back(t: float) -> float:
	const c1 := 1.70158
	const c3 := c1 + 1.0
	return c3 * pow(t, 3) - c1 * pow(t, 2)
