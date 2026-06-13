extends RefCounted
class_name CraftingRecipe

## Recipe shape + validation. Recipes are plain dictionaries (JSON-friendly,
## wire-friendly) defined in CraftingRegistry; this class documents the schema
## and provides the validator the registry and the test suite share.
##
## Schema:
## {
##   recipe_id: String        stable id, never renamed
##   display_name: String
##   category: String         one of CATEGORIES
##   inputs: {item_id: int}   storable ids (materials/components) or crop items
##   output_id: String        storable id (or crop item) granted
##   output_amount: int
##   required_level: int      1 = always available
##   required_station: String "" = hand-craftable, else a station placeable id
##   xp_reward: int
##   admin_only: bool         hidden from the normal panel (none shipped yet)
##   description: String
## }

const CATEGORY_MATERIALS := "materials"
const CATEGORY_BUILDING := "building_components"
const CATEGORY_FURNITURE := "furniture"
const CATEGORY_FARMING := "farming"
const CATEGORY_DECOR := "decor"
const CATEGORY_TOOLS := "tools"
const CATEGORY_ADMIN := "admin_world"

const CATEGORIES: Array[String] = [
	CATEGORY_MATERIALS, CATEGORY_BUILDING, CATEGORY_FURNITURE,
	CATEGORY_FARMING, CATEGORY_DECOR, CATEGORY_TOOLS, CATEGORY_ADMIN,
]

## Crop items may flow through crafting (farming bridge) alongside storables.
static func is_valid_craft_item(item_id: String) -> bool:
	return ResourceIds.is_storable(item_id) or ContentRegistry.items().has(item_id)

## Returns "" when valid, otherwise a description of the first problem.
static func validate(recipe: Dictionary) -> String:
	if String(recipe.get("recipe_id", "")).is_empty():
		return "missing recipe_id"
	if not CATEGORIES.has(String(recipe.get("category", ""))):
		return "unknown category '%s'" % recipe.get("category")
	var inputs: Variant = recipe.get("inputs", {})
	if typeof(inputs) != TYPE_DICTIONARY or (inputs as Dictionary).is_empty():
		return "inputs must be a non-empty dictionary"
	for input_id in (inputs as Dictionary).keys():
		if not is_valid_craft_item(String(input_id)):
			return "unknown input id '%s'" % input_id
		if int((inputs as Dictionary)[input_id]) <= 0:
			return "non-positive input amount for '%s'" % input_id
	if not is_valid_craft_item(String(recipe.get("output_id", ""))):
		return "unknown output id '%s'" % recipe.get("output_id")
	if int(recipe.get("output_amount", 0)) <= 0:
		return "non-positive output amount"
	if int(recipe.get("required_level", 1)) < 1:
		return "required_level below 1"
	var station: String = String(recipe.get("required_station", ""))
	if not station.is_empty() and not ContentRegistry.placeables().has(station):
		return "unknown required_station '%s'" % station
	var required_skill: String = String(recipe.get("required_skill", ""))
	if not required_skill.is_empty() and not ProgressionRegistry.SKILL_IDS.has(required_skill):
		return "unknown required_skill '%s'" % required_skill
	return ""
