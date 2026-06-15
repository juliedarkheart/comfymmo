# Dungeon instances (DEFERRED — design doc, not implemented)

No dungeons exist yet. This records the intended shape so nothing built now
blocks them.

## Principles

- Dungeons are **separate instances**, not tied to house interiors (see
  docs/interiors_strategy.md). A dungeon entrance is a world object on the
  overworld/plot; entering loads an instance.
- Instances route through **WorldRegionManager**, which has been reserved for
  exactly this since the continuous-overworld pivot (it never scene-swaps the
  outdoor world). The `world.instances` save section is already reserved.

## Future models

1. **Randomly generated server instances** — the server rolls a layout per
   entry/party, runs it authoritatively, and tears it down after.
2. **Player/admin-created dungeons** via land ownership + world-builder tools
   (place an entrance on owned/admin land that links to an authored instance).
3. **Fixed authored dungeons** at landmark entrances (the simplest first step).

## Why deferred

Dungeons need combat, loot, enemy AI, and instance lifecycle — none of which
the cozy survival-building loop requires yet. The weapon item placeholders
(wooden staff, practice sword, slingshot) already exist so the eventual combat
milestone has item plumbing waiting.
