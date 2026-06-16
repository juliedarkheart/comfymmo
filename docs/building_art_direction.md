# Hearthvale Building Art Direction

Hearthvale uses survival-builder logic adapted to cozy 2D isometric
presentation. The player gathers resources, crafts components, and places,
moves, rotates, or deletes pieces on owned land. The art direction should keep
that loop readable without copying 3D base-building visuals.

## Building Principles

- Every piece needs a strong silhouette and clear footprint.
- Modular pieces should look good as exterior components.
- Prefabs can carry richer authored details and optional interiors.
- Costs and requirements must be visible before selection.
- Unavailable pieces should stay visible but clearly muted.
- The build menu should explain the kit through categories and selected info.

## Core Piece Rules

- Foundation/floor: flat, stable base, clear tile coverage, modest shadow.
- Wall: vertical silhouette, readable face direction, not too thin.
- Door/window: visible opening or trim so it reads differently from a wall.
- Roof: chunky cap shape, warm color, clear top silhouette.
- Fence/gate: small but unmistakable boundary rhythm; gate needs a break or
  latch cue.
- Post: vertical anchor, slightly taller than low decor.
- Path: ground-overlay family, lower contrast than objects.
- Workbench/storage: strong top surface, tool/storage cues, readable at camera
  distance.
- Prefab cottage/shed: authored shell, door location, warm roof, clear entry
  affordance.

## Prefabs And Interiors

Prefab buildings can opt into interiors through
`systems/building/prefab_interiors.gd`. Interiors are separate scenes/instances
opened from the prefab door interaction. Missing or invalid metadata should fail
softly with "Interior coming later."

Modular custom buildings are exterior-only for now. A player-made arrangement
of foundations, walls, windows, doors, roofs, fences, and gates does not require
or generate an interior. Modular interiors are deferred because reliable indoor
generation needs shape analysis, doorway resolution, collision transfer,
ownership permissions, save data, and multiplayer sync.

## Future Boundaries

Dungeons are future separate instances, not part of this building pass.
Player-created dungeons or adventure plots are also future work and should be
designed separately from homestead building.
