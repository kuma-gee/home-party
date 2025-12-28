extends CharacterBody3D

@export var speed = 3.0
@export var name_label: Label3D

@onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var game_client: GameClient
var locked := true

func _ready() -> void:
	var data = LobbyServer.get_player_data(game_client.uuid)
	name_label.text = "%s" % data.get("name", "Player")

func _physics_process(delta: float) -> void:
	if not is_instance_valid(game_client):
		velocity = Vector3.ZERO
		return
	
	if not is_on_floor():
		velocity.y -= gravity * delta

	if not locked:
		var motion = game_client.get_move()
		var direction = (transform.basis * Vector3(motion.x, 0, motion.y)).normalized()
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
	
	move_and_slide()
