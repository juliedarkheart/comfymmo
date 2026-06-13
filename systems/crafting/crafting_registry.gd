extends RefCounted
class_name CraftingRegistry

## All crafting recipes, keyed by stable recipe_id. The unlock ladder:
##   Lv1 hand:         plank, fiber_rope
##   Lv2 workbench:    stone_block, clay_brick      Lv2 garden table: seed_packet
##   Lv3 garden table: cloth_roll, flower_bundle
## Components then gate the prettier build costs (see BuildCosts), which is the
## progression: raw materials build simple things, crafted components build
## bigger/prettier things.

static func recipes() -> Dictionary:
	return {
		"craft_plank": {
			"recipe_id": "craft_plank", "display_name": "Planks",
			"category": CraftingRecipe.CATEGORY_MATERIALS,
			"inputs": {ResourceIds.MATERIAL_WOOD: 1},
			"output_id": ResourceIds.COMPONENT_PLANK, "output_amount": 2,
			"required_level": 1, "required_station": "", "xp_reward": 2,
			"admin_only": false,
			"description": "Split a log into two smooth planks.",
		},
		"craft_fiber_rope": {
			"recipe_id": "craft_fiber_rope", "display_name": "Fiber Rope",
			"category": CraftingRecipe.CATEGORY_MATERIALS,
			"inputs": {ResourceIds.MATERIAL_FIBER: 2},
			"output_id": ResourceIds.COMPONENT_FIBER_ROPE, "output_amount": 1,
			"required_level": 1, "required_station": "", "xp_reward": 2,
			"admin_only": false,
			"description": "Twist fibers into sturdy rope.",
		},
		"craft_stone_block": {
			"recipe_id": "craft_stone_block", "display_name": "Stone Block",
			"category": CraftingRecipe.CATEGORY_BUILDING,
			"inputs": {ResourceIds.MATERIAL_STONE: 2},
			"output_id": ResourceIds.COMPONENT_STONE_BLOCK, "output_amount": 1,
			"required_level": 2, "required_station": ContentIds.PLACEABLE_WORKBENCH, "xp_reward": 3,
			"admin_only": false,
			"description": "Square off rough stone at the workbench.",
		},
		"craft_clay_brick": {
			"recipe_id": "craft_clay_brick", "display_name": "Clay Brick",
			"category": CraftingRecipe.CATEGORY_BUILDING,
			"inputs": {ResourceIds.MATERIAL_CLAY: 2},
			"output_id": ResourceIds.COMPONENT_CLAY_BRICK, "output_amount": 1,
			"required_level": 2, "required_station": ContentIds.PLACEABLE_WORKBENCH, "xp_reward": 3,
			"admin_only": false,
			"description": "Press and dry clay into a tidy brick.",
		},
		"craft_cloth_roll": {
			"recipe_id": "craft_cloth_roll", "display_name": "Cloth Roll",
			"category": CraftingRecipe.CATEGORY_MATERIALS,
			"inputs": {ResourceIds.MATERIAL_FIBER: 2, ContentIds.ITEM_BERRY: 1},
			"output_id": ResourceIds.COMPONENT_CLOTH_ROLL, "output_amount": 1,
			"required_level": 3, "required_station": ContentIds.PLACEABLE_GARDEN_TABLE, "xp_reward": 5,
			"required_skill": ProgressionRegistry.SKILL_CRAFTING, "required_skill_level": 2,
			"admin_only": false,
			"description": "Weave fiber and berry-dye into soft cloth.",
		},
		"craft_flower_bundle": {
			"recipe_id": "craft_flower_bundle", "display_name": "Flower Bundle",
			"category": CraftingRecipe.CATEGORY_DECOR,
			"inputs": {ResourceIds.MATERIAL_FIBER: 1, ContentIds.ITEM_BERRY: 2},
			"output_id": ResourceIds.COMPONENT_FLOWER_BUNDLE, "output_amount": 1,
			"required_level": 3, "required_station": ContentIds.PLACEABLE_GARDEN_TABLE, "xp_reward": 5,
			"required_skill": ProgressionRegistry.SKILL_GATHERING, "required_skill_level": 2,
			"admin_only": false,
			"description": "Tie blossoms and berries into a cheerful bundle.",
		},
		"craft_seed_packet": {
			"recipe_id": "craft_seed_packet", "display_name": "Seed Packet",
			"category": CraftingRecipe.CATEGORY_FARMING,
			"inputs": {ContentIds.ITEM_CARROT: 1, ContentIds.ITEM_TURNIP: 1},
			"output_id": ResourceIds.COMPONENT_SEED_PACKET, "output_amount": 1,
			"required_level": 2, "required_station": ContentIds.PLACEABLE_GARDEN_TABLE, "xp_reward": 4,
			"admin_only": false,
			"description": "Save seeds from your best crops (future planting stock).",
		},
	}

static func get_recipe(recipe_id: String) -> Dictionary:
	var entry: Variant = recipes().get(recipe_id, {})
	if typeof(entry) == TYPE_DICTIONARY:
		return entry as Dictionary
	return {}

static func has_recipe(recipe_id: String) -> bool:
	return recipes().has(recipe_id)

## Recipes shown to normal players, sorted by level then name.
static func player_recipes() -> Array:
	var result: Array = []
	for recipe in recipes().values():
		if not bool((recipe as Dictionary).get("admin_only", false)):
			result.append(recipe)
	result.sort_custom(func(a, b) -> bool:
		if int(a["required_level"]) != int(b["required_level"]):
			return int(a["required_level"]) < int(b["required_level"])
		return String(a["display_name"]) < String(b["display_name"])
	)
	return result

## Station placeable ids referenced by any recipe.
static func station_ids() -> Array:
	var stations: Dictionary = {}
	for recipe in recipes().values():
		var station: String = String((recipe as Dictionary).get("required_station", ""))
		if not station.is_empty():
			stations[station] = true
	return stations.keys()

static func inputs_text(recipe: Dictionary) -> String:
	var parts: Array[String] = []
	var inputs: Dictionary = recipe.get("inputs", {}) as Dictionary
	for input_id in inputs.keys():
		parts.append("%d %s" % [int(inputs[input_id]), _item_label(String(input_id))])
	return ", ".join(parts)

static func _item_label(item_id: String) -> String:
	if ResourceIds.is_storable(item_id):
		return ResourceIds.display_name(item_id)
	var item: Dictionary = ContentRegistry.items().get(item_id, {}) as Dictionary
	return String(item.get("display_name", item_id.capitalize()))
