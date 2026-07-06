class_name DrawGuessPet
extends Plushie

@onready var correct_icon: Label = %CorrectIcon
@onready var incorrect_icon: Label = %IncorrectIcon
@onready var word_label: Label = %WordLabel


func show_typed_word(word: String) -> void:
	word_label.text = word.strip_edges()


func on_correct_guess(word: String = "") -> void:
	if not word.is_empty():
		show_typed_word(word)
	incorrect_icon.hide()
	correct_icon.show()
	_squeak_and_glow()
	await get_tree().create_timer(1.5).timeout
	correct_icon.hide()


func on_incorrect_guess(word: String = "") -> void:
	if not word.is_empty():
		show_typed_word(word)
	correct_icon.hide()
	incorrect_icon.show()
	await get_tree().create_timer(0.8).timeout
	incorrect_icon.hide()


func reset_for_round() -> void:
	word_label.text = ""
	correct_icon.hide()
	incorrect_icon.hide()
