class_name CastlePlayerUI
extends JoinedPlayer

signal player_spawned

@export var firepower_label: Label
@export var firepower := 1:
	set(v):
		firepower = v
		if firepower_label:
			firepower_label.text = "%d" % firepower
		if game_client:
			StatsManager.record_firepower(game_client.uuid, firepower)
			
@export var dash_icon: Control
@export var shield_icon: Control

@onready var respawn_timer: Timer = $RespawnTimer
@onready var skill_timer: Timer = $SkillTimer

var current_player: FPSPlayer
var alive := false
var player_spawner: PlayerSpawner
var _game_started := false
var selected_skill : = FPSPlayer.Skill.NONE

func _ready():
	super()
	self.firepower = firepower
	player_spawner = get_tree().get_first_node_in_group("player_spawner")
	game_client.primary_action_pressed.connect(_handle_click)
	game_client.secondary_action_pressed.connect(_handle_secondary)

func can_respawn() -> bool:
	return not alive and respawn_timer.is_stopped()

func _handle_secondary() -> void:
	if is_ready and (not _game_started or get_tree().paused):
		reset_ready()

func _handle_click() -> void:
	if not is_ready:
		set_ready()
	else:
		if not _game_started:
			reset_ready()
		elif not get_tree().paused:
			spawn_player()

func spawn_player():
	if not can_respawn():
		return

	player_spawned.emit()
	var player = player_spawner.create_player(game_client)
	player.global_rotation.y = PI
	player.firepower = firepower
	player.reached_gate.connect(func(): firepower += 1)
	player.died.connect(func():
		alive = false
		StatsManager.record_death(game_client.uuid)
		respawn_timer.start(player.respawn_time)
	)
	player.snap_zone.has_picked_up.connect(func(obj: XRToolsPickable):
		if obj is Bomb:
			(obj as Bomb).hit_box.attacker_uuid = game_client.uuid
	)
	current_player = player
	alive = true
