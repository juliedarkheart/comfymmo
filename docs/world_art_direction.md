# Hearthvale World Art Direction

The world should read as a warm storybook village laid out in readable
Sprout-compatible top-down / gentle 3/4 space. The older 64x32 isometric diamond
view remains a legacy fallback. The player should be able to understand paths,
plots, public areas, wilderness, and biome changes at a glance.

## Composition

- Important paths should lead the eye between homestead, neighborhood, town, and
  forest landmarks.
- Landmarks should have strong silhouettes and a distinct color accent.
- Public roads should look authored and cozy, not like debug corridors.
- Normal gameplay should not show harsh grey construction or measurement lines.
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

Clean checkout behavior must stay boring: no Sprout pack means the generated
fallback renders and worldbuilder/minimap/build tools keep using the same logical
tile positions.

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

Homestead plots should feel like yards:

- biome-tinted ground patch
- soft plot boundary
- warm corner posts
- readable claim sign
- light biome decor outside the buildable rect

Plot boundaries must remain visible enough for playtesting, but they should not
look like combat zones, selection boxes, or permanent debug art.

## Graphics polish pass

In the live Sprout/top-down renderer the map draws real 32x32 square tiles: a
licensed Sprout tile when present, otherwise the original Hearthvale top-down
generated tile (`art/generated/hearthvale/terrain/`). Only the legacy 64x48
isometric diamonds are suppressed in top-down mode. Because the generated
Hearthvale tiles carry their own texture, the legacy iso decorative
highlight/patch overlays are skipped in Sprout-compatible mode (they would just
cover the tile art); they still draw in the legacy `iso_64x32` view. Plot ground,
terrain-paint overrides, road tiles, and the minimap continue to share
`TerrainArtRegistry`, `terrain_color`, and `minimap` tints, so painted/authored
terrain matches the world.
