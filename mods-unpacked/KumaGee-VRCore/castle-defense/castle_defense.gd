extends XRToolsSceneBase

@export var gate_hurtbox: HurtBox

@onready var play_time: Timer = $PlayTime

var logger := KumaLog.new("CastleDefense")

func _ready() -> void:
	play_time.timeout.connect(_on_play_time_timeout)
	gate_hurtbox.died.connect(_on_gate_died)

func _on_game_start() -> void:
	get_tree().paused = false
	LobbyServer.send_layout("joystick")

	play_time.start()
	logger.info("Game started — %.0f seconds to survive" % play_time.wait_time)

func _on_gate_died() -> void:
	_finish_game("Attackers stormed the gate!")

func _on_play_time_timeout() -> void:
	_finish_game("Castle survived!")

func _finish_game(message: String) -> void:
	logger.info("Game over: %s" % message)
	xr_player.gameover(message)
	play_time.stop()
