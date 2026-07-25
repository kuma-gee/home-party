extends XRToolsSceneBase

const MOVE_GUIDE_LEFT_SMOOTH := preload("res://assets/living_room/guide/MoveGuide_Left_Smooth.png")
const MOVE_GUIDE_LEFT_TELEPORT := preload("res://assets/living_room/guide/MoveGuide_Left_Teleport.png")

@export var move_guide_left: TextureRect
@export var remote: Node3D

@onready var game_shelve: GameShelve = $GameShelve
@onready var reset_area: Area3D = $GameShelve/ResetArea
@onready var initial_remote_transform := remote.global_transform

var starting := false

func _ready() -> void:
	PlayerManager.playing_clients = []
	LobbyServer.send_join_available()
	LobbyServer.send_layout("joystick")
	game_shelve.started_game.connect(start_game)
	reset_area.area_entered.connect(func(_a): reset_objects())
	UserSettings.setting_changed.connect(_on_user_setting_changed)
	_update_move_guide()

func reset_objects():
	game_shelve.reset_objects()
	remote.global_transform = initial_remote_transform

func _on_user_setting_changed(section: String, key: String) -> void:
	if section == "comfort" and key == "movement_mode":
		_update_move_guide()


func _update_move_guide() -> void:
	if UserSettings.get_movement_mode() == UserSettings.MovementMode.SMOOTH:
		move_guide_left.texture = MOVE_GUIDE_LEFT_SMOOTH
		return

	move_guide_left.texture = MOVE_GUIDE_LEFT_TELEPORT


func start_game(game: GameResource):
	if starting: return
	starting = true
	PlayerManager.start_game()
	load_scene(game.scene.resource_path)
