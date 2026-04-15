extends XRToolsSceneBase

@export var main_menu: MainMenu

func _ready() -> void:
	main_menu.start_game.connect(_start_game)
	
func _start_game(game: GameResource):
	PlayerManager.start_game()
	load_scene(game.scene.resource_path)
