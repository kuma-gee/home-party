class_name DrawPrepareInstructions
extends Control

signal ready_clicked()

@onready var status_label: Label = %StatusLabel
@onready var ready_button: Button = %ReadyButton

func _ready() -> void:
	ready_button.pressed.connect(func(): ready_clicked.emit())

func update(list: Array, total_words := 0, max_words_per_player := 1, freestyle_available := false) -> void:
	if freestyle_available:
		status_label.text = "Freestyle mode\n1 mobile player connected"
		ready_button.disabled = false
		return

	var active_client_count = 0
	for child in list:
		if child is DrawPlayerUI and child.is_ready:
			active_client_count += 1

	var total_players = list.size()
	var max_words: int = total_players * max_words_per_player
	status_label.text = "%d / %d words submitted\n%d / %d players ready" % [total_words, max_words, active_client_count, total_players]
	ready_button.disabled = active_client_count < total_players or total_words <= 0
