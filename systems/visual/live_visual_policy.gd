extends RefCounted
class_name LiveVisualPolicy

## Live visual presentation guardrails for normal gameplay. Gameplay/data systems
## still own the logical grid; this file only states how the live screen should be
## composed so old prototype visuals stay quarantined.

## Sprout is optional/reference-only. A clean checkout, missing Sprout pack, or
## corrupted local Sprout manifest must still boot the playable overworld through
## LimeZu if ready, then generated/procedural fallbacks. Sprout readiness is still
## reported for diagnostics, but it is never a runtime boot gate.
const SPROUT_REQUIRED_FOR_LIVE := false

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
## Interaction reach calibrated for the 32px top-down grid and x2 LimeZu sprites.
## The old 54px reach was precise enough for legacy markers but too fussy around
## visible LimeZu crops, signs, and tall/bottom-anchored props.
const INTERACTION_RADIUS := 78.0

## True when the live game should render the LimeZu curated slice: provider is LimeZu
## AND local LimeZu assets are at least partially usable. Full normalized live slices
## are ideal, but existing derivative/inspired/generated outputs or read-only raw
## extracted pack files are good enough to keep the current visual direction active.
## Only fall to committed generated/procedural art when LimeZu is genuinely absent.
static func live_limezu_slice() -> bool:
	return ArtProviderRegistry.LIVE_PROVIDER == ArtProviderRegistry.PROVIDER_LIMEZU \
		and LimeZuArtRegistry.is_usable_for_live()

## True when LimeZu is the selected live provider (regardless of local availability).
static func limezu_is_live_provider() -> bool:
	return ArtProviderRegistry.LIVE_PROVIDER == ArtProviderRegistry.PROVIDER_LIMEZU

## Sprout is manual/reference-only unless the live provider is explicitly switched
## to Sprout. The LimeZu live path must never auto-mix Sprout just because local
## Sprout manifests exist.
static func should_auto_use_sprout_visuals() -> bool:
	return ArtProviderRegistry.LIVE_PROVIDER == ArtProviderRegistry.PROVIDER_SPROUT

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

## ----------------------------------------------------------------------------
## STRICT LIVE VISUAL ALLOWLIST (Task 2 of the visual-quarantine pass).
## In normal LimeZu live mode only LimeZu-family source tiers may be visible. Old
## legacy/procedural/Sprout art is quarantined to clean-checkout emergency fallback
## or explicit debug mode. Validation (tools/validate_project.gd) and the live audit
## (tools/audit_live_visuals.gd) consult these so old placeholders cannot silently
## creep back into the opening view. Tier strings match VisualSourceReport.classify_texture.
## ----------------------------------------------------------------------------
const LIVE_ALLOWED_SOURCE_TIERS: Array[String] = [
	"limezu_reviewed",      # active manifest / normalized LimeZu UI
	"limezu_raw",           # hand-reviewed raw LimeZu single-file crops (RAW_PACK_FALLBACKS)
	"limezu_derivative",    # licensed-pixel derivative generator outputs
	"limezu_inspired",      # Hearthvale LimeZu-style original generator outputs
	"limezu_generated_local",  # LimeZu-style locally generated, tagged as such
]
## Hard-disallowed in normal LimeZu live mode. Visible occurrence => validation fails.
const LIVE_DISALLOWED_SOURCE_TIERS: Array[String] = [
	"legacy_generated", "procedural", "sprout", "blank", "missing", "unknown",
]
## The ONE documented procedural exception: farm plot / crop polygons that FarmPlot
## draws live until a reviewed LimeZu farm-plot asset replaces them. Validation reports
## these as an explicit deferral (a bounded Polygon2D budget) rather than a hard failure.
const PROCEDURAL_FARM_DEFERRAL := true

## True when a classified source tier may appear in the normal LimeZu live opening.
static func is_allowed_live_tier(tier: String) -> bool:
	return LIVE_ALLOWED_SOURCE_TIERS.has(String(tier).strip_edges())

## True when a tier must never appear in the normal LimeZu live opening.
static func is_disallowed_live_tier(tier: String) -> bool:
	return LIVE_DISALLOWED_SOURCE_TIERS.has(String(tier).strip_edges())

static func terrain_for_plot_ground(biome_id: String, rect: Rect2i, tile: Vector2i) -> String:
	var normalized := String(biome_id).strip_edges().to_lower()
	if normalized == "farmland":
		var center := rect.position + Vector2i(rect.size.x / 2, rect.size.y / 2)
		var field := Rect2i(center - Vector2i(2, 2), Vector2i(4, 4))
		return "tilled_soil" if field.has_point(tile) else "meadow"
	if normalized == "town":
		return "stone_path" if tile.x == rect.position.x + rect.size.x / 2 else "meadow"
	return "meadow"
