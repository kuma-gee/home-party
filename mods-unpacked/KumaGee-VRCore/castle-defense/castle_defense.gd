extends XRToolsSceneBase

@export var menu_button: Button
@export var restart_button: Button
@export var gameover_ui: Control
@export var gameover_label: Label
@export var gate_hurtbox: HurtBox

@onready var play_time: Timer = $PlayTime
@onready var player_spawner: PlayerSpawner = $PlayerSpawner

var logger := KumaLog.new("CastleDefense")

func _ready() -> void:
	play_time.timeout.connect(_on_play_time_timeout)
	gate_hurtbox.died.connect(_on_gate_died)
	menu_button.pressed.connect(func(): exit_to_main_menu())
	restart_button.pressed.connect(func(): reset_scene())
	gameover_ui.hide()

func scene_loaded(_user_data = null) -> void:
	get_tree().paused = false
	LobbyServer.send_layout("joystick")

	player_spawner.init_players()
	play_time.start()
	logger.info("Game started — %.0f seconds to survive" % play_time.wait_time)

func _on_gate_died() -> void:
	_finish_game("Attackers stormed the gate!")

func _on_play_time_timeout() -> void:
	_finish_game("Castle survived!")

func _finish_game(message: String) -> void:
	logger.info("Game over: %s" % message)
	get_tree().paused = true
	gameover_label.text = message
	gameover_ui.show()
	play_time.stop()
