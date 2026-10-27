class_name VortexArena
extends Node3D

signal round_ended(scores: Array[Dictionary])
signal lives_updated(data: Array[Dictionary])
signal speed_updated(speed: float)
signal core_health_updated(hp: int)
signal time_updated(remaining: float)

const ARENA_RADIUS: float = 4.5
const ORB_SPEED_BASE: float = 5.0
const ORB_SPEED_MAX: float = 10.0
const ORB_SPEED_STEP: float = 0.5
const REFLECT_SPEED_BONUS: float = 1.5
## Each saber slice sends the two resulting orbs this far off the original path.
const SABER_SPLIT_ANGLE_DEG: float = 20.0
const START_LIVES: int = 3
const RESPAWN_DELAY: float = 1.5
const ROUND_TIME: float = 180.0
## Max launch angle away from the center line when the paddle is moving at full speed.
const AIM_MAX_ANGLE: float = deg_to_rad(30.0)
## Brief spawn grace so an orb does not bounce off the paddle that fired it.
const LAUNCH_CLEARANCE_TIME: float = 0.3
## How long a power-up stays collectible before expiring.
const POWERUP_LIFETIME: float = 12.0
## How long the spawn position is telegraphed before the power-up is collectible.
const POWERUP_TELEGRAPH_TIME: float = 1.5
## Radial band power-ups spawn in. Kept clear of the VR defender (center platform
## radius 1.2m) and the mobile paddles (DeflectorPlayer.PADDLE_RADIUS = 4.0m) by a
## 0.6m margin on each side, so a power-up never sits on either.
const POWERUP_SPAWN_RADIUS_MIN: float = 1.8
const POWERUP_SPAWN_RADIUS_MAX: float = 3.4
## Turbo: speed added to the collecting player's active orbs.
const POWERUP_TURBO_SPEED: float = 2.0
## Paddle Boost: temporary paddle speed multiplier and its duration.
const POWERUP_PADDLE_BOOST_MULT: float = 1.5
const POWERUP_PADDLE_BOOST_DURATION: float = 10.0
## Duplicate stops spawning at or above this many active orbs; below it the
## weight scales down linearly as orbs accumulate.
const POWERUP_DUPLICATE_MAX_ORBS: int = 10

enum Phase { WAITING, PLAYING, ENDED }

@export var orb_scene: PackedScene
@export var power_up_scene: PackedScene
## Delay range before the next power-up spawns after the previous one resolves.
## Randomized per spawn; tune in the inspector.
@export var powerup_spawn_delay_min: float = 2.0
@export var powerup_spawn_delay_max: float = 4.0

var phase: Phase = Phase.WAITING
## Slots currently assigned to a player (phone or AI).
var deflectors: Array[PlayerSpawn] = []
## All pre-placed slots in the arena, sorted by angle around the core (slot 0..7).
var slot_deflectors: Array[PlayerSpawn] = []
## AI-controlled players supplied by VortexAIManager. Combined with the real
## PlayerManager players when assigning slots.
var ai_controllers: Array[ClientController] = []
var active_orbs: Array[GameOrb] = []
var core: VortexCore
var time_remaining: float = ROUND_TIME

var _speed: float = ORB_SPEED_BASE
var _elimination_order: Array[PlayerSpawn] = []
## Active (swung) shield blocks by the VR player this round.
var _active_shield_blocks: int = 0
## Core damage dealt per mobile player, keyed by attacker uuid.
var _core_damage: Dictionary = {}
## The single active power-up, or null while the next spawn is pending.
var _power_up: VortexPowerUp = null
var _power_up_spawn_delay: float = 0.0

func _ready() -> void:
	_collect_slot_deflectors()
	PlayerManager.clients_changed.connect(_on_clients_changed)

func _process(delta: float) -> void:
	if phase != Phase.PLAYING:
		return
	time_remaining -= delta
	time_updated.emit(time_remaining)
	if time_remaining <= 0.0:
		time_remaining = 0.0
		_end_round()
		return
	_prune_orbs()
	_tick_power_ups(delta)

func start_round() -> void:
	phase = Phase.PLAYING
	_speed = ORB_SPEED_BASE
	time_remaining = ROUND_TIME
	_elimination_order.clear()
	_active_shield_blocks = 0
	_core_damage.clear()
	_clear_power_up()
	_schedule_next_power_up()
	if core:
		if not core.core_health_changed.is_connected(_on_core_health_changed):
			core.core_health_changed.connect(_on_core_health_changed)
		if not core.core_destroyed.is_connected(_end_round):
			core.core_destroyed.connect(_end_round)
		core.reset()
		core_health_updated.emit(core.health)
	speed_updated.emit(_speed)
	_sync_deflectors()
	for d in deflectors:
		d.lives = START_LIVES
		d.has_orb = true
		d.revive()
		d.set_orb_ready()
	lives_updated.emit(_build_lives_data())

func reset() -> void:
	phase = Phase.WAITING
	_speed = ORB_SPEED_BASE
	time_remaining = ROUND_TIME
	_elimination_order.clear()
	_active_shield_blocks = 0
	_core_damage.clear()
	_clear_power_up()
	_power_up_spawn_delay = 0.0
	for d in deflectors:
		d.has_orb = false
		if is_instance_valid(d.deflector):
			d.deflector.clear_speed_boost()
	for orb in active_orbs:
		if is_instance_valid(orb):
			orb.queue_free()
	active_orbs.clear()

func request_launch(player: PlayerSpawn) -> bool:
	if phase != Phase.PLAYING or not is_instance_valid(player):
		return false
	if not player.can_launch():
		return false
	player.has_orb = false
	player.clear_orb_ready()
	_spawn_orb_from_paddle(player)
	return true

func on_orb_blocked(orb: GameOrb, reflect_dir: Vector3, active: bool = false) -> void:
	if phase != Phase.PLAYING or not is_instance_valid(orb):
		return
	if not active_orbs.has(orb):
		return
	var incoming_speed := orb.velocity.length()
	if active:
		_active_shield_blocks += 1
		_set_speed(minf(_speed + ORB_SPEED_STEP, ORB_SPEED_MAX))
	var reflect_speed := incoming_speed
	if active:
		reflect_speed = minf(incoming_speed + REFLECT_SPEED_BONUS, ORB_SPEED_MAX)
	orb.velocity = reflect_dir.normalized() * reflect_speed

func on_orb_sliced(orb: GameOrb, _slice_dir: Vector3) -> void:
	if phase != Phase.PLAYING or not is_instance_valid(orb):
		return
	if not active_orbs.has(orb) or orb.is_resolved():
		return
	var speed := orb.velocity.length()
	if speed <= 0.0:
		return
	var launcher := orb.owner_player
	if orb.apply_slice_damage():
		active_orbs.erase(orb)
		# The orb was sliced to death instead of leaving the arena, so return a
		# ready orb to its launcher or they would be soft-locked with none.
		_schedule_respawn(launcher)
		return
	var forward := orb.velocity.normalized()
	var angle := deg_to_rad(SABER_SPLIT_ANGLE_DEG)
	orb.launch(forward.rotated(Vector3.UP, angle), speed)
	_spawn_split_orb(orb, forward.rotated(Vector3.UP, -angle), speed)

## Creates the second orb from a saber slice. It keeps the same owner, speed, and
## remaining health so both halves can still hit any mobile player.
func _spawn_split_orb(source: GameOrb, direction: Vector3, speed: float) -> void:
	if not orb_scene:
		return
	var clone := orb_scene.instantiate() as GameOrb
	if not clone:
		return
	add_child(clone)
	clone.global_position = source.global_position
	clone.owner_player = source.owner_player
	clone.health = source.health
	if is_instance_valid(source.hitbox) and is_instance_valid(clone.hitbox):
		clone.hitbox.attacker_uuid = source.hitbox.attacker_uuid
	clone.core_hit.connect(_on_orb_core_hit)
	clone.launch(direction, speed)
	active_orbs.append(clone)

# ── Power-ups ─────────────────────────────────────────────────────────────────

## Spawns the next power-up once the previous one resolved and the delay elapsed.
## Exactly one is active at a time; the node runs its own telegraph → active →
## expire lifecycle and reports back through picked_up/expired.
func _tick_power_ups(delta: float) -> void:
	if is_instance_valid(_power_up):
		return
	_power_up_spawn_delay -= delta
	if _power_up_spawn_delay <= 0.0:
		_spawn_power_up()

## Starts the randomized countdown to the next power-up spawn.
func _schedule_next_power_up() -> void:
	_power_up_spawn_delay = randf_range(powerup_spawn_delay_min, powerup_spawn_delay_max)

func _spawn_power_up() -> void:
	if not power_up_scene:
		return
	var power_up := power_up_scene.instantiate() as VortexPowerUp
	if not power_up:
		return
	power_up.type = _pick_power_up_type()
	add_child(power_up)
	power_up.global_position = _random_power_up_position()
	power_up.telegraph_time = POWERUP_TELEGRAPH_TIME
	power_up.lifetime = POWERUP_LIFETIME
	power_up.picked_up.connect(_on_power_up_picked)
	power_up.expired.connect(_on_power_up_expired)
	_power_up = power_up

func _random_power_up_position() -> Vector3:
	var angle := randf() * TAU
	var radius := randf_range(POWERUP_SPAWN_RADIUS_MIN, POWERUP_SPAWN_RADIUS_MAX)
	return Vector3(cos(angle) * radius, GameOrb.ORB_HEIGHT, sin(angle) * radius)

## Counts live orbs currently in play, ignoring freed or resolved entries that
## have not yet been pruned.
func _count_active_orbs() -> int:
	var n := 0
	for orb in active_orbs:
		if is_instance_valid(orb) and not orb.is_resolved():
			n += 1
	return n

## Weighted random power-up type. Duplicate's weight scales down linearly as
## active orbs accumulate and hits zero at POWERUP_DUPLICATE_MAX_ORBS; Turbo and
## Paddle Boost keep a constant weight so the pool never collapses to one type.
func _pick_power_up_type() -> VortexPowerUp.Type:
	var duplicate_weight := clampf(
		1.0 - float(_count_active_orbs()) / float(POWERUP_DUPLICATE_MAX_ORBS), 0.0, 1.0)
	var total := duplicate_weight + 2.0
	var roll := randf() * total
	if roll < duplicate_weight:
		return VortexPowerUp.Type.DUPLICATE
	if roll < duplicate_weight + 1.0:
		return VortexPowerUp.Type.TURBO
	return VortexPowerUp.Type.PADDLE_BOOST

## A mobile-owned orb collected the power-up. The orb keeps flying; the effect
## activates immediately for its owner.
func _on_power_up_picked(orb: GameOrb) -> void:
	if phase != Phase.PLAYING:
		return
	var power_up := _power_up
	_clear_power_up()
	_schedule_next_power_up()
	if is_instance_valid(power_up) and is_instance_valid(orb) and not orb.is_resolved():
		_grant_power_up(power_up.type, orb)

func _on_power_up_expired() -> void:
	_clear_power_up()
	_schedule_next_power_up()

func _grant_power_up(type: VortexPowerUp.Type, orb: GameOrb) -> void:
	match type:
		VortexPowerUp.Type.DUPLICATE:
			_duplicate_orb(orb)
		VortexPowerUp.Type.TURBO:
			_boost_owner_orbs(orb)
		VortexPowerUp.Type.PADDLE_BOOST:
			_boost_owner_paddle(orb)

## Duplicate: splits the collecting orb into two in place at the current speed.
## The original continues straight; the clone diverges 20°. No escalation.
func _duplicate_orb(orb: GameOrb) -> void:
	if not active_orbs.has(orb) or orb.is_resolved():
		return
	var speed := orb.velocity.length()
	if speed <= 0.0:
		return
	var forward := orb.velocity.normalized()
	var angle := deg_to_rad(SABER_SPLIT_ANGLE_DEG)
	_spawn_split_orb(orb, forward.rotated(Vector3.UP, angle), speed)

## Turbo: +2.0 m/s to every active orb owned by the collecting player, capped at
## ORB_SPEED_MAX. Other players' orbs are untouched.
func _boost_owner_orbs(orb: GameOrb) -> void:
	if not is_instance_valid(orb.owner_player):
		return
	var owner := orb.owner_player
	for o in active_orbs:
		if not is_instance_valid(o) or o.is_resolved() or o.owner_player != owner:
			continue
		if o.velocity.length_squared() < 0.0001:
			continue
		var speed := minf(o.velocity.length() + POWERUP_TURBO_SPEED, ORB_SPEED_MAX)
		o.velocity = o.velocity.normalized() * speed

## Paddle Boost: the collecting player's paddle moves faster for a short window.
func _boost_owner_paddle(orb: GameOrb) -> void:
	if not is_instance_valid(orb.owner_player):
		return
	var deflector := orb.owner_player.deflector
	if is_instance_valid(deflector):
		deflector.apply_speed_boost(POWERUP_PADDLE_BOOST_MULT, POWERUP_PADDLE_BOOST_DURATION)

func _clear_power_up() -> void:
	if is_instance_valid(_power_up):
		_power_up.queue_free()
	_power_up = null

func force_end_round() -> void:
	_end_round()

## Replaces the AI controller pool and resyncs paddle assignments. Called by
## VortexAIManager as AI players are added/removed during the prepare phase.
func set_ai_controllers(controllers: Array[ClientController]) -> void:
	ai_controllers = controllers
	if phase == Phase.WAITING:
		_sync_deflectors()

func _spawn_orb_from_paddle(paddle: PlayerSpawn) -> void:
	if not orb_scene or not is_instance_valid(paddle):
		return
	var orb := orb_scene.instantiate() as GameOrb
	if not orb:
		return
	add_child(orb)
	orb.global_position = paddle.deflector.held_orb_position()
	orb.owner_player = paddle
	if is_instance_valid(paddle.controller):
		orb.hitbox.attacker_uuid = paddle.controller.uuid
	orb.core_hit.connect(_on_orb_core_hit)
	# The orb spawns on its own paddle; clear that overlap briefly so it can leave,
	# then let it collide normally when it comes back.
	orb.ignore_collision_with(paddle.deflector, LAUNCH_CLEARANCE_TIME)
	orb.launch(_launch_direction(paddle.deflector), _speed)
	active_orbs.append(orb)

## Launch aim: straight at the core when the paddle is still, up to
## AIM_MAX_ANGLE toward the paddle's movement direction when it is sliding.
func _launch_direction(paddle: DeflectorPlayer) -> Vector3:
	var to_center := -paddle.global_position
	to_center.y = 0.0
	var tangent := paddle._tangent()
	var lateral := clampf(paddle.velocity.dot(tangent) / DeflectorPlayer.MOVE_SPEED, -1.0, 1.0)
	var dir := to_center.normalized() + tangent * lateral * tan(AIM_MAX_ANGLE)
	return dir.normalized()

## Called when an orb exited the arena through a player's goal area → that player
## missed it and loses a life. The orb returns to its launcher's paddle.
func on_orb_passed(player: PlayerSpawn, orb: GameOrb) -> void:
	if phase != Phase.PLAYING or not is_instance_valid(orb) or orb.is_resolved():
		return
	var launcher := orb.owner_player
	player.lives -= 1
	player.flash_hit()
	lives_updated.emit(_build_lives_data())
	if player.lives <= 0:
		_eliminate_player(player)
	orb.resolve()
	active_orbs.erase(orb)
	_schedule_respawn(launcher)
	if _get_alive_count() == 0:
		_end_round()

func _schedule_respawn(player: PlayerSpawn) -> void:
	if not is_instance_valid(player) or player.eliminated or player.has_orb:
		return
	if _has_active_orbs_for(player):
		return
	get_tree().create_timer(RESPAWN_DELAY).timeout.connect(
		func(): _respawn_orb_for(player), CONNECT_ONE_SHOT)

## True when [param player] still owns at least one orb in play. Respawn is
## delayed until the whole orb family is gone (pong-style re-serve).
func _has_active_orbs_for(player: PlayerSpawn) -> bool:
	for orb in active_orbs:
		if is_instance_valid(orb) and not orb.is_resolved() and orb.owner_player == player:
			return true
	return false

func _on_core_health_changed(hp: int, _max_hp: int) -> void:
	core_health_updated.emit(hp)

## Records core damage attributed to a mobile player and gives the launcher its
## replacement orb, since the orb is removed on impact.
func _on_orb_core_hit(orb: GameOrb, attacker_uuid: String, amount: int) -> void:
	if attacker_uuid != "":
		_core_damage[attacker_uuid] = int(_core_damage.get(attacker_uuid, 0)) + amount
	active_orbs.erase(orb)
	if is_instance_valid(orb.owner_player):
		_schedule_respawn(orb.owner_player)

func _eliminate_player(player: PlayerSpawn) -> void:
	if player.eliminated:
		return
	player.eliminate()
	_elimination_order.append(player)
	var to_remove: Array[GameOrb] = []
	for orb in active_orbs:
		if is_instance_valid(orb) and orb.owner_player == player:
			to_remove.append(orb)
	for orb in to_remove:
		orb.resolve()
		active_orbs.erase(orb)

func _respawn_orb_for(player: PlayerSpawn) -> void:
	if phase != Phase.PLAYING or not is_instance_valid(player):
		return
	if player.eliminated or player.has_orb:
		return
	if _has_active_orbs_for(player):
		return
	player.has_orb = true
	player.set_orb_ready()

func _get_alive_count() -> int:
	var n := 0
	for d in deflectors:
		if is_instance_valid(d) and not d.eliminated and d.lives > 0:
			n += 1
	return n

func _build_lives_data() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for d in deflectors:
		if is_instance_valid(d.controller):
			out.append({"uuid": d.controller.uuid, "lives": d.lives})
	return out

func _build_scores() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.append({
		"name": "VR",
		"score": _vr_score(),
	})
	for d in deflectors:
		out.append({
			"name": _player_display_name(d),
			"score": _mobile_score(d),
		})
	return out

## VR score: surviving core health plus a bonus per active (swung) shield block.
func _vr_score() -> int:
	var core_health := core.health if is_instance_valid(core) else 0
	return core_health * 100 + _active_shield_blocks * 10

## Mobile score: lives kept plus a bonus per point of core damage dealt.
func _mobile_score(d: PlayerSpawn) -> int:
	if not is_instance_valid(d.controller):
		return d.lives * 100
	var damage := int(_core_damage.get(d.controller.uuid, 0))
	return d.lives * 100 + damage * 10

## Display name for a deflector: `P#` from the controller's color index so real
## players and AI both map to the same shared palette naming. Never a raw UUID.
func _player_display_name(d: PlayerSpawn) -> String:
	if not is_instance_valid(d.controller):
		return "P??"
	var idx := d.controller.get_color_idx()
	if idx < 0:
		return "P??"
	return "P%d" % (idx + 1)

func _end_round() -> void:
	if phase == Phase.ENDED:
		return
	phase = Phase.ENDED
	for d in deflectors:
		d.has_orb = false
	_clear_power_up()
	for orb in active_orbs:
		if is_instance_valid(orb):
			orb.queue_free()
	active_orbs.clear()
	round_ended.emit(_build_scores())

func _on_clients_changed() -> void:
	if phase == Phase.WAITING:
		_sync_deflectors()

## Finds the pre-placed PlayerSpawn slots and sorts them by their angle around
## the core so slot index i matches octant i. All start released.
func _collect_slot_deflectors() -> void:
	slot_deflectors.clear()
	for node in get_tree().get_nodes_in_group(PlayerSpawn.SPAWN_GROUP):
		var d := node as PlayerSpawn
		if d and is_instance_valid(d):
			slot_deflectors.append(d)
	slot_deflectors.sort_custom(func(a: PlayerSpawn, b: PlayerSpawn) -> bool:
		return a.base_angle < b.base_angle)
	for d in slot_deflectors:
		d.release()

func _slot_for_player(i: int, player_count: int) -> int:
	return roundi(float(i) * 8.0 / float(player_count))

## Reassigns slots to the active players. Unused slots are released back to the
## pool and everyone recomputes their slot from scratch, so a player count change
## redistributes fairly around the ring.
func _sync_deflectors() -> void:
	if slot_deflectors.is_empty():
		return
	var active: Array[ClientController] = PlayerManager.get_active_players()
	active.append_array(ai_controllers)
	var n := mini(active.size(), slot_deflectors.size())
	if _assignments_match(active, n):
		return
	for d in deflectors.duplicate():
		_release_deflector(d)
	for i in n:
		var d := slot_deflectors[_slot_for_player(i, active.size())]
		_assign_deflector(d, active[i])

## True when the current slot/controller mapping already equals the one a fresh
## sync would produce. Avoids release/re-assign churn (which replays the wall
## animations) when nothing changed, e.g. going from prepare to game phase.
func _assignments_match(active: Array[ClientController], count: int) -> bool:
	if deflectors.size() != count:
		return false
	for i in count:
		var expected := slot_deflectors[_slot_for_player(i, active.size())]
		if deflectors[i] != expected or expected.controller != active[i]:
			return false
	return true

func _assign_deflector(d: PlayerSpawn, controller: ClientController) -> void:
	d.assign(controller, self)
	deflectors.append(d)

func _release_deflector(d: PlayerSpawn) -> void:
	d.release()
	deflectors.erase(d)

func _set_speed(value: float) -> void:
	_speed = value
	for orb in active_orbs:
		if not is_instance_valid(orb) or orb.is_resolved():
			continue
		if orb.velocity == Vector3.ZERO:
			continue
		orb.velocity = orb.velocity.normalized() * _speed
	speed_updated.emit(_speed)

func _prune_orbs() -> void:
	var i := 0
	while i < active_orbs.size():
		if not is_instance_valid(active_orbs[i]):
			active_orbs.remove_at(i)
		else:
			i += 1
