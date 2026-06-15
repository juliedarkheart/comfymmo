# Building Content

Hearthvale's current building slice is a cute 2D isometric take on the
survival-builder grammar popularized by games like ARK and Once Human. The
adaptation keeps the readable "foundations / walls / roofs / fences / utility"
language, but trims away 3D stacking complexity, combat pressure, raids,
structure decay, and freeform interior simulation.

The runtime pipeline is:

- stable ids in `systems/content/content_ids.gd`
- metadata in `systems/content/content_registry.gd`
- player-facing menu grouping in `systems/building/build_categories.gd`
- costs in `systems/building/build_costs.gd`
- live catalog in `systems/object_registry.gd`
- placement/edit/move/remove in `systems/building_placement_system.gd`
- optional prefab-interior mapping in `systems/building/prefab_interiors.gd`

## Build menu

Press `B` to enter placement mode. When placement is active, the build menu
opens and stays non-modal: movement still works while it is visible.

Menu controls:

- click a category button to filter the catalog
- click `Select` on a card to arm that piece immediately
- click `Compact` to collapse the item text to a shorter summary
- press `Esc` or click `Close (Esc)` to hide the panel
- press `Tab` to cycle the active placeable even with the panel open
- click in the world or press `Enter` to place the active piece
- press `E` to switch to edit mode for move/remove work

Each card shows:

- display name
- cost
- required tool
- footprint size
- interior status for prefab structures
- an unavailable reason if the player lacks materials, tools, or unlocks

## Build menu categories

The menu currently exposes 12 categories, in this order:

1. Foundations
2. Walls
3. Doors & Windows
4. Roofs
5. Fences & Gates
6. Structures
7. Crafting & Utilities
8. Storage
9. Farming
10. Paths & Terrain
11. Furniture
12. Decor

These categories are a UI layer over the coarser `ContentRegistry` placeable
metadata so the catalog reads like a survival-builder kit instead of a raw
content dump.

## Content families

The current catalog is intentionally broad enough to build a small homestead:

- prefab structures: cottage shell, storage shed, workshop hut, barn shell,
  greenhouse shell, well
- modular construction: stone foundation, deck floor, wood wall, stone wall,
  wood door wall, wood window wall, wooden pillar, roof cap, fence segment,
  fence corner, fence gate, steps
- terrain overlays: dirt path, stone path, grass patch, flower meadow, plaza
  tile, forest floor patch
- stations and utilities: workbench, garden table, mailbox
- storage and decor: crate, wood pile, berry basket, lanterns, signpost,
  shrub, pond, picnic blanket, birdhouse, furniture, and related yard pieces

## Cute 2D isometric adaptation

This branch is deliberately not trying to recreate full 3D base building.
Instead it adapts the idea into a readable, cozy 2D grid:

- every placement is tile-snapped
- footprints stay small and legible
- terrain and prop silhouettes stay readable at MMO camera distance
- tools and costs gate building without making the UI heavy
- large homestead plots provide the "yard to grow into" feeling without true
  voxel or free-height construction

The result is closer to "build a charming outdoor homestead" than "simulate a
fortress."

## Plots and scale

The modular and prefab kit is sized around the new claimable lots in
`systems/land/land_registry.gd`. There are 4 claimable neighborhood plots, and
each one is at least `12x12` tiles. That larger footprint is important:

- prefab structures need room for paths, fences, and work areas
- modular builds need space for custom exterior shapes
- the system wants a homestead feel, not a single-object pad

## Interiors

Prefab buildings can opt into interiors through
`systems/building/prefab_interiors.gd`. The current branch uses this only for
selected authored shells.

Modular custom buildings remain exterior-only for now. A player-built shape
made from foundations, walls, roofs, and gates does not generate or require a
matching interior.

See `docs/interiors_strategy.md` for the reasoning and the forward plan.
