# ADR-0005: Modular System Architecture with ObjectRegistry

**Date:** 2026-06-30
**Manifest Version:** 2026-06-30-v1

## Status

Accepted

## Context

Hearthvale's early prototype placed all game logic in monolithic controllers. As the project grew to include building placement, farming, inventory, crafting, progression, interactions, networking, and survival, this approach became unmaintainable. The project needed a modular architecture with clear system boundaries, centralised content IDs, and shared registries to keep gameplay systems decoupled and testable.

## Decision

Adopt a modular system architecture with systems as sibling nodes under the active scene root, coordinated through shared registries (ObjectRegistry, ContentIds, ContentRegistry). Each system owns a narrow API surface. Cross-system communication goes through registries or the shared OutdoorAreaController base class, never through direct node references across domain boundaries.

## Consequences

### Positive
- Systems are independently replaceable and testable
- ObjectRegistry centralises placeable definitions by stable `object_id` — all object types share the same placement/save/load/move/removal flow
- ContentIds provides a single source of truth for stable string IDs (items, crops, placeables, creatures, interaction types, areas, flags, tasks)
- ContentRegistry provides read-only data definitions keyed by those IDs (display names, categories, scene paths)
- Systems expose small surfaces rather than broad frameworks — each new system adds minimal coupling
- Clear separation: GameStateManager (save orchestration), BuildingPlacementSystem (placement rules), InteractableSystem (proximity registry), FarmingSystem (plot state), InventorySystem (item container), etc.
- Shared OutdoorAreaController provides generic lookup helpers and lifecycle hooks across homestead and overworld

### Negative
- Systems as scene siblings requires consistent scene tree structure
- Some cross-system wiring still happens in controllers (homestead_controller.gd registers farming+interaction+placement coordination)
- ContentRegistry is intentionally NOT a gameplay authority yet — some literal IDs remain outside ContentIds
- Transitional inheritance (OutdoorController → HomesteadController → OverworldController) is load-bearing and not yet unwound into pure composition

## Options Considered

### Option 1: Modular Systems with ObjectRegistry (Chosen)
Current architecture with sibling systems under scene root, centralised registries, narrow API surfaces. Full detail in `docs/system_architecture.md`.

### Option 2: Monolithic Controller
Everything in one or two large controllers. Simpler initial structure but would not scale to 25+ systems. Rules out multiplayer, save versioning, and independent testing.

### Option 3: ECS (Entity-Component-System)
Full ECS pattern with systems operating on component data. Over-engineered for current scope — Godot's node tree provides adequate composition for 2D isometric. Future chunk streaming might revisit this.

## ADR Dependencies

Depends on: ADR-0001 (Continuous Overworld — system boundaries defined around the continuous scene model)
Used by: ADR-0003 (Versioned JSON Save Format — content IDs are part of save contract)

## Engine Compatibility

Godot 4.6.3 — Node2D composition, scene tree hierarchy, @onready references, class_name global registration. All systems use standard Godot patterns.

## GDD Requirements Addressed

- **System Architecture** (docs/system_architecture.md): Content IDs & registries, runtime shape, current responsibilities of each system, design notes
- **Building Placement** (docs/building_placement.md): ObjectRegistry for placeable definitions, split responsibilities across systems
- **Interactions** (docs/interactions.md): InteractableSystem registry for proximity interactions
- **Farming** (docs/farming.md): FarmingSystem as dedicated agricultural state machine
- **Crafting** (docs/crafting.md): CraftingSystem with shared check/spend/grant logic
- **Progression** (docs/progression.md): PlayerProgression system with XP curve and skill tracking

## Performance Implications

The modular approach adds minimal overhead — each system is a single node with a small script. ObjectRegistry lookups are dictionary O(1). InteractableSystem scans nearby interactables each frame in Explore mode (negligible for current counts of <50 interactables). No measurable performance impact compared to a monolithic approach.
