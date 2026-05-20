extends CenterContainer

@export var player_list: PlayerList
@export var skill_select_text: Label
@export var player_select: PackedScene
@export var dash_container: Control
@export var shield_container: Control

func _ready() -> void:
	player_list.player_created.connect(_create_select)
	_update_ready_text()

func _create_select(uuid: String):
	var player = PlayerManager.find_player_by_uuid(uuid)
	var select = player_select.instantiate() as PlayerSelect
	select.set_player(player)
	dash_container.add_child(select)
	
	var ui = player_list.find_existing_node(player.uuid) as CastlePlayerUI
	player.active_changed.connect(func(): select.visible = player.active)
	ui.ready_updated.connect(func():
		select.set_ready(ui.is_ready)
		_update_ready_text()
	)
	ui.skill_changed.connect(func(s):
		var container = dash_container if s == FPSPlayer.Skill.DASH else shield_container
		select.reparent(container)
	)

func _update_ready_text():
	skill_select_text.text = "Select your skill (%s/%s)" % [player_list.get_ready_count(), player_list.get_player_count()]
