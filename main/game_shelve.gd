class_name GameShelve
extends Node3D

signal started_game(game: GameResource)

@export var game_details_ui: GameDetailsUI
@export var scene: PackedScene
@export var radius := 0.85

@onready var game_loader: GameLoader = $GameLoader
@onready var game_details: Sprite3D = $GameDetails

var games = []
var logger := KumaLog.new("GameShelve")

func _ready() -> void:
	_populate()
	for game in games:
		if game:
			logger.info("Game: %s" % game.name)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key = event as InputEventKey
		if key.shift_pressed:
			var code = key.keycode
			if code >= KEY_1 and code <= KEY_9:
				var idx = code - KEY_1
				if idx < games.size():
					var g = games[idx]
					if g:
						started_game.emit(g)

func _populate() -> void:
	for child in get_children():
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
		if not g.icon:
			continue

		var inst = scene.instantiate() as GameSelectArea
		inst.name = "game_icon_%d" % i
		inst.game = g
		inst.hovered.connect(func(): _on_hovered(inst))
		inst.start_game.connect(func(): started_game.emit(g))
		add_child(inst)

		# Place on circle in XZ plane
		var angle = TAU * float(i) / float(n)
		var local_pos = Vector3(sin(angle) * radius, 0.0, cos(angle) * radius)
		inst.transform.origin = local_pos

		# Make the instance look toward the shelf's global center
		var center_global = global_transform.origin
		inst.look_at(center_global, Vector3.UP)

		# Keep object upright: zero X/Z rotation components
		var rot = inst.rotation_degrees
		rot.x = 0
		rot.z = 0
		inst.rotation_degrees = rot

func _on_hovered(select: GameSelectArea) -> void:
	game_details_ui.update_details(select.game)
	game_details.update_details(select.game)
	game_details.global_transform.origin = select.global_transform.origin + Vector3(0, 0.5, 0)
