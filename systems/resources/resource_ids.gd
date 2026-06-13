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

# Crafted components (outputs of CraftingRegistry recipes). Same storage
# contract as raw materials: ordinary inventory items offline, pouch entries
# on the server.
const COMPONENT_PLANK := "plank"
const COMPONENT_STONE_BLOCK := "stone_block"
const COMPONENT_CLAY_BRICK := "clay_brick"
const COMPONENT_FIBER_ROPE := "fiber_rope"
const COMPONENT_CLOTH_ROLL := "cloth_roll"
const COMPONENT_FLOWER_BUNDLE := "flower_bundle"
const COMPONENT_SEED_PACKET := "seed_packet_crafted"

const ALL_MATERIALS: Array[String] = [
	MATERIAL_WOOD,
	MATERIAL_STONE,
	MATERIAL_FIBER,
	MATERIAL_CLAY,
]

const ALL_COMPONENTS: Array[String] = [
	COMPONENT_PLANK,
	COMPONENT_STONE_BLOCK,
	COMPONENT_CLAY_BRICK,
	COMPONENT_FIBER_ROPE,
	COMPONENT_CLOTH_ROLL,
	COMPONENT_FLOWER_BUNDLE,
	COMPONENT_SEED_PACKET,
]

static func definitions() -> Dictionary:
	return {
		MATERIAL_WOOD: {"id": MATERIAL_WOOD, "display_name": "Wood", "source": "trees"},
		MATERIAL_STONE: {"id": MATERIAL_STONE, "display_name": "Stone", "source": "rocks"},
		MATERIAL_FIBER: {"id": MATERIAL_FIBER, "display_name": "Fiber", "source": "bushes"},
		MATERIAL_CLAY: {"id": MATERIAL_CLAY, "display_name": "Clay", "source": "clay pits"},
		COMPONENT_PLANK: {"id": COMPONENT_PLANK, "display_name": "Plank", "source": "crafted"},
		COMPONENT_STONE_BLOCK: {"id": COMPONENT_STONE_BLOCK, "display_name": "Stone Block", "source": "crafted"},
		COMPONENT_CLAY_BRICK: {"id": COMPONENT_CLAY_BRICK, "display_name": "Clay Brick", "source": "crafted"},
		COMPONENT_FIBER_ROPE: {"id": COMPONENT_FIBER_ROPE, "display_name": "Fiber Rope", "source": "crafted"},
		COMPONENT_CLOTH_ROLL: {"id": COMPONENT_CLOTH_ROLL, "display_name": "Cloth Roll", "source": "crafted"},
		COMPONENT_FLOWER_BUNDLE: {"id": COMPONENT_FLOWER_BUNDLE, "display_name": "Flower Bundle", "source": "crafted"},
		COMPONENT_SEED_PACKET: {"id": COMPONENT_SEED_PACKET, "display_name": "Seed Packet", "source": "crafted"},
	}

static func is_material(item_id: String) -> bool:
	return ALL_MATERIALS.has(item_id)

static func is_component(item_id: String) -> bool:
	return ALL_COMPONENTS.has(item_id)

## Anything the material pouch / build costs / crafting may hold or spend.
static func is_storable(item_id: String) -> bool:
	return is_material(item_id) or is_component(item_id)

static func display_name(material_id: String) -> String:
	var entry: Variant = definitions().get(material_id, {})
	if typeof(entry) == TYPE_DICTIONARY:
		return String((entry as Dictionary).get("display_name", material_id))
	return material_id.capitalize()
