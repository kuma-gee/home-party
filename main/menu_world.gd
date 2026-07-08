extends XRToolsSceneBase

@onready var game_shelve: GameShelve = $GameShelve
@onready var feedback_form_pickup: XRToolsPickable = %FeedbackFormPickup
@onready var reset_area: Area3D = $GameShelve/ResetArea

var starting := false

func _ready() -> void:
	PlayerManager.playing_clients = []
	game_shelve.started_game.connect(start_game)
	reset_area.area_entered.connect(func(_a): game_shelve.reset_objects())
	_update_feedback_form_pickup()


func _update_feedback_form_pickup() -> void:
	var should_show := Env.is_demo() and Env.has_played_game()
	feedback_form_pickup.visible = should_show
	feedback_form_pickup.enabled = should_show

func start_game(game: GameResource):
	if starting: return
	starting = true
	PlayerManager.start_game()
	load_scene(game.scene.resource_path)
