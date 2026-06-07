class_name DrawPrepareScene
extends Control

signal ready_clicked()
signal skipped()


# Doesn't work as @export ?!?!?!
@onready var ready_button: Button = %ReadyButton
@onready var word_count: Label = %WordCount
@onready var skip_button: Button = %SkipButton
@onready var in_game: VBoxContainer = %InGame
@onready var prepare: VBoxContainer = %Prepare
@onready var round_label: Label = %Round
@onready var time_label: Label = %Time
@onready var word_label: Label = %Word

var round_timer: Timer

func _ready() -> void:
	ready_button.pressed.connect(func(): ready_clicked.emit())
	skip_button.pressed.connect(func(): skipped.emit())
	_show_prepare()

func _show_prepare() -> void:
	prepare.show()
	in_game.hide()

func _show_game() -> void:
	prepare.hide()
	in_game.show()

func _process(_delta: float) -> void:
	if round_timer == null or round_timer.is_stopped(): return
	_update_timer_label(round_timer.time_left)

func _update_timer_label(time_left: float) -> void:
	var minutes = int(time_left) / 60
	var seconds = int(time_left) % 60
	time_label.text = "%d:%02d" % [minutes, seconds]

func update(list: Array):
	var active_client_count = 0
	for child in list:
		if child is DrawPlayerUI and child.has_submitted_word:
			active_client_count += 1
	
	var total_players = list.size()
	var text = "Players connected: %d\nWords submitted: %d / %d" % [
		total_players,
		active_client_count,
		total_players
	]
	word_count.text = text

func start_new_game(word: String, round: int, total_round: int):
	_show_game()
	round_label.text = "Word %d of %d" % [round, total_round]
	word_label.text = word
