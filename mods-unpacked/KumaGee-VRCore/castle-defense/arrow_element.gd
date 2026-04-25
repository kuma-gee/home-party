class_name ArrowElement
extends Area3D

@export var visual: MeshInstance3D

var element := Arrow.Element.FIRE:
	set(v):
		element = v
		update_visual(visual, element)

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area3D) -> void:
	if area is ElementOrb:
		var orb := area as ElementOrb
		element = orb.element

static func update_visual(visual: MeshInstance3D, element: Arrow.Element) -> void:
	var indicator := visual
	if not indicator:
		return
	var mat := indicator.get_active_material(0) as StandardMaterial3D
	if not mat:
		return
	match element:
		Arrow.Element.FIRE:
			mat.albedo_color = Color(1.0, 0.4, 0.0)
			mat.emission = Color(1.0, 0.4, 0.0)
		Arrow.Element.ICE:
			mat.albedo_color = Color(0.3, 0.8, 1.0)
			mat.emission = Color(0.3, 0.8, 1.0)
		Arrow.Element.EARTH:
			mat.albedo_color = Color(0.4, 0.25, 0.1)
			mat.emission = Color(0.4, 0.25, 0.1)
