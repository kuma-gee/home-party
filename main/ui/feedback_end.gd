extends PanelContainer

@onready var feedback_manager: Node = FeedbackManager
@onready var feedback_input: TextEdit = %FeedbackInput
@onready var send_button: Button = %SendButton
@onready var status_label: Label = %StatusLabel
@onready var throttle_label: Label = %ThrottleLabel

var _request_running := false

func _ready() -> void:
	feedback_manager.request_running.connect(_on_request_running)
	feedback_manager.request_failed.connect(_on_request_failed)
	feedback_manager.request_successful.connect(_on_request_successful)
	feedback_manager.request_throttled.connect(_on_request_throttled)
	send_button.pressed.connect(_on_send_button_pressed)
	feedback_input.text_changed.connect(_update_send_button)
	_update_send_button()
	_update_throttle_label()
	_set_status("", false)

func _process(_delta: float) -> void:
	_update_throttle_label()

func _on_send_button_pressed() -> void:
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
	feedback_input.clear()
	_update_send_button()
	_set_status("Feedback sent. Thank you!", false)
	_update_throttle_label()

func _on_request_throttled(time_left: float) -> void:
	_update_send_button()
	_set_status("Please wait %d seconds before sending more feedback." % ceili(time_left), true)
	_update_throttle_label()

func _update_send_button() -> void:
	var has_text := not feedback_input.text.strip_edges().is_empty()
	var throttled: bool = float(feedback_manager.get_time_until_next_feedback()) > 0.0
	send_button.disabled = not has_text or throttled or _request_running

func _update_throttle_label() -> void:
	var time_left: float = float(feedback_manager.get_time_until_next_feedback())
	if time_left > 0.0:
		throttle_label.text = "Next feedback available in %d seconds." % ceili(time_left)
		throttle_label.show()
	else:
		throttle_label.hide()
	_update_send_button()

func _set_status(message: String, is_error: bool) -> void:
	status_label.text = message
	status_label.modulate = Color(1.0, 0.35, 0.35) if is_error else Color.WHITE
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
