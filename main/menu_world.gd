extends XRToolsSceneBase

@onready var game_shelve: GameShelve = $GameShelve

var starting := false

func _ready() -> void:
	game_shelve.started_game.connect(start_game)

func start_game(game: GameResource):
	if starting: return
	starting = true
	PlayerManager.start_game()
	load_scene(game.scene.resource_path)
