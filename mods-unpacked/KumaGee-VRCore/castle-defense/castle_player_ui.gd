class_name CastlePlayerUI
extends JoinedPlayer

signal skill_changed(skill: FPSPlayer.Skill)
signal player_spawned

@export var firepower_label: Label
@export var firepower := 1:
	set(v):
		firepower = v
		if firepower_label:
			firepower_label.text = "%d" % firepower
			
@export var dash_cooldown := 3.0
@export var shield_cooldown := 5.0
@export var dash_icon: Control
@export var shield_icon: Control

@onready var respawn_timer: Timer = $RespawnTimer
@onready var skill_timer: Timer = $SkillTimer

var current_player: FPSPlayer
var alive := false
var player_spawner: PlayerSpawner
var selected_skill : = FPSPlayer.Skill.NONE:
	set(v):
		selected_skill = v
		dash_icon.visible = v == FPSPlayer.Skill.DASH
		shield_icon.visible = v == FPSPlayer.Skill.SHIELD
		skill_timer.wait_time = dash_cooldown if v == FPSPlayer.Skill.DASH else shield_cooldown
		skill_changed.emit(v)

func _ready():
	super()
	firepower = 1
	selected_skill = FPSPlayer.Skill.DASH
	player_spawner = get_tree().get_first_node_in_group("player_spawner")
	game_client.primary_action_pressed.connect(_handle_click)
	game_client.secondary_action_pressed.connect(_handle_secondary)
	game_client.moved.connect(func(dir):
		if is_ready: return
		if dir.x > 0 and selected_skill == FPSPlayer.Skill.DASH:
			selected_skill = FPSPlayer.Skill.SHIELD
		elif dir.x < 0 and selected_skill == FPSPlayer.Skill.SHIELD:
			selected_skill = FPSPlayer.Skill.DASH
	)
	skill_timer.timeout.connect(func():
		if is_instance_valid(current_player):
			current_player.indicators.set_skill_ready(selected_skill)
	)

func can_respawn() -> bool:
	return not alive and respawn_timer.is_stopped()

func _handle_secondary() -> void:
	if is_ready and get_tree().paused:
		reset_ready()

func _handle_click() -> void:
	if not is_ready:
		set_ready()
	else:
		if get_tree().paused:
			reset_ready()
		else:
			spawn_player()

func spawn_player():
	if not can_respawn():
		return

	player_spawned.emit()
	var player = player_spawner.create_player(game_client)
	player.global_rotation.y = PI
	player.firepower = firepower
	player.skill = selected_skill
	player.skill_cooldown_timer = skill_timer
	player.reached_gate.connect(func(): firepower += 1)
	player.died.connect(func():
		alive = false
		StatsManager.record_death(game_client.uuid)
		respawn_timer.start(player.respawn_time)
		skill_timer.stop()
	)
	player.skill_activated.connect(func(): 
		var cooldown = dash_cooldown if selected_skill == FPSPlayer.Skill.DASH else shield_cooldown
		skill_timer.start(cooldown)
	)

	player.snap_zone.has_picked_up.connect(func(obj: XRToolsPickable):
		if obj is Bomb:
			(obj as Bomb).hit_box.attacker_uuid = game_client.uuid
	)
	current_player = player
	alive = true
