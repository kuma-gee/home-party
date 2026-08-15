extends Area3D

@export var game_shelve: GameShelve
@export var remote: Node3D
@export var press_sfx: AudioStream
@export var button_node: Node3D
@export var up_pos_y = 0.009
@export var down_pos_y = 0.005

@onready var initial_remote_transform := remote.global_transform
@onready var _up_pos := button_node.position.y
var _objects_inside := 0

func _ready() -> void:
	area_entered.connect(func(_a): _on_area_entered())
	area_exited.connect(func(_a): _on_area_exited())

func _on_area_entered():
	_objects_inside += 1
	if _objects_inside == 1:
		button_node.position.y = down_pos_y
		AudioManager.play_randomized_sfx(press_sfx, -5, 1.0, 1.2)
		reset_objects()

func _on_area_exited():
	_objects_inside -= 1
	if _objects_inside <= 0:
		_objects_inside = 0
		button_node.position.y = _up_pos
		AudioManager.play_randomized_sfx(press_sfx, -10, 0.5, 0.7)

func reset_objects():
	game_shelve.reset_objects()
	remote.global_transform = initial_remote_transform
