extends RefCounted
class_name ContentIds

## Centralized, stable string ids for all current content. These are the single
## source of truth for the magic strings that were previously scattered across
## systems and controllers.
##
## CRITICAL: these ids are part of SAVE COMPATIBILITY. They must equal the exact
## strings already written to saves and used as dictionary keys. Never rename an id
## casually — display names can change, ids cannot. (See docs/save_data_model.md.)

# --- Items (player.inventory.items keys; also item-definition ids) -------------
const ITEM_CARROT := "carrot"
const ITEM_TURNIP := "turnip"
const ITEM_BERRY := "berry"
const ITEM_PLACEHOLDER_SEED_PACKET := "placeholder_seed_packet"
const ITEM_MAIL_TOKEN := "mail_token"

# --- Crops (crop_id in farming; harvest yields the matching item id) -----------
const CROP_CARROT := "carrot"
const CROP_TURNIP := "turnip"
const CROP_BERRY := "berry"

# Farm plot ids (keys under world.regions.homestead.farming.plots).
const FARM_PLOT_CARROT := "farm_plot_carrot"
const FARM_PLOT_TURNIP := "farm_plot_turnip"
const FARM_PLOT_BERRY := "farm_plot_berry"
const FARM_PLOT_LEGACY_MAIN := "farm_plot_main"

# --- Placeables (object_id in world.regions.*.placed_objects; registry keys) ----
const PLACEABLE_CRATE := "crate"
const PLACEABLE_MAILBOX := "mailbox"
const PLACEABLE_STOOL := "stool"
const PLACEABLE_LANTERN := "lantern"
const PLACEABLE_PLANTER := "planter"
# Cozy decor set (persistent-world pass). All share the PlaceableDecor scene
# family; ids are written to placed_objects records and must never change.
const PLACEABLE_ROUND_TABLE := "round_table"
const PLACEABLE_COZY_CHAIR := "cozy_chair"
const PLACEABLE_GARDEN_ARCH := "garden_arch"
const PLACEABLE_PICNIC_BLANKET := "picnic_blanket"
const PLACEABLE_BIRDHOUSE := "birdhouse"
const PLACEABLE_FENCE_SEGMENT := "fence_segment"
const PLACEABLE_PATH_LANTERN := "path_lantern"
const PLACEABLE_BERRY_BASKET := "berry_basket"
const PLACEABLE_WOOD_PILE := "wood_pile"
const PLACEABLE_SIGNPOST := "signpost"
const PLACEABLE_DECOR_SHRUB := "decor_shrub"
const PLACEABLE_TEA_TABLE := "tea_table"
const PLACEABLE_BENCH := "bench"
const PLACEABLE_FLOWER_BED := "flower_bed"
const PLACEABLE_TINY_POND := "tiny_pond"
# Crafting stations (outdoor placeables; interacting opens the crafting panel).
const PLACEABLE_WORKBENCH := "workbench"
const PLACEABLE_GARDEN_TABLE := "garden_table"
# Structure shells (exterior-only; "interior coming soon" — no entering).
const PLACEABLE_COTTAGE_SHELL := "cottage_shell"
const PLACEABLE_STORAGE_SHED := "storage_shed"
const PLACEABLE_WORKSHOP_HUT := "workshop_hut"
const PLACEABLE_BARN_SHELL := "barn_shell"
const PLACEABLE_GREENHOUSE_SHELL := "greenhouse_shell"
const PLACEABLE_WELL := "well"
# Modular construction pieces.
const PLACEABLE_WOOD_WALL := "wood_wall"
const PLACEABLE_WOOD_DOOR_WALL := "wood_door_wall"
const PLACEABLE_STONE_WALL := "stone_wall"
const PLACEABLE_FLOOR_DECK := "floor_deck"
const PLACEABLE_STONE_FOUNDATION := "stone_foundation"
const PLACEABLE_WOODEN_PILLAR := "wooden_pillar"
# Terrain/path overlays (terrain-as-placeables; shovel jobs).
const PLACEABLE_DIRT_PATH := "dirt_path"
const PLACEABLE_STONE_PATH := "stone_path"
const PLACEABLE_GRASS_PATCH := "grass_patch"
const PLACEABLE_FLOWER_MEADOW := "flower_meadow"
const PLACEABLE_PLAZA_TILE := "plaza_tile"
const PLACEABLE_FOREST_FLOOR := "forest_floor_patch"

const DECOR_PLACEABLE_IDS: Array[String] = [
	PLACEABLE_ROUND_TABLE, PLACEABLE_COZY_CHAIR, PLACEABLE_GARDEN_ARCH,
	PLACEABLE_PICNIC_BLANKET, PLACEABLE_BIRDHOUSE, PLACEABLE_FENCE_SEGMENT,
	PLACEABLE_PATH_LANTERN, PLACEABLE_BERRY_BASKET, PLACEABLE_WOOD_PILE,
	PLACEABLE_SIGNPOST, PLACEABLE_DECOR_SHRUB, PLACEABLE_TEA_TABLE,
	PLACEABLE_BENCH, PLACEABLE_FLOWER_BED, PLACEABLE_TINY_POND,
	PLACEABLE_WORKBENCH, PLACEABLE_GARDEN_TABLE,
	PLACEABLE_COTTAGE_SHELL, PLACEABLE_STORAGE_SHED, PLACEABLE_WORKSHOP_HUT,
	PLACEABLE_BARN_SHELL, PLACEABLE_GREENHOUSE_SHELL, PLACEABLE_WELL,
	PLACEABLE_WOOD_WALL, PLACEABLE_WOOD_DOOR_WALL, PLACEABLE_STONE_WALL,
	PLACEABLE_FLOOR_DECK, PLACEABLE_STONE_FOUNDATION, PLACEABLE_WOODEN_PILLAR,
	PLACEABLE_DIRT_PATH, PLACEABLE_STONE_PATH, PLACEABLE_GRASS_PATCH,
	PLACEABLE_FLOWER_MEADOW, PLACEABLE_PLAZA_TILE, PLACEABLE_FOREST_FLOOR,
]

# --- Creatures (conceptual ids; creatures are currently spawned by class, not
# persisted by id, so these are forward-looking definition keys) ----------------
const CREATURE_MOSS_RABBIT := "moss_rabbit"
const CREATURE_LANTERN_MOTH := "lantern_moth"
const CREATURE_STUMP_TURTLE := "stump_turtle"

# --- Villagers (conceptual ids; match the scene file names) ---------------------
const VILLAGER_MARIBEL_TOCK := "maribel_tock"
const VILLAGER_BRAM_NETTLE := "bram_nettle"

# --- Interaction types (InteractableSystem interaction_type strings) ------------
const INTERACTION_MAILBOX := "mailbox"
const INTERACTION_FARM_PLOT := "farm_plot"
const INTERACTION_AMBIENT_CREATURE := "ambient_creature"
const INTERACTION_VILLAGER := "villager"
const INTERACTION_NOTICE_BOARD := "notice_board"
const INTERACTION_SHRINE_MARKER := "shrine_marker"
const INTERACTION_REST := "rest"
const INTERACTION_REGION_TRANSITION := "region_transition"
const INTERACTION_TASK_BOARD := "task_board"
const INTERACTION_CRAFTING_STATION := "crafting_station"
const INTERACTION_GENERIC := "generic"

# --- Action ids (what the player can DO with an interactable; the values returned
# by InteractableSystem.get_available_actions). These are a separate concept from
# INTERACTION_* (which identifies what something IS). Exact existing strings only. --
const ACTION_CHECK_MAIL := "check_mail"
const ACTION_TEND_PLOT := "tend_plot"
const ACTION_READ_NOTICE := "read_notice"
const ACTION_TRAVEL := "travel"
const ACTION_REVIEW_TASKS := "review_tasks"
const ACTION_OBSERVE := "observe"
const ACTION_TALK := "talk"
const ACTION_REST := "rest"
const ACTION_INSPECT := "inspect"

# --- Areas / region ids (world.regions.* keys; outdoor areas of the overworld) --
const AREA_HOMESTEAD := "homestead"
const AREA_VILLAGE_SQUARE := "village_square"
const AREA_FOREST_EDGE := "forest_edge"
const AREA_WILDERNESS := "wilderness"

# --- Region flags (keys under world.regions.<area>.region_flags) ----------------
const FLAG_MARIBEL_INTRO_SEEN := "maribel_intro_seen"
const FLAG_MARIBEL_VISIT_COUNT := "maribel_visit_count"
const FLAG_BRAM_INTRO_SEEN := "bram_intro_seen"
const FLAG_BRAM_VISIT_COUNT := "bram_visit_count"
const FLAG_NOTICE_BOARD_SEEN := "notice_board_seen"
const FLAG_ADVENTURE_MARKER_SEEN := "adventure_marker_seen"

# --- Task / mailbox message ids (tasks.integration.* keys) ----------------------
const TASK_GROCERIES := "mock_groceries"
const TASK_WATER_GARDEN := "mock_water_garden"
const TASK_LEGACY_WATER_GARDEN := "mock_garden"
const TASK_HARVEST_CARROT := "mock_harvest_carrot"
const TASK_COOKOUT := "mock_cookout"
const TASK_DELIVERY := "mock_delivery"

# --- Future instance categories (WorldRegionManager instance loading) -----------
const INSTANCE_CATEGORY_DUNGEON := "dungeon"
const INSTANCE_CATEGORY_CAVE := "cave"
const INSTANCE_CATEGORY_INTERIOR := "interior"
