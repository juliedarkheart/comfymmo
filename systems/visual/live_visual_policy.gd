extends RefCounted
class_name LiveVisualPolicy

## Sprout-first presentation guardrails for normal gameplay. Gameplay/data systems
## still own the logical grid; this file only states how the live screen should be
## composed so old prototype visuals stay quarantined.

## The live visual build is Sprout-required: a clean checkout without the licensed
## Sprout pack is not a playable visual target. When Sprout is missing the game shows
## a missing-assets screen rather than the old generated/procedural fallback. The
## actual installed/active check + the boot gate live in SproutAssetRequirement and
## WorldRegionManager; this flag is the single discoverable source of the policy.
const SPROUT_REQUIRED_FOR_LIVE := true

## Curated demo slice: normal play opens in a small, hand-composed cozy homestead
## area instead of the full procedural overworld. The gameplay/data world is intact
## (plots, NPCs, resources still exist and are walkable), but the broad/ugly visual
## layers (wilderness scatter, connecting roads to far regions, etc.) are suppressed
## in the OPENING view and the camera frames the curated core. Toggle this off to
## return to rendering the whole overworld. See OverworldMap._build_curated_slice().
const CURATED_SLICE := true

## Opening-camera zoom for the curated slice — tighter than the wide overworld view
## so the first screenshot frames the composed homestead, not far empty map.
const CURATED_SLICE_ZOOM := 1.7
const OVERWORLD_WIDE_ZOOM := 1.3

## LimeZu is now the PRIMARY live visual direction (ArtProviderRegistry.LIVE_PROVIDER).
## The live curated opening slice composes LimeZu Modern Farm art over the existing
## gameplay grid (colliders/placement/data unchanged), the UI re-skins to Modern UI,
## and live human actors use the LimeZu farmer sprite. Sprout stays integrated as a
## comparison/fallback provider. LimeZu art is 16px, drawn at x2 to fill the 32px grid.
const LIMEZU_DISPLAY_SCALE := 2.0

## True when the live game should render the LimeZu curated slice: provider is LimeZu
## AND the local LimeZu assets actually resolve. If LimeZu is selected but absent, the
## boot gate shows a missing-assets screen instead (see WorldRegionManager).
static func live_limezu_slice() -> bool:
	return ArtProviderRegistry.LIVE_PROVIDER == ArtProviderRegistry.PROVIDER_LIMEZU \
		and LimeZuArtRegistry.is_available()

## True when LimeZu is the selected live provider (regardless of local availability).
static func limezu_is_live_provider() -> bool:
	return ArtProviderRegistry.LIVE_PROVIDER == ArtProviderRegistry.PROVIDER_LIMEZU

const PRIMARY_PROJECTION := WorldProjection.MODE_SPROUT_TOPDOWN
const TILE_SIZE := Vector2i(32, 32)
const ACTOR_CANVAS_SIZE := Vector2i(96, 96)
const OBJECT_CANVAS_SIZE := Vector2i(96, 96)
const NORMAL_HUD_MAX_WIDTH := 340
const NORMAL_HUD_MAX_HEIGHT := 190
const NORMAL_SCENERY_DENSITY := 0.35

static func should_draw_broad_procedural_scenery() -> bool:
	return false

static func should_draw_procedural_actor_fallbacks() -> bool:
	return false

static func normal_hud_is_compact(size: Vector2) -> bool:
	return size.x <= NORMAL_HUD_MAX_WIDTH and size.y <= NORMAL_HUD_MAX_HEIGHT

static func terrain_for_plot_ground(biome_id: String, rect: Rect2i, tile: Vector2i) -> String:
	var normalized := String(biome_id).strip_edges().to_lower()
	if normalized == "farmland":
		var center := rect.position + Vector2i(rect.size.x / 2, rect.size.y / 2)
		var field := Rect2i(center - Vector2i(2, 2), Vector2i(4, 4))
		return "tilled_soil" if field.has_point(tile) else "meadow"
	if normalized == "town":
		return "stone_path" if tile.x == rect.position.x + rect.size.x / 2 else "meadow"
	return "meadow"
