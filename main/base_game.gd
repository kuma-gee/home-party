class_name BaseGame
extends XRToolsSceneBase

signal prepare_phase()
signal game_phase()
signal gameover_phase()

## Set true on games that shouldn't let the player walk/teleport around
## (e.g. fixed-position defense games).
@export var disable_locomotion := false

## Optional VR overlay viewport (tutorial/HUD/gameover panels swap through
## it via set_scene). Games that skip a VR gameover screen can leave this unset.
@export var vr_screen: XRToolsViewport2DIn3D
@export var gameover_scene: PackedScene = preload("res://main/ui/gameover_screen.tscn")

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
	if disable_locomotion:
		xr_player.set_locomotion_enabled(false)

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

## Shift+1 debug hotkey: advances prepare -> game -> gameover without
## waiting on real players. Default just force-starts the game; override
## _debug_advance() to also end the game early from the game phase.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and event.shift_pressed and event.keycode == KEY_1:
		_debug_advance()

func _debug_advance() -> void:
	if not is_game_phase:
		_start_game()

## Ends the game and shows the shared gameover screen on desktop, and in VR
## if vr_screen is set. populate_leaderboard, if given, is called with the
## Leaderboard node so each game can fill it with its own score shape
## (set_entries / set_rankings / set_table); omit it for score-less modes.
func finish_game(title: String, populate_leaderboard: Callable = Callable()) -> void:
	gameover_phase.emit()
	if desktop_gameover:
		desktop_gameover.show_gameover(title, populate_leaderboard)
	_show_vr_gameover(title, populate_leaderboard)

func _show_vr_gameover(title: String, populate_leaderboard: Callable) -> void:
	if not vr_screen or not gameover_scene:
		return
	vr_screen.set_scene(gameover_scene)
	vr_screen.show()
	var screen = vr_screen.get_scene_instance() as GameoverPanel
	if not screen:
		return
	screen.back_to_menu.connect(func(): xr_player.back_to_home.emit())
	screen.restart_game.connect(func(): xr_player.restart_game.emit())
	screen.set_title(title)
	if populate_leaderboard.is_valid():
		screen.leaderboard.show()
		populate_leaderboard.call(screen.leaderboard)
