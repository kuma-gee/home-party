class_name GameShelve
extends Node3D

signal started_game(game: GameResource)

@export var game_details_desktop_root: Control
@export var game_details_desktop: GameDetailsPanel
@export var game_details_vr: GameDetailsPanel
@export var scene: PackedScene
@export var axis := Vector3.RIGHT
@export var item_spacing := 0.2
@export var player_list: PlayerList

@onready var game_loader: GameLoader = $GameLoader
@onready var game_select_zone: GameSelectZone = $GameSelectZone
@onready var games_root: Node3D = $GamesRoot
@onready var tv_remote: XRToolsPickable = $TVRemote
@onready var slot_highlight: Node3D = $SlotHighlight

var selected_game: GameResource
var games = []
var logger := KumaLog.new("GameShelve")

func _ready() -> void:
	game_select_zone.selected_game.connect(_on_game_selected)
	tv_remote.action_pressed.connect(func(_p):
		_try_start_selected_game()
	)
	
	_on_game_selected(null)
	_populate()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.echo:
		var key = event as InputEventKey
		if key.ctrl_pressed and key.alt_pressed and not key.shift_pressed:
			var code = key.keycode
			if code >= KEY_1 and code <= KEY_9:
				var idx = code - KEY_1
				if idx < games.size():
					var g = games[idx]
					if g:
						if selected_game == g:
							_on_game_selected(null)
						else:
							_on_game_selected(g)
			elif code == KEY_ENTER or code == KEY_KP_ENTER:
				_try_start_selected_game()

func _populate() -> void:
	for child in games_root.get_children():
		if typeof(child) == TYPE_OBJECT and child.name.begins_with("game_icon_"):
			child.queue_free()

	games = []
	if game_loader:
		games = game_loader.list_games()

	var n: int = games.size()
	if n == 0:
		return

	for i in range(n):
		var g = games[i]
		if not g:
			continue

		var inst = scene.instantiate() as GameSelectArea
		inst.name = "game_icon_%d" % i
		inst.game = g
		games_root.add_child(inst)
		_place(inst, i, n)


func _place(inst: Node3D, i: int, n: int) -> void:
	# Place in a line along the configured axis with fixed spacing
	var offset = axis.normalized() * (float(i) - float(n - 1) / 2.0) * item_spacing
	inst.transform.origin = offset
	inst.rotation.x = deg_to_rad(-20.0)


func reset_objects() -> void:
	var n: int = games.size()
	for child in games_root.get_children():
		if not (typeof(child) == TYPE_OBJECT and child.name.begins_with("game_icon_")):
			continue
		if child.has_method("drop") and child.has_method("is_picked_up") and child.is_picked_up():
			child.drop()
		var idx := child.name.trim_prefix("game_icon_").to_int()
		_place(child, idx, n)
		if child is RigidBody3D:
			child.linear_velocity = Vector3.ZERO
			child.angular_velocity = Vector3.ZERO

func _on_game_selected(game: GameResource) -> void:
	selected_game = game
	slot_highlight.visible = game == null
	game_details_desktop.update_details(game)
	game_details_vr.update_details(game)
	game_details_desktop_root.visible = game != null
	if player_list:
		player_list.update_selection(game)


func select_game_with_path(resource_path: String) -> void:
	var game: GameResource
	if not resource_path.is_empty():
		game = load(resource_path) as GameResource
	game_select_zone.selected_game.emit(game)


func start_selected_game() -> void:
	_try_start_selected_game()


func _try_start_selected_game() -> void:
	if selected_game and Env.is_game_available(selected_game):
		started_game.emit(selected_game)
