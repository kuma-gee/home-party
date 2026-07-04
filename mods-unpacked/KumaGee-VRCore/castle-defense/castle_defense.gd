class_name CastleDefense
extends BaseGame

signal game_started

@export var gate_hurtbox: HurtBox
@export var gate_destruction_vfx: PackedScene
@export var tutorial_scene: PackedScene
@export var orbs: Array[ElementOrb]
@export var arrow_types: Node3D
@export var spawn_hint: SpawnHint
@export var ai_count_viewport: Node3D
@export var sieges: Node3D
@export var vr_screen: XRToolsViewport2DIn3D
@export var gameover_scene: PackedScene
@export var win_sound: AudioStreamPlayer3D

@onready var play_time: Timer = $PlayTime
@onready var ai_spawner: AISpawner = $AISpawner
@onready var health_sprite: Sprite3D = %HealthSprite
@onready var bomb_spawner: BombSpawner = %BombSpawner
@onready var quiver: Quiver = %Quiver
@onready var bow: Bow = %Bow

var logger := KumaLog.new("CastleDefense")
var gate_destroyed := false

var _tutorial: VRTutorial
var _element_select: ElementSelect
var _vr_elements: Array[Arrow.Element] = [Arrow.Element.FIRE]

func _ready() -> void:
	super()
	play_time.timeout.connect(_on_play_time_timeout)
	gate_hurtbox.died.connect(_on_gate_died)
	player_list.ready_changed.connect(_check_all_ready)
	quiver.element_changed.connect(_on_element_changed)
	
	game_phase.connect(_on_game_phase)
	prepare_phase.connect(_on_prepare_phase)
	PlayerManager.clients_changed.connect(_update_ai_count_visibility)
	_on_element_changed(Arrow.Element.NONE)
	_update_ai_count_visibility()

	_set_bow_active(true)
	health_sprite.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_pressed() and event.shift_pressed and event.keycode == KEY_1:
			_on_vr_ready([Arrow.Element.FIRE])

## VR player signals ready with default elements.
## Used by E2E tests to simulate VR player readiness without needing
## to pass typed arrays through the MCP bridge.
func vr_player_ready() -> void:
	_vr_elements = [Arrow.Element.FIRE]
	_check_all_ready(true)

func _set_bow_active(active: bool) -> void:
	bow.visible = active

func _update_ai_count_visibility() -> void:
	if ai_count_viewport:
		ai_count_viewport.visible = PlayerManager.playing_clients.is_empty()

func _on_element_changed(elem: Arrow.Element) -> void:
	for orb in orbs:
		orb.set_selected(orb.element == elem)

func _show_vr_screen(scene: PackedScene) -> Node:
	vr_screen.set_scene(scene)
	vr_screen.show()
	return vr_screen.get_scene_instance()

func _hide_vr_screen() -> void:
	vr_screen.hide()

func _show_vr_gameover(message: String) -> void:
	var screen = _show_vr_screen(gameover_scene) as GameoverPanel
	if not screen:
		return
	screen.back_to_menu.connect(func(): xr_player.back_to_home.emit())
	screen.restart_game.connect(func(): xr_player.restart_game.emit())
	screen.set_title(message)
	var rankings = StatsManager.get_rankings()
	screen.set_rankings(rankings)

func _on_prepare_phase() -> void:
	# Lower the BGM during the prepare/tutorial phase
	BGMManager.set_volume_db(-40.0, true)
	arrow_types.show()
	_tutorial = _show_vr_screen(tutorial_scene) as VRTutorial

	for i in orbs.size():
		var element := _vr_elements[i] if i < _vr_elements.size() else Arrow.Element.NONE
		orbs[i].set_element(element)
		orbs[i].set_active(element != Arrow.Element.NONE)
		orbs[i].reset_cooldown()

	_element_select = _tutorial.element_select
	_element_select.ready_pressed.connect(_on_vr_ready)
	_element_select.selection_changed.connect(_on_elements_changed)
	_check_all_ready()
	_on_elements_changed(_element_select.selected_elements)

func _on_vr_ready(elements: Array[Arrow.Element]) -> void:
	_vr_elements = elements
	_check_all_ready(true)

func _on_elements_changed(elements: Array[Arrow.Element]) -> void:
	# Deactivate orbs whose element is no longer selected.
	# Using element identity instead of array index preserves orb positions
	# so deselecting a middle element doesn't shuffle the others for the VR player.
	for orb in orbs:
		if orb.element != Arrow.Element.NONE and orb.element not in elements:
			orb.set_element(Arrow.Element.NONE)
			orb.set_active(false)

	# Assign newly selected elements to the first available inactive orb.
	for elem in elements:
		var already_assigned := false
		for orb in orbs:
			if orb.element == elem:
				already_assigned = true
				break
		if not already_assigned:
			for orb in orbs:
				if orb.element == Arrow.Element.NONE:
					orb.set_element(elem)
					orb.set_active(true)
					break

func _on_all_players_ready() -> void:
	_check_all_ready()

func _check_all_ready(start = false) -> void:
	if is_instance_valid(_element_select):
		_element_select.update_ready(player_list.get_ready_count(), player_list.get_player_count())
	if start and player_list.is_all_ready():
		_start_game()

func _get_gate_hp(player_count: int) -> int:
	if player_count <= 2:
		return 40
	elif player_count <= 4:
		return 55
	elif player_count <= 6:
		return 75
	else:
		return 100

func _on_game_phase() -> void:
	if not play_time.is_stopped(): return
	
	if ai_count_viewport:
		ai_count_viewport.hide()
	game_started.emit()
	
	# Restore BGM to default volume when game starts
	BGMManager.set_volume_db(-25.0, false)
	StatsManager.initialize(PlayerManager.playing_clients)
	for child in player_list.get_children():
		if child is CastlePlayerUI:
			child._game_started = true

	var player_count = PlayerManager.playing_clients.size()
	if player_count == 0:
		player_count = GameSettings.get_ai_count()
	gate_hurtbox.set_max_health(_get_gate_hp(player_count))
	logger.info("Gate HP set to %d for %d agents" % [gate_hurtbox.health, player_count])

	gate_destroyed = false
	_hide_vr_screen()
	prepare_ui.hide()
	play_time.start()
	game_ui.show()
	health_sprite.show()
	spawn_hint.start(player_list)
	logger.info("Game started — %.0f seconds to survive" % play_time.wait_time)

	_set_bow_active(true)

	for i in orbs.size():
		var element := _vr_elements[i] if i < _vr_elements.size() else Arrow.Element.NONE
		orbs[i].set_element(element)
		orbs[i].set_active(element != Arrow.Element.NONE)
		orbs[i].reset_cooldown()
	arrow_types.show()

func _on_gate_died() -> void:
	if gate_destroyed: return
	gate_destroyed = true
	if gate_destruction_vfx:
		var vfx = gate_destruction_vfx.instantiate()
		add_child(vfx)
		vfx.global_position = gate_hurtbox.global_position
	_finish_game("Attackers stormed the gate!")
	_disable_attackers()

@export var siege_delay_min: float = 0.5
@export var siege_delay_max: float = 1.5

func _on_play_time_timeout() -> void:
	win_sound.play()
	gate_hurtbox.enabled = false
	
	var children = sieges.get_children()
	for i in children.size():
		var child = children[i]
		if child is Siege:
			var time = randf_range(siege_delay_min, siege_delay_max)
			get_tree().create_timer(time).timeout.connect(func(): child.start())
	
	get_tree().create_timer(4.0).timeout.connect(_on_siege_complete)

func _on_siege_complete() -> void:
	_finish_game("Castle survived!")
	_cleanup_after_siege()

func _cleanup_after_siege() -> void:
	for child in player_list.get_children():
		if child is CastlePlayerUI:
			if is_instance_valid(child.current_player) and not child.current_player.is_dead:
				child.current_player.on_hurtbox_died()
			child.respawn_timer.stop()

	for catapult in get_tree().get_nodes_in_group("catapult"):
		if catapult is Catapult:
			catapult.destroy()

	for bomb in get_tree().get_nodes_in_group("bomb"):
		bomb.queue_free()

	if is_instance_valid(ai_spawner):
		ai_spawner.stop_and_clear()

	if is_instance_valid(bomb_spawner):
		bomb_spawner.stop()

func _disable_attackers() -> void:
	for catapult in get_tree().get_nodes_in_group("catapult"):
		if catapult is Catapult:
			catapult.disable()
	if is_instance_valid(ai_spawner):
		ai_spawner.stop()

func _finish_game(message: String) -> void:
	logger.info("Game over: %s" % message)
	_show_vr_gameover(message)
	if desktop_gameover:
		desktop_gameover.show_leaderboard(message, StatsManager.get_rankings())
	play_time.stop()
