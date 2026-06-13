extends RefCounted
class_name ProgressionRegistry

## Skill catalog, XP-source amounts, and progression-based unlock locks for
## recipes/placeables. Stable ids; display names may change. One place to
## balance the whole loop — see docs/progression.md.

const SKILL_GATHERING := "gathering"
const SKILL_MINING := "mining"
const SKILL_FARMING := "farming"
const SKILL_CRAFTING := "crafting"
const SKILL_BUILDING := "building"
const SKILL_SOCIAL := "social"
const SKILL_EXPLORATION := "exploration"
const SKILL_STEWARDSHIP := "stewardship"

const SKILL_IDS: Array[String] = [
	SKILL_GATHERING, SKILL_MINING, SKILL_FARMING, SKILL_CRAFTING,
	SKILL_BUILDING, SKILL_SOCIAL, SKILL_EXPLORATION, SKILL_STEWARDSHIP,
]

static func skills() -> Dictionary:
	return {
		SKILL_GATHERING: {"display_name": "Gathering", "hint": "wood, fiber, foraging"},
		SKILL_MINING: {"display_name": "Mining", "hint": "stone, clay"},
		SKILL_FARMING: {"display_name": "Farming", "hint": "planting, watering, harvesting"},
		SKILL_CRAFTING: {"display_name": "Crafting", "hint": "components and recipes"},
		SKILL_BUILDING: {"display_name": "Building", "hint": "placing and arranging"},
		SKILL_SOCIAL: {"display_name": "Social", "hint": "villagers and neighbours"},
		SKILL_EXPLORATION: {"display_name": "Exploration", "hint": "creatures and landmarks"},
		SKILL_STEWARDSHIP: {"display_name": "Stewardship", "hint": "tasks and town care"},
	}

static func skill_display_name(skill_id: String) -> String:
	var entry: Dictionary = skills().get(skill_id, {}) as Dictionary
	return String(entry.get("display_name", skill_id.capitalize()))

## Which skill a gathered material trains: wood/fiber = gathering, stone/clay
## = mining (the "mining" track until ore-like nodes exist).
static func skill_for_material(material_id: String) -> String:
	if material_id == ResourceIds.MATERIAL_STONE or material_id == ResourceIds.MATERIAL_CLAY:
		return SKILL_MINING
	return SKILL_GATHERING

## Building XP: advanced (component-costing) placements train more.
static func building_xp_for_cost(cost: Dictionary) -> int:
	for item_id in cost.keys():
		if ResourceIds.is_component(String(item_id)):
			return 5
	return 2

## Progression locks on placeables (demonstration set; most stay unlocked).
## Shape: {placeable_id: {required_player_level, required_skill,
## required_skill_level}} — any key may be absent.
static func placeable_locks() -> Dictionary:
	return {
		ContentIds.PLACEABLE_GARDEN_ARCH: {"required_skill": SKILL_BUILDING, "required_skill_level": 2},
		ContentIds.PLACEABLE_TINY_POND: {"required_player_level": 3},
	}

## Shared unlock check for recipes and placeables. `lock` may contain
## required_player_level / required_skill + required_skill_level. Returns ""
## when allowed, otherwise a friendly denial.
static func lock_reason(lock: Dictionary, player_level: int, skill_levels: Dictionary) -> String:
	if lock.is_empty():
		return ""
	var needed_player: int = int(lock.get("required_player_level", 1))
	if player_level < needed_player:
		return "Requires Player Level %d" % needed_player
	var skill_id: String = String(lock.get("required_skill", ""))
	if not skill_id.is_empty():
		var needed_skill: int = int(lock.get("required_skill_level", 1))
		if int(skill_levels.get(skill_id, 1)) < needed_skill:
			return "Requires %s Level %d" % [skill_display_name(skill_id), needed_skill]
	return ""
