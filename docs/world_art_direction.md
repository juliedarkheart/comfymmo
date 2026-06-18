# Hearthvale World Art Direction

The world should read as a warm storybook village laid out in readable
Sprout-compatible top-down / gentle 3/4 space. The older 64x32 isometric diamond
view remains a legacy fallback. The player should be able to understand paths,
plots, public areas, wilderness, and biome changes at a glance.

## Collision vs. visual footprints (LimeZu homestead)

Collision is keyed to **ground footprints**, not full sprite bounds: tall bottom-anchored
props (barn, apple trees) block at their base/trunk, not their canopy/roof airspace, so the
player can walk "in front of/behind" the tall art. Solid = barn + homestead trees (trunk) +
fence; visual-only = edge trees, flowers, grass, path, soil, crops, crate; signs/NPCs/farm
are interactable but not solid. The full contract + the F7 "Show Collision" debug overlay are
in `docs/playtest_readiness.md`.

## UI art direction (LimeZu Modern UI, cozy-survival inspired)

The live UI uses the LimeZu **Modern UI** kit as real 9-patch frames — a Stardew /
Minecraft / cozy-survival **inspired** layout (bottom hotbar, grid inventory, framed
panels/dialogue/tooltips/tabs), never copied art or layouts. Panels are light-tan
parchment with dark-ink text and wood frames; slots and buttons are the reviewed Modern
UI frames at native-compatible scale (sliced x2 with measured margins, NEAREST, no
stretching). Approved flat tan fills are interior fallbacks only. Default window is
1280x720. The contract + slicing live in `ui/limezu_ui_theme.gd` and
`tools/art/limezu_slice_spike_assets.py`; see `docs/ui_style_guide.md`.

**Characters/portraits** come from the LimeZu **Farmer/Character generators** (GUI tools).
Generated sheets/portraits are local licensed/derived art (gitignored
`licensed_assets/limezu/generator_outputs/`) cataloged by `tools/art/limezu_generator_catalog.py`
into a local manifest and resolved by `GeneratorCharacterRegistry` with a clean null
fallback. Never commit generator executables, outputs, or manifests. See
`docs/limezu_generator_workflow.md`.

## Sprout secondary-provider policy

Sprout remains integrated as a secondary/comparison provider, and its local licensed
files still stay gitignored under `licensed_assets/`. This branch's current live
playtest target is LimeZu, not the older Sprout-required opening. A clean checkout
without required local licensed assets should show a clear missing-assets screen
rather than silently falling back to generated/procedural art:

- When Sprout is missing/inactive the game shows a clear missing-assets screen
  (`ui/missing_assets_screen.gd`) instead of mounting the overworld — it does
  **not** silently render the generated/procedural fallback as the live look.
- The boot gate lives in `systems/world_region_manager.gd`; the installed/active
  check lives in `systems/visual/sprout_asset_requirement.gd`; the policy flag is
  `LiveVisualPolicy.SPROUT_REQUIRED_FOR_LIVE`.
- The original Hearthvale generated art that still ships in the repo is a
  **temporary diagnostic/dev fallback**, not the intended live style. Prefer a
  missing-assets report over shipping ugly fallback as the live game.

## Curated demo slice (opening view)

The full overworld is too ambitious for the current art state, so normal play opens
in a small, **hand-composed demo slice** instead of framing the broad procedural map:

- The opening camera frames a curated homestead (`LiveVisualPolicy.CURATED_SLICE`,
  zoom 1.7): cottage focal point + a Sprout well + a small tilled garden bed + flower
  beds + framing trees/bushes (`OverworldMap._build_curated_slice`). Sprout sprites
  only; the additions are decor (no collision).
- Broad/ugly layers are **suppressed** in normal play: the long connecting road to
  the far regions and the wilderness scatter are not drawn, and the dirt path is a
  tidy 2-tile lane (not a 3-tile band). No giant fields, biome blocks, or empty flat
  areas should sit in the opening camera view.
- **The rest of the overworld visual polish is deferred.** The gameplay/data world
  (plots, NPCs, resources, claiming) is intact and still walkable — only the broad
  *visual* layers are held back until they have art. Turn `CURATED_SLICE` off to
  render the whole overworld again.

## LimeZu ecosystem (now the live visual direction)

LimeZu's "Modern" ecosystem is now the **primary live visual direction**
(`ArtProviderRegistry.LIVE_PROVIDER == "limezu"`). The live overworld opens into a
curated LimeZu Modern Farm slice — `OverworldMap._build_limezu_slice()` composes
LimeZu grass, a barn focal point, apple trees, a tilled garden + crops, fences,
flowers, a cow + chicken, and props over the **unchanged gameplay grid** (placement,
colliders, spawn, farming data, movement are all preserved; LimeZu art is drawn at x2
to fill the 32px cells). Live human actors (player + NPCs) use the LimeZu farmer
sprite. **Sprout remains fully integrated as a secondary/comparison provider** and is
not removed. LimeZu local licensed assets are **required** for the live visual
prototype (a missing pack shows a clear missing-assets screen, not ugly fallback).

Live polish note: the LimeZu opening hides the old farm-plot soil/highlight
polygons plus the old rest-marker doormat diamond, and suppresses the generated
homestead rabbit/turtle spawns so the default screenshot does not mix generated
woodland creatures with the LimeZu farm set. The old-visual cleanup also replaces
the uniform opaque dirt-road tile with a reviewed transparent Modern Exteriors dirt
patch, hides optional old cottage/map signs from the opening, and routes visible
plot/service signs through a LimeZu sign sprite or hides their visual safely. Those
creature classes, rest interaction, farming data, sign interactions, placement, and
movement remain intact for future art coverage.

Layering rule: LimeZu terrain is always ground. Grass, dirt/path, tilled soil, and
water are drawn on the non-y-sorted terrain layer below the y-sorted gameplay layer.
Buildings, props, crops, signs, animals, NPCs, and the player render above it. The
curated opening uses visual footprint exclusions for the barn, signs, crate/props,
and trees so dirt/path/soil cells are skipped before they can bleed into object art.
Any broader LimeZu map expansion must preserve this rule: if a terrain cell conflicts
with a building/object footprint, hide the terrain cell rather than drawing it over
the object.

Source-purity rule (hard): in LimeZu live mode, every visible asset in the default
opening view must be a resolved LimeZu asset, a deliberate disabled/blocked UI fallback,
or hidden/deferred. **No Sprout, old generated, old procedural, old
placeholder, or legacy debug visuals are allowed in the opening.** Concretely, the
LimeZu opening suppresses: the Sprout neighborhood plot grounds + per-plot biome
grounds (`_build_neighborhood_ground`, `paint_plot_ground`), the generated
dirt/stone neighborhood access roads (the old "broken road"), the village/forest
generated decor, the procedural plot-skirt decor + wardrobe mirror, and re-skins
gather/resource nodes to LimeZu sprites. The road/path uses the LimeZu `terrain.dirt_path`
tile (a short, footprint-blocked lane) — never a ColorRect/Polygon2D/old-generated
slab; if no good tile exists it is hidden. Trees/props resolve through `LimeZuArtRegistry`
or are hidden. `VisualSourceReport.live_opening_sources()` audits this and validation
hard-fails on any `sprout`/`legacy` sprite in the LimeZu opening.

UI scaling rule: the Modern UI source slices are the live UI source. They are small
and non-square, so panel and control layouts should be compact enough to fit the
assets. Live LimeZu HUD cards, minimap, toolbelt, inventory, menus, slots, buttons,
close buttons, and tabs use reviewed Modern UI texture slices. If a surface looks
wrong, simplify or resize the surface first; a flat fallback is only for missing art
or deliberately muted blocked/unavailable states.

Collision/interaction rule: gameplay footprints must match the visible LimeZu art.
The live barn uses an explicit LimeZu footprint collider and blocked-tile rect; trees
and fences keep aligned blockers; decorative ground/flowers stay visual-only. The
visible garden bed is wired to the existing farm plot interactions, and LimeZu mode
uses a slightly wider interaction radius so prompts line up with 32px top-down art
instead of the old hidden cottage/farm positions.

Small playable-area expansion: the live LimeZu treatment now has a named bounded
homestead area (`OverworldMap.LIMEZU_PLAYABLE_AREA_BOUNDS`) around spawn, the barn,
garden, immediate east/south walking space, and a small approach toward the wider
world. This is deliberately not a full overworld makeover and does not broaden the
opening camera. The area uses LimeZu grass, sparse LimeZu trees/flowers/fence/crate
clusters, and a short ground-layer path approach; old Sprout/generated/legacy ground
and props remain forbidden in this immediate playable area. Old procedural plot
boundary lines/posts are suppressed in LimeZu live mode while marker data and
interactions stay intact. Broader village, forest, creature-family, dungeon, and
adventure-plot art coverage remains deferred.

Coverage findings (honest): strong for farming/building/interiors/office/UI; still
weak for cozy dungeon tilesets and tameable-companion creatures beyond the curated
opening. Full report: docs/limezu_visual_spike.md; pivot details:
docs/limezu_live_pivot_plan.md.

## Composition

- Important paths should lead the eye between homestead, neighborhood, town, and
  forest landmarks.
- Landmarks should have strong silhouettes and a distinct color accent.
- Public roads should look authored and cozy, not like debug corridors.
- Normal gameplay should not show harsh grey construction, measurement lines, or
  broad rectangular/region-tint debug blocks.
- Admin overlays can be clearer and more technical, but they should remain off
  by default.

## Biome Readability

Required active biomes:

- meadow: bright safe green, flowers, open homestead language.
- forest: darker green, denser trees, deeper shade.
- orchard: productive green, fruit/tree language.
- creekside: cooler green-blue ground, ponds/creek cues.
- hilltop: lighter grass, rocks, height-adjacent cues without sculpting.
- grove: forest-like but friendlier and homestead-ready.
- town: structured public space, stone/dirt paths, plaza accents.
- farmland: tilled soil, crop rows, training farm cues.

Biome ids should be reflected in:

- ground color
- plot decor
- resources where supported
- minimap tint
- HUD/area label

## Terrain And Path Palette

The central color helpers live in `systems/world/biome_registry.gd`:

- `ground_color(id)` for biome ground.
- `minimap_tint(id)` for map readout.
- `terrain_color(id)` for biome paint plus dirt path, stone path, tilled soil,
  water, road, and plot boundary.
- `terrain_detail_color(id)` for edge/highlight details.

Worldbuilder terrain paint should use these same helpers so admin-authored
tiles match authored terrain.

## Terrain Art Registry

Game-facing terrain art paths are centralized in
`systems/art/terrain_art_registry.gd`. The registry maps meadow, forest,
orchard, creekside, riverbank, hilltop, grove, town, farmland,
farmer_training, dirt_path, stone_path, tilled_soil, water, creek,
plot_boundary, and plot_corner to PNG tiles under `art/tiles/`.

The map renderer keeps its existing polygon fallback under the sprites. Invalid
or missing terrain ids resolve to `art/placeholders/missing.png` instead of
crashing. Terrain painting/worldbuilder output should use the same registry
palette/assets as authored terrain.

First-pass transition assets live in `art/tiles/terrain/` for grass-to-path,
grass-to-water, grass-to-farmland, soft biome edges, path edges, and water
edges. They are extension points for a future autotiling pass, not a complete
neighbor solver yet.

## Projection Compatibility

The logical grid is separate from the visual projection. `WorldProjection`
supports the primary live `sprout_topdown` view plus legacy/fallback
`iso_64x32` and other top-down modes (`topdown_16`, `topdown_32`). Placement,
land ownership, minimap, terrain paint, and saves keep using logical tiles while
the renderer projects them as 32x32 top-down cells.

Player-facing systems follow the active projection too: the avatar moves straight
along screen axes in top-down mode (the iso skew is legacy-only), and the parcel
tool + world-builder overlay previews expand their footprints by half a tile in
top-down so they cover the visible cells rather than stopping at tile centers.

No-Sprout behavior is intentional, not boring-but-playable: with the pack absent
the live world refuses to mount and the missing-assets screen explains why (see
the Sprout-required visual policy above). The logical grid, worldbuilder, minimap,
and build tools still operate on the same tile positions when Sprout is present;
the generated fallback tiles exist only for diagnostics/dev, never as the shipped
live style.

### Terrain source split (Sprout / modified / Hearthvale generated)

In Sprout-compatible modes terrain resolves in this order — **licensed Sprout →
licensed_modified Sprout → original Hearthvale top-down generated → legacy iso →
missing**:

- **Licensed Sprout (local-only):** `meadow`, `orchard`, `grove`, `creekside`
  (Cup Nooble's pre-cut, descriptively-named grass cutout tiles), plus `water`
  and `creek`. Local-only, never committed.
- **licensed_modified Sprout (local-only):** `forest`, `hilltop`, `town` are
  recolor/tint variants derived from the licensed Sprout grass tile (allowed by
  the Sprout license, kept under the gitignored `licensed_assets/.../modified/`).
- **Original Hearthvale generated (committable):** every terrain id has an
  original top-down tile under `art/generated/hearthvale/terrain/` from
  `tools/art/generate_hearthvale_gap_assets.py`. These are the clean-checkout
  fallback and cover `farmland`, `tilled_soil`, `dirt_path`, `stone_path`,
  `riverbank`, `farmer_training`, `plot_boundary`, and `plot_corner` (paths read
  as paths, soil reads as soil, plot markers read as cozy posts — not debug
  lines). They are NOT derived from Sprout media and may be committed.

The original `art/tiles/` 64x48 isometric diamonds remain only as the legacy
`iso_64x32` fallback and are never rendered as sprites in the top-down view.

## Plot Presentation

Homestead plots should feel like yards, not giant biome swatches:

- shared meadow/grass base in normal play
- only small terrain accents for special cases, such as a tiny tilled patch on
  farmland or a narrow path accent in town plots
- soft plot boundary
- warm corner posts
- readable claim sign
- light biome decor outside the buildable rect

Plot boundaries must remain visible enough for playtesting, but they should not
look like combat zones, selection boxes, or permanent debug art.

## Label Readability

World-space labels should be sparse. Character nameplates use a smaller name
line, and role subtitles (`Villager`, `Mentor`, `Land Office`, `You`) are hidden
by default unless a future hover/selection/debug state deliberately opts in.
Plot labels should live on physical sign boards or panel/HUD context, not as
always-on floating text over every yard.

## Graphics polish pass

In the live Sprout/top-down renderer the map draws real 32x32 square tiles: a
licensed Sprout tile when present, otherwise the original Hearthvale top-down
generated tile (`art/generated/hearthvale/terrain/`). Only the legacy 64x48
isometric diamonds are suppressed in top-down mode. The map **skips the old
colored ground polygon whenever a tile sprite covers the cell** (the opaque fill
used to hide the sprites), and the broad background scenery (backdrop, region
tints, borders, connecting roads) sits on a `z = −10` layer beneath the tiles.
World decoration and structures (trees, bushes, rocks, flowers, mushrooms, pines,
the cottage, fences) render through `ObjectArtRegistry` as top-down sprites
(`art/generated/hearthvale/objects/`, or licensed Sprout) rather than procedural
polygons. Live player/NPC/creature bodies render through `CharacterArtRegistry`
as original top-down actor sprites under `art/generated/hearthvale/characters/`
and `art/generated/hearthvale/creatures/`; the old polygon character builder is
only a fallback. `systems/visual_source_report.gd` logs terrain/object/UI/actor
tiers on boot. Because the generated Hearthvale tiles carry their own texture,
the legacy iso decorative
highlight/patch overlays are skipped in Sprout-compatible mode (they would just
cover the tile art); they still draw in the legacy `iso_64x32` view. Plot ground,
terrain-paint overrides, road tiles, and the minimap continue to share
`TerrainArtRegistry`, `terrain_color`, and `minimap` tints, so painted/authored
terrain matches the world.

The Sprout-first live policy is centralized in
`systems/visual/live_visual_policy.gd`: primary scale is 32x32 terrain, generated
actor canvases render scaled down against that grid, broad procedural scenery is
off in normal play, and old market/fountain/border slabs stay deferred until
they have sprite replacements. Connecting roads/plazas render as tile sprites,
not broad ribbons.

## Terrain composition (screenshot cleanup)

The live world should read as a cozy farmed map, not a flat grid of one repeated
tile:

- **Meadow/grass is the base.** Plots are meadow-first with only small special-case
  accents (a tiny tilled patch on farmland, a narrow stone strip in town), never
  giant biome rectangles or flower-field slabs.
- **Break up flat grass with sparse detail.** `OverworldMap._scatter_core_detail()`
  sprinkles a light, deterministic layer of small Sprout flower patches + pebbles
  and a few generated grass tufts over the OPEN starting core (skipping paths, the
  town pad, the cottage, the spawn, and props). It is decor-only (no collision), in
  the ground layer under the player, and intentionally low-density so it reads as a
  tended yard rather than clutter.
- Prefer Sprout / modified-Sprout terrain and decor over generated art. Where only
  generated art exists, prefer clean, low-noise tiles over fake detail.

### Remaining terrain art tasks (deferred)

- Reviewed Sprout path/soil/edge tiles (dirt/stone path, tilled soil, biome edges)
  to replace the generated Hearthvale support tiles.
- Neighbor-aware edge/corner transitions (only a deterministic edge-hint scaffold
  exists today).
- A crisp single signpost sprite at native resolution (the current Sprout sign is a
  small source upscaled, so it is drawn small to stay tidy).
