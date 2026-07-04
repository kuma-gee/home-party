class_name BaseGame
extends XRToolsSceneBase

signal prepare_phase()
signal game_phase()

@onready var game_ui: Control = %GameUI
@onready var prepare_ui: Control = %PrepareUI
@onready var player_list: PlayerList = %PlayerList
@onready var desktop_gameover: DesktopGameover = %DesktopGameover

var is_game_phase := false:
	set(v):
		is_game_phase = v
		prepare_ui.visible = not v
		game_ui.visible = v

func _ready() -> void:
	scene_loaded_finish.connect(_prepare_game)

func _prepare_game():
	is_game_phase = false
	prepare_phase.emit()

func _start_game():
	Env.mark_game_played()
	is_game_phase = true
	game_phase.emit()

func check_all_ready(vr_ready := false):
	if player_list.is_all_ready() and vr_ready:
		_start_game()
