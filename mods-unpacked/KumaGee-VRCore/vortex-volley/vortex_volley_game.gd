class_name VortexVolleyGame
extends Node

signal round_ended(scores: Array[Dictionary])
signal lives_updated(data: Array[Dictionary])

const ARENA_RADIUS: float = 4.5
const ORB_SPEED_BASE: float = 4.5
const ORB_SPEED_MAX: float = 9.0
const ORB_SPEED_STEP: float = 0.3
const START_LIVES: int = 3
const RESPAWN_DELAY: float = 1.5
const MIN_THROW_SPEED: float = 0.5
const CENTER_SPAWN_RADIUS: float = 0.45

enum Phase { WAITING, PLAYING, ENDED }

@export var deflector_scene: PackedScene
@export var orb_scene: PackedScene

var phase: Phase = Phase.WAITING
var deflectors: Array[DeflectorPlayer] = []
var active_orbs: Array[GameOrb] = []

var _speed: float = ORB_SPEED_BASE
var _max_active_balls: int = 1
var _target_ball_count: int = 1

func _ready() -> void:
	PlayerManager.clients_changed.connect(_on_clients_changed)

func _process(delta: float) -> void:
	if phase != Phase.PLAYING:
		return
	_prune_orbs()
	for orb in active_orbs.duplicate():
		if not is_instance_valid(orb) or orb.is_picked_up():
			continue
		orb.global_position += orb.velocity * delta
		orb.global_position.y = GameOrb.ORB_HEIGHT
		_check_wall_bounce(orb)

func start_round() -> void:
	phase = Phase.PLAYING
	_speed = ORB_SPEED_BASE
	_sync_deflectors()
	_max_active_balls = maxi(deflectors.size(), 1)
	_target_ball_count = 1
	_send_to_all(JSON.stringify({"type": "phase", "phase": "playing"}))
	_spawn_orbs_until_target()

func reset() -> void:
	phase = Phase.WAITING
	_speed = ORB_SPEED_BASE
	_target_ball_count = 1
	_max_active_balls = 1
	for d in deflectors:
		if is_instance_valid(d):
			d.lives = START_LIVES
	for orb in active_orbs:
		if is_instance_valid(orb):
			orb.queue_free()
	active_orbs.clear()

func on_orb_hit_by_vr(orb: GameOrb, new_velocity: Vector3) -> void:
	if phase != Phase.PLAYING or not is_instance_valid(orb) or not active_orbs.has(orb):
		return
	_launch_orb(orb, new_velocity)

func _spawn_waiting_orb() -> void:
	if not orb_scene:
		return
	var orb := orb_scene.instantiate() as GameOrb
	if not orb:
		return
	add_child(orb)
	orb.global_position = _get_center_spawn_position(active_orbs.size())
	orb.velocity = Vector3.ZERO
	orb.thrown.connect(_on_orb_thrown)
	active_orbs.append(orb)

func _spawn_orbs_until_target() -> void:
	if phase != Phase.PLAYING:
		return
	_prune_orbs()
	var desired := mini(_target_ball_count, _max_active_balls)
	while active_orbs.size() < desired:
		_spawn_waiting_orb()

func _check_wall_bounce(orb: GameOrb) -> void:
	if not is_instance_valid(orb):
		return
	var pos := orb.global_position
	var flat := Vector2(pos.x, pos.z)
	if flat.length() < ARENA_RADIUS - 0.25:
		return

	var impact_angle := atan2(pos.z, pos.x)
	var paddle := _paddle_at_angle(impact_angle)
	if paddle:
		var inward := Vector3(-flat.normalized().x, 0.0, -flat.normalized().y)
		orb.velocity = orb.velocity.bounce(inward).normalized() * _speed
		_set_speed(minf(_speed + ORB_SPEED_STEP, ORB_SPEED_MAX))
		paddle.flash_hit()
	else:
		var owner := _zone_owner_at_angle(impact_angle)
		if owner:
			_score_on(owner, orb)

func _paddle_at_angle(angle: float) -> DeflectorPlayer:
	for d in deflectors:
		if is_instance_valid(d) and d.lives > 0 and d.covers_angle(angle):
			return d
	return null

func _zone_owner_at_angle(angle: float) -> DeflectorPlayer:
	for d in deflectors:
		if is_instance_valid(d) and d.is_base_zone(angle):
			return d
	return null

func _score_on(player: DeflectorPlayer, orb: GameOrb) -> void:
	player.lives -= 1
	if player.controller is GameClient:
		(player.controller as GameClient).send_text(JSON.stringify({
			"type": "scored",
			"lives": player.lives,
		}))

	lives_updated.emit(_build_lives_data())

	if is_instance_valid(orb):
		active_orbs.erase(orb)
		orb.queue_free()

	if _get_alive_count() <= 1:
		_end_round()
		return

	_set_speed(minf(_speed + ORB_SPEED_STEP, ORB_SPEED_MAX))
	_target_ball_count = mini(_target_ball_count + 1, _max_active_balls)
	get_tree().create_timer(RESPAWN_DELAY).timeout.connect(_spawn_orbs_until_target, CONNECT_ONE_SHOT)

func _end_round() -> void:
	if phase == Phase.ENDED:
		return
	phase = Phase.ENDED
	for orb in active_orbs:
		if is_instance_valid(orb):
			orb.queue_free()
	active_orbs.clear()
	_send_to_all(JSON.stringify({"type": "phase", "phase": "ended"}))
	round_ended.emit(_build_scores())

func _get_alive_count() -> int:
	var n := 0
	for d in deflectors:
		if is_instance_valid(d) and d.lives > 0:
			n += 1
	return n

func _build_lives_data() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for d in deflectors:
		out.append({"name": d.player_name, "lives": d.lives})
	return out

func _build_scores() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for d in deflectors:
		out.append({
			"name": d.player_name,
			"score": d.lives,
			"survived": d.lives > 0,
		})
	return out

func _on_clients_changed() -> void:
	if phase == Phase.WAITING:
		_sync_deflectors()

func _sync_deflectors() -> void:
	var active := PlayerManager.get_active_players()
	var i := 0
	while i < deflectors.size():
		if not active.has(deflectors[i].controller):
			deflectors[i].queue_free()
			deflectors.remove_at(i)
		else:
			i += 1
	for player in active:
		var found := false
		for d in deflectors:
			if d.controller == player:
				found = true
				break
		if not found:
			_add_deflector(player)
	_assign_zones()

func _add_deflector(controller: ClientController) -> void:
	if not deflector_scene:
		return
	var d := deflector_scene.instantiate() as DeflectorPlayer
	if not d:
		return
	add_child(d)
	d.controller = controller
	d.player_name = controller.uuid
	d.lives = START_LIVES
	d.arena_radius = ARENA_RADIUS
	deflectors.append(d)
	controller.moved.connect(d._on_moved)

func _assign_zones() -> void:
	var n := deflectors.size()
	if n == 0:
		return
	for i in n:
		deflectors[i].base_angle = float(i) * TAU / float(n)
		deflectors[i].zone_half_arc = TAU / float(n) * 0.5
		deflectors[i].update_position(ARENA_RADIUS)

func _send_to_all(msg: String) -> void:
	for d in deflectors:
		if is_instance_valid(d) and d.controller is GameClient:
			(d.controller as GameClient).send_text(msg)

func _on_orb_thrown(orb: GameOrb, release_velocity: Vector3) -> void:
	if phase != Phase.PLAYING or not is_instance_valid(orb) or not active_orbs.has(orb):
		return
	var flat := Vector3(release_velocity.x, 0.0, release_velocity.z)
	if flat.length() < MIN_THROW_SPEED:
		orb.velocity = Vector3.ZERO
		orb.global_position.y = GameOrb.ORB_HEIGHT
		return
	_launch_orb(orb, flat)

func _launch_orb(orb: GameOrb, direction: Vector3) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if not is_instance_valid(orb) or flat == Vector3.ZERO:
		return
	orb.velocity = flat.normalized() * _speed
	orb.global_position.y = GameOrb.ORB_HEIGHT

func _set_speed(value: float) -> void:
	_speed = value
	for orb in active_orbs:
		if not is_instance_valid(orb):
			continue
		if orb.velocity == Vector3.ZERO:
			continue
		orb.velocity = orb.velocity.normalized() * _speed

func _prune_orbs() -> void:
	var i := 0
	while i < active_orbs.size():
		if not is_instance_valid(active_orbs[i]):
			active_orbs.remove_at(i)
		else:
			i += 1

func _get_center_spawn_position(index: int) -> Vector3:
	if index <= 0:
		return Vector3(0.0, GameOrb.ORB_HEIGHT, 0.0)
	var angle := float(index - 1) * TAU / float(maxi(_max_active_balls - 1, 1))
	return Vector3(cos(angle), 0.0, sin(angle)) * CENTER_SPAWN_RADIUS + Vector3(0.0, GameOrb.ORB_HEIGHT, 0.0)
