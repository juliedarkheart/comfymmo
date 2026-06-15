extends RefCounted
class_name BuildCosts

## Material costs for every placeable, keyed by the stable placeable content id.
## Costs use ResourceIds storable ids (raw materials AND crafted components).
## A placeable missing from this table is free (legacy behaviour); validation
## asserts every registered placeable has an entry.
##
## Progression tiering (docs/crafting.md): starter items cost RAW materials so
## new players build immediately; the prettier/advanced tier costs CRAFTED
## components, so gathering -> crafting -> building forms a real ladder.

static func costs() -> Dictionary:
	return {
		# --- Starter tier: raw materials only ----------------------------------
		ContentIds.PLACEABLE_CRATE: {ResourceIds.MATERIAL_WOOD: 2},
		ContentIds.PLACEABLE_MAILBOX: {ResourceIds.MATERIAL_WOOD: 2, ResourceIds.MATERIAL_STONE: 1},
		ContentIds.PLACEABLE_STOOL: {ResourceIds.MATERIAL_WOOD: 1},
		ContentIds.PLACEABLE_LANTERN: {ResourceIds.MATERIAL_WOOD: 1, ResourceIds.MATERIAL_FIBER: 1},
		ContentIds.PLACEABLE_PLANTER: {ResourceIds.MATERIAL_CLAY: 2},
		ContentIds.PLACEABLE_PICNIC_BLANKET: {ResourceIds.MATERIAL_FIBER: 3},
		ContentIds.PLACEABLE_FENCE_SEGMENT: {ResourceIds.MATERIAL_WOOD: 1},
		ContentIds.PLACEABLE_BERRY_BASKET: {ResourceIds.MATERIAL_FIBER: 2},
		ContentIds.PLACEABLE_WOOD_PILE: {ResourceIds.MATERIAL_WOOD: 2},
		ContentIds.PLACEABLE_SIGNPOST: {ResourceIds.MATERIAL_WOOD: 2},
		ContentIds.PLACEABLE_DECOR_SHRUB: {ResourceIds.MATERIAL_FIBER: 1},
		# Stations cost raw materials so crafting can bootstrap.
		ContentIds.PLACEABLE_WORKBENCH: {ResourceIds.MATERIAL_WOOD: 3, ResourceIds.MATERIAL_STONE: 2},
		ContentIds.PLACEABLE_GARDEN_TABLE: {ResourceIds.MATERIAL_WOOD: 2, ResourceIds.MATERIAL_FIBER: 2},
		# --- Crafted tier: requires components ----------------------------------
		ContentIds.PLACEABLE_ROUND_TABLE: {ResourceIds.COMPONENT_PLANK: 3},
		ContentIds.PLACEABLE_BENCH: {ResourceIds.COMPONENT_PLANK: 3},
		ContentIds.PLACEABLE_COZY_CHAIR: {ResourceIds.COMPONENT_PLANK: 2, ResourceIds.COMPONENT_CLOTH_ROLL: 1},
		ContentIds.PLACEABLE_TEA_TABLE: {ResourceIds.COMPONENT_PLANK: 2, ResourceIds.COMPONENT_CLAY_BRICK: 1},
		ContentIds.PLACEABLE_BIRDHOUSE: {ResourceIds.COMPONENT_PLANK: 1, ResourceIds.COMPONENT_FIBER_ROPE: 1},
		ContentIds.PLACEABLE_PATH_LANTERN: {ResourceIds.COMPONENT_STONE_BLOCK: 1, ResourceIds.COMPONENT_FIBER_ROPE: 1},
		ContentIds.PLACEABLE_GARDEN_ARCH: {ResourceIds.COMPONENT_PLANK: 2, ResourceIds.COMPONENT_FIBER_ROPE: 1, ResourceIds.COMPONENT_FLOWER_BUNDLE: 1},
		ContentIds.PLACEABLE_FLOWER_BED: {ResourceIds.COMPONENT_FLOWER_BUNDLE: 1, ResourceIds.MATERIAL_CLAY: 1},
		ContentIds.PLACEABLE_TINY_POND: {ResourceIds.COMPONENT_STONE_BLOCK: 2, ResourceIds.MATERIAL_CLAY: 2},
		# --- Structure shells (component-heavy; the construction tier) ----------
		ContentIds.PLACEABLE_COTTAGE_SHELL: {ResourceIds.COMPONENT_PLANK: 6, ResourceIds.COMPONENT_STONE_BLOCK: 3, ResourceIds.COMPONENT_FIBER_ROPE: 2},
		ContentIds.PLACEABLE_STORAGE_SHED: {ResourceIds.COMPONENT_PLANK: 4, ResourceIds.COMPONENT_STONE_BLOCK: 2},
		ContentIds.PLACEABLE_WORKSHOP_HUT: {ResourceIds.COMPONENT_PLANK: 5, ResourceIds.COMPONENT_STONE_BLOCK: 2, ResourceIds.COMPONENT_FIBER_ROPE: 1},
		ContentIds.PLACEABLE_BARN_SHELL: {ResourceIds.COMPONENT_PLANK: 6, ResourceIds.COMPONENT_FIBER_ROPE: 3},
		ContentIds.PLACEABLE_GREENHOUSE_SHELL: {ResourceIds.COMPONENT_PLANK: 4, ResourceIds.COMPONENT_CLAY_BRICK: 3, ResourceIds.COMPONENT_FIBER_ROPE: 1},
		ContentIds.PLACEABLE_WELL: {ResourceIds.COMPONENT_STONE_BLOCK: 3, ResourceIds.COMPONENT_PLANK: 2},
		# --- Modular pieces -------------------------------------------------------
		ContentIds.PLACEABLE_WOOD_WALL: {ResourceIds.COMPONENT_PLANK: 2},
		ContentIds.PLACEABLE_WOOD_DOOR_WALL: {ResourceIds.COMPONENT_PLANK: 2, ResourceIds.COMPONENT_FIBER_ROPE: 1},
		ContentIds.PLACEABLE_STONE_WALL: {ResourceIds.COMPONENT_STONE_BLOCK: 2},
		ContentIds.PLACEABLE_FLOOR_DECK: {ResourceIds.COMPONENT_PLANK: 2},
		ContentIds.PLACEABLE_STONE_FOUNDATION: {ResourceIds.COMPONENT_STONE_BLOCK: 2},
		ContentIds.PLACEABLE_WOODEN_PILLAR: {ResourceIds.COMPONENT_PLANK: 1},
		# --- Terrain overlays (cheap, raw; shovel jobs) -----------------------------
		ContentIds.PLACEABLE_DIRT_PATH: {ResourceIds.MATERIAL_CLAY: 1},
		ContentIds.PLACEABLE_STONE_PATH: {ResourceIds.MATERIAL_STONE: 2},
		ContentIds.PLACEABLE_GRASS_PATCH: {ResourceIds.MATERIAL_FIBER: 1},
		ContentIds.PLACEABLE_FLOWER_MEADOW: {ResourceIds.COMPONENT_FLOWER_BUNDLE: 1},
		ContentIds.PLACEABLE_PLAZA_TILE: {ResourceIds.COMPONENT_STONE_BLOCK: 1},
		ContentIds.PLACEABLE_FOREST_FLOOR: {ResourceIds.MATERIAL_FIBER: 1, ResourceIds.MATERIAL_CLAY: 1},
	}

static func cost_of(placeable_id: String) -> Dictionary:
	var entry: Variant = costs().get(placeable_id, {})
	if typeof(entry) == TYPE_DICTIONARY:
		return entry as Dictionary
	return {}

## Friendly "2 Wood, 1 Fiber" string for HUD hints; empty when free.
static func cost_text(placeable_id: String) -> String:
	var cost: Dictionary = cost_of(placeable_id)
	if cost.is_empty():
		return ""
	var parts: Array[String] = []
	for material_id in cost.keys():
		parts.append("%d %s" % [int(cost[material_id]), ResourceIds.display_name(String(material_id))])
	return ", ".join(parts)
