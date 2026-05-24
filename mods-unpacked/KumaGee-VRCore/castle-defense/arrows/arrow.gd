@tool
class_name Arrow
extends XRToolsPickable

signal element_changed(elem: Arrow.Element)

enum Element { NONE, FIRE, ICE, LIGHTNING, WIND, POISON, VOID }

@export var damage := 1
@export var element_area: ArrowElement
@onready var lifetime_timer: Timer = $LifetimeTimer

var _hit := false
var fired := false

func _ready() -> void:
	super()
	body_entered.connect(_on_body_entered)
	element_area.element_changed.connect(func(e): element_changed.emit(e))
	lifetime_timer.timeout.connect(queue_free)
	dropped.connect(func(a):
		if is_inside_tree():
			await get_tree().physics_frame
			if not is_picked_up() and a is Arrow and not fired:
				queue_free()
	)
	freeze = true

func fire(force: Vector3):
	freeze = false
	linear_velocity = force
	fired = true
	element_area.fired()

func _physics_process(_delta: float) -> void:
	if linear_velocity.length() > 0.5 and fired:
		look_at(global_position + linear_velocity, Vector3.UP)

func _on_body_entered(body: Node3D) -> void:
	if _hit or not fired or body is XRToolsPickable:
		return
	_on_hit()
	if body.has_method("on_hit"):
		body.on_hit()

func _on_hit() -> void:
	_hit = true
	#freeze = true
	#linear_velocity = Vector3.ZERO
	#lifetime_timer.start()
	element_area.activate_effect()
	queue_free()

func get_element():
	return element_area.element
