class_name Arrow
extends RigidBody3D

enum Element { FIRE, ICE, EARTH }

@export var damage := 1
@export var visual: MeshInstance3D

var element: Element = Element.FIRE:
	set(v):
		element = v
		_update_visual()

#@onready var hit_area: Area3D = $HitArea
@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var element_area: Area3D = $ElementArea

var _hit := false

func _ready() -> void:
	#hit_area.area_entered.connect(_on_hit_area_area_entered)
	#hit_area.body_entered.connect(_on_hit_area_body_entered)
	body_entered.connect(_on_body_entered)
	lifetime_timer.timeout.connect(queue_free)
	element_area.area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area3D) -> void:
	if area is ElementOrb:
		var orb := area as ElementOrb
		element = orb.element

func _physics_process(_delta: float) -> void:
	print(linear_velocity)
	if linear_velocity.length() > 0.5:
		look_at(global_position + linear_velocity, Vector3.UP)

#func _on_hit_area_area_entered(area: Area3D) -> void:
	#if _hit:
		#return
	#if area is HurtBox:
		#var bonus_damage := 1 if element == Element.FIRE else 0
		#area.hit(damage + bonus_damage)
		#_destroy()
#
#func _on_hit_area_body_entered(body: Node3D) -> void:
	#if _hit:
		#return
	#if body is FPSPlayer:
		#_apply_element_effect(body as FPSPlayer)
	#_destroy()

func _on_body_entered(_body: Node3D) -> void:
	if _hit:
		return
	_destroy()

func _destroy() -> void:
	_hit = true
	lifetime_timer.stop()
	queue_free()

func _apply_element_effect(player: FPSPlayer) -> void:
	match element:
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

func _update_visual() -> void:
	var indicator := visual
	if not indicator:
		return
	var mat := indicator.get_active_material(0) as StandardMaterial3D
	if not mat:
		return
	match element:
		Element.FIRE:
			mat.albedo_color = Color(1.0, 0.4, 0.0)
			mat.emission = Color(1.0, 0.4, 0.0)
		Element.ICE:
			mat.albedo_color = Color(0.3, 0.8, 1.0)
			mat.emission = Color(0.3, 0.8, 1.0)
		Element.EARTH:
			mat.albedo_color = Color(0.4, 0.25, 0.1)
			mat.emission = Color(0.4, 0.25, 0.1)
