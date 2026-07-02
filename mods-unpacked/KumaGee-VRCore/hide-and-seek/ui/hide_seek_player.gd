extends JoinedPlayer

var _is_alive := true


func _ready() -> void:
	super()
	_update_status_label()


func update_game_selection(_game: GameResource) -> void:
	_update_status_label()


func update_hider_status(is_alive: bool) -> void:
	_is_alive = is_alive
	_update_status_label()


func _update_status_label() -> void:
	if unplayable_label:
		unplayable_label.visible = not _is_alive
