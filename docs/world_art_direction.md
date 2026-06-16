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

## Plot Presentation

Homestead plots should feel like yards:

- biome-tinted ground patch
- soft plot boundary
- warm corner posts
- readable claim sign
- light biome decor outside the buildable rect

Plot boundaries must remain visible enough for playtesting, but they should not
look like combat zones, selection boxes, or permanent debug art.
