extends BaseGame

@export var menu_button: Button
@export var restart_button: Button
@export var gameover_label: Label
@export var gameover_ui: Control

@export var player_hurtbox: HurtBox
@export var shoot_points: Array[Node3D] = []
@export var player_scene: PackedScene
@export var barrel_scene: PackedScene
@onready var play_time: Timer = $PlayTime

func _ready() -> void:
	play_time.timeout.connect(_on_game_finished)
	player_hurtbox.died.connect(_on_player_died)
	
	menu_button.pressed.connect(func(): back_to_menu.emit())
	restart_button.pressed.connect(func(): game_restart.emit())
	gameover_ui.hide()

func _on_player_died():
	get_tree().paused = true
	gameover_ui.show()
	gameover_label.text = "Player died!"

func _on_game_finished():
	get_tree().paused = true
	gameover_ui.show()
	gameover_label.text = "Player survived!"

func start_game(players: Array[GameClient], _game_setup: GameSetup):
	get_tree().paused = false
	LobbyServer.send_layout("joystick")

	for i in range(players.size()):
		var player := player_scene.instantiate() as PlayerShootPoint
		player.game_client = players[i]
		player.shoot_at.connect(func(target: Vector3): _spawn_barrel_at(player, target))

		var point = shoot_points[i % shoot_points.size()]
		point.add_child(player)
		player.global_transform = point.global_transform
	
	play_time.start()

func _spawn_barrel_at(player: PlayerShootPoint, target: Vector3):
	var barrel = barrel_scene.instantiate()
	barrel.position = player.global_position
	get_tree().current_scene.add_child(barrel)
	barrel.throw_to(target)
