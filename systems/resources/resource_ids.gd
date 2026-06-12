extends RefCounted
class_name ResourceIds

## Stable ids for gatherable building materials. These are ITEM ids: materials
## live in the existing InventorySystem (`player.inventory.items`), so they
## persist through the existing save path with zero migration. Same contract as
## ContentIds — display names may change, ids may not.

const MATERIAL_WOOD := "wood"
const MATERIAL_STONE := "stone"
const MATERIAL_FIBER := "fiber"
const MATERIAL_CLAY := "clay"

const ALL_MATERIALS: Array[String] = [
	MATERIAL_WOOD,
	MATERIAL_STONE,
	MATERIAL_FIBER,
	MATERIAL_CLAY,
]

static func definitions() -> Dictionary:
	return {
		MATERIAL_WOOD: {"id": MATERIAL_WOOD, "display_name": "Wood", "source": "trees"},
		MATERIAL_STONE: {"id": MATERIAL_STONE, "display_name": "Stone", "source": "rocks"},
		MATERIAL_FIBER: {"id": MATERIAL_FIBER, "display_name": "Fiber", "source": "bushes"},
		MATERIAL_CLAY: {"id": MATERIAL_CLAY, "display_name": "Clay", "source": "clay pits"},
	}

static func is_material(item_id: String) -> bool:
	return ALL_MATERIALS.has(item_id)

static func display_name(material_id: String) -> String:
	var entry: Variant = definitions().get(material_id, {})
	if typeof(entry) == TYPE_DICTIONARY:
		return String((entry as Dictionary).get("display_name", material_id))
	return material_id
