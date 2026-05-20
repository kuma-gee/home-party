extends XRToolsSceneBase

@export var gate_hurtbox: HurtBox
@export var element_select_scene: PackedScene
@export var player_list: PlayerList
@export var skill_select: Control

@onready var play_time: Timer = $PlayTime

var logger := KumaLog.new("CastleDefense")

var _element_select: ElementSelect
var _vr_ready := false
var _players_ready := false
var _vr_element: Arrow.Element = Arrow.Element.FIRE

func _ready() -> void:
	play_time.timeout.connect(_on_play_time_timeout)
	gate_hurtbox.died.connect(_on_gate_died)
	player_list.ready_changed.connect(_check_all_ready)

func _on_game_start() -> void:
	_element_select = xr_player.show_screen(element_select_scene, false) as ElementSelect
	_element_select.ready_pressed.connect(_on_vr_ready)

func _on_vr_ready(element: Arrow.Element) -> void:
	_vr_ready = true
	_vr_element = element
	_check_all_ready()

func _on_all_players_ready() -> void:
	_players_ready = true
	_check_all_ready()

func _check_all_ready() -> void:
	if is_instance_valid(_element_select):
		_element_select.update_ready(player_list.get_ready_count(), player_list.get_player_count())
	if _vr_ready and _players_ready:
		_start_game()

func _start_game() -> void:
	StatsManager.initialize(PlayerManager.playing_clients)
	xr_player.hide_screen()
	skill_select.hide()
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
