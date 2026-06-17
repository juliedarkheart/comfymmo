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
fallback colors/placeholders render and worldbuilder/minimap/build tools keep
using the same logical tile positions. Local Sprout terrain is activated only for
reviewed `meadow`, `water`, and `creek` ids in Sprout-compatible modes; it is not
required for modular/custom building pieces and does not activate in legacy iso.

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

Generated terrain placeholders still exist as safe fallback art. In the live
Sprout/top-down renderer, generated 64x48 diamond terrain sprites are not forced
onto square cells; the map draws biome/terrain colors instead unless a reviewed
top-down local Sprout tile exists. Plot ground, terrain-paint overrides, and the
minimap continue to share `TerrainArtRegistry`, `terrain_color`, and `minimap`
tints.
