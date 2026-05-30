class_name ScoreTable
extends Control

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var rankings_list: VBoxContainer = $VBoxContainer/ScrollContainer/RankingsList

func set_title(txt: String) -> void:
	title_label.text = txt

func set_rankings(rankings: Array) -> void:
	for child in rankings_list.get_children():
		child.queue_free()

	var header := Label.new()
	header.text = "%-4s %-4s %10s %14s %8s" % ["#", "P#", "Firepower", "Damage", "Score"]
	rankings_list.add_child(header)

	for entry in rankings:
		var row := Label.new()
		row.text = "%-4d %-4s %10d %14d %8d" % [
			entry["rank"],
			entry["name"],
			entry["firepower"],
			entry["damage_dealt"],
			entry["score"],
		]
		rankings_list.add_child(row)
