extends XRToolsSceneBase

@export var gate_hurtbox: HurtBox
@export var element_select_scene: PackedScene
@export var player_list: PlayerList
@export var orbs: Array[ElementOrb]
@export var arrow_types: Node3D
@export var quiver: Quiver
@export var bow: Bow
@export var tutorial: CastleDefenseTutorial
@export var game_ui: Control
@export var prepare_ui: Control
@export var spawn_hint: SpawnHint

@onready var play_time: Timer = $PlayTime

var _indicator_timer: Timer

var logger := KumaLog.new("CastleDefense")

var _element_select: ElementSelect
var _vr_elements: Array[Arrow.Element] = [Arrow.Element.FIRE]

func _ready() -> void:
	_indicator_timer = Timer.new()
	_indicator_timer.one_shot = true
	_indicator_timer.timeout.connect(_on_indicator_timeout)
	add_child(_indicator_timer)

	play_time.timeout.connect(_on_play_time_timeout)
	gate_hurtbox.died.connect(_on_gate_died)
	player_list.ready_changed.connect(_check_all_ready)
	quiver.element_changed.connect(_on_element_changed)
	_on_element_changed(Arrow.Element.NONE)

	_set_bow_active(false)
	game_ui.hide()

func _set_bow_active(active: bool) -> void:
	bow.visible = active

func _on_element_changed(elem: Arrow.Element) -> void:
	for orb in orbs:
		orb.set_selected(orb.element == elem)

func _set_prepare_indicators(v: bool) -> void:
	for cata in get_tree().get_nodes_in_group("catapult"):
		if is_instance_valid(cata) and cata is Catapult:
			cata.set_prepare_mode(v)
	for bomb in get_tree().get_nodes_in_group("bomb"):
		if is_instance_valid(bomb) and bomb is Bomb:
			bomb.set_prepare_mode(v)

func _on_indicator_timeout() -> void:
	_set_prepare_indicators(false)

func _on_game_start() -> void:
	_set_prepare_indicators(true)
	_element_select = xr_player.show_screen(element_select_scene, false) as ElementSelect
	_element_select.ready_pressed.connect(_on_vr_ready)
	arrow_types.hide()
	_check_all_ready()

func _on_vr_ready(elements: Array[Arrow.Element]) -> void:
	_vr_elements = elements
	_check_all_ready(true)

func _on_all_players_ready() -> void:
	_check_all_ready()

func _check_all_ready(start = false) -> void:
	if is_instance_valid(_element_select):
		_element_select.update_ready(player_list.get_ready_count(), player_list.get_player_count())
	if start and player_list.is_all_ready():
		_start_game()

func _start_game() -> void:
	StatsManager.initialize(PlayerManager.playing_clients)
	xr_player.hide_screen()
	prepare_ui.hide()
	play_time.start()
	game_ui.show()
	spawn_hint.start(player_list)
	logger.info("Game started — %.0f seconds to survive" % play_time.wait_time)
	_indicator_timer.start(3.0)

	_set_bow_active(true)

	for i in orbs.size():
		var element := _vr_elements[i] if i < _vr_elements.size() else Arrow.Element.NONE
		orbs[i].set_element(element)
		orbs[i].set_active(element != Arrow.Element.NONE)
	arrow_types.show()

func _on_gate_died() -> void:
	_finish_game("Attackers stormed the gate!")

func _on_play_time_timeout() -> void:
	_finish_game("Castle survived!")

func _finish_game(message: String) -> void:
	tutorial.finish()
	logger.info("Game over: %s" % message)
	xr_player.gameover(message)
	play_time.stop()
