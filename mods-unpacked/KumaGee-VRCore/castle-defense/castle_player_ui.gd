class_name CastlePlayerUI
extends JoinedPlayer

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

var alive := false
var player_spawner: PlayerSpawner
var selected_skill : = FPSPlayer.Skill.NONE:
	set(v):
		selected_skill = v
		dash_icon.visible = v == FPSPlayer.Skill.DASH
		shield_icon.visible = v == FPSPlayer.Skill.SHIELD
		skill_timer.wait_time = dash_cooldown if v == FPSPlayer.Skill.DASH else shield_cooldown

func _ready():
	super()
	firepower = 1
	selected_skill = FPSPlayer.Skill.NONE
	player_spawner = get_tree().get_first_node_in_group("player_spawner")
	game_client.input_received.connect(func(input, value):
		if not value: return
		if input == "skill_dash":
			selected_skill = FPSPlayer.Skill.DASH
			set_ready()
		elif input == "skill_shield":
			selected_skill = FPSPlayer.Skill.SHIELD
			set_ready()
		elif input == "skill_none":
			selected_skill = FPSPlayer.Skill.NONE
			reset_ready()
		elif input == "action":
			spawn_player()
	)

func can_respawn() -> bool:
	return not alive and respawn_timer.is_stopped()

func spawn_player():
	if not can_respawn():
		return

	var player = player_spawner.create_player(game_client)
	player.global_rotation.y = PI
	player.firepower = firepower
	player.skill_cooldown_timer = skill_timer
	player.reached_gate.connect(func(): firepower += 1)
	player.died.connect(func():
		alive = false
		respawn_timer.start(player.respawn_time)
		player.queue_free()
	)
	alive = true
