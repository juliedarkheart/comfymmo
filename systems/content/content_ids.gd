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
