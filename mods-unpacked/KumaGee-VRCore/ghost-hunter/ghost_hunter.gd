class_name GhostHunter
extends BaseGame

var logger := KumaLog.new("GHOST_HUNTER")

func _ready() -> void:
	super()
	prepare_phase.connect(_on_prepare_phase)
	game_phase.connect(_on_game_phase)

func _on_prepare_phase() -> void:
	pass

func _on_game_phase() -> void:
	pass
