class_name GameOrb
extends CharacterBody3D

signal hit_core()

const ORB_HEIGHT: float = 0.9
const COLLISION_LAYER: int = 1024  # Physics layer 11; lets paddle goal areas see the orb.

var owner_player: PlayerSpawn = null
var _resolved: bool = false

@onready var hitbox: HitBox = $HitBox

func _ready() -> void:
	add_to_group("game_orbs")
	hitbox.area_entered.connect(_on_hitbox_area_entered)

func _physics_process(delta: float) -> void:
	if _resolved:
		return
	velocity.y = 0.0
	var col := move_and_collide(velocity * delta)
	if col:
		var reflect_dir := velocity.bounce(col.get_normal())
		velocity = Vector3(reflect_dir.x, 0.0, reflect_dir.z).normalized() * velocity.length()
	global_position.y = ORB_HEIGHT

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
	if area is HurtBox and not _resolved:
		hit_core.emit(self)
