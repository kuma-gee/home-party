extends CharacterBody3D

@export var falling_speed := 1.0
@export var acceleration := 0.01
@export var initial_speed := 0.1
@export var end_height := 3.0
@onready var recover_time: Timer = $RecoverTime
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

@onready var original_height := global_position.y

var current_fall_speed := 0.0
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
		current_fall_speed = min(current_fall_speed + acceleration, falling_speed)
		velocity.y = -current_fall_speed
	else:
		velocity.y = 0
	
	move_and_slide()
	
	if falling and global_position.y < -end_height:
		falling = false
		collision_shape_3d.disabled = true
		hide()
		recover_time.start()

func push(dir: Vector3):
	if not falling and dir.dot(Vector3.DOWN) == 1:
		falling = true
		current_fall_speed = initial_speed
