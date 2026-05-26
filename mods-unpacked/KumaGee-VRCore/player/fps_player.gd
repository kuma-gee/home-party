class_name FPSPlayer
extends CharacterBody3D

signal reached_gate()
signal died()
signal skill_activated()

const POISON_MAT = preload("uid://bymwrrnafu4mv")

enum Skill {
	NONE,
	DASH,
	SHIELD,
}

@export var camera_up_axis := Vector2(-1.0, 0.0)

@export var speed := 1.0
@export var acceleration := 10.0
@export var push_force = 2.0

@export var body: Node3D
@export var color_ring: ColorRing
@export var snap_zone: XRToolsSnapZone
@export var meshes: Array[MeshInstance3D] = []

@export_category("Skills")
@export var dash_speed := 8.0
@export var dash_time := 0.15
@export var dash_sfx: AudioStreamPlayer
@export var shield_duration := 1.0
@export var shield_activate_time := 0.5
@export var shield_vfx: MeshInstance3D
@export var dash_particles: GPUParticles3D

@export_category("Death")
@export var min_respawn_time := 3.0
@export var max_respawn_time := 6.0
@export var explosion_respawn_time := 2.0
@export var death_sound: RandomizedSfx

@export_category("Animation")
@export var animation: AnimationPlayer
@export var idle_anim := "Idle_B" 
@export var running_anim := "Running_A"
@export var spawn_anim := "Spawn_Ground"
@export var dash_anim := "Dash"
@export var death_anim := "Death_A"

@export_category("Poison Icon")
@export var poison_pulse_speed_min := 3.0
@export var poison_pulse_speed_max := 18.0
@export var poison_pulse_amplitude_min := 0.15
@export var poison_pulse_amplitude_max := 0.3
@export var poison_color_flash_threshold := 0.7

@onready var ground_spring_cast: GroundSpringCast = $GroundSpringCast
@onready var hurtbox: HurtBox = $Hurtbox
@onready var freeze_timer: Timer = $FreezeTimer
@onready var slow_restore_timer: Timer = $SlowRestoreTimer
@onready var poison_timer: Timer = $PoisonTimer
@onready var death_timer: Timer = $DeathTimer

@onready var poison_icon: Label3D = $PoisonIcon
var _poison_pulse_time := 0.0

var game_client: ClientController
var player_num := 0
var slow := 0.0
var respawn_time := 0.0
var is_spawning := true
var firepower := 1

var is_dead := false
var is_dashing := false
var is_shielded := false
var skill = Skill.NONE
var skill_cooldown_timer: Timer

func _ready():
	death_timer.timeout.connect(_cleanup)
	poison_timer.timeout.connect(on_hurtbox_died)
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
	game_client.secondary_action_pressed.connect(activate_skill)

	tree_exiting.connect(func():
		if not is_dead:
			_on_death()
	)

func poison():
	if not poison_timer.is_stopped(): return
	poison_timer.start()
	_poison_pulse_time = 0.0
	poison_icon.scale = Vector3.ONE
	poison_icon.modulate = Color.WHITE
	poison_icon.show()
	for mesh in meshes:
		mesh.material_override = POISON_MAT

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
	if is_dead: return

	poison_icon.hide()
	snap_zone.drop_object()
	animation.play(death_anim)
	death_sound.play_randomized()
	is_dead = true
	velocity = Vector3.ZERO
	death_timer.start()
	_on_death()

func _on_death():
	respawn_time = _compute_respawn_delay_for_count(PlayerManager.playing_clients.size())
	died.emit()

func _cleanup():
	queue_free()

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

func can_control():
	return not is_dead and not is_dashing and not is_shielded and not is_spawning and freeze_timer.is_stopped()

func _physics_process(delta):
	if not can_control():
		if not is_dead:
			ground_spring_cast.apply_gravity(self, delta)
			move_and_slide()
		return
	
	var direction := get_direction()
	var _speed = speed * (1.0 - slow)
	var accel = delta * (acceleration if ground_spring_cast.is_grounded() else 3.0)
	velocity.x = lerp(velocity.x, direction.x * _speed, accel)
	velocity.z = lerp(velocity.z, direction.z * _speed, accel)

	if direction:
		body.look_at(body.global_position + direction, Vector3.UP, true)

	animation.play(idle_anim if direction == Vector3.ZERO else running_anim)
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

func _process(delta: float) -> void:
	if poison_timer.is_stopped() or is_dead:
		_poison_pulse_time = 0.0
		poison_icon.scale = Vector3.ONE
		poison_icon.modulate = Color.WHITE
		if poison_icon.visible:
			poison_icon.hide()
		return

	_poison_pulse_time += delta

	var progress := 1.0 - (poison_timer.time_left / poison_timer.wait_time)
	var speed := lerpf(poison_pulse_speed_min, poison_pulse_speed_max, progress)
	var amplitude := lerpf(poison_pulse_amplitude_min, poison_pulse_amplitude_max, progress)
	var s := 1.0 + amplitude * sin(_poison_pulse_time * speed)
	poison_icon.scale = Vector3.ONE * s

	if progress > poison_color_flash_threshold:
		var flash := (sin(_poison_pulse_time * speed) + 1.0) / 2.0
		var flash_progress := (progress - poison_color_flash_threshold) / (1.0 - poison_color_flash_threshold)
		poison_icon.modulate = Color.WHITE.lerp(Color.RED, flash * flash_progress)
	else:
		poison_icon.modulate = Color.WHITE

func activate_skill():
	if not can_control(): return
	
	match skill:
		Skill.DASH:
			dash()
		Skill.SHIELD:
			shield()

func get_direction() -> Vector3:
	var direction = game_client.get_move()
	var right := Vector2(-camera_up_axis.y, camera_up_axis.x)
	return Vector3(
		direction.dot(right),
		0.0,
		-direction.dot(camera_up_axis)
	).normalized()

func dash() -> void:
	if is_spawning or not is_instance_valid(game_client) or not freeze_timer.is_stopped():
		return

	var direction = game_client.get_move()
	if direction == Vector2.ZERO:
		return

	if is_dashing or not skill_cooldown_timer.is_stopped():
		return

	is_dashing = true

	var dir3 := get_direction()
	velocity.x = dir3.x * dash_speed
	velocity.z = dir3.z * dash_speed

	animation.play(dash_anim)
	dash_particles.emitting = true
	dash_sfx.play()
	await get_tree().create_timer(dash_time).timeout

	skill_activated.emit()
	is_dashing = false

func set_shield(v: float):
	var mat = shield_vfx.get_active_material(0) as ShaderMaterial
	mat.set_shader_parameter("fade_value", v)

func tween_shield(start: float, end: float):
	var tw = create_tween()
	tw.tween_method(set_shield, start, end, shield_activate_time)

func shield() -> void:
	if is_spawning or not is_instance_valid(hurtbox) or not skill_cooldown_timer.is_stopped():
		return
	
	is_shielded = true
	velocity = Vector3.ZERO
	animation.play(idle_anim)
	hurtbox.invulnerable(shield_duration)
	tween_shield(0.0, 1.0)
	await get_tree().create_timer(shield_duration).timeout
	
	skill_activated.emit()
	is_shielded = false
	tween_shield(1.0, 0.0)
