class_name FPSPlayer
extends CharacterBody3D

signal reached_gate()
signal died()
signal skill_activated()

enum Skill {
	NONE,
	DASH,
	SHIELD,
}

@export var speed := 1.0
@export var acceleration := 10.0
@export var push_force = 2.0

@export var body: Node3D
@export var color_ring: ColorRing
@export var snap_zone: XRToolsSnapZone

@export_category("Skills")
@export var dash_speed := 8.0
@export var dash_time := 0.15
@export var shield_duration := 1.0

@export_category("Death")
@export var min_respawn_time := 3.0
@export var max_respawn_time := 6.0
@export var explosion_respawn_time := 2.0

@export_category("Animation")
@export var animation: AnimationPlayer
@export var idle_anim := "Idle_B" 
@export var running_anim := "Running_A"
@export var spawn_anim := "Spawn_Ground"

@onready var ground_spring_cast: GroundSpringCast = $GroundSpringCast
@onready var hurtbox: HurtBox = $Hurtbox
@onready var freeze_timer: Timer = $FreezeTimer
@onready var slow_restore_timer: Timer = $SlowRestoreTimer

var game_client: ClientController
var player_num := 0
var slow := 0.0
var respawn_time := 0.0
var is_spawning := true
var firepower := 1

var is_dashing := false
var is_shielded := false
var skill = Skill.NONE
var skill_cooldown_timer: Timer

func _ready():
	color_ring.set_color(PlayerList.get_color(player_num))
	hurtbox.died.connect(on_hurtbox_died)
	slow_restore_timer.timeout.connect(func(): slow = 0.0)
	animation.animation_finished.connect(func(anim):
		if anim == spawn_anim:
			is_spawning = false
			hurtbox.enabled = true
	)
	snap_zone.has_picked_up.connect(_on_pickup)
	animation.play(spawn_anim)
	game_client.primary_action_pressed.connect(activate_skill)

func trigger_explosion():
	reached_gate.emit()
	respawn_time = explosion_respawn_time

func _compute_respawn_delay_for_count(count: int) -> float:
	if count <= 2:
		return min_respawn_time
	if count >= 6:
		return max_respawn_time
	var t := float(count - 2) / float(6 - 2)
	return lerp(min_respawn_time, max_respawn_time, t)

func on_hurtbox_died():
	if respawn_time == 0.0:
		respawn_time = _compute_respawn_delay_for_count(PlayerManager.playing_clients.size())

	snap_zone.drop_object()
	died.emit()

func _on_pickup(obj: XRToolsPickable):
	if obj is Bomb:
		var bomb = obj as Bomb
		bomb.firepower = firepower
		#bomb.exploded.connect(func(): reached_gate.emit())

func freeze(time: float):
	if is_spawning: return
	freeze_timer.start(time)
	velocity = Vector3.ZERO
	animation.pause()

func apply_slow(slow_amount: float):
	slow = slow_amount
	slow_restore_timer.start()

func _physics_process(delta):
	if is_shielded:
		velocity = Vector3.ZERO
		return

	if not freeze_timer.is_stopped() or is_spawning or not is_instance_valid(game_client):
		if not is_dashing:
			return

	if is_dashing:
		ground_spring_cast.apply_gravity(self, delta)
		move_and_slide()
		return
	
	var direction = game_client.get_move()
	var _speed = speed * (1.0 - slow)

	if ground_spring_cast.is_grounded():
		velocity.x = lerp(velocity.x, direction.x * _speed, delta * acceleration)
		velocity.z = lerp(velocity.z, direction.y * _speed, delta * acceleration)
	else:
		velocity.x = lerp(velocity.x, direction.x * _speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.y * _speed, delta * 3.0)

	if direction:
		var dir = Vector3(direction.x, 0, direction.y)
		body.look_at(body.global_position + dir, Vector3.UP, true)

	animation.play(idle_anim if direction == Vector2.ZERO else running_anim)
	ground_spring_cast.apply_gravity(self, delta)
	move_and_slide()

	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider is FPSPlayer:
			var other_player = collider as FPSPlayer
			push_other_player(other_player)
	
func push_other_player(other_player: FPSPlayer) -> void:
	var push_direction = (other_player.global_position - global_position).normalized()

	if velocity.length() > 0 and other_player.velocity.length() < 0.1:
		other_player.velocity.x = push_direction.x * push_force
		other_player.velocity.z = push_direction.z * push_force

func activate_skill():
	match skill:
		Skill.DASH:
			dash()
		Skill.SHIELD:
			shield()

func dash() -> void:
	if is_spawning or not is_instance_valid(game_client) or not freeze_timer.is_stopped():
		return

	var direction = game_client.get_move()
	if direction == Vector2.ZERO:
		return

	if is_dashing or not skill_cooldown_timer.is_stopped():
		return

	is_dashing = true

	var dir3 = Vector3(direction.x, 0, direction.y)
	dir3 = dir3.normalized()

	velocity.x = dir3.x * dash_speed
	velocity.z = dir3.z * dash_speed

	animation.play(running_anim)
	await get_tree().create_timer(dash_time).timeout

	skill_activated.emit()
	is_dashing = false

func shield() -> void:
	if is_spawning or not is_instance_valid(hurtbox) or not skill_cooldown_timer.is_stopped():
		return
	
	is_shielded = true
	hurtbox.invulnerable(shield_duration)
	await get_tree().create_timer(shield_duration).timeout
	
	skill_activated.emit()
	is_shielded = false
