# Hearthvale World Art Direction

The world should read as a warm storybook village laid out in readable 2D
isometric space. The player should be able to understand paths, plots, public
areas, wilderness, and biome changes at a glance.

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

Terrain tiles are now Pillow-rendered (anti-aliased iso diamonds with a soft 3D
lip and per-biome texture): meadow grass blades, forest/grove leafy dapple,
orchard blossoms, hilltop speckle, cobbled town, furrowed farmland, pebbled dirt
paths, and rippling blue water. They overlay the existing polygon fills (which
stay as safe fallback) via `TerrainArtRegistry`, and the same sprites flow
through plot ground, terrain-paint overrides, and the minimap `terrain_color` /
`minimap` tints. No external art was imported this pass (see
docs/asset_credits.md); these are upgraded local placeholders.
