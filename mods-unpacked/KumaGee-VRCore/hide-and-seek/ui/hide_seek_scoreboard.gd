class_name HideSeekScoreboard
extends Control

## End-of-round scoreboard for Hide & Seek.
## Shows victory/defeat, scores, and play-again button.

@onready var result_label: Label = %ResultLabel
@onready var vr_score_label: Label = %VRScoreLabel
@onready var hider_scores_container: VBoxContainer = %HiderScoresContainer

## Scoring data
var vr_score: int = 0
var hider_scores: Array[Dictionary] = []  # [{name, score, survived, last_survivor, distracts}]

## Whether VR won
var vr_won: bool = false

func _ready() -> void:
	pass

func show_result(won: bool, vr_score: int, hiders: Array[Dictionary]) -> void:
	"""Show the end-of-round scoreboard."""
	vr_won = won
	vr_score = vr_score
	hider_scores = hiders
	
	if won:
		result_label.text = "🏆 VR Wins!"
		result_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	else:
		result_label.text = "🎭 Hiders Win!"
		result_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
	
	vr_score_label.text = "VR Score: %d" % vr_score
	
	# Clear existing hider scores
	for child in hider_scores_container.get_children():
		child.queue_free()
	
	# Add hider scores
	for hider in hiders:
		var row = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var name_label = Label.new()
		name_label.text = str(hider.get("name", "Unknown"))
		name_label.custom_minimum_size = Vector2(150, 30)
		row.add_child(name_label)
		
		var score_label = Label.new()
		score_label.text = "%d pts" % hider.get("score", 0)
		score_label.custom_minimum_size = Vector2(80, 30)
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(score_label)
		
		var details = []
		if hider.get("survived", false):
			details.append("Survived +3")
		if hider.get("last_survivor", false):
			details.append("Last +2")
		var distracts = hider.get("distracts", 0)
		if distracts > 0:
			details.append("Distracts +%d" % distracts)
		
		if not details.is_empty():
			var detail_label = Label.new()
			detail_label.text = " (%s)" % ", ".join(details)
			detail_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
			row.add_child(detail_label)
		
		hider_scores_container.add_child(row)

func calculate_vr_score(found_count: int, total_hiders: int) -> int:
	"""Calculate VR score: +1 per hider found, +3 bonus if all found."""
	var score = found_count
	if found_count == total_hiders and total_hiders > 0:
		score += 3  # All found bonus
	return score

func calculate_hider_score(survived: bool, last_survivor: bool, distracts: int) -> int:
	"""Calculate hider score: +3 for surviving, +2 for last survivor, +1 per distract."""
	var score = 0
	if survived:
		score += 3
	if last_survivor:
		score += 2
	score += distracts  # +1 per distract
	return score
