class_name Cup
extends RefCounted

## A drink cup that tracks which components have been added.

signal component_added(component: RecipeData.Component)
signal cup_ruined

var components: Array[RecipeData.Component] = []
var is_ruined: bool = false

func add_component(component: RecipeData.Component) -> void:
	if is_ruined:
		return
	components.append(component)
	component_added.emit(component)

func get_components() -> Array[RecipeData.Component]:
	return components

func has_component(component: RecipeData.Component) -> bool:
	return component in components

func is_empty() -> bool:
	return components.is_empty()

func ruin() -> void:
	is_ruined = true
	cup_ruined.emit()

func reset() -> void:
	components.clear()
	is_ruined = false
