class_name DrawPrepareScene
extends Control

signal skipped()
signal continued()
signal ready_clicked()
signal freestyle_timer_started()
signal freestyle_correct()
signal freestyle_wrong()
signal freestyle_stopped()

# Doesn't work as @export ?!?!?!
@onready var skip_button: Button = %SkipButton
@onready var in_game: VBoxContainer = %InGame
@onready var prepare: VBoxContainer = %Prepare
@onready var round_label: Label = %Round
@onready var word_label: Label = %Word
@onready var time: Label = %Time
@onready var status_label: Label = %StatusLabel
@onready var ready_button: Button = %ReadyButton
@onready var start_timer_button: Button = %StartTimerButton
@onready var result_buttons: HBoxContainer = %ResultButtons
@onready var correct_button: Button = %CorrectButton
@onready var wrong_button: Button = %WrongButton
@onready var stop_game_button: Button = %StopGameButton

var round_timer: Timer:
	set(v):
		round_timer = v
		time.timer = v

var _is_revealing := false
var _is_freestyle := false

func _ready() -> void:
	skip_button.pressed.connect(_on_skip_button_pressed)
	ready_button.pressed.connect(func(): ready_clicked.emit())
	start_timer_button.pressed.connect(func(): freestyle_timer_started.emit())
	correct_button.pressed.connect(func(): freestyle_correct.emit())
	wrong_button.pressed.connect(func(): freestyle_wrong.emit())
	stop_game_button.pressed.connect(func(): freestyle_stopped.emit())
	_show_container(prepare)

func update_prepare_status(list: Array, total_words := 0, max_words_per_player := 1, freestyle_available := false) -> void:
	if freestyle_available:
		status_label.text = "Freestyle mode\n1 mobile player connected"
		ready_button.disabled = false
		return

	var active_client_count := 0
	for child in list:
		if child is DrawPlayerUI and child.is_ready:
			active_client_count += 1

	var total_players := list.size()
	status_label.text = "%d words\n%d / %d ready" % [total_words, active_client_count, total_players]
	ready_button.disabled = active_client_count < total_players or total_words <= 0

func _on_skip_button_pressed() -> void:
	if _is_revealing:
		continued.emit()
		return
	skipped.emit()

func _show_container(container) -> void:
	prepare.hide()
	in_game.hide()
	container.show()

func start_new_game(word: String, r: int, total_round: int):
	_is_freestyle = false
	_is_revealing = false
	_show_container(in_game)
	_set_freestyle_controls(false, false)
	skip_button.show()
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

func show_freestyle_ready(last_round: int) -> void:
	_is_freestyle = true
	_is_revealing = false
	_show_container(in_game)
	round_label.text = "Freestyle"
	word_label.text = "Start timer when ready for next word."
	if last_round > 0:
		word_label.text = "Word %d finished. Start timer when ready." % last_round
	_set_freestyle_controls(true, false)

func show_freestyle_drawing(round_number: int) -> void:
	_is_freestyle = true
	_show_container(in_game)
	round_label.text = "Freestyle word %d" % round_number
	word_label.text = "Draw your word."
	_set_freestyle_controls(false, true)

func _set_freestyle_controls(waiting_for_timer: bool, drawing: bool) -> void:
	skip_button.visible = not _is_freestyle
	start_timer_button.visible = _is_freestyle and waiting_for_timer
	stop_game_button.visible = _is_freestyle and waiting_for_timer
	result_buttons.visible = _is_freestyle and drawing
	correct_button.visible = _is_freestyle and drawing
	wrong_button.visible = _is_freestyle and drawing
