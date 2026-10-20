class_name GameOrb
extends CharacterBody3D

const ORB_HEIGHT: float = 0.9
const COLLISION_LAYER: int = 1024  # Physics layer 11; lets paddle goal areas see the orb.
## Prevents one grazing pass from dealing damage on every frame inside the core.
const CORE_HIT_COOLDOWN: float = 0.3

var owner_player: PlayerSpawn = null
var _resolved: bool = false
var _core_hit_cooldown: float = 0.0
var _ignored_body: PhysicsBody3D = null
var _ignore_time: float = 0.0

@onready var hitbox: HitBox = $HitBox

func _ready() -> void:
	add_to_group("game_orbs")
	# Damage is applied by this script so the core hit cooldown can gate it.
	hitbox.hit_on_enter = false
	hitbox.area_entered.connect(_on_hitbox_area_entered)

func _physics_process(delta: float) -> void:
	if _resolved:
		return
	_tick_timers(delta)
	velocity.y = 0.0
	var col := move_and_collide(velocity * delta)
	if col:
		var reflect_dir := velocity.bounce(col.get_normal())
		velocity = Vector3(reflect_dir.x, 0.0, reflect_dir.z).normalized() * velocity.length()
	global_position.y = ORB_HEIGHT

## Adds this orb to a body's collision exceptions for `duration`, then restores
## normal collision. Used so an orb can leave the paddle that launched it but
## still bounce off that paddle when it returns.
func ignore_collision_with(body: PhysicsBody3D, duration: float) -> void:
	if not is_instance_valid(body):
		return
	add_collision_exception_with(body)
	_ignored_body = body
	_ignore_time = duration

func _tick_timers(delta: float) -> void:
	if _ignore_time > 0.0:
		_ignore_time -= delta
		if _ignore_time <= 0.0 and is_instance_valid(_ignored_body):
			remove_collision_exception_with(_ignored_body)
			_ignored_body = null
	if _core_hit_cooldown > 0.0:
		_core_hit_cooldown -= delta

func launch(direction: Vector3, speed: float) -> void:
	velocity = direction.normalized() * speed
	global_position.y = ORB_HEIGHT

func resolve() -> void:
	if _resolved:
		return
	_resolved = true
	queue_free()

func is_resolved() -> bool:
	return _resolved

func _on_hitbox_area_entered(area: Area3D) -> void:
	if _resolved or not area is HurtBox:
		return
	if _core_hit_cooldown <= 0.0:
		_core_hit_cooldown = CORE_HIT_COOLDOWN
		(area as HurtBox).hit(hitbox.damage, hitbox.attacker_uuid)
	_bounce_off(area.global_position)

## Pong-style bounce off the core; the orb keeps playing at the same speed.
func _bounce_off(point: Vector3) -> void:
	var normal := global_position - point
	normal.y = 0.0
	if normal.length_squared() < 0.0001:
		normal = -velocity
		normal.y = 0.0
	if normal.length_squared() < 0.0001:
		return
	velocity = velocity.bounce(normal.normalized())
