class_name GameoverPanel
extends Control

signal back_to_menu()
signal restart_game()

@onready var gameover_label: Label = $VBoxContainer/GameoverLabel
@onready var rankings_list: VBoxContainer = $VBoxContainer/ScrollContainer/RankingsList
@onready var menu_button: Button = $VBoxContainer/MenuButton
@onready var restart_button: Button = $VBoxContainer/RestartButton


func _ready() -> void:
	if menu_button:
		menu_button.pressed.connect(func(): back_to_menu.emit())
	if restart_button:
		restart_button.pressed.connect(func(): restart_game.emit())

func set_title(txt: String):
	gameover_label.text = txt

func set_rankings(rankings: Array) -> void:
	for child in rankings_list.get_children():
		child.queue_free()

	var header := Label.new()
	header.text = "%-4s %-16s %6s %14s %8s" % ["#", "Name", "Deaths", "Damage", "Score"]
	rankings_list.add_child(header)

	for entry in rankings:
		var row := Label.new()
		row.text = "%-4d %-16s %6d %14d %8d" % [
			entry["rank"],
			entry["name"],
			entry["deaths"],
			entry["damage_dealt"],
			entry["score"],
		]
		rankings_list.add_child(row)

