@tool
class_name OverlayMesh
extends MeshInstance3D

@export var overlay_alpha := 0.8
@export var overlay_fade_duration := 0.5

var _fade_tween: Tween

func _ready() -> void:
	_set_overlay_alpha(0.0)

func show_overlay():
	if _get_overlay_alpha() > 0:
		return
	
	if _fade_tween:
		_fade_tween.kill()
	
	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_CUBIC)
	_fade_tween.set_ease(Tween.EASE_OUT)
	_fade_tween.tween_method(_set_overlay_alpha, 0.0, overlay_alpha, overlay_fade_duration)
	
func hide_overlay():
	if _get_overlay_alpha() < overlay_alpha:
		return
		
	if _fade_tween:
		_fade_tween.kill()
	
	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_CUBIC)
	_fade_tween.set_ease(Tween.EASE_IN)
	_fade_tween.tween_method(_set_overlay_alpha, overlay_alpha, 0.0, overlay_fade_duration)

func _set_overlay_alpha(alpha: float) -> void:
	var material := get_surface_override_material(0) as ShaderMaterial
	if material:
		material.set_shader_parameter("albedo", Color(0, 0, 0, alpha))

	visible = alpha > 0.0

func _get_overlay_alpha():
	var mat = get_surface_override_material(0) as ShaderMaterial
	return mat.get_shader_parameter("albedo").a
