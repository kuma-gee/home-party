class_name ArrowElement
extends Area3D

const ELEMENT_SCENE = {
	Arrow.Element.FIRE: preload("uid://bnh078xxhjtqf"),
	Arrow.Element.ICE: preload("uid://c684oj6gh0t68"),
}

const ELEMENT_COLOR := {
	Arrow.Element.FIRE: Color(1.0, 0.4, 0.0),
	Arrow.Element.ICE: Color(0.3, 0.8, 1.0),
	Arrow.Element.LIGHTNING: Color(0.9, 0.9, 0.4),
}

@export var visual: MeshInstance3D

var is_fired := false
var orb: ElementOrb
var element := Arrow.Element.NONE:
	set(v):
		element = v
		visible = element != Arrow.Element.NONE
		update_visual(visual, element)

func _ready() -> void:
	self.element = element
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area3D) -> void:
	if area is ElementOrb and not is_fired:
		orb = area
		element = orb.element

func activate_effect():
	if element not in ELEMENT_SCENE: return
	var scene = ELEMENT_SCENE[element].instantiate()
	scene.position = global_position
	Staging.add_scene_child(scene)
	
func fired():
	if orb:
		orb.fired()
	is_fired = true

static func get_element_color(elem: Arrow.Element) -> Color:
	return ELEMENT_COLOR[elem] as Color

static func update_visual(mesh: MeshInstance3D, elem: Arrow.Element) -> void:
	var indicator := mesh
	if not indicator:
		return
		
	var mat := indicator.get_active_material(0) as StandardMaterial3D
	if not mat:
		return
	
	if elem not in ELEMENT_COLOR:
		mesh.hide()
		return
	
	var color := get_element_color(elem)
	mat.albedo_color = color
	mat.emission = color
	mesh.show()
