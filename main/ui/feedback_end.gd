extends PanelContainer

@onready var feedback_manager: Node = FeedbackManager
@onready var feedback_input: TextEdit = %FeedbackInput
@onready var send_button: Button = %SendButton
@onready var character_limit_label: Label = %CharacterLimitLabel
@onready var status_label: Label = %StatusLabel
@onready var throttle_label: Label = %ThrottleLabel

const MAX_FEEDBACK_LENGTH := 300

var _request_running := false
var _show_throttle_label := false

func _ready() -> void:
	feedback_manager.request_running.connect(_on_request_running)
	feedback_manager.request_failed.connect(_on_request_failed)
	feedback_manager.request_successful.connect(_on_request_successful)
	feedback_manager.request_throttled.connect(_on_request_throttled)
	send_button.pressed.connect(_on_send_button_pressed)
	feedback_input.text_changed.connect(_on_feedback_input_text_changed)
	_update_character_limit_label()
	_update_send_button()
	_update_throttle_label()
	_set_status("", false)

func _process(_delta: float) -> void:
	_update_throttle_label()

func _on_send_button_pressed() -> void:
	_limit_feedback_text()
	var feedback_text := feedback_input.text.strip_edges()
	if feedback_text.is_empty():
		_set_status("Please enter feedback before sending.", true)
		return

	feedback_manager.send_feedback(feedback_text)

func _on_request_running() -> void:
	_request_running = true
	send_button.disabled = true
	_set_status("Sending feedback...", false)

func _on_request_failed(reason: int) -> void:
	_request_running = false
	_update_send_button()
	_set_status(_get_error_message(reason), true)

func _on_request_successful() -> void:
	_request_running = false
	_show_throttle_label = false
	feedback_input.clear()
	_update_character_limit_label()
	_update_send_button()
	_set_status("Feedback sent. Thank you!", false)
	_update_throttle_label()

func _on_request_throttled(_time_left: float) -> void:
	_show_throttle_label = true
	_update_send_button()
	_update_throttle_label()

func _on_feedback_input_text_changed() -> void:
	_limit_feedback_text()
	_update_character_limit_label()
	_update_send_button()

func _limit_feedback_text() -> void:
	if feedback_input.text.length() <= MAX_FEEDBACK_LENGTH:
		return

	feedback_input.text = feedback_input.text.substr(0, MAX_FEEDBACK_LENGTH)
	var last_line_index := feedback_input.get_line_count() - 1
	feedback_input.set_caret_line(last_line_index)
	feedback_input.set_caret_column(feedback_input.get_line(last_line_index).length())

func _update_character_limit_label() -> void:
	var character_count := mini(feedback_input.text.length(), MAX_FEEDBACK_LENGTH)
	character_limit_label.text = "%d/%d characters" % [character_count, MAX_FEEDBACK_LENGTH]
	character_limit_label.modulate = Color(1.0, 0.35, 0.35) if character_count >= MAX_FEEDBACK_LENGTH else Color.WHITE

func _update_send_button() -> void:
	var has_text := not feedback_input.text.strip_edges().is_empty()
	send_button.disabled = not has_text or _request_running

func _update_throttle_label() -> void:
	var time_left: float = float(feedback_manager.get_time_until_next_feedback())
	if _show_throttle_label and time_left > 0.0:
		throttle_label.text = "Next feedback available in %d seconds." % ceili(time_left)
		throttle_label.show()
		status_label.hide()
	else:
		_show_throttle_label = false
		throttle_label.hide()
	_update_send_button()

func _set_status(message: String, is_error: bool) -> void:
	status_label.text = message
	status_label.modulate = Color(1.0, 0.35, 0.35) if is_error else Color.WHITE
	if throttle_label.visible:
		status_label.hide()
	else:
		status_label.show()

func _get_error_message(reason: int) -> String:
	match reason:
		FeedbackManager.Error.IN_PROGRESS:
			return "Feedback is already sending."
		FeedbackManager.Error.NOT_ENABLED:
			return "Feedback sending is not available right now."
		FeedbackManager.Error.SEND_ERROR:
			return "Could not start feedback request. Try again later."
		FeedbackManager.Error.RESPONSE_ERROR:
			return "Feedback server rejected the request. Try again later."
		_:
			return "Feedback could not be sent."
