extends Node

signal ai_count_changed(new_count: int)

const MIN_AI_COUNT := 2
const MAX_AI_COUNT := 10
const DEFAULT_AI_COUNT := 4

var _ai_count: int = DEFAULT_AI_COUNT

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func get_ai_count() -> int:
	return _ai_count

func set_ai_count(value: int) -> void:
	_ai_count = clampi(value, MIN_AI_COUNT, MAX_AI_COUNT)
	ai_count_changed.emit(_ai_count)

func increase_ai_count() -> void:
	set_ai_count(_ai_count + 1)

func decrease_ai_count() -> void:
	set_ai_count(_ai_count - 1)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_ai_increase"):
		increase_ai_count()
		KumaLog.new("GameSettings").info("AI count increased to %d" % _ai_count)
	elif event.is_action_pressed("debug_ai_decrease"):
		decrease_ai_count()
		KumaLog.new("GameSettings").info("AI count decreased to %d" % _ai_count)
