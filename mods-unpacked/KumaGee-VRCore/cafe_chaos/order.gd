class_name Order
extends RefCounted

## A single customer order with recipe and patience timer.

signal patience_depleted

enum State { WAITING, SERVED, FAILED }

var recipe_id: String
var recipe: Dictionary
var patience_remaining: float
var state: State = State.WAITING

func _init(p_recipe_id: String) -> void:
	recipe_id = p_recipe_id
	recipe = RecipeData.get_recipe(recipe_id)
	patience_remaining = recipe.get("patience", 45.0)

func tick(delta: float) -> void:
	if state != State.WAITING:
		return
	patience_remaining -= delta
	if patience_remaining <= 0.0:
		patience_remaining = 0.0
		state = State.FAILED
		patience_depleted.emit()

func get_patience_ratio() -> float:
	var max_patience: float = recipe.get("patience", 45.0)
	if max_patience <= 0.0:
		return 0.0
	return patience_remaining / max_patience

func is_complete() -> bool:
	return state != State.WAITING

func serve() -> void:
	state = State.SERVED

func fail() -> void:
	state = State.FAILED
