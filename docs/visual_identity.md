# Hearthvale Visual Identity

Hearthvale is a cozy 2D isometric MMO prototype with a gentle 3/4 top-down
read. The visual target is a warm storybook village: readable paths, chunky
silhouettes, soft toy-like props, and UI that feels built from parchment, honey,
and wood.

The reference mix is directional, not asset-copying:

- Chrono Trigger: readable world composition, strong landmarks, clear travel
  paths, and charming environment scenes.
- Harvest Moon: rural homestead language, readable fields, tools, fences,
  storage, and farm lots.
- Animal Crossing: soft toy-like charm, friendly shapes, and approachable UI.
- Stardew Valley: warm inventory grids, item slots, category tabs, toolbars,
  hover/selected states, and low-friction status panels.
- Minecraft, ARK, and Once Human: building logic only. Hearthvale adapts the
  resource, craft, place, move, rotate, delete loop into cute 2D isometric UI.

## Style Rules

- Use cozy 2D isometric or gentle 3/4 top-down staging.
- Route game-facing terrain/object art through the art registries before adding
  scene-specific paths.
- Favor low visual noise: no harsh debug lines in normal gameplay.
- Keep object silhouettes chunky enough to read at MMO camera distance.
- Give every buildable item a clear footprint and recognizable outline.
- Treat roads and paths as intentional village routes, not plain test strips.
- Make plots feel like homestead yards with ground tint, posts, signs, and soft
  boundaries rather than debug rectangles.
- Let biomes visibly affect ground, decor, resources, minimap tint, and HUD
  labels.
- Always provide visible close paths on important UI panels.
- Always show selected, hover, unavailable, and denied states where the player
  is making a choice.

## Terrain Language

- Grass and meadow: warm green, readable as safe common ground.
- Dirt path: honey-brown, softer than soil, used for cozy foot routes.
- Stone path: light grey with warm edging, used for town/plaza structure.
- Tilled soil: darker brown, specifically agricultural.
- Water and creek: clear blue, bright edge highlights, never grey debug bands.
- Forest floor: deeper green with lower brightness and more decor density.
- Plot boundary: soft yellow/wood posts, visible but not alarming.
- Road: wider dirt-path family, laid out as an authored route.

## What This Pass Is Not

This pass does not add combat, dungeons, economy, new world scale, or new
gameplay systems. It establishes visual and UI conventions so existing and
future systems can inherit a coherent Hearthvale style.

See `docs/graphics_pipeline.md` for folder layout, placeholder generation,
registry behavior, fallback art, and replacement order.

## Graphics polish pass

The placeholder art is now Pillow-rendered (4x supersampled, anti-aliased) so
the cozy 2D isometric, storybook target reads in-engine: soft toy props, warm
biome tiles with a subtle 3D lip, water that reads as water, cozy dirt/stone
paths, and post/corner plot boundaries instead of harsh debug rectangles. UI is
unchanged in structure but inventory slots now show registry icons. No external
assets were imported this pass; everything is upgraded local placeholder art
(see docs/asset_credits.md).
