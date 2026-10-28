class_name GameOrb
extends CharacterBody3D

## Emitted when this orb reaches the core. [param orb] is this orb so the arena
## can schedule the launcher's replacement; [param attacker_uuid] is the launcher
## attributed with the damage; [param amount] is the damage dealt.
signal core_hit(orb: GameOrb, attacker_uuid: String, amount: int)

const ORB_HEIGHT: float = 1.3
const COLLISION_LAYER: int = 1024  # Physics layer 11; lets paddle goal areas see the orb.
## Prevents one grazing pass from dealing damage on every frame inside the core.
const CORE_HIT_COOLDOWN: float = 0.3
## Saber slices needed to destroy an orb: the first slice splits it, the second
## destroys it. Each split spawns a smaller clone.
const MAX_HEALTH: int = 2
## Health removed by one saber slice.
const SLICE_DAMAGE: int = 1
## Visual/collision size of an orb at its last point of health.
const MIN_SIZE_FACTOR: float = 0.6
## Maximum speed a boosted orb can reach (Reflect Boost or Turbo).
const MAX_BOOSTED_SPEED: float = 12.0

## Launcher of this orb. Its player color tints the orb so player-owned orbs stay
## visually distinguishable in flight.
var owner_player: PlayerSpawn = null:
	set(value):
		owner_player = value
		_apply_owner_color()
## Saber hits remaining before this orb is destroyed instead of split.
var health: int = MAX_HEALTH:
	set(value):
		health = clampi(value, 0, MAX_HEALTH)
		if is_node_ready():
			_apply_health_visuals()
var _resolved: bool = false
var _core_hit_cooldown: float = 0.0
var _ignored_body: PhysicsBody3D = null
var _ignore_time: float = 0.0
## True while this orb carries a temporary Reflect Boost. The boost expires on
## contact with a wall, paddle, or other surface.
var _is_boosted: bool = false
## Orb speed before the Reflect Boost was applied. Restored when the boost expires.
var _base_speed: float = 0.0

@onready var hitbox: HitBox = $HitBox
@onready var _sphere: CSGSphere3D = $CSGSphere3D
@onready var _glow: CSGSphere3D = $CSGSphere3D2
@onready var _body_shape: CollisionShape3D = $CollisionShape3D
@onready var _hitbox_shape: CollisionShape3D = $HitBox/CollisionShape3D

func _ready() -> void:
	add_to_group("game_orbs")
	# Damage is applied by this script so the core hit cooldown can gate it.
	hitbox.hit_on_enter = false
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	_apply_owner_color()
	_apply_health_visuals()

## Removes one health from a saber slice. Returns true when the orb is destroyed
## instead of split.
func apply_slice_damage() -> bool:
	if _resolved:
		return true
	health -= SLICE_DAMAGE
	if health > 0:
		return false
	resolve()
	return true

## Applies a Reflect Boost: temporarily increases the orb's speed by [param amount].
## Boosts do not stack — a fresh boost replaces any existing one. The boost
## expires when the orb hits a wall, paddle, or other surface.
func apply_reflect_boost(amount: float) -> void:
	if _resolved or velocity.length_squared() < 0.0001:
		return
	if not _is_boosted:
		_base_speed = velocity.length()
	_is_boosted = true
	var new_speed := minf(_base_speed + amount, MAX_BOOSTED_SPEED)
	velocity = velocity.normalized() * new_speed

## Removes the Reflect Boost, restoring the orb to its pre-boost speed.
func remove_reflect_boost() -> void:
	if not _is_boosted:
		return
	_is_boosted = false
	if velocity.length_squared() > 0.0001:
		velocity = velocity.normalized() * _base_speed

## True while this orb carries an active Reflect Boost.
func is_boosted() -> bool:
	return _is_boosted

## Returns the orb's speed before the Reflect Boost was applied.
func get_base_speed() -> float:
	return _base_speed

## Restores a previously active Reflect Boost after a state reset (e.g. after a
## saber slice re-launches the orb). [param base_speed] is the pre-boost speed.
func restore_reflect_boost(base_speed: float) -> void:
	if _resolved or velocity.length_squared() < 0.0001:
		return
	_base_speed = base_speed
	_is_boosted = true

## Shrinks the orb one step per point of health lost so damage is readable in VR.
func _apply_health_visuals() -> void:
	var size := _size_for_health(health)
	if is_instance_valid(_sphere):
		_sphere.scale = Vector3.ONE * size
	if is_instance_valid(_glow):
		_glow.scale = Vector3.ONE * size
	if is_instance_valid(_body_shape):
		_body_shape.scale = Vector3.ONE * size
	if is_instance_valid(_hitbox_shape):
		_hitbox_shape.scale = Vector3.ONE * size

func _size_for_health(value: int) -> float:
	if MAX_HEALTH <= 1:
		return 1.0
	var t := clampf(float(value - 1) / float(MAX_HEALTH - 1), 0.0, 1.0)
	return lerpf(MIN_SIZE_FACTOR, 1.0, t)

## Tints the orb with its owner's player color.
func _apply_owner_color() -> void:
	var mesh := get_node_or_null("CSGSphere3D") as CSGSphere3D
	if not mesh:
		return
	var material := mesh.material as ShaderMaterial
	if not material:
		return
	var color := owner_player.get_player_color() if is_instance_valid(owner_player) else Color.WHITE
	material.set_shader_parameter("base_color", color)

func _physics_process(delta: float) -> void:
	if _resolved:
		return
	_tick_timers(delta)
	velocity.y = 0.0
	var col := move_and_collide(velocity * delta)
	if col:
		# Any wall/paddle contact expires the Reflect Boost — the orb returns
		# to its pre-boost speed before bouncing.
		remove_reflect_boost()
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
	# Fresh launch always starts unboosted; boosts never carry over to new orbs.
	_is_boosted = false
	_base_speed = speed

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
		core_hit.emit(self, hitbox.attacker_uuid, hitbox.damage)
		(area as HurtBox).hit(hitbox.damage, hitbox.attacker_uuid)
	resolve()
