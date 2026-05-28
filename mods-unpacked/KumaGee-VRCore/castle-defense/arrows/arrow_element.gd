class_name ArrowElement
extends Area3D

signal element_changed(elem: Arrow.Element)

const ELEMENT_SCENE = {
	Arrow.Element.FIRE: preload("uid://bnh078xxhjtqf"),
	Arrow.Element.ICE: preload("uid://c684oj6gh0t68"),
	Arrow.Element.LIGHTNING: preload("uid://bdkwolot88p0j"),
	Arrow.Element.WIND: preload("uid://b6cxw3y4xo030"),
	Arrow.Element.VOID: preload("uid://jqg3l1wgpb77"),
	Arrow.Element.POISON: preload("uid://divwtjoh71sg2"),
}

const ELEMENT_COLOR := {
	Arrow.Element.FIRE: Color(1.0, 0.4, 0.0, 0.8),
	Arrow.Element.ICE: Color(0.3, 0.8, 1.0, 0.8),
	Arrow.Element.LIGHTNING: Color(0.9, 0.9, 0.0, 0.8),
	Arrow.Element.WIND: Color(0.8, 0.8, 0.8, 0.8),
	Arrow.Element.POISON: Color(0.22, 1.0, 0.415, 0.8),
	Arrow.Element.VOID: Color(0.92, 0.285, 0.92, 0.8),
}

@export var visual: MeshInstance3D
@export var vfx: ElementVFX

var is_fired := false
var orb: ElementOrb
var element := Arrow.Element.NONE:
	set(v):
		element = v
		update_visual(visual, element)
		element_changed.emit(v)
		if vfx: vfx.element = v

func _ready() -> void:
	self.element = element
	if vfx: vfx.element = element
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area3D) -> void:
	if area is ElementOrb and not is_fired and area.is_loaded():
		orb = area
		element = orb.element

func activate_effect():
	if element not in ELEMENT_SCENE: return

	var spawn_pos := global_position
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(spawn_pos, spawn_pos + Vector3.DOWN * 50.0, 1 | 512)
	var hit := space_state.intersect_ray(query)
	if not hit.is_empty():
		spawn_pos = hit.position

	var scene = ELEMENT_SCENE[element].instantiate()
	scene.position = spawn_pos
	scene.rotation.y = global_rotation.y
	Staging.add_scene_child(scene)
	
func fired():
	if orb:
		orb.fired()
	is_fired = true

static func get_element_color(elem: Arrow.Element) -> Color:
	if not elem in ELEMENT_COLOR: return Color.WHITE
	return ELEMENT_COLOR[elem] as Color

static func update_visual(mesh: MeshInstance3D, elem: Arrow.Element, emission_enable := true) -> void:
	if not mesh:
		return
		
	var mat := mesh.get_active_material(0) as StandardMaterial3D
	if not mat:
		return
		
	if elem == Arrow.Element.NONE:
		mat.albedo_color = Color.WHITE
		mat.emission = Color.BLACK
		return
	
	var color := get_element_color(elem)
	mat.albedo_color = color
	if emission_enable:
		mat.emission = color
	else:
		mat.emission = Color.BLACK
