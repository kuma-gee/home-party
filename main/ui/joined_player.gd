class_name JoinedPlayer
extends Control

@export var container: Control
@export var texture: TextureRect
@export var name_label: Label
@export var max_length: int = 20

var uuid: String
var player_name: String:
	set(v):
		player_name = v
		if v == "":
			name_label.text = "(awaiting data)"
		else:
			name_label.text = "%s" % v
	
var tw: Tween

func _ready() -> void:
	container.position.x = 0
	size.x = 0

func update_data(data: Dictionary):
	uuid = data.client_id
	player_name = data.name.substr(0, max_length) # TODO: limit on client side
	if data.name.length() > max_length:
		player_name += "..."

func move_in():
	if tw:
		tw.stop()
	tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(container, "position:x", -container.custom_minimum_size.x, 1.0)

func move_out():
	if tw:
		tw.stop()
	tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(container, "position:x", 0, 1.0)
	tw.finished.connect(func(): queue_free())
