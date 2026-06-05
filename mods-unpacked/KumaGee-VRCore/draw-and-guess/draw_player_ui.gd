class_name DrawPlayerUI
extends JoinedPlayer

signal word_submitted(word: String)
signal guessed(word: String)

var has_submitted_word := false
var has_guessed_correctly := false
var current_phase := "word_submit"

@export var checkmark: Label
@export var errormark: Label

func update_data(data: Dictionary):
	super(data)
	if game_client is GameClient:
		game_client.input_received.connect(_on_input_received)

func _on_input_received(input: String, value) -> void:
	if input == "word" and current_phase == "word_submit":
		_handle_word_submission(str(value))
	elif input == "guess" and current_phase == "guess":
		_handle_guess(str(value))

func _handle_word_submission(word: String) -> void:
	word_submitted.emit(word)

func _handle_guess(guess: String) -> void:
	guessed.emit(guess)

func mark_word_submitted() -> void:
	has_submitted_word = true
	checkmark.show()

func mark_guessed_correctly() -> void:
	has_guessed_correctly = true
	checkmark.show()

func mark_guessed_incorrectly() -> void:
	errormark.show()
	await get_tree().create_timer(0.5).timeout
	errormark.hide()

func set_phase(phase: String) -> void:
	current_phase = phase
	checkmark.hide()
	errormark.hide()

func reset_for_round() -> void:
	has_guessed_correctly = false
	errormark.hide()
	checkmark.hide()
