# ADR-0001: Continuous Overworld Instead of Paged Regions

**Date:** 2026-06-30
**Manifest Version:** 2026-06-30-v1

## Status

Accepted

## Context

Hearthvale originally used a paged-region architecture where the outdoor world was divided into separate scenes (homestead, village square, forest edge) with Area2D triggers swapping between them via WorldRegionManager. This caused visible scene transitions, broke immersion for a "cozy" MMO, and added complexity to every system that needed cross-region state. The project needed to decide whether to keep paged regions or move to a single continuous overworld.

## Decision

Adopt a single continuous overworld scene (`scenes/world/overworld.tscn`) containing the homestead, village square, and forest edge as connected areas. Outdoor traversal is walking with no scene swapping. WorldRegionManager is retained exclusively for future non-outdoor instances (dungeons, caves, interiors).

## Consequences

### Positive
- No scene transitions during outdoor gameplay — seamless exploration
- Simplified state management — one active scene for all outdoor content
- Future systems (chunk streaming, interest management) build on a single coordinate space
- Save model simplified: overworld-wide flags in `world.overworld.flags` instead of per-region state for outdoor content
- OutdoorAreaController base class provides shared lookup helpers, observe/message-panel lifecycle, and interactable registration without duplicating code across controllers

### Negative
- Six legacy region scenes remain on disk as fallbacks/templates (technical debt)
- Transitional inheritance chain (OverworldController → HomesteadController → OutdoorAreaController) must be preserved carefully — unwinding is deferred
- Original homestead scene and its controller/map are reused via inheritance rather than composition
- Grid-based placement and farming are meaningful only in the homestead area; the rest of the overworld is open terrain

## Options Considered

### Option 1: Continuous Overworld (Chosen)
Single scene with all outdoor areas connected. Walking traverses between areas. Full details in `docs/overworld_architecture.md`.

### Option 2: Paged Regions with Transitions
Original approach — separate scenes for each outdoor region, connected by Area2D triggers. Would require maintaining cross-region state and handling transition animation/loading.

### Option 3: Hybrid (Deferred Instances, Continuous Outdoor)
The chosen approach — continuous overworld for outdoor, WorldRegionManager reserved for future dungeons/interiors which will use scene transitions.

## ADR Dependencies

Depends on: None
Used by: ADR-0005 (Modular System Architecture with ObjectRegistry)

## Engine Compatibility

Godot 4.6.3 — Node2D scene tree, Area2D deferred transitions, CanvasLayer for fade effects. Fully compatible with Forward Plus renderer.

## GDD Requirements Addressed

- **Overworld Architecture** (docs/overworld_architecture.md): Single continuous scene, no outdoor scene swaps, system boundaries, grid usage
- **World Structure** (docs/world_structure.md): Hearthvale Landing, Town, Neighborhood, Wilderness zones within continuous space
- **System Architecture** (docs/system_architecture.md): Runtime shape, one active scene, WorldRegionManager for instances only

## Performance Implications

No measurable performance regression compared to paged regions — the continuous scene loads all areas upfront, but the total node count for the three connected outdoor areas is well within Godot 4.x capacity for a 2D isometric scene. Future chunk streaming would be additive and not required at current scale. The transitional inheritance adds negligible overhead.
