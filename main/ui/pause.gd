extends Control

@export var game_mode: GameMode
@export var continue_btn: Button
@export var back_btn: Button

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	game_mode.finished.connect(func(): hide())
	visibility_changed.connect(_on_visibility_change)
	continue_btn.pressed.connect(func(): hide())
	back_btn.pressed.connect(func():
		game_mode.end_game()
		hide()
	)

func _on_visibility_change():
	get_tree().paused = visible

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and game_mode.playing:
		visible = not visible
