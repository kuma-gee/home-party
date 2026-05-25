class_name GameShelve
extends Node3D

signal started_game(game: GameResource)

@export var game_details_desktop: GameDetailsPanel
@export var game_details_vr: GameDetailsPanel
@export var scene: PackedScene
@export var radius := 0.85
@export_range(1, 90, 1, "degrees") var item_spacing := 20.0

@onready var game_loader: GameLoader = $GameLoader
@onready var game_select_zone: GameSelectZone = $GameSelectZone
@onready var games_root: Node3D = $GamesRoot
@onready var tv_remote: XRToolsPickable = $TVRemote

var selected_game: GameResource
var games = []
var logger := KumaLog.new("GameShelve")

func _ready() -> void:
	game_select_zone.selected_game.connect(_on_game_selected)
	tv_remote.action_pressed.connect(func(_p):
		if selected_game:
			started_game.emit(selected_game)
	)
	
	_on_game_selected(null)
	_populate()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		var key = event as InputEventKey
		if key.shift_pressed:
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
			elif code == KEY_F1:
				started_game.emit(selected_game)

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
		if not g or not g.icon:
			continue

		var inst = scene.instantiate() as GameSelectArea
		inst.name = "game_icon_%d" % i
		inst.game = g
		games_root.add_child(inst)

		# Place on arc in XZ plane with fixed spacing
		var step = deg_to_rad(item_spacing)
		var angle = step * (float(i) - float(n - 1) / 2.0)
		var local_pos = Vector3(sin(angle) * radius, 0.0, cos(angle) * radius)
		inst.transform.origin = local_pos

		# Make the instance look toward the shelf's global center
		var center_global = games_root.global_transform.origin
		inst.look_at(center_global, Vector3.UP)

		# Keep object upright: zero X/Z rotation components
		var rot = inst.rotation_degrees
		rot.x = 0
		rot.z = 0
		inst.rotation_degrees = rot

func _on_game_selected(game: GameResource) -> void:
	selected_game = game
	game_details_desktop.update_details(game)
	game_details_vr.update_details(game)
