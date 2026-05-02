class_name FPSPlayer
extends CharacterBody3D

signal died()

@export var speed := 1.0
@export var push_force = 2.0

@export var body: Node3D
@export var colors: Array[Color] = []
@export var color_ring: ColorRect
@export var hand: PickupHand3D

@export_category("Animation")
@export var animation: AnimationPlayer
@export var idle_anim := "Idle_B"
@export var running_anim := "Running_A"

@onready var ground_spring_cast: GroundSpringCast = $GroundSpringCast
@onready var hurtbox: HurtBox = $Hurtbox

var game_client: GameClient
var player_num := 0

func _ready():
	#reset()
	color_ring.color = colors[player_num % colors.size()]
	hurtbox.died.connect(func(): died.emit())
	game_client.input_received.connect(func(input, _value):
		if input == "action":
			hand.action()
	)

func _physics_process(delta):
	var direction = game_client.get_move()
	var _speed = speed

	if ground_spring_cast.is_grounded():
		if direction:
			velocity.x = direction.x * _speed
			velocity.z = direction.y * _speed
		else:
			velocity.x = lerp(velocity.x, direction.x * _speed, delta * 15.0)
			velocity.z = lerp(velocity.z, direction.y * _speed, delta * 15.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * _speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.y * _speed, delta * 3.0)

	if direction:
		var dir = Vector3(direction.x, 0, direction.y)
		body.look_at(body.global_position + dir, Vector3.UP, true)

	animation.play(idle_anim if direction == Vector2.ZERO else running_anim)
	ground_spring_cast.apply_gravity(self, delta)
	move_and_slide()

	# for i in range(get_slide_collision_count()):
	# 	var collision = get_slide_collision(i)
	# 	var collider = collision.get_collider()
		
	# 	if collider is FPSPlayer:
	# 		var other_player = collider as FPSPlayer
	# 		push_other_player(other_player)
	
func push_other_player(other_player: FPSPlayer) -> void:
	var push_direction = (other_player.global_position - global_position).normalized()

	if velocity.length() > 0 and other_player.velocity.length() < 0.1:
		other_player.velocity.x = push_direction.x * push_force
		other_player.velocity.z = push_direction.z * push_force

#func reset(_restore = false):
	#hand.release(self)
