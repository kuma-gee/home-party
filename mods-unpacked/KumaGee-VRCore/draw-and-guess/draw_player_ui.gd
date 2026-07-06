class_name DrawPlayerUI
extends JoinedPlayer

signal guessed(word: String)

var has_guessed_correctly := false

@export var checkmark: Label
@export var errormark: Label

func update_data(data: Dictionary):
	super(data)
	if game_client is GameClient and not game_client.input_received.is_connected(_on_input_received):
		game_client.input_received.connect(_on_input_received)

func _on_input_received(input: String, value) -> void:
	if input == "word":
		guessed.emit(str(value))

func mark_word_submitted(count := 1, max_count := 1) -> void:
	game_client.send_text("word_ack;ok;%d;%d" % [count, max_count])
	checkmark.show()
	set_ready()

func mark_guessed_correctly() -> void:
	has_guessed_correctly = true
	checkmark.show()

func mark_guessed_incorrectly() -> void:
	errormark.show()
	await get_tree().create_timer(0.5).timeout
	errormark.hide()

func reset_for_round() -> void:
	has_guessed_correctly = false
	errormark.hide()
	checkmark.hide()
	if game_client is GameClient:
		game_client.send_text("word_ack;reset")
