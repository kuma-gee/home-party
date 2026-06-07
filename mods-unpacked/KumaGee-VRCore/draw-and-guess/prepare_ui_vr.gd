class_name DrawPrepareScene
extends Control

signal ready_clicked()
signal skipped()

@export_category("In-Game UI")
@export var in_game: Control
@export var round_label: Label
@export var time_label: Label
@export var word_label: Label
@export var skip_button: Button
@export var round_timer: Timer

@export_category("Prepare UI")
@export var ready_button: Button
@export var count_label: Label
@export var prepare: Control

func _ready() -> void:
	ready_button.pressed.connect(func(): ready_clicked.emit())

func _process(delta: float) -> void:
	if round_timer == null or round_timer.is_stopped(): return

func update(list: Array):
	var active_client_count = 0
	for child in list:
		if child is DrawPlayerUI and child.has_submitted_word:
			active_client_count += 1
	
	var total_players = list
	var text = "Players connected: %d\nWords submitted: %d / %d" % [
		total_players,
		active_client_count,
		total_players
	]
	count_label.text = text

func start_new_game(word: String, round: int, total_round: int):
	pass
