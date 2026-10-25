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

enum Phase { WAITING, PLAYING, ENDED }

@export var orb_scene: PackedScene

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

func start_round() -> void:
	phase = Phase.PLAYING
	_speed = ORB_SPEED_BASE
	time_remaining = ROUND_TIME
	_elimination_order.clear()
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
	for d in deflectors:
		d.has_orb = false
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
	var forward := orb.velocity.normalized()
	var angle := deg_to_rad(SABER_SPLIT_ANGLE_DEG)
	orb.launch(forward.rotated(Vector3.UP, angle), speed)
	_spawn_split_orb(orb, forward.rotated(Vector3.UP, -angle), speed)

## Creates the second orb from a saber slice. It keeps the same owner and speed
## so both halves can still hit any mobile player.
func _spawn_split_orb(source: GameOrb, direction: Vector3, speed: float) -> void:
	if not orb_scene:
		return
	var clone := orb_scene.instantiate() as GameOrb
	if not clone:
		return
	add_child(clone)
	clone.global_position = source.global_position
	clone.owner_player = source.owner_player
	if is_instance_valid(source.hitbox) and is_instance_valid(clone.hitbox):
		clone.hitbox.attacker_uuid = source.hitbox.attacker_uuid
	clone.launch(direction, speed)
	active_orbs.append(clone)

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
	get_tree().create_timer(RESPAWN_DELAY).timeout.connect(
		func(): _respawn_orb_for(player), CONNECT_ONE_SHOT)

func _on_core_health_changed(hp: int, _max_hp: int) -> void:
	core_health_updated.emit(hp)

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
	var alive: Array[PlayerSpawn] = []
	var eliminated: Array[PlayerSpawn] = []
	for d in deflectors:
		if d.eliminated:
			eliminated.append(d)
		else:
			alive.append(d)
	var rank := 1
	alive.sort_custom(func(a, b): return a.lives > b.lives)
	for d in alive:
		out.append({
			"name": d.player_name,
			"score": deflectors.size() - rank + 1,
			"lives": d.lives,
			"survived": true,
			"rank": rank,
		})
		rank += 1
	for i in range(eliminated.size() - 1, -1, -1):
		var d := eliminated[i]
		out.append({
			"name": d.player_name,
			"score": deflectors.size() - rank + 1,
			"lives": 0,
			"survived": false,
			"rank": rank,
		})
		rank += 1
	return out

func _end_round() -> void:
	if phase == Phase.ENDED:
		return
	phase = Phase.ENDED
	for d in deflectors:
		d.has_orb = false
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
