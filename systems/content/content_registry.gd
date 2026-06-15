extends RefCounted
class_name ContentRegistry

## Lightweight, read-only content definitions keyed by the stable ids in
## `ContentIds`. This is DATA, not gameplay logic — it is intentionally not wired
## into the runtime systems yet (ObjectRegistry/FarmingSystem still own live state).
## It exists so future work (UI, tooling, backend, moderation, multiplayer) has one
## place to look up display names and metadata by id instead of re-deriving them.
##
## Display names may change freely. Ids must not (save compatibility).

# --- Items ---------------------------------------------------------------------
static func items() -> Dictionary:
	return {
		ContentIds.ITEM_CARROT: {"id": ContentIds.ITEM_CARROT, "display_name": "Carrot", "category": "crop", "icon_id": "", "stackable": true},
		ContentIds.ITEM_TURNIP: {"id": ContentIds.ITEM_TURNIP, "display_name": "Turnip", "category": "crop", "icon_id": "", "stackable": true},
		ContentIds.ITEM_BERRY: {"id": ContentIds.ITEM_BERRY, "display_name": "Berry", "category": "crop", "icon_id": "", "stackable": true},
	}

# --- Crops ---------------------------------------------------------------------
static func crops() -> Dictionary:
	return {
		ContentIds.CROP_CARROT: {"id": ContentIds.CROP_CARROT, "display_name": "Carrot", "harvest_item_id": ContentIds.ITEM_CARROT, "stage_count": 4, "comfort_value": 5},
		ContentIds.CROP_TURNIP: {"id": ContentIds.CROP_TURNIP, "display_name": "Turnip", "harvest_item_id": ContentIds.ITEM_TURNIP, "stage_count": 4, "comfort_value": 0},
		ContentIds.CROP_BERRY: {"id": ContentIds.CROP_BERRY, "display_name": "Berry", "harvest_item_id": ContentIds.ITEM_BERRY, "stage_count": 4, "comfort_value": 0},
	}

# --- Placeables (scene paths match ObjectRegistry's live catalog) ---------------
static func placeables() -> Dictionary:
	return {
		ContentIds.PLACEABLE_CRATE: {"id": ContentIds.PLACEABLE_CRATE, "display_name": "Wooden Crate", "scene_path": "res://scenes/buildings/placeable_crate.tscn", "footprint": Vector2i.ONE, "category": "storage"},
		ContentIds.PLACEABLE_MAILBOX: {"id": ContentIds.PLACEABLE_MAILBOX, "display_name": "Cozy Mailbox", "scene_path": "res://scenes/buildings/placeable_mailbox.tscn", "footprint": Vector2i.ONE, "category": "interactive"},
		ContentIds.PLACEABLE_STOOL: {"id": ContentIds.PLACEABLE_STOOL, "display_name": "Small Stool", "scene_path": "res://scenes/buildings/placeable_stool.tscn", "footprint": Vector2i.ONE, "category": "decor"},
		ContentIds.PLACEABLE_LANTERN: {"id": ContentIds.PLACEABLE_LANTERN, "display_name": "Porch Lantern", "scene_path": "res://scenes/buildings/placeable_lantern.tscn", "footprint": Vector2i.ONE, "category": "decor"},
		ContentIds.PLACEABLE_PLANTER: {"id": ContentIds.PLACEABLE_PLANTER, "display_name": "Cozy Planter", "scene_path": "res://scenes/buildings/placeable_planter.tscn", "footprint": Vector2i.ONE, "category": "decor"},
		ContentIds.PLACEABLE_ROUND_TABLE: _decor_entry(ContentIds.PLACEABLE_ROUND_TABLE, "Round Table", "furniture"),
		ContentIds.PLACEABLE_COZY_CHAIR: _decor_entry(ContentIds.PLACEABLE_COZY_CHAIR, "Cozy Chair", "furniture"),
		ContentIds.PLACEABLE_GARDEN_ARCH: _decor_entry(ContentIds.PLACEABLE_GARDEN_ARCH, "Garden Arch", "garden"),
		ContentIds.PLACEABLE_PICNIC_BLANKET: _decor_entry(ContentIds.PLACEABLE_PICNIC_BLANKET, "Picnic Blanket", "garden"),
		ContentIds.PLACEABLE_BIRDHOUSE: _decor_entry(ContentIds.PLACEABLE_BIRDHOUSE, "Birdhouse", "garden"),
		ContentIds.PLACEABLE_FENCE_SEGMENT: _decor_entry(ContentIds.PLACEABLE_FENCE_SEGMENT, "Fence Segment", "structure"),
		ContentIds.PLACEABLE_PATH_LANTERN: _decor_entry(ContentIds.PLACEABLE_PATH_LANTERN, "Path Lantern", "decor"),
		ContentIds.PLACEABLE_BERRY_BASKET: _decor_entry(ContentIds.PLACEABLE_BERRY_BASKET, "Berry Basket", "decor"),
		ContentIds.PLACEABLE_WOOD_PILE: _decor_entry(ContentIds.PLACEABLE_WOOD_PILE, "Wood Pile", "decor"),
		ContentIds.PLACEABLE_SIGNPOST: _decor_entry(ContentIds.PLACEABLE_SIGNPOST, "Signpost", "decor"),
		ContentIds.PLACEABLE_DECOR_SHRUB: _decor_entry(ContentIds.PLACEABLE_DECOR_SHRUB, "Trimmed Shrub", "garden"),
		ContentIds.PLACEABLE_TEA_TABLE: _decor_entry(ContentIds.PLACEABLE_TEA_TABLE, "Tea Table", "furniture"),
		ContentIds.PLACEABLE_BENCH: _decor_entry(ContentIds.PLACEABLE_BENCH, "Garden Bench", "furniture"),
		ContentIds.PLACEABLE_FLOWER_BED: _decor_entry(ContentIds.PLACEABLE_FLOWER_BED, "Flower Bed", "garden"),
		ContentIds.PLACEABLE_TINY_POND: _decor_entry(ContentIds.PLACEABLE_TINY_POND, "Tiny Pond", "garden"),
		ContentIds.PLACEABLE_WORKBENCH: _decor_entry(ContentIds.PLACEABLE_WORKBENCH, "Workbench", "station"),
		ContentIds.PLACEABLE_GARDEN_TABLE: _decor_entry(ContentIds.PLACEABLE_GARDEN_TABLE, "Garden Table", "station"),
		# Structure shells (exterior-only, 2x2 footprint except the well).
		ContentIds.PLACEABLE_COTTAGE_SHELL: _decor_entry(ContentIds.PLACEABLE_COTTAGE_SHELL, "Tiny Cottage Shell", "structure", Vector2i(2, 2)),
		ContentIds.PLACEABLE_STORAGE_SHED: _decor_entry(ContentIds.PLACEABLE_STORAGE_SHED, "Storage Shed", "structure", Vector2i(2, 2)),
		ContentIds.PLACEABLE_WORKSHOP_HUT: _decor_entry(ContentIds.PLACEABLE_WORKSHOP_HUT, "Workshop Hut", "structure", Vector2i(2, 2)),
		ContentIds.PLACEABLE_BARN_SHELL: _decor_entry(ContentIds.PLACEABLE_BARN_SHELL, "Barn Shell", "structure", Vector2i(2, 2)),
		ContentIds.PLACEABLE_GREENHOUSE_SHELL: _decor_entry(ContentIds.PLACEABLE_GREENHOUSE_SHELL, "Greenhouse Shell", "structure", Vector2i(2, 2)),
		ContentIds.PLACEABLE_WELL: _decor_entry(ContentIds.PLACEABLE_WELL, "Stone Well", "structure"),
		# Modular construction pieces.
		ContentIds.PLACEABLE_WOOD_WALL: _decor_entry(ContentIds.PLACEABLE_WOOD_WALL, "Wood Wall", "modular"),
		ContentIds.PLACEABLE_WOOD_DOOR_WALL: _decor_entry(ContentIds.PLACEABLE_WOOD_DOOR_WALL, "Wood Door Wall", "modular"),
		ContentIds.PLACEABLE_STONE_WALL: _decor_entry(ContentIds.PLACEABLE_STONE_WALL, "Stone Wall", "modular"),
		ContentIds.PLACEABLE_FLOOR_DECK: _decor_entry(ContentIds.PLACEABLE_FLOOR_DECK, "Deck Floor", "modular"),
		ContentIds.PLACEABLE_STONE_FOUNDATION: _decor_entry(ContentIds.PLACEABLE_STONE_FOUNDATION, "Stone Foundation", "modular"),
		ContentIds.PLACEABLE_WOODEN_PILLAR: _decor_entry(ContentIds.PLACEABLE_WOODEN_PILLAR, "Wooden Pillar", "modular"),
		# Terrain/path overlays (shovel jobs).
		ContentIds.PLACEABLE_DIRT_PATH: _decor_entry(ContentIds.PLACEABLE_DIRT_PATH, "Dirt Path", "terrain"),
		ContentIds.PLACEABLE_STONE_PATH: _decor_entry(ContentIds.PLACEABLE_STONE_PATH, "Stone Path", "terrain"),
		ContentIds.PLACEABLE_GRASS_PATCH: _decor_entry(ContentIds.PLACEABLE_GRASS_PATCH, "Grass Patch", "terrain"),
		ContentIds.PLACEABLE_FLOWER_MEADOW: _decor_entry(ContentIds.PLACEABLE_FLOWER_MEADOW, "Flower Meadow", "terrain"),
		ContentIds.PLACEABLE_PLAZA_TILE: _decor_entry(ContentIds.PLACEABLE_PLAZA_TILE, "Plaza Stone", "terrain"),
		ContentIds.PLACEABLE_FOREST_FLOOR: _decor_entry(ContentIds.PLACEABLE_FOREST_FLOOR, "Forest Floor", "terrain"),
	}

static func _decor_entry(placeable_id: String, display_name: String, category: String, footprint: Vector2i = Vector2i.ONE) -> Dictionary:
	return {
		"id": placeable_id,
		"display_name": display_name,
		"scene_path": "res://scenes/buildings/decor/placeable_%s.tscn" % placeable_id,
		"footprint": footprint,
		"category": category,
	}

static func placeable_category(placeable_id: String) -> String:
	var entry: Dictionary = placeables().get(placeable_id, {}) as Dictionary
	return String(entry.get("category", ""))

static func placeable_footprint(placeable_id: String) -> Vector2i:
	var entry: Dictionary = placeables().get(placeable_id, {}) as Dictionary
	var footprint: Variant = entry.get("footprint", Vector2i.ONE)
	return footprint if footprint is Vector2i else Vector2i.ONE

## Tool required to place an item: terrain overlays take the shovel, every
## other build job takes the hammer (both in the starter loadout).
static func placeable_required_tool(placeable_id: String) -> String:
	if placeable_category(placeable_id) == "terrain":
		return ItemIds.TOOL_BASIC_SHOVEL
	return ItemIds.TOOL_SIMPLE_HAMMER

# --- Creatures -----------------------------------------------------------------
static func creatures() -> Dictionary:
	return {
		ContentIds.CREATURE_MOSS_RABBIT: {"id": ContentIds.CREATURE_MOSS_RABBIT, "display_name": "Moss Rabbit", "type": "ground"},
		ContentIds.CREATURE_LANTERN_MOTH: {"id": ContentIds.CREATURE_LANTERN_MOTH, "display_name": "Lantern Moth", "type": "flying"},
		ContentIds.CREATURE_STUMP_TURTLE: {"id": ContentIds.CREATURE_STUMP_TURTLE, "display_name": "Stump Turtle", "type": "ground"},
	}

# --- Villagers -----------------------------------------------------------------
static func villagers() -> Dictionary:
	return {
		ContentIds.VILLAGER_MARIBEL_TOCK: {"id": ContentIds.VILLAGER_MARIBEL_TOCK, "display_name": "Maribel Tock", "role": "calendar keeper", "area_id": ContentIds.AREA_VILLAGE_SQUARE},
		ContentIds.VILLAGER_BRAM_NETTLE: {"id": ContentIds.VILLAGER_BRAM_NETTLE, "display_name": "Bram Nettle", "role": "groundskeeper", "area_id": ContentIds.AREA_VILLAGE_SQUARE},
	}

# --- Interaction prompts (display only; the live prompt text lives at the call
# site / InteractableSystem defaults — this is reference metadata) ---------------
static func interactions() -> Dictionary:
	return {
		ContentIds.INTERACTION_MAILBOX: {"id": ContentIds.INTERACTION_MAILBOX, "display_name": "Check mailbox"},
		ContentIds.INTERACTION_FARM_PLOT: {"id": ContentIds.INTERACTION_FARM_PLOT, "display_name": "Tend plot"},
		ContentIds.INTERACTION_AMBIENT_CREATURE: {"id": ContentIds.INTERACTION_AMBIENT_CREATURE, "display_name": "Observe"},
		ContentIds.INTERACTION_VILLAGER: {"id": ContentIds.INTERACTION_VILLAGER, "display_name": "Talk"},
		ContentIds.INTERACTION_NOTICE_BOARD: {"id": ContentIds.INTERACTION_NOTICE_BOARD, "display_name": "Read notice board"},
		ContentIds.INTERACTION_SHRINE_MARKER: {"id": ContentIds.INTERACTION_SHRINE_MARKER, "display_name": "Inspect shrine"},
		ContentIds.INTERACTION_REST: {"id": ContentIds.INTERACTION_REST, "display_name": "Rest"},
	}

# --- Areas ---------------------------------------------------------------------
static func areas() -> Dictionary:
	return {
		ContentIds.AREA_HOMESTEAD: {"id": ContentIds.AREA_HOMESTEAD, "display_name": "Homestead"},
		ContentIds.AREA_VILLAGE_SQUARE: {"id": ContentIds.AREA_VILLAGE_SQUARE, "display_name": "Village Square"},
		ContentIds.AREA_FOREST_EDGE: {"id": ContentIds.AREA_FOREST_EDGE, "display_name": "Forest Edge"},
		ContentIds.AREA_WILDERNESS: {"id": ContentIds.AREA_WILDERNESS, "display_name": "Wilderness/Unknown"},
	}

static func area_display_name(area_id: String) -> String:
	var entry: Variant = areas().get(area_id, {})
	if typeof(entry) == TYPE_DICTIONARY:
		return String((entry as Dictionary).get("display_name", area_id))
	return area_id
