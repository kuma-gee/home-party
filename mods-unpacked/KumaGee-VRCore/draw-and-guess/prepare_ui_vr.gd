class_name DrawPrepareScene
extends Control

signal ready_clicked()
signal skipped()
signal continued()

# Doesn't work as @export ?!?!?!
@onready var ready_button: Button = %ReadyButton
@onready var word_count: Label = %WordCount
@onready var skip_button: Button = %SkipButton
@onready var in_game: VBoxContainer = %InGame
@onready var prepare: VBoxContainer = %Prepare
@onready var round_label: Label = %Round
@onready var word_label: Label = %Word
@onready var time: Label = %Time
@onready var leaderboard: Leaderboard = %Leaderboard

var round_timer: Timer:
	set(v):
		round_timer = v
		time.timer = v

var _is_revealing := false

func _ready() -> void:
	ready_button.pressed.connect(func(): ready_clicked.emit())
	skip_button.pressed.connect(_on_skip_button_pressed)
	_show_container(prepare)

func _on_skip_button_pressed() -> void:
	if _is_revealing:
		continued.emit()
		return
	skipped.emit()

func _show_container(container) -> void:
	prepare.hide()
	in_game.hide()
	leaderboard.hide()
	container.show()

func show_leaderboard(title, entries):
	leaderboard.set_title(title)
	leaderboard.set_entries(entries)
	_show_container(leaderboard)

func update(list: Array, total_words := 0, max_words_per_player := 1):
	var active_client_count = 0
	for child in list:
		if child is DrawPlayerUI and child.is_ready:
			active_client_count += 1
	
	var total_players = list.size()
	var max_words: int = total_players * max_words_per_player
	word_count.text = "%d / %d words\n%d / %d players ready" % [total_words, max_words, active_client_count, total_players]
	ready_button.disabled = active_client_count < total_players or total_words <= 0

func start_new_game(word: String, r: int, total_round: int):
	_is_revealing = false
	_show_container(in_game)
	round_label.text = "Word %d of %d" % [r, total_round]
	word_label.text = word
	skip_button.text = "Skip Word"
	var len = word.length()
	if len < 8:
		word_label.theme_type_variation = "LabelLarge"
	elif len < 11:
		word_label.theme_type_variation = ""
	else:
		word_label.theme_type_variation = "LabelSmall"

func show_reveal() -> void:
	_is_revealing = true
	skip_button.text = "Next Word"
