extends XRToolsSceneBase

@export var player_spawner: PlayerSpawner

func scene_loaded(_user_data = null):
	player_spawner.init_players()
