class_name ArrowElement
extends Area3D

const ELEMENT_SCENE = {
	Arrow.Element.FIRE: preload("uid://bnh078xxhjtqf"),
	Arrow.Element.ICE: preload("uid://c684oj6gh0t68"),
}

const ELEMENT_COLOR := {
	Arrow.Element.FIRE: Color(1.0, 0.4, 0.0),
	Arrow.Element.ICE: Color(0.3, 0.8, 1.0),
	Arrow.Element.EARTH: Color(0.4, 0.25, 0.1),
}

@export var visual: MeshInstance3D

var element := Arrow.Element.FIRE:
	set(v):
		element = v
		visible = element != Arrow.Element.NONE
		update_visual(visual, element)

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area3D) -> void:
	if area is ElementOrb:
		var orb := area as ElementOrb
		element = orb.element

func activate_effect():
	if element not in ELEMENT_SCENE: return
	var scene = ELEMENT_SCENE[element].instantiate()
	scene.position = global_position
	get_tree().current_scene.add_child(scene)

static func update_visual(visual: MeshInstance3D, element: Arrow.Element) -> void:
	var indicator := visual
	if not indicator:
		return
		
	var mat := indicator.get_active_material(0) as StandardMaterial3D
	if not mat:
		return
	
	if element not in ELEMENT_COLOR:
		return
	var color := ELEMENT_COLOR[element] as Color
	mat.albedo_color = color
	mat.emission = color
