class_name JoinedPlayer
extends Control

signal ready_updated()

@export var container: Control
@export var max_length: int = 20
@export var player_icon: PlayerIcon

var is_ready := false:
	set(v):
		is_ready = v
		ready_updated.emit()
	
var uuid: String
var game_select_zone: GameSelectZone

@onready var out_pos := -container.custom_minimum_size.x
@onready var in_pos := 0
@onready var unplayable_label: Label = $HBoxContainer/UnplayableLabel

var tw: Tween
var game_client: ClientController


func _ready() -> void:
	container.position.x = -container.custom_minimum_size.x
	size.x = 0
	if game_select_zone:
		game_select_zone.selected_game.connect(_on_game_selected)
		var shelve = game_select_zone.get_parent() as GameShelve
		if shelve:
			_on_game_selected(shelve.selected_game)


func set_ready():
	is_ready = true

func reset_ready():
	is_ready = false

func update_data(data: Dictionary):
	uuid = data.client_id
	game_client = PlayerManager.find_player_by_uuid(uuid)
	player_icon.update(data)

func move_in():
	if tw:
		tw.stop()
	tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(container, "position:x", in_pos, 1.0)

func move_out():
	if tw:
		tw.stop()
	tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(container, "position:x", container.custom_minimum_size.x, 1.0)
	tw.finished.connect(func(): queue_free())


func _on_game_selected(game: GameResource) -> void:
	if not game_client or not game_client.active:
		unplayable_label.visible = false
		return
	if game and game.phone_only and game_client is GamepadController:
		unplayable_label.visible = true
	else:
		unplayable_label.visible = false
