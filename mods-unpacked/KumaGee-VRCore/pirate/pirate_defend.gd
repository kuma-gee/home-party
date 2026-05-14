extends XRToolsSceneBase

@export var menu_button: Button
@export var restart_button: Button
@export var gameover_label: Label
@export var gameover_ui: Control
@export var spawner: PowerUpSpawner

@export var player_hurtbox: HurtBox
@export var shoot_points: Array[Node3D] = []
@export var player_scene: PackedScene
@export var barrel_scene: PackedScene
@onready var play_time: Timer = $PlayTime

func _ready() -> void:
	play_time.timeout.connect(_on_game_finished)
	player_hurtbox.died.connect(_on_player_died)
	
	menu_button.pressed.connect(func(): exit_to_main_menu())
	restart_button.pressed.connect(func(): reset_scene())
	gameover_ui.hide()

func _on_player_died():
	_finish_game()
	gameover_label.text = "Player died!"

func _on_game_finished():
	_finish_game()
	gameover_label.text = "Player survived!"

func _finish_game():
	get_tree().paused = true
	gameover_ui.show()
	spawner.stop()

func scene_loaded(_user_data = null):
	get_tree().paused = false
	LobbyServer.send_layout("joystick")

	var players = PlayerManager.playing_clients
	for i in range(players.size()):
		var player := player_scene.instantiate() as PlayerShootPoint
		player.game_client = players[i]
		player.shoot_at.connect(func(target: Vector3): _spawn_barrel_at(player, target))

		var point = shoot_points[i % shoot_points.size()]
		point.add_child(player)
		player.global_transform = point.global_transform
	
	play_time.start()
	spawner.start()

func _spawn_barrel_at(player: PlayerShootPoint, target: Vector3):
	var barrel = barrel_scene.instantiate()
	barrel.position = player.global_position
	barrel.speed_multiplier = player.get_speed_multiplier()
	barrel.scale *= player.get_scale_multiplier()
	barrel.picked_up.connect(func(power_up): player.add_power_up(power_up))
	Staging.add_scene_child(barrel)
	barrel.throw_to(target)
