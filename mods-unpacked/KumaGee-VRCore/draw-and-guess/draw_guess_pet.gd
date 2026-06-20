class_name DrawGuessPet
extends Plushie

@onready var correct_icon: Label3D = %CorrectIcon
@onready var incorrect_icon: Label3D = %IncorrectIcon


func on_correct_guess() -> void:
	correct_icon.show()
	_squeak_and_glow()
	await get_tree().create_timer(1.5).timeout
	correct_icon.hide()


func on_incorrect_guess() -> void:
	incorrect_icon.show()
	await get_tree().create_timer(0.8).timeout
	incorrect_icon.hide()


func reset_for_round() -> void:
	correct_icon.hide()
	incorrect_icon.hide()
