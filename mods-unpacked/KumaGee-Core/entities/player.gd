extends CharacterBody3D

enum Action {
	NONE,
	STUN,
	JUMP,
}

@export var jump_force = 7.0
@export var speed = 3.0
@export var name_label: Label3D
@export var body: Node3D
@export var hit_area: Area3D

@onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var stun_timer: Timer = $StunTimer

var game_client: GameClient
var action := Action.NONE
var locked := true
var stunned := false

func _ready() -> void:
	var data = LobbyServer.get_player_data(game_client.uuid)
	name_label.text = "%s" % data.get("name", "Player")
	game_client.input_received.connect(_on_input_received)
	stun_timer.timeout.connect(func(): stunned = false)

func _on_input_received(input: String, value):
	if input == "action" and value == true:
		_do_action()

func _do_action():
	match action:
		Action.STUN: _stun_others()
		Action.JUMP: _jump()

func enable_stun():
	action = Action.STUN

func enable_jump():
	action = Action.JUMP

func _stun_others():
	for b in hit_area.get_overlapping_bodies():
		if b.has_method("stun"):
			b.stun()

func _jump():
	if is_on_floor():
		velocity.y = jump_force

func _physics_process(delta: float) -> void:
	if not is_instance_valid(game_client):
		velocity = Vector3.ZERO
		return
	
	if not is_on_floor():
		velocity.y -= gravity * delta

	if not locked and not stunned:
		var motion = game_client.get_move()
		var direction = (transform.basis * Vector3(motion.x, 0, motion.y)).normalized()
		direction.y = 0

		if direction:
			body.look_at(body.global_position - direction, Vector3.UP)
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
	
	move_and_slide()

func stun():
	stunned = true
	stun_timer.start()
