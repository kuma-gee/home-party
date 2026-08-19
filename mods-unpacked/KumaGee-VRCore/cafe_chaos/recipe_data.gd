class_name RecipeData
extends RefCounted

## Static recipe definitions for Café Chaos drinks.

enum Component {
	ESPRESSO_SHOT,
	STEAMED_MILK,
	MILK_FOAM,
	HOT_WATER,
	CHOCOLATE_SYRUP,
	VANILLA_SYRUP,
	CARAMEL_SYRUP,
}

const RECIPES := {
	"espresso": {
		"name": "Espresso",
		"components": [Component.ESPRESSO_SHOT],
		"patience": 45.0,
	},
}

static func get_recipe(recipe_id: String) -> Dictionary:
	return RECIPES.get(recipe_id, {})

static func get_all_recipe_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in RECIPES.keys():
		ids.append(key)
	return ids
