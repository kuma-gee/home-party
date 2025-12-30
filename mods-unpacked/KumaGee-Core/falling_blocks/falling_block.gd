extends CharacterBody3D

@export var falling_speed := 0.5
@export var end_height := 3.0
@onready var recover_time: Timer = $RecoverTime
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

@onready var original_height := global_position.y

var locked := true:
	set(v):
		locked = v
		if locked:
			recover_time.stop()
			velocity.y = 0
			
var falling := false:
	set(v):
		if v == falling: return
		falling = v

func _ready() -> void:
	recover_time.timeout.connect(func():
		collision_shape_3d.disabled = false
		position.y = original_height
		show()
	)

func set_locked(lock: bool):
	locked = lock

func _physics_process(_delta: float) -> void:
	if locked: return
	
	if falling:
		velocity.y = -falling_speed
	else:
		velocity.y = 0
	
	move_and_slide()
	
	if not falling:
		var collision = get_last_slide_collision()
		if collision:
			falling = true
	elif global_position.y < -end_height:
		falling = false
		collision_shape_3d.disabled = true
		hide()
		recover_time.start()
