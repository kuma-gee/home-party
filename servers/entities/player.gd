class_name Player
extends CharacterBody3D

signal send_candidate(mid: String, index: int, sdp: String)
signal send_session(type: String, sdp: String)

@export var speed = 3.0
@export var name_label: Label3D

@onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var game_client: GameClient = $GameClient

var data = {}
var inputs = {}

func _ready() -> void:
	name_label.text = "%s" % data.get("name", "Player")
	game_client.input_received.connect(func(input: String, v): inputs[input] = v)
	game_client.send_candidate.connect(func(mid: String, index: int, sdp: String):
		send_candidate.emit(mid, index, sdp)
	)
	game_client.send_session.connect(func(type: String, sdp: String):
		send_session.emit(type, sdp)
	)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	var motion = inputs["move"] if inputs.has("move") else Vector2.ZERO
	var direction = (transform.basis * Vector3(motion.x, 0, motion.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	move_and_slide()
