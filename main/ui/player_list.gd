class_name PlayerList
extends VBoxContainer

signal player_created(uuid)
signal player_removed(uuid)
signal ready_changed()

const COLORS = [
	Color(1, 0, 0, 1),
	Color(0.10830901, 0.44832176, 0.90811163, 1),
	Color(0.14999998, 1, 0, 1),
	Color(1, 0.9607843, 0.2509804, 1),
	Color(0.4000001, 0, 1, 1),
	Color(1, 0.61960787, 0.011764706, 1),
	Color(0, 0.93333334, 1, 1),
	Color(0.9019608, 0.27058825, 1, 1)
]

static func get_color(idx: int) -> Color:
	return COLORS[idx % COLORS.size()]

@export var player_scene: PackedScene
@export var initial_delay := 1.0
@export var create_delay := 0.1
@export var allow_empty := true

var current_game: GameResource
var _refresh_generation := 0

func _ready() -> void:
	PlayerManager.clients_changed.connect(_refresh_list)
	await get_tree().create_timer(initial_delay).timeout
	_refresh_list()

func _refresh_list() -> void:
	_refresh_generation += 1
	var gen := _refresh_generation

	var players_data: Array[Dictionary] = []
	for child in PlayerManager.get_children():
		if child is ClientController and child.active:
			players_data.append(child.get_display_data())

	var current_uuids: Array = []
	for player_data in players_data:
		if gen != _refresh_generation:
			return
		current_uuids.append(player_data.client_id)
		var existing = find_existing_node(player_data.client_id)
		if existing:
			existing.update_data(player_data)
			existing.move_in()
		else:
			var new_node = player_scene.instantiate() as JoinedPlayer
			new_node.ready_updated.connect(func(): ready_changed.emit())
			new_node.update_data(player_data)
			add_child(new_node)
			new_node.update_game_selection(current_game)
			new_node.move_in()
			player_created.emit(player_data.client_id)

		await get_tree().create_timer(create_delay).timeout

	if gen != _refresh_generation:
		return

	for child in get_children():
		if child is JoinedPlayer and child.uuid not in current_uuids:
			child.move_out()
			player_removed.emit(child.uuid)

func update_selection(game: GameResource) -> void:
	current_game = game
	for child in get_children():
		if child is JoinedPlayer:
			child.update_game_selection(game)

func find_existing_node(uuid: String):
	for child in get_children():
		if child is JoinedPlayer and child.uuid == uuid:
			return child
	return null

func is_all_ready():
	if not allow_empty and get_player_count() == 0:
		return false
	return get_ready_count() == get_player_count()

func get_player_count():
	return PlayerManager.get_active_players().size()

func get_ready_count():
	var count = 0
	for child in get_children():
		if child is JoinedPlayer:
			if child.is_ready:
				count += 1
	return count
