extends RefCounted
class_name BuildCategories

## Maps each placeable content id to a player-facing BUILD MENU category, and
## defines the ordered category list. This is a UI grouping layer over the
## coarser ContentRegistry `category` field, so the build menu reads like a
## survival-builder kit (Foundations / Walls / Roofs / ...). Unmapped ids fall
## into "Decor" so nothing ever disappears from the menu.

const FOUNDATIONS := "Foundations"
const WALLS := "Walls"
const DOORS_WINDOWS := "Doors & Windows"
const ROOFS := "Roofs"
const FENCES_GATES := "Fences & Gates"
const STRUCTURES := "Structures"
const CRAFTING := "Crafting & Utilities"
const STORAGE := "Storage"
const FARMING := "Farming"
const PATHS := "Paths & Terrain"
const FURNITURE := "Furniture"
const DECOR := "Decor"

## Display order for the category selector.
const ORDER: Array[String] = [
	FOUNDATIONS, WALLS, DOORS_WINDOWS, ROOFS, FENCES_GATES, STRUCTURES,
	CRAFTING, STORAGE, FARMING, PATHS, FURNITURE, DECOR,
]

static func _map() -> Dictionary:
	return {
		# Foundations / floors
		ContentIds.PLACEABLE_STONE_FOUNDATION: FOUNDATIONS,
		ContentIds.PLACEABLE_FLOOR_DECK: FOUNDATIONS,
		# Walls
		ContentIds.PLACEABLE_WOOD_WALL: WALLS,
		ContentIds.PLACEABLE_STONE_WALL: WALLS,
		ContentIds.PLACEABLE_WOODEN_PILLAR: WALLS,
		# Doors & windows
		ContentIds.PLACEABLE_WOOD_DOOR_WALL: DOORS_WINDOWS,
		ContentIds.PLACEABLE_WOOD_WINDOW_WALL: DOORS_WINDOWS,
		# Roofs
		ContentIds.PLACEABLE_ROOF_CAP: ROOFS,
		# Fences & gates
		ContentIds.PLACEABLE_FENCE_SEGMENT: FENCES_GATES,
		ContentIds.PLACEABLE_FENCE_CORNER: FENCES_GATES,
		ContentIds.PLACEABLE_FENCE_GATE: FENCES_GATES,
		ContentIds.PLACEABLE_GARDEN_ARCH: FENCES_GATES,
		# Structures (prefab shells)
		ContentIds.PLACEABLE_COTTAGE_SHELL: STRUCTURES,
		ContentIds.PLACEABLE_STORAGE_SHED: STRUCTURES,
		ContentIds.PLACEABLE_WORKSHOP_HUT: STRUCTURES,
		ContentIds.PLACEABLE_BARN_SHELL: STRUCTURES,
		ContentIds.PLACEABLE_GREENHOUSE_SHELL: STRUCTURES,
		ContentIds.PLACEABLE_WELL: STRUCTURES,
		# Crafting & utilities
		ContentIds.PLACEABLE_WORKBENCH: CRAFTING,
		ContentIds.PLACEABLE_GARDEN_TABLE: CRAFTING,
		# Storage
		ContentIds.PLACEABLE_CRATE: STORAGE,
		ContentIds.PLACEABLE_BERRY_BASKET: STORAGE,
		ContentIds.PLACEABLE_WOOD_PILE: STORAGE,
		# Farming
		ContentIds.PLACEABLE_PLANTER: FARMING,
		ContentIds.PLACEABLE_FLOWER_BED: FARMING,
		# Paths & terrain
		ContentIds.PLACEABLE_DIRT_PATH: PATHS,
		ContentIds.PLACEABLE_STONE_PATH: PATHS,
		ContentIds.PLACEABLE_GRASS_PATCH: PATHS,
		ContentIds.PLACEABLE_FLOWER_MEADOW: PATHS,
		ContentIds.PLACEABLE_PLAZA_TILE: PATHS,
		ContentIds.PLACEABLE_FOREST_FLOOR: PATHS,
		ContentIds.PLACEABLE_STEPS: PATHS,
		# Furniture
		ContentIds.PLACEABLE_ROUND_TABLE: FURNITURE,
		ContentIds.PLACEABLE_COZY_CHAIR: FURNITURE,
		ContentIds.PLACEABLE_BENCH: FURNITURE,
		ContentIds.PLACEABLE_TEA_TABLE: FURNITURE,
		ContentIds.PLACEABLE_STOOL: FURNITURE,
		# Decor
		ContentIds.PLACEABLE_LANTERN: DECOR,
		ContentIds.PLACEABLE_PATH_LANTERN: DECOR,
		ContentIds.PLACEABLE_BIRDHOUSE: DECOR,
		ContentIds.PLACEABLE_SIGNPOST: DECOR,
		ContentIds.PLACEABLE_DECOR_SHRUB: DECOR,
		ContentIds.PLACEABLE_TINY_POND: DECOR,
		ContentIds.PLACEABLE_PICNIC_BLANKET: DECOR,
		ContentIds.PLACEABLE_MAILBOX: DECOR,
	}

static func category_of(placeable_id: String) -> String:
	return String(_map().get(placeable_id, DECOR))

## All placeable ids in a category, in registry order.
static func ids_in(category: String, all_ids: Array) -> Array:
	var result: Array = []
	for id_variant in all_ids:
		if category_of(String(id_variant)) == category:
			result.append(String(id_variant))
	return result
