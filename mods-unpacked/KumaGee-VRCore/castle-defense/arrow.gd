@tool
class_name Arrow
extends XRToolsPickable

enum Element { NONE, FIRE, ICE, EARTH }

@export var damage := 1

@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var element_area: ArrowElement = $ElementArea

var _hit := false
var fired := false

func _ready() -> void:
	super()
	body_entered.connect(_on_body_entered)
	lifetime_timer.timeout.connect(queue_free)
	freeze = true

func fire(force: Vector3):
	freeze = false
	linear_velocity = force
	fired = true

func _physics_process(_delta: float) -> void:
	if linear_velocity.length() > 0.5 and fired:
		look_at(global_position + linear_velocity, Vector3.UP)

func _on_body_entered(_body: Node3D) -> void:
	if _hit or not fired:
		return
	_on_hit()

func _on_hit() -> void:
	_hit = true
	freeze = true
	linear_velocity = Vector3.ZERO
	lifetime_timer.start()

func _apply_element_effect(player: FPSPlayer) -> void:
	match element_area.element:
		Element.ICE:
			var original_speed := player.speed
			player.speed = 0.3
			get_tree().create_timer(2.0).timeout.connect(func():
				if is_instance_valid(player):
					player.speed = original_speed
			)
		Element.EARTH:
			var dir := (player.global_position - global_position).normalized()
			player.velocity = Vector3(dir.x, 0.5, dir.z) * 6.0
