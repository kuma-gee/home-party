class_name ElementOrb
extends Area3D

const COOLDOWN_TIME = {
	Arrow.Element.FIRE: 1.0,
	Arrow.Element.ICE: 3.0,
	Arrow.Element.LIGHTNING: 4.0,
	Arrow.Element.WIND: 2.0,
	Arrow.Element.POISON: 2.5,
	Arrow.Element.VOID: 5.0
}

@export var visual: MeshInstance3D
@export var color_rect: ColorRect
@export var label: Label3D
@export var vfx: ElementVFX
@export var min_fill := 0.3
@export var max_fill := 0.7

@export var element := Arrow.Element.FIRE:
	set(v):
		element = v
		label.text = ElementSelect.get_element_icon(element)

@onready var cooldown_timer: Timer = $CooldownTimer
@onready var active_circle: Sprite3D = $ActiveCircle

var _target_emission: float = 10.0
var _current_emission: float = 0.0

func _ready() -> void:
	set_selected(false)
	update_visual()
	if vfx: vfx.element = element
	cooldown_timer.timeout.connect(func(): update_visual())

func _process(delta: float) -> void:
	var mat = visual.get_active_material(0) as ShaderMaterial
	if not mat: return

	_current_emission = move_toward(_current_emission, _target_emission, delta * 20.0)
	mat.set_shader_parameter("emission_strength", _current_emission)

	if cooldown_timer.is_stopped(): return
	var p = cooldown_timer.time_left / get_cooldown_time()
	var v = remap(p, 1.0, 0.0, min_fill, max_fill)
	mat.set_shader_parameter("fill_level", v)

func set_selected(active: bool):
	active_circle.visible = active

func set_active(active: bool):
	visible = active
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED 
	set_selected(false)

func reset_cooldown() -> void:
	cooldown_timer.stop()
	var mat := visual.get_active_material(0) as ShaderMaterial
	if mat:
		mat.set_shader_parameter("fill_level", max_fill)

func is_loaded():
	return cooldown_timer.is_stopped()

func get_cooldown_time():
	if not element in COOLDOWN_TIME: return 1.0
	return COOLDOWN_TIME[element]

func fired():
	cooldown_timer.start(get_cooldown_time())
	update_visual(false)

func set_element(new_element: Arrow.Element) -> void:
	element = new_element
	update_visual()
	if vfx: vfx.element = new_element

func update_visual(emission_enable := true) -> void:
	var elem = element 
	var mat := visual.get_active_material(0) as ShaderMaterial
	if not mat:
		return
	
	var color = Color.WHITE
	if elem != Arrow.Element.NONE:
		color = ArrowElement.get_element_color(elem)
	else:
		emission_enable = false
	
	mat.set_shader_parameter("fill_color", color)
	mat.set_shader_parameter("emission_color", color)
	_target_emission = 10.0 if emission_enable else 0.0
