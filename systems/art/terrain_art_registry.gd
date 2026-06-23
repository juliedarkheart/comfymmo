extends RefCounted
class_name TerrainArtRegistry

## Centralized lookup for terrain and biome art. Map/rendering code asks here
## first, then keeps its existing polygon fallback if a sprite cannot load.

const FALLBACK_PATH := "res://art/placeholders/missing.png"
const TILE_SIZE := Vector2i(64, 48)

## Activated external derivatives live under this root, but are only used when
## ALSO listed in art/active_art_manifest.json (see ArtActivation). A derivative
## just sitting in the folder is NOT used until activated — this is what prevents
## blind full-pack replacement. Order: activated external -> generated -> missing.
const EXTERNAL_ACTIVE_ROOT := "res://art/generated/from_external/active/"

## Original, committable Hearthvale top-down tiles (generate_hearthvale_gap_assets.py).
## In sprout-compatible modes these are preferred over the legacy 64x48 isometric
## diamond art, so a clean checkout (no Sprout pack) still reads as a top-down world.
const HEARTHVALE_TOPDOWN_ROOT := "res://art/generated/hearthvale/terrain/"
const LEGACY_TILE_ROOT := "res://art/tiles/"

## Resolve a mapped art path through the preference order. Always returns a path
## that exists (falls back to the obvious-but-safe missing placeholder). Used for
## transitions; terrain ids go through texture_path (which also prefers top-down).
static func resolve_path(mapped_path: String, projection_mode: String = WorldProjection.DEFAULT_MODE, force_allow_sprout: bool = false) -> String:
	var allow_licensed: bool = WorldProjection.is_sprout_compatible(projection_mode) \
		and (force_allow_sprout or LiveVisualPolicy.should_auto_use_sprout_visuals())
	var override_path: String = ArtActivation.override_for(mapped_path, allow_licensed)
	if not override_path.is_empty():
		return override_path
	if FileAccess.file_exists(mapped_path):
		return mapped_path
	return FALLBACK_PATH

static func _hearthvale_topdown_path(terrain_id: String, projection_mode: String) -> String:
	if not WorldProjection.is_sprout_compatible(projection_mode):
		return ""
	var candidate: String = HEARTHVALE_TOPDOWN_ROOT + normalize_id(terrain_id) + ".png"
	return candidate if FileAccess.file_exists(candidate) else ""

## Where a resolved path came from: "licensed", "licensed_modified", "external",
## "generated", "missing".
static func source_of(resolved_path: String) -> String:
	if resolved_path == FALLBACK_PATH:
		return "missing"
	if resolved_path.begins_with("res://licensed_assets/"):
		return "licensed_modified" if resolved_path.contains("/modified/") else "licensed"
	if resolved_path.begins_with(EXTERNAL_ACTIVE_ROOT):
		return "external"
	return "generated"

const REQUIRED_IDS: Array[String] = [
	"meadow",
	"forest",
	"orchard",
	"creekside",
	"riverbank",
	"hilltop",
	"grove",
	"town",
	"farmland",
	"farmer_training",
	"dirt_path",
	"stone_path",
	"tilled_soil",
	"water",
	"creek",
	"plot_boundary",
	"plot_corner",
]

const TERRAIN_PATHS := {
	"meadow": "res://art/tiles/biomes/meadow.png",
	"forest": "res://art/tiles/biomes/forest.png",
	"orchard": "res://art/tiles/biomes/orchard.png",
	"creekside": "res://art/tiles/biomes/creekside.png",
	"riverbank": "res://art/tiles/biomes/riverbank.png",
	"hilltop": "res://art/tiles/biomes/hilltop.png",
	"grove": "res://art/tiles/biomes/grove.png",
	"town": "res://art/tiles/biomes/town.png",
	"farmland": "res://art/tiles/biomes/farmland.png",
	"farmer_training": "res://art/tiles/biomes/farmer_training.png",
	"dirt_path": "res://art/tiles/paths/dirt_path.png",
	"stone_path": "res://art/tiles/paths/stone_path.png",
	"tilled_soil": "res://art/tiles/paths/tilled_soil.png",
	"water": "res://art/tiles/water/water.png",
	"creek": "res://art/tiles/water/creek.png",
	"plot_boundary": "res://art/tiles/paths/plot_boundary.png",
	"plot_corner": "res://art/tiles/paths/plot_corner.png",
}

const TRANSITION_PATHS := {
	"grass_to_path": "res://art/tiles/terrain/grass_to_path.png",
	"grass_to_water": "res://art/tiles/terrain/grass_to_water.png",
	"grass_to_farmland": "res://art/tiles/terrain/grass_to_farmland.png",
	"biome_soft_edge": "res://art/tiles/terrain/biome_soft_edge.png",
	"path_edge": "res://art/tiles/terrain/path_edge.png",
	"water_edge": "res://art/tiles/terrain/water_edge.png",
}

static func required_ids() -> Array[String]:
	return REQUIRED_IDS.duplicate()

static func normalize_id(terrain_id: String) -> String:
	return String(terrain_id).strip_edges().to_lower()

static func texture_path(terrain_id: String, projection_mode: String = WorldProjection.DEFAULT_MODE, force_allow_sprout: bool = false) -> String:
	var nid: String = normalize_id(terrain_id)
	var mapped: String = String(TERRAIN_PATHS.get(nid, FALLBACK_PATH))
	# 1. Licensed (Sprout) / licensed_modified override — only in sprout-compatible modes.
	var allow_licensed: bool = WorldProjection.is_sprout_compatible(projection_mode) \
		and (force_allow_sprout or LiveVisualPolicy.should_auto_use_sprout_visuals())
	var override_path: String = ArtActivation.override_for(mapped, allow_licensed)
	if not override_path.is_empty():
		return override_path
	# 2. Original Hearthvale top-down generated tile (preferred over legacy iso art).
	var topdown: String = _hearthvale_topdown_path(nid, projection_mode)
	if not topdown.is_empty():
		return topdown
	# 3. Legacy generated diamond art, then 4. missing placeholder.
	if FileAccess.file_exists(mapped):
		return mapped
	return FALLBACK_PATH

static func texture(terrain_id: String, projection_mode: String = WorldProjection.DEFAULT_MODE, force_allow_sprout: bool = false) -> Texture2D:
	return load(texture_path(terrain_id, projection_mode, force_allow_sprout)) as Texture2D

static func variation_index(terrain_id: String, tile: Vector2i) -> int:
	var hash_value: int = hash("%s:%d:%d" % [normalize_id(terrain_id), tile.x, tile.y])
	return absi(hash_value) % 4

static func visual_for(terrain_id: String, tile: Vector2i = Vector2i.ZERO, projection_mode: String = WorldProjection.DEFAULT_MODE, force_allow_sprout: bool = false) -> Dictionary:
	var normalized_id: String = normalize_id(terrain_id)
	var path: String = texture_path(normalized_id, projection_mode, force_allow_sprout)
	var projection: Dictionary = WorldProjection.visual_hints(projection_mode)
	var source: String = source_of(path)
	return {
		"id": normalized_id,
		"path": path,
		"texture": load(path) as Texture2D,
		"fallback": path == FALLBACK_PATH,
		"source": source,
		# Only the LEGACY 64x48 isometric diamond art (res://art/tiles/...) is
		# suppressed in the Sprout/top-down projection (the map draws a flat color
		# square for it instead). Licensed Sprout tiles AND the original Hearthvale
		# top-down generated tiles (res://art/generated/hearthvale/...) are real
		# square top-down tiles, so they DO render as sprites.
		"render_sprite": not (bool(projection.get("sprout_compatible", false)) and source == "generated" and path.begins_with(LEGACY_TILE_ROOT)),
		"variation": variation_index(normalized_id, tile),
		"tile_size": projection.get("sprite_canvas_size", TILE_SIZE),
		"projection": projection,
	}

static func make_tile_sprite(terrain_id: String, tile: Vector2i = Vector2i.ZERO, projection_mode: String = WorldProjection.DEFAULT_MODE) -> Sprite2D:
	var visual: Dictionary = visual_for(terrain_id, tile, projection_mode)
	var tex: Texture2D = visual.get("texture", null) as Texture2D
	if tex == null or not bool(visual.get("render_sprite", true)):
		return null
	var sprite := Sprite2D.new()
	sprite.name = "TerrainArt_%s" % String(visual.get("id", "unknown"))
	sprite.texture = tex
	sprite.centered = true
	sprite.scale = (visual.get("projection", {}) as Dictionary).get("sprite_scale", Vector2.ONE) as Vector2
	sprite.z_index = -1
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return sprite

static func transition_path(transition_id: String) -> String:
	return resolve_path(String(TRANSITION_PATHS.get(normalize_id(transition_id), FALLBACK_PATH)))

static func transition_visual(from_id: String, to_id: String) -> Dictionary:
	var from_normalized: String = normalize_id(from_id)
	var to_normalized: String = normalize_id(to_id)
	var transition_id := "biome_soft_edge"
	if _is_path(from_normalized) or _is_path(to_normalized):
		transition_id = "grass_to_path"
	if from_normalized == "water" or to_normalized == "water" or from_normalized == "creek" or to_normalized == "creek":
		transition_id = "grass_to_water"
	if from_normalized == "farmland" or to_normalized == "farmland" or from_normalized == "tilled_soil" or to_normalized == "tilled_soil":
		transition_id = "grass_to_farmland"
	var path: String = transition_path(transition_id)
	return {
		"id": transition_id,
		"from": from_normalized,
		"to": to_normalized,
		"path": path,
		"texture": load(path) as Texture2D,
		"fallback": path == FALLBACK_PATH,
	}

static func _is_path(terrain_id: String) -> bool:
	return terrain_id == "dirt_path" or terrain_id == "stone_path"
