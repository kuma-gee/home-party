class_name AISpawner
extends Node

enum _State { IDLE, MOVE_TO_CATAPULT, AT_CATAPULT, MOVE_TO_BOMB, CARRY_BOMB, DEAD }

var logger := KumaLog.new("AISpawner")

@export var player_spawner: PlayerSpawner
@export var ai_player_count: int = 3
@export var catapult_wait_min: float = 5.0
@export var catapult_wait_max: float = 15.0
@export var respawn_delay: float = 3.0
@export var skill_dodge_chance: float = 0.4
@export var skill_check_radius: float = 5.0

var _agents: Array[FPSPlayer] = []
var _controllers: Array[AIClientController] = []
var _agent_states: Array[int] = []
var _agent_targets: Array[Vector3] = []
var _agent_timers: Array[float] = []
var _spawn_positions: Array[Vector3] = []
var _agent_skill_cooldowns: Array[float] = []

var _gate: Node3D = null
var _active := false

func _ready() -> void:
	if PlayerManager.playing_clients.is_empty():
		call_deferred("_start_ai")

func _start_ai() -> void:
	var scene := _resolve_player_scene()
	if scene == null:
		logger.warn("No player_scene set — AI spawner disabled")
		return

	_active = true
	logger.info("No players connected — spawning %d AI agents" % ai_player_count)

	var catapults := get_tree().get_nodes_in_group("catapult")
	if catapults.size() > 0:
		_gate = (catapults[0] as Catapult).gate_target

	await get_tree().create_timer(4.0).timeout
	_init_agents(scene)

func _init_agents(scene: PackedScene):
	var spawn_origin := _get_spawn_origin()
	for i in ai_player_count:
		var spawn_pos := spawn_origin + Vector3.RIGHT * ((i - (ai_player_count - 1) / 2.0) * 1.5)
		var controller := AIClientController.new()
		add_child(controller)
		var player := _spawn_agent(scene, i, spawn_pos, controller)

		_controllers.append(controller)
		_connect_died(player, i)
		_agents.append(player)
		_agent_states.append(_State.IDLE)
		_agent_targets.append(spawn_pos)
		_agent_timers.append(i * 0.5)  # stagger initial decisions
		_spawn_positions.append(spawn_pos)
		_agent_skill_cooldowns.append(0.0)

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

	var chosen_skill: FPSPlayer.Skill = FPSPlayer.Skill.DASH if randi() % 2 == 0 else FPSPlayer.Skill.SHIELD
	player.skill = chosen_skill

	var cooldown_timer := Timer.new()
	cooldown_timer.one_shot = true
	cooldown_timer.wait_time = 1.5 if chosen_skill == FPSPlayer.Skill.DASH else 3.0
	player.add_child(cooldown_timer)
	player.skill_cooldown_timer = cooldown_timer

	controller.bind_player(player)
	Staging.add_scene_child(player)
	return player


func _on_agent_died(i: int, respawn_time: float) -> void:
	_controllers[i].clear_player()
	_agents[i].queue_free()
	_agent_states[i] = _State.DEAD
	_agent_timers[i] = respawn_time


func _respawn_agent(i: int) -> void:
	var scene := _resolve_player_scene()
	if scene == null:
		return
	var spawn_pos := _spawn_positions[i]
	var player := _spawn_agent(scene, i, spawn_pos, _controllers[i])
	_connect_died(player, i)
	_agents[i] = player
	_agent_states[i] = _State.IDLE
	_agent_timers[i] = randf_range(1.0, 2.0)
	_agent_skill_cooldowns[i] = 0.0


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

		_State.MOVE_TO_CATAPULT, _State.MOVE_TO_BOMB:
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
				_agent_timers[i] = randf_range(1.0, 3.0)
		_State.DEAD:
			pass  # handled in _process

	_check_skill_dodge(i, delta)


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

	if threat_found and randf() < skill_dodge_chance:
		_controllers[i].trigger_skill()
		_agent_skill_cooldowns[i] = 2.0


func _on_arrived(i: int) -> void:
	match _agent_states[i]:
		_State.MOVE_TO_CATAPULT:
			_agent_states[i] = _State.AT_CATAPULT
			_agent_timers[i] = randf_range(catapult_wait_min, catapult_wait_max)
		_State.MOVE_TO_BOMB:
			_pick_up_bomb(i)
		_State.CARRY_BOMB:
			_deliver_bomb(i)


func _decide_action(i: int) -> void:
	var catapults := get_tree().get_nodes_in_group("catapult")
	var bombs := get_tree().get_nodes_in_group("bomb")

	if not bombs.is_empty() and (catapults.is_empty() or randf() < 0.5):
		_head_to_bomb(i, bombs[randi() % bombs.size()] as Bomb)
	elif not catapults.is_empty():
		_head_to_catapult(i, catapults)
	else:
		_agent_states[i] = _State.IDLE
		_agent_timers[i] = 3.0


func _head_to_catapult(i: int, catapults: Array) -> void:
	var cat := catapults[randi() % catapults.size()] as Catapult
	_agent_targets[i] = cat.global_position
	_agent_states[i] = _State.MOVE_TO_CATAPULT


func _head_to_bomb(i: int, bomb: Bomb) -> void:
	_agent_targets[i] = bomb.global_position
	_agent_states[i] = _State.MOVE_TO_BOMB


func _pick_up_bomb(i: int) -> void:
	_agent_targets[i] = _gate.global_position
	_agent_states[i] = _State.CARRY_BOMB


func _deliver_bomb(i: int) -> void:
	_agent_states[i] = _State.IDLE
	_agent_timers[i] = randf_range(2.0, 5.0)
