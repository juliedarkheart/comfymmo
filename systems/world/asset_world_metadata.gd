extends RefCounted
class_name AssetWorldMetadata

## Authoritative, commit-safe world-behavior contract for the live LimeZu homestead assets.
##
## ONE place that declares, per logical asset id, HOW it collides, WHETHER/WHERE it is
## interactable, and HOW it shows on the minimap + debug overlay. This replaces the scattered
## hand-patched blockers/markers with a single readable registry the map/minimap/overlay read.
##
## Pure data + helpers — no licensed media, no scene/texture deps. A clean checkout works and
## Sprout is unaffected. Collision is NEVER auto-derived from raw PNG alpha at runtime; these
## are CURATED footprints (alpha analysis is an offline authoring aid only). PLACEMENT (which
## tile each instance sits on) still lives in OverworldMap's curated slice; this declares the
## per-TYPE behaviour those placements use.

## Collision architecture:
## - Runtime physics reads collision_shapes and instantiates Godot shapes from this data.
## - Tile rectangles are terrain/grid fallbacks or placement proxies, never the final barn
##   runtime collision.
## - Alpha masks are analyzed only by local tools under licensed_assets/limezu; committed
##   metadata stores simplified points/rects/circles/lines, not copied image pixels.
# --- collision_type ---
const COLLISION_NONE := "none"            # visual-only / ground — never blocks
const COLLISION_TRUNK := "trunk_circle"   # small circle at the visible base (trees)
const COLLISION_RECT := "rect"            # local-space rectangle shape
const COLLISION_LINE := "line"            # thin segment (fence)

const COLLISION_CIRCLE := "circle"
const COLLISION_MULTI_RECT := "multi_rect"
const COLLISION_POLYGON := "polygon"
const COLLISION_MULTI_POLYGON := "multi_polygon"
const COLLISION_TILE_RECT_FALLBACK := "tile_rect_fallback"
const COLLISION_ALPHA_MASK_SOURCE := "alpha_mask_source"
const COLLISION_GENERATED_POLYGON_FROM_ALPHA := "generated_polygon_from_alpha"

# --- minimap_kind ---
const MINIMAP_HIDDEN := "hidden"
const MINIMAP_PLAYER_DOT := "player_dot"
const MINIMAP_NPC_DOT := "npc_dot"
const MINIMAP_BUILDING_FOOTPRINT := "building_footprint"
const MINIMAP_FARM_PATCH := "farm_patch"
const MINIMAP_PATH_SHAPE := "path_shape"
const MINIMAP_FENCE_LINE := "fence_line"
const MINIMAP_TREE_DOT := "tree_dot"
const MINIMAP_SIGN_DOT := "sign_dot"
const MINIMAP_PLACED_OBJECT_DOT := "placed_object_dot"

# Backward-compatible aliases for older validation/callers.
const MINIMAP_NONE := MINIMAP_HIDDEN
const MINIMAP_PLAYER := MINIMAP_PLAYER_DOT
const MINIMAP_BUILDING := MINIMAP_BUILDING_FOOTPRINT
const MINIMAP_FARM := MINIMAP_FARM_PATCH
const MINIMAP_NPC := MINIMAP_NPC_DOT
const MINIMAP_SIGN := MINIMAP_SIGN_DOT

# Curated homestead barn collision footprint (ABSOLUTE tiles for the slice barn placed at
# base tile (13,13)). Trims the silo-dome top rows + the empty right column of the old
# 9x10 block so the player is blocked by the building BODY, not open grass beside the silo.
const BARN_COLLISION_RECT := Rect2i(9, 6, 8, 8)
const BARN_PLACEMENT_PROXY_RECT := BARN_COLLISION_RECT

const _DEFAULT := {
	"debug_name": "Unknown",
	"collision_type": COLLISION_NONE,
	"collision_radius": 0.0,
	"collision_offset": Vector2.ZERO,
	"collision_anchor": "tile_origin",
	"collision_rect": Rect2i(),
	"collision_tile_proxy": Rect2i(),
	"collision_shapes": [],
	"collision_precision": "visual_only",
	"collision_source": "",
	"interaction_enabled": false,
	"interaction_label": "",
	"interaction_point_offset": Vector2.ZERO,
	"minimap_visible": false,
	"minimap_kind": MINIMAP_NONE,
	"minimap_color": "#ffffff",
	"minimap_shape": "dot",
	"minimap_priority": 0,
	"minimap_style_id": "",
	"minimap_label": "",
	"minimap_footprint": Rect2i(),
	"notes": "",
}

const DATA := {
	"object.barn": {
		"debug_name": "Barn",
		"collision_type": COLLISION_MULTI_POLYGON,
		"collision_rect": Rect2i(),
		"collision_tile_proxy": BARN_PLACEMENT_PROXY_RECT,
		"collision_anchor": "sprite_bottom_center",
		"collision_precision": "asset_polygon_curated_from_alpha",
		"collision_source": "object.barn alpha-mask review (128x160 source, x2 render)",
		"collision_shapes": [
			{
				"type": COLLISION_POLYGON,
				"label": "barn_lower_body",
				"points": [
					Vector2(-118, -172), Vector2(-96, -206), Vector2(36, -206),
					Vector2(76, -178), Vector2(112, -146), Vector2(114, -18),
					Vector2(104, 0), Vector2(-112, 0), Vector2(-122, -18),
				],
			},
			{
				"type": COLLISION_POLYGON,
				"label": "silo_lower_body",
				"points": [
					Vector2(38, -238), Vector2(100, -238), Vector2(116, -206),
					Vector2(116, -18), Vector2(104, 0), Vector2(44, 0),
					Vector2(34, -18),
				],
			},
		],
		"interaction_enabled": false,
		"minimap_visible": true,
		"minimap_kind": MINIMAP_BUILDING_FOOTPRINT,
		"minimap_color": "#8d6b46",
		"minimap_shape": "rect",
		"minimap_priority": 80,
		"minimap_label": "Barn",
		"minimap_footprint": Rect2i(9, 4, 9, 10),
		"notes": "Solid building. Runtime collision is two local-space polygons traced/curated against the lower body/silo silhouette; tile proxy is placement-only.",
	},
	"object.tree": {
		"debug_name": "Apple Tree",
		"collision_type": COLLISION_CIRCLE,
		"collision_radius": 10.0,
		"collision_offset": Vector2(0, -4),
		"collision_anchor": "sprite_bottom_center",
		"collision_precision": "asset_base_circle_from_alpha",
		"collision_source": "object.tree lower trunk alpha-mask review (80x80 source, x2 render)",
		"collision_shapes": [
			{"type": COLLISION_CIRCLE, "label": "trunk_base", "offset": Vector2(0, -4), "radius": 10.0},
		],
		"interaction_enabled": false,
		"minimap_visible": true,
		"minimap_kind": MINIMAP_TREE_DOT,
		"minimap_color": "#355f37",
		"minimap_shape": "dot",
		"minimap_priority": 25,
		"notes": "FOREGROUND homestead tree (TREE_TILES). Blocks at the visible trunk/base circle, never the canopy.",
	},
	"object.tree_small": {
		"debug_name": "Small Tree (decor)",
		"collision_type": COLLISION_NONE,
		"interaction_enabled": false,
		"minimap_visible": false,
		"notes": "BACKGROUND/edge decoration. Visual-only by design: no collider, no prompt.",
	},
	"object.tree_edge": {
		"debug_name": "Edge Tree (decor)",
		"collision_type": COLLISION_NONE,
		"interaction_enabled": false,
		"minimap_visible": false,
		"notes": "Peripheral framing tree. Visual-only by design (consistent with object.tree_small).",
	},
	"object.fence_horizontal": {
		"debug_name": "Fence",
		"collision_type": COLLISION_LINE,
		"collision_anchor": "sprite_bottom_center",
		"collision_precision": "asset_line_from_alpha",
		"collision_source": "object.fence_horizontal alpha-mask review (16x16 source, x2 render)",
		"collision_shapes": [
			{
				"type": COLLISION_LINE,
				"label": "rail_strip",
				"from": Vector2(-16, -12),
				"to": Vector2(16, -12),
				"thickness": 8.0,
			},
		],
		"interaction_enabled": false,
		"minimap_visible": true,
		"minimap_kind": MINIMAP_FENCE_LINE,
		"minimap_color": "#9d6b42",
		"minimap_shape": "tiles",
		"minimap_priority": 45,
		"notes": "Blocks along the fence line (FENCE_START_TILE..+FENCE_LENGTH).",
	},
	"object.crate": {
		"debug_name": "Crate (decor)",
		"collision_type": COLLISION_NONE,
		"interaction_enabled": false,
		"minimap_visible": false,
		"notes": "Visual-only prop (apple crate). Intentionally not solid.",
	},
	"object.sign": {
		"debug_name": "Sign",
		"collision_type": COLLISION_NONE,
		"interaction_enabled": true,
		"interaction_label": "view",
		"interaction_point_offset": Vector2(0, -6),
		"minimap_visible": true,
		"minimap_kind": MINIMAP_SIGN_DOT,
		"minimap_color": "#e8c060",
		"minimap_shape": "dot",
		"minimap_priority": 70,
		"minimap_label": "Sign",
		"notes": "Interactable at the sign face; not a physical blocker.",
	},
	"animal.cow": {
		"debug_name": "Cow",
		"collision_type": COLLISION_NONE,
		"interaction_enabled": false,
		"minimap_visible": false,
		"notes": "Ambient animal. Must NOT trap the player, so no collider.",
	},
	"animal.chicken": {
		"debug_name": "Chicken",
		"collision_type": COLLISION_NONE,
		"interaction_enabled": false,
		"minimap_visible": false,
		"notes": "Ambient animal; non-blocking.",
	},
	"object.flower": {
		"debug_name": "Flowers",
		"collision_type": COLLISION_NONE,
		"minimap_visible": false,
		"notes": "Decoration; never blocks.",
	},
	"placed_object": {
		"debug_name": "Player Placed Object",
		"collision_type": COLLISION_NONE,
		"minimap_visible": true,
		"minimap_kind": MINIMAP_PLACED_OBJECT_DOT,
		"minimap_color": "#d9c27a",
		"minimap_shape": "dot",
		"minimap_priority": 75,
		"minimap_label": "Placed",
		"notes": "Generic minimap dot for visible player-placed content. Actual build/collision remains owned by BuildingPlacementSystem.",
	},
	"terrain.grass": {"debug_name": "Grass", "collision_type": COLLISION_NONE, "notes": "Ground; never blocks."},
	"terrain.dirt_path": {
		"debug_name": "Path",
		"collision_type": COLLISION_NONE,
		"minimap_visible": true,
		"minimap_kind": MINIMAP_PATH_SHAPE,
		"minimap_color": "#c39b62",
		"minimap_shape": "tiles",
		"minimap_priority": 35,
		"notes": "Ground; never blocks.",
	},
	"terrain.tilled_soil": {
		"debug_name": "Tilled Soil",
		"collision_type": COLLISION_NONE,
		"interaction_enabled": true,
		"interaction_label": "tend plot",
		"minimap_visible": true,
		"minimap_kind": MINIMAP_FARM_PATCH,
		"minimap_color": "#6b4a2e",
		"minimap_shape": "rect",
		"minimap_priority": 60,
		"minimap_label": "Farm",
		"minimap_footprint": Rect2i(2, 12, 3, 3),
		"notes": "Farm patch. Walkable; interactable for planting/tending. Crops render above soil.",
	},
	"crop.carrot": {"debug_name": "Carrot Crop", "collision_type": COLLISION_NONE, "notes": "Crops never hard-block."},
	"crop.cauliflower": {"debug_name": "Cauliflower Crop", "collision_type": COLLISION_NONE, "notes": "Crops never hard-block."},
	"crop.watermelon": {"debug_name": "Watermelon Crop", "collision_type": COLLISION_NONE, "notes": "Crops never hard-block."},
	"npc": {
		"debug_name": "NPC",
		"collision_type": COLLISION_CIRCLE,
		"collision_radius": 7.0,
		"collision_offset": Vector2(0, -8),
		"collision_anchor": "sprite_bottom_center",
		"collision_precision": "compact_body_soft",
		"collision_shapes": [
			{"type": COLLISION_CIRCLE, "label": "npc_body", "offset": Vector2(0, -8), "radius": 7.0},
		],
		"interaction_enabled": true,
		"interaction_label": "talk",
		"minimap_visible": true,
		"minimap_kind": MINIMAP_NPC_DOT,
		"minimap_color": "#9fc4e8",
		"minimap_shape": "dot",
		"minimap_priority": 90,
		"minimap_label": "NPC",
		"notes": "Compact feet/body collider so NPCs feel physically present. Small (r7) + at open spots so it never traps; interaction reach (78px) is far larger, so talking still works. Set body_collision_enabled=false on a villager for a debug ghost.",
	},
}

static func has(asset_id: String) -> bool:
	return DATA.has(asset_id)

static func meta_for(asset_id: String) -> Dictionary:
	var merged := _DEFAULT.duplicate(true)
	if DATA.has(asset_id):
		var entry: Dictionary = DATA[asset_id]
		for key in entry.keys():
			merged[key] = entry[key]
	return merged

## Maps a BUILDABLE placeable content id (ContentIds.PLACEABLE_* values) to the world-asset
## metadata id that governs its collision/interaction/minimap. Unmapped placeables fall back
## to BuildingPlacementSystem's generic placement proxy (conservative blocking box). Keys are
## the content-id strings so this file stays free of a ContentIds dependency.
const PLACEABLE_TO_ASSET := {
	"crate": "object.crate",            # decor, non-blocking
	"berry_basket": "object.crate",
	"wood_pile": "object.crate",
	"signpost": "object.sign",          # interactable, non-blocking
	"fence_segment": "object.fence_horizontal",  # blocking rail line
	"fence_corner": "object.fence_horizontal",
	"barn_shell": "object.barn",        # building polygons
	"dirt_path": "terrain.dirt_path",   # walkable ground, non-blocking
	"floor_deck": "terrain.dirt_path",
	"flower_bed": "object.flower",      # decor, non-blocking
	"decor_shrub": "object.tree_small", # visual-only
}

## Asset metadata id for a placeable content id, or "" when none is mapped (use the proxy).
static func asset_id_for_placeable(content_id: String) -> String:
	return String(PLACEABLE_TO_ASSET.get(content_id, ""))

# --- Collision helpers ------------------------------------------------------------------
static func collision_type(asset_id: String) -> String:
	return String(meta_for(asset_id).get("collision_type", COLLISION_NONE))

static func is_blocking(asset_id: String) -> bool:
	return collision_type(asset_id) != COLLISION_NONE

static func trunk_radius(asset_id: String) -> float:
	return float(meta_for(asset_id).get("collision_radius", 0.0))

static func trunk_offset(asset_id: String) -> Vector2:
	return meta_for(asset_id).get("collision_offset", Vector2.ZERO)

static func barn_collision_rect() -> Rect2i:
	return collision_tile_proxy("object.barn")

static func collision_anchor(asset_id: String) -> String:
	return String(meta_for(asset_id).get("collision_anchor", "sprite_bottom_center"))

static func collision_shapes(asset_id: String) -> Array:
	return (meta_for(asset_id).get("collision_shapes", []) as Array).duplicate(true)

static func collision_rect(asset_id: String) -> Rect2i:
	return meta_for(asset_id).get("collision_rect", Rect2i()) as Rect2i

static func collision_tile_proxy(asset_id: String) -> Rect2i:
	var proxy: Rect2i = meta_for(asset_id).get("collision_tile_proxy", Rect2i()) as Rect2i
	if proxy.size.x > 0 and proxy.size.y > 0:
		return proxy
	return meta_for(asset_id).get("collision_rect", Rect2i()) as Rect2i

static func collision_precision(asset_id: String) -> String:
	return String(meta_for(asset_id).get("collision_precision", "visual_only"))

static func collision_source(asset_id: String) -> String:
	return String(meta_for(asset_id).get("collision_source", ""))

static func has_asset_collision_shapes(asset_id: String) -> bool:
	return is_blocking(asset_id) and not collision_shapes(asset_id).is_empty()

# --- Minimap helpers --------------------------------------------------------------------
static func minimap_visible(asset_id: String) -> bool:
	return bool(meta_for(asset_id).get("minimap_visible", false))

static func minimap_kind(asset_id: String) -> String:
	return String(meta_for(asset_id).get("minimap_kind", MINIMAP_NONE))

static func minimap_color(asset_id: String) -> Color:
	return Color(String(meta_for(asset_id).get("minimap_color", "#ffffff")))

static func minimap_shape(asset_id: String) -> String:
	return String(meta_for(asset_id).get("minimap_shape", "dot"))

static func minimap_priority(asset_id: String) -> int:
	return int(meta_for(asset_id).get("minimap_priority", 0))

static func minimap_style_id(asset_id: String) -> String:
	return String(meta_for(asset_id).get("minimap_style_id", ""))

static func minimap_label(asset_id: String) -> String:
	return String(meta_for(asset_id).get("minimap_label", ""))

static func minimap_footprint(asset_id: String) -> Rect2i:
	return meta_for(asset_id).get("minimap_footprint", Rect2i())

# --- Interaction helpers ----------------------------------------------------------------
static func interaction_enabled(asset_id: String) -> bool:
	return bool(meta_for(asset_id).get("interaction_enabled", false))

static func interaction_label(asset_id: String) -> String:
	return String(meta_for(asset_id).get("interaction_label", ""))

static func interaction_point_offset(asset_id: String) -> Vector2:
	return meta_for(asset_id).get("interaction_point_offset", Vector2.ZERO)

## Ids that should appear on the live minimap (used by validation + the minimap builder).
static func minimap_visible_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in DATA.keys():
		if minimap_visible(String(key)):
			ids.append(String(key))
	ids.sort()
	return ids
