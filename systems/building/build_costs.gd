extends RefCounted
class_name BuildCosts

## Material costs for every placeable, keyed by the stable placeable content id.
## Costs use ResourceIds material ids. A placeable missing from this table is
## free (legacy behaviour); validation asserts every registered placeable has an
## entry so new content can't silently skip the survival-lite loop.

static func costs() -> Dictionary:
	return {
		# Original five placeables.
		ContentIds.PLACEABLE_CRATE: {ResourceIds.MATERIAL_WOOD: 2},
		ContentIds.PLACEABLE_MAILBOX: {ResourceIds.MATERIAL_WOOD: 2, ResourceIds.MATERIAL_STONE: 1},
		ContentIds.PLACEABLE_STOOL: {ResourceIds.MATERIAL_WOOD: 1},
		ContentIds.PLACEABLE_LANTERN: {ResourceIds.MATERIAL_WOOD: 1, ResourceIds.MATERIAL_FIBER: 1},
		ContentIds.PLACEABLE_PLANTER: {ResourceIds.MATERIAL_CLAY: 2},
		# Cozy decor set (experiment/persistent-world pass).
		ContentIds.PLACEABLE_ROUND_TABLE: {ResourceIds.MATERIAL_WOOD: 3},
		ContentIds.PLACEABLE_COZY_CHAIR: {ResourceIds.MATERIAL_WOOD: 2, ResourceIds.MATERIAL_FIBER: 1},
		ContentIds.PLACEABLE_GARDEN_ARCH: {ResourceIds.MATERIAL_WOOD: 3, ResourceIds.MATERIAL_FIBER: 2},
		ContentIds.PLACEABLE_PICNIC_BLANKET: {ResourceIds.MATERIAL_FIBER: 3},
		ContentIds.PLACEABLE_BIRDHOUSE: {ResourceIds.MATERIAL_WOOD: 2},
		ContentIds.PLACEABLE_FENCE_SEGMENT: {ResourceIds.MATERIAL_WOOD: 1},
		ContentIds.PLACEABLE_PATH_LANTERN: {ResourceIds.MATERIAL_STONE: 1, ResourceIds.MATERIAL_FIBER: 1},
		ContentIds.PLACEABLE_BERRY_BASKET: {ResourceIds.MATERIAL_FIBER: 2},
		ContentIds.PLACEABLE_WOOD_PILE: {ResourceIds.MATERIAL_WOOD: 2},
		ContentIds.PLACEABLE_SIGNPOST: {ResourceIds.MATERIAL_WOOD: 2},
		ContentIds.PLACEABLE_DECOR_SHRUB: {ResourceIds.MATERIAL_FIBER: 1},
		ContentIds.PLACEABLE_TEA_TABLE: {ResourceIds.MATERIAL_WOOD: 2, ResourceIds.MATERIAL_CLAY: 1},
		ContentIds.PLACEABLE_BENCH: {ResourceIds.MATERIAL_WOOD: 3},
		ContentIds.PLACEABLE_FLOWER_BED: {ResourceIds.MATERIAL_FIBER: 1, ResourceIds.MATERIAL_CLAY: 1},
		ContentIds.PLACEABLE_TINY_POND: {ResourceIds.MATERIAL_STONE: 3, ResourceIds.MATERIAL_CLAY: 2},
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
