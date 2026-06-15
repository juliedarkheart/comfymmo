# Building content catalog

20 placeables total: the original 5 plus 15 new cozy decor items. All flow
through the same pipeline: stable id in `ContentIds` → metadata in
`ContentRegistry.placeables()` → live catalog in `ObjectRegistry` → cost in
`BuildCosts` → placement/edit/move/remove via `BuildingPlacementSystem` →
persistence in `placed_objects` (offline save) or the server world file.

## Original five (unchanged ids, scenes, behavior — now with costs)

crate · mailbox · stool · lantern · planter

## New decor set (this pass)

| id | display name | cost |
|---|---|---|
| round_table | Round Table | 3 wood |
| cozy_chair | Cozy Chair | 2 wood, 1 fiber |
| garden_arch | Garden Arch | 3 wood, 2 fiber |
| picnic_blanket | Picnic Blanket | 3 fiber |
| birdhouse | Birdhouse | 2 wood |
| fence_segment | Fence Segment | 1 wood |
| path_lantern | Path Lantern | 1 stone, 1 fiber |
| berry_basket | Berry Basket | 2 fiber |
| wood_pile | Wood Pile | 2 wood |
| signpost | Signpost | 2 wood |
| decor_shrub | Trimmed Shrub | 1 fiber |
| tea_table | Tea Table | 2 wood, 1 clay |
| bench | Garden Bench | 3 wood |
| flower_bed | Flower Bed | 1 fiber, 1 clay |
| tiny_pond | Tiny Pond | 3 stone, 2 clay |

## How the new items are built

One shared root script, `buildings/placeable_decor.gd` (extends
`PlaceableCrate`, so every placement-system cast/preview/select call works),
plus one tiny scene per item under `scenes/buildings/decor/` that sets
`decor_id`. Visuals are drawn at runtime by `buildings/decor_visuals.gd` —
soft-ellipse cozy shapes in the established palette.

**Adding a new placeable** = 1 const in ContentIds + 1 list entry +
1 ContentRegistry line + 1 BuildCosts line + 1 drawer in DecorVisuals +
1 six-line scene. Validation fails if any piece is missing.

## ARK / Once Human inspired modular construction (cozy 2D iso adaptation)

The build kit aims at survival-builder construction — foundations, walls,
doors/windows, roofs, fences/gates, structures, stations, storage, farming,
paths/terrain, furniture, decor — adapted to the cute 2D iso grid. It does NOT
attempt 3D snapping complexity, interiors, raids, PvP, or structure damage.

Categories (in `ContentRegistry.placeables()` `category` field): structure,
modular, terrain, station, furniture, garden, decor, storage. Modular pieces
(wooden/stone foundations, deck floor, walls, door/window walls, pillars,
fences) and structure shells (cottage/shed/workshop/barn/greenhouse/well) are
**exterior-only** — doors say "Interior coming later" (docs/interiors_strategy.md).

Placement is **grid-aligned** (snaps to tiles), with a ghost preview, red
invalid tint, footprint metadata (shells are 2×2), and clear denials for
cost/tool/permission. Terrain overlays (paths, grass, plaza, flower meadow,
forest floor) require the shovel and are walk-over. A player on a claimed lot
can lay foundations, run walls, add a door/window wall and roof, fence a yard,
place stations/storage, and pave paths — a tiny cozy survival-builder kit.

## Build UX (Minecraft-like, cozy)

B opens placement with a ghost preview snapped to the grid; green/red tint +
a world-space bubble give validity ("Needs 2 Wood", "Occupied", ...). Tab
cycles the 20-item palette; the HUD mode line names the item and its cost.
Click/Enter places (and spends), E edits (click select, M move, Delete
remove), Esc exits. A visual category-palette UI is future work — the catalog
and category metadata it needs already exist.

## Deferred from the wishlist

flower_pot (planter covers it), rug (picnic_blanket covers it), potted
mushroom, clothesline, scarecrow — the pipeline makes each a ~20-minute add.
