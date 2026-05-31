class_name ScoreTable
extends Control

@onready var title_label: Label = $TitleLabel
@onready var rankings_grid: GridContainer = $ScrollContainer/RankingsGrid

func set_title(txt: String) -> void:
	title_label.text = txt

func set_rankings(rankings: Array) -> void:
	for child in rankings_grid.get_children():
		child.queue_free()

	var headers := ["#", "P#", "Firepower", "Damage", "Score"]
	for header_text in headers:
		var header := Label.new()
		header.text = header_text
		header.theme_type_variation = "LabelSmall"
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rankings_grid.add_child(header)

	for entry in rankings:
		var cells := [
			str(entry["rank"]),
			entry["name"],
			str(entry["firepower"]),
			str(entry["damage_dealt"]),
			str(entry["score"]),
		]
		for cell_text in cells:
			var cell := Label.new()
			cell.text = cell_text
			cell.theme_type_variation = "LabelSmall"
			cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			rankings_grid.add_child(cell)
