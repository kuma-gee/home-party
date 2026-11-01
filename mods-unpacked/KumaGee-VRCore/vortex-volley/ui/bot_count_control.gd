extends Control

@onready var count_label: Label = %CountLabel

func _ready() -> void:
	_update_display()
	GameSettings.ai_count_changed.connect(_update_display)

func _on_decrease_pressed() -> void:
	GameSettings.decrease_ai_count()

func _on_increase_pressed() -> void:
	GameSettings.increase_ai_count()

func _update_display(_new_count: int = 0) -> void:
	count_label.text = str(GameSettings.get_ai_count())
