class_name AISpawner
extends Node

enum _State { IDLE, MOVE_TO_CATAPULT, AT_CATAPULT, MOVE_TO_BOMB, CARRY_BOMB, DEAD }

var logger := KumaLog.new("AISpawner")

@export var player_spawner: PlayerSpawner
@export var catapult_wait_min: float = 5.0
@export var catapult_wait_max: float = 15.0
@export var respawn_delay: float = 3.0
@export var spawn_delay_min: float = 0.5
@export var spawn_delay_max: float = 3.0
@export var skill_dodge_chance: float = 0.4
@export var skill_check_radius: float = 5.0

var _agents: Array[FPSPlayer] = []
var _controllers: Array[AIClientController] = []
var _agent_states: Array[int] = []
var _agent_targets: Array[Vector3] = []
var _agent_timers: Array[float] = []
var _spawn_positions: Array[Vector3] = []
var _agent_skill_cooldowns: Array[float] = []
var _agent_bombs: Array[Bomb] = []

var _gate: Node3D = null
var _active := false
var _game_started := false

func _ready() -> void:
	var castle_defense := get_parent()
	if castle_defense and castle_defense.has_signal("game_started"):
		castle_defense.game_started.connect(_on_game_started)
	elif PlayerManager.playing_clients.is_empty():
		call_deferred("_start_ai")

func _on_game_started() -> void:
	_game_started = true
	if PlayerManager.playing_clients.is_empty():
		call_deferred("_start_ai")

func _start_ai() -> void:
	var scene := _resolve_player_scene()
	if scene == null:
		logger.warn("No player_scene set — AI spawner disabled")
		return

	_active = true
	var count := GameSettings.get_ai_count()
	logger.info("No players connected — spawning %d AI agents" % count)

	var catapults := get_tree().get_nodes_in_group("catapult")
	if catapults.size() > 0:
		_gate = (catapults[0] as Catapult).gate_target

	await get_tree().create_timer(4.0).timeout
	_init_agents(scene, count)

func _init_agents(scene: PackedScene, count: int):
	var spawn_origin := _get_spawn_origin()
	for i in count:
		var delay = randf_range(spawn_delay_min, spawn_delay_max)
		get_tree().create_timer(delay).timeout.connect(func(): _init_controller(scene, count, i, spawn_origin))

func _init_controller(scene: PackedScene, count: int, i: int, spawn_origin: Vector3):
	var spawn_pos := spawn_origin + Vector3.RIGHT * ((i - (count - 1) / 2.0) * 1.5)
	var controller := AIClientController.new()
	add_child(controller)
	var player := _spawn_agent(scene, i, spawn_pos, controller)

	_controllers.append(controller)
	_connect_died(player, i)
	_agents.append(player)
	_agent_states.append(_State.IDLE)
	_agent_targets.append(spawn_pos)
	_agent_timers.append(randf_range(0.5, 3.0))
	_spawn_positions.append(spawn_pos)
	_agent_skill_cooldowns.append(0.0)
	_agent_bombs.append(null)
	

func _resolve_player_scene() -> PackedScene:
	return player_spawner.player_scene

func _get_spawn_origin() -> Vector3:
	return player_spawner.global_position


func _connect_died(player: FPSPlayer, i: int) -> void:
	player.died.connect(func(): _on_agent_died(i, player.respawn_time))


func _spawn_agent(scene: PackedScene, i: int, spawn_pos: Vector3, controller: AIClientController) -> FPSPlayer:
	var player := scene.instantiate() as FPSPlayer
	player.player_num = i
	player.position = spawn_pos

	player.skill = FPSPlayer.Skill.NONE

	controller.bind_player(player)
	Staging.add_scene_child(player)
	return player


func _on_agent_died(i: int, respawn_time: float) -> void:
	_controllers[i].clear_player()
	_agent_states[i] = _State.DEAD
	_agent_timers[i] = respawn_time + randf_range(-0.5, 0.5)


func _respawn_agent(i: int) -> void:
	var scene := _resolve_player_scene()
	if scene == null:
		return
	var spawn_pos := _spawn_positions[i] + Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
	var player := _spawn_agent(scene, i, spawn_pos, _controllers[i])
	_connect_died(player, i)
	_agents[i] = player
	_agent_states[i] = _State.IDLE
	_agent_timers[i] = randf_range(1.0, 2.5)
	_agent_skill_cooldowns[i] = 0.0
	_agent_bombs[i] = null


func _process(delta: float) -> void:
	if not _active:
		return
	for i in _agents.size():
		if _agent_states[i] == _State.DEAD:
			_agent_timers[i] -= delta
			if _agent_timers[i] <= 0.0:
				_respawn_agent(i)
		elif is_instance_valid(_agents[i]):
			_update_agent(i, delta)


func _update_agent(i: int, delta: float) -> void:
	var player := _agents[i]
	var controller = player.game_client
	var state: int = _agent_states[i]

	match state:
		_State.IDLE:
			controller.target = player.global_position
			_agent_timers[i] -= delta
			if _agent_timers[i] <= 0.0:
				_decide_action(i)

		_State.MOVE_TO_CATAPULT:
			controller.target = _agent_targets[i]
			var diff := player.global_position - _agent_targets[i]
			diff.y = 0.0
			if diff.length() < 0.5:
				_on_arrived(i)

		_State.MOVE_TO_BOMB:
			if is_instance_valid(_agent_bombs[i]):
				_agent_targets[i] = _agent_bombs[i].global_position
			controller.target = _agent_targets[i]
			var diff := player.global_position - _agent_targets[i]
			diff.y = 0.0
			if diff.length() < 0.5:
				_on_arrived(i)

		_State.CARRY_BOMB:
			controller.target = _agent_targets[i]
			var diff := player.global_position - _agent_targets[i]
			diff.y = 0.0
			if diff.length() < 0.5:
				_on_arrived(i)

		_State.AT_CATAPULT:
			controller.target = player.global_position
			_agent_timers[i] -= delta
			if _agent_timers[i] <= 0.0:
				_agent_states[i] = _State.IDLE
				_agent_timers[i] = randf_range(1.0, 2.0)
		_State.DEAD:
			pass

	_check_skill_dodge(i, delta)


func _get_catapult_wait(_i: int) -> float:
	return randf_range(catapult_wait_min, catapult_wait_max)


func _check_skill_dodge(i: int, delta: float) -> void:
	_agent_skill_cooldowns[i] = maxf(_agent_skill_cooldowns[i] - delta, 0.0)
	if _agent_skill_cooldowns[i] > 0.0:
		return

	var player := _agents[i]
	if player.skill == FPSPlayer.Skill.NONE:
		return

	var player_pos := player.global_position
	var radius_sq := skill_check_radius * skill_check_radius
	var threat_found := false

	for projectile in get_tree().get_nodes_in_group("arrow"):
		if (projectile as Node3D).global_position.distance_squared_to(player_pos) < radius_sq:
			threat_found = true
			break

	if not threat_found:
		for projectile in get_tree().get_nodes_in_group("boulder"):
			if (projectile as Node3D).global_position.distance_squared_to(player_pos) < radius_sq:
				threat_found = true
				break

	var dodge_chance := skill_dodge_chance

	if threat_found and randf() < dodge_chance:
		_controllers[i].trigger_skill()
		_agent_skill_cooldowns[i] = 2.0


func _on_arrived(i: int) -> void:
	match _agent_states[i]:
		_State.MOVE_TO_CATAPULT:
			_agent_states[i] = _State.AT_CATAPULT
			_agent_timers[i] = _get_catapult_wait(i)
		_State.MOVE_TO_BOMB:
			_pick_up_bomb(i)
		_State.CARRY_BOMB:
			_deliver_bomb(i)


func _decide_action(i: int) -> void:
	var catapults := get_tree().get_nodes_in_group("catapult")
	var bombs := get_tree().get_nodes_in_group("bomb")

	if bombs.is_empty() and catapults.is_empty():
		_agent_states[i] = _State.IDLE
		_agent_timers[i] = randf_range(2.0, 4.0)
	elif bombs.is_empty():
		_head_to_catapult(i, catapults)
	elif catapults.is_empty():
		_head_to_bomb(i, bombs[randi() % bombs.size()] as Bomb)
	elif randf() < 0.5:
		_head_to_bomb(i, bombs[randi() % bombs.size()] as Bomb)
	else:
		_head_to_catapult(i, catapults)


func _head_to_catapult(i: int, catapults: Array) -> void:
	var cat := catapults[randi() % catapults.size()] as Catapult
	_agent_targets[i] = cat.global_position
	_agent_states[i] = _State.MOVE_TO_CATAPULT


func _head_to_bomb(i: int, bomb: Bomb) -> void:
	_agent_bombs[i] = bomb
	_agent_targets[i] = bomb.global_position
	_agent_states[i] = _State.MOVE_TO_BOMB


func _pick_up_bomb(i: int) -> void:
	_agent_bombs[i] = null
	_agent_targets[i] = _gate.global_position
	_agent_states[i] = _State.CARRY_BOMB


func _deliver_bomb(i: int) -> void:
	_agent_states[i] = _State.IDLE
	_agent_timers[i] = randf_range(2.0, 5.0)


func stop() -> void:
	_active = false

func stop_and_clear() -> void:
	_active = false
	for i in _agents.size():
		if is_instance_valid(_agents[i]) and not _agents[i].is_dead:
			_agents[i].on_hurtbox_died()
