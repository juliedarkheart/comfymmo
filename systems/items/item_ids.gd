extends RefCounted
class_name ItemIds

## Item taxonomy beyond materials/components: tools, weapons, wearables, and
## quest items. Everything here is an ordinary inventory item id (offline) and
## a pouch entry (server), so persistence is inherited. Stable ids only.
## Tools gate jobs NOW; weapons are future-combat placeholders; wearables map
## to existing appearance accessories. (The suggested systems/tools/* files
## are folded in here — one taxonomy beats three small registries.)

const CATEGORY_MATERIAL := "material"
const CATEGORY_COMPONENT := "component"
const CATEGORY_TOOL := "tool"
const CATEGORY_WEAPON := "weapon"
const CATEGORY_WEARABLE := "wearable"
const CATEGORY_QUEST := "quest_item"

# --- Tools (required for jobs) -------------------------------------------------
const TOOL_WORN_AXE := "worn_axe"
const TOOL_WORN_PICKAXE := "worn_pickaxe"
const TOOL_WORN_HOE := "worn_hoe"
const TOOL_WATERING_CAN := "watering_can"
const TOOL_SIMPLE_HAMMER := "simple_hammer"
const TOOL_BASIC_SHOVEL := "basic_shovel"

const ALL_TOOLS: Array[String] = [
	TOOL_WORN_AXE, TOOL_WORN_PICKAXE, TOOL_WORN_HOE,
	TOOL_WATERING_CAN, TOOL_SIMPLE_HAMMER, TOOL_BASIC_SHOVEL,
]

# --- Weapons (future-ready placeholders; no combat wired) -----------------------
const WEAPON_WOODEN_STAFF := "wooden_staff"
const WEAPON_PRACTICE_SWORD := "practice_sword"
const WEAPON_SLINGSHOT := "slingshot"

const ALL_WEAPONS: Array[String] = [
	WEAPON_WOODEN_STAFF, WEAPON_PRACTICE_SWORD, WEAPON_SLINGSHOT,
]

# --- Wearables (craftable; map to existing appearance accessory ids) ------------
const WEARABLE_LEAF_CLIP := "wearable_leaf_clip"
const WEARABLE_TINY_HAT := "wearable_tiny_hat"
const WEARABLE_ROUND_GLASSES := "wearable_round_glasses"
const WEARABLE_ACORN_CAP := "wearable_acorn_cap"

const ALL_WEARABLES: Array[String] = [
	WEARABLE_LEAF_CLIP, WEARABLE_TINY_HAT, WEARABLE_ROUND_GLASSES, WEARABLE_ACORN_CAP,
]

# --- Quest items -----------------------------------------------------------------
const QUEST_LAND_TOKEN := "land_token"

const ALL_QUEST_ITEMS: Array[String] = [QUEST_LAND_TOKEN]

## Starter loadout granted to new profiles (and recraftable by hand — see
## docs/new_player_onboarding.md "starter soft-lock prevention").
static func starter_loadout() -> Dictionary:
	return {
		TOOL_WORN_AXE: 1,
		TOOL_WORN_PICKAXE: 1,
		TOOL_WORN_HOE: 1,
		TOOL_WATERING_CAN: 1,
		TOOL_SIMPLE_HAMMER: 1,
		TOOL_BASIC_SHOVEL: 1,
	}

static func definitions() -> Dictionary:
	return {
		TOOL_WORN_AXE: {"display_name": "Axe", "category": CATEGORY_TOOL, "job": "chop trees"},
		TOOL_WORN_PICKAXE: {"display_name": "Pickaxe", "category": CATEGORY_TOOL, "job": "mine boulders"},
		TOOL_WORN_HOE: {"display_name": "Hoe", "category": CATEGORY_TOOL, "job": "till soil"},
		TOOL_WATERING_CAN: {"display_name": "Watering Can", "category": CATEGORY_TOOL, "job": "water crops"},
		TOOL_SIMPLE_HAMMER: {"display_name": "Build Tool", "category": CATEGORY_TOOL, "job": "place objects"},
		TOOL_BASIC_SHOVEL: {"display_name": "Path Tool", "category": CATEGORY_TOOL, "job": "dig clay, lay paths"},
		WEAPON_WOODEN_STAFF: {"display_name": "Wooden Staff", "category": CATEGORY_WEAPON, "job": "future adventures"},
		WEAPON_PRACTICE_SWORD: {"display_name": "Practice Sword", "category": CATEGORY_WEAPON, "job": "future adventures"},
		WEAPON_SLINGSHOT: {"display_name": "Slingshot", "category": CATEGORY_WEAPON, "job": "future adventures"},
		WEARABLE_LEAF_CLIP: {"display_name": "Leaf Clip (wearable)", "category": CATEGORY_WEARABLE, "accessory_id": "leaf_clip"},
		WEARABLE_TINY_HAT: {"display_name": "Tiny Hat (wearable)", "category": CATEGORY_WEARABLE, "accessory_id": "tiny_hat"},
		WEARABLE_ROUND_GLASSES: {"display_name": "Round Glasses (wearable)", "category": CATEGORY_WEARABLE, "accessory_id": "round_glasses"},
		WEARABLE_ACORN_CAP: {"display_name": "Acorn Cap (wearable)", "category": CATEGORY_WEARABLE, "accessory_id": "acorn_cap"},
		QUEST_LAND_TOKEN: {"display_name": "Land Token", "category": CATEGORY_QUEST, "job": "claim a neighborhood plot"},
	}

# Named is_tool_item (not is_tool) to avoid Object's built-in is_tool().
static func is_tool_item(item_id: String) -> bool:
	return ALL_TOOLS.has(item_id)

static func is_equipment(item_id: String) -> bool:
	return ALL_TOOLS.has(item_id) or ALL_WEAPONS.has(item_id) or ALL_WEARABLES.has(item_id) or ALL_QUEST_ITEMS.has(item_id)

## Everything the pouch/inventory/costs/crafting may hold or spend.
static func is_storable(item_id: String) -> bool:
	return ResourceIds.is_storable(item_id) or is_equipment(item_id)

static func display_name(item_id: String) -> String:
	var entry: Dictionary = definitions().get(item_id, {}) as Dictionary
	if not entry.is_empty():
		return String(entry.get("display_name", item_id.capitalize()))
	return ResourceIds.display_name(item_id)

## Accessory id a wearable unlock corresponds to ("" if none).
static func wearable_accessory(item_id: String) -> String:
	var entry: Dictionary = definitions().get(item_id, {}) as Dictionary
	return String(entry.get("accessory_id", ""))
