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
	if not (event is InputEventKey) or not event.is_pressed() or event.echo:
		return

	var key := event as InputEventKey
	if not (key.ctrl_pressed and key.alt_pressed) or key.shift_pressed:
		return

	if key.keycode == KEY_UP:
		increase_ai_count()
		KumaLog.new("GameSettings").info("AI count increased to %d" % _ai_count)
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_DOWN:
		decrease_ai_count()
		KumaLog.new("GameSettings").info("AI count decreased to %d" % _ai_count)
		get_viewport().set_input_as_handled()
