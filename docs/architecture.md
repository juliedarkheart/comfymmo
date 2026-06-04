# Architecture

Hearthvale is organized around small domain modules that can grow independently
while sharing clear boundaries.

## Runtime Shape

- `scenes/` owns Godot scene composition and app entry points.
- `systems/` owns cross-domain orchestration.
- `world/` owns isometric map data, coordinate conversion, regions, and world simulation.
- `avatar/` owns player-facing movement, appearance, and avatar state.
- `creatures/` owns non-player entity definitions and behavior.
- `buildings/` owns structures, placement rules, and building definitions.
- `ui/` owns presentation logic and screen composition.
- `multiplayer/` owns networking mode, authority rules, sessions, and replication.
- `integrations/` owns external service boundaries.
- `tools/` owns local automation and editor support.

## Multiplayer Posture

The project should be designed as multiplayer-ready, not multiplayer-complete.

Early gameplay code should separate:

- player intent
- authoritative state changes
- replicated state
- local presentation

Single-player and offline prototypes may use the same service boundaries as
online play so they can graduate into networked flows later.

## Isometric World

The world begins with a simple 2D isometric coordinate convention:

- grid coordinates are stored as `Vector2i`
- world coordinates are stored as `Vector2`
- conversion helpers live in `world/world_system.gd`

Future tilemaps, chunk loading, region streaming, and placement logic should
build on that shared convention.

## Modularity

Modules should expose narrow APIs and avoid reaching across folders for internal
state. Shared behavior belongs in `systems/` only when at least two domains
actually need it.

## Current Boundaries

This scaffold intentionally does not include inventory, combat, persistence,
quests, chat, economy, guilds, or live operations. Those systems should be
introduced milestone by milestone.

