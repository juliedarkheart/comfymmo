# Dungeon Instances

Dungeons are still future work.

This document exists so the current building, land, and interior decisions do
not accidentally block them.

## Core rule

Dungeons are planned as separate instances, not as part of the outdoor build
grid and not as an extension of the prefab house-interior prototype.

That means:

- a dungeon entrance will live in the outdoor world
- entering it will hand off to a separate instance/scene lifecycle
- the outdoor overworld remains continuous while the dungeon runs as its own
  gameplay space

`systems/world_region_manager.gd` is the intended seam for that future work.

## Relationship to interiors

Prefab interiors and dungeons solve different problems:

- prefab interiors serve cozy authored building spaces
- dungeons serve adventure/combat/encounter spaces

They may both end up using instance routing, but they should not be treated as
the same feature.

## Future models

Reasonable future directions include:

1. Authored fixed dungeons at world landmarks.
2. Server-created run instances for parties or solo players.
3. Player-created or admin-authored dungeon/adventure plots that link an owned
   entrance to a separate instance.

That third option is explicitly future work. Player-created dungeons or
adventure plots are not part of the current branch.

## Why deferred

True dungeon support needs more than a room loader:

- combat rules
- enemies and encounter scripting
- loot/reward loops
- instance lifecycle and exit handling
- multiplayer authority for combat and state

None of that is required for the current homestead-building branch, so the
branch keeps the instance seam reserved without pretending dungeons are active.

## What to assume right now

- no dungeon entrances ship in this branch
- no player-created dungeon tools ship in this branch
- no land plot can be turned into a real adventure instance yet
- combat and dungeon progression remain outside the current release target
