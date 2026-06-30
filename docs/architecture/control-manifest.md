# Control Manifest

**Manifest Version:** 2026-06-30-v1
**Last updated:** 2026-06-30
**Source ADRs:** ADR-0001, ADR-0002, ADR-0003, ADR-0004, ADR-0005, ADR-0006
**Source GDDs:** game-concept, farming, crafting, building-placement, progression, interactions, resources-gathering, survival-building, ui-hud

---

## Required Patterns

- **Content IDs must come from ContentIds** — Source: ADR-0003, ADR-0005 — Layer: Data
  All stable string IDs (items, crops, placeables, creatures, interaction types, areas, flags, tasks) must reference `ContentIds` constants, not inline string literals. The validate_project.gd tool asserts equality.

- **All placeable definitions must be registered in ObjectRegistry** — Source: ADR-0005 — Layer: Data
  Every placeable object needs an entry in `ObjectRegistry` keyed by its stable `object_id`. Placement, save/load, move, and removal flow through the registry.

- **All buildable items must have defined material costs in build_costs.gd** — Source: GDD: survival-building — Layer: Gameplay
  Every registered placeable must have a corresponding entry in `build_costs.gd` validated against known material IDs. Missing costs are caught by validation script.

- **ADR files must include ## Status, ## ADR Dependencies, ## Engine Compatibility, ## GDD Requirements Addressed, ## Performance Implications** — Source: architecture-decision skill — Layer: Core
  Every ADR requires these five sections to be digestible by framework skills (story-readiness, architecture-review, gate-check).

- **Server-authoritative: clients send requests, never state** — Source: ADR-0002 — Layer: Network
  Clients must send action requests to the server; the server validates, executes, and broadcasts results. The only exception is position sync (unreliable-ordered, client-trusted, documented exception).

- **Systems must expose narrow APIs and avoid cross-domain direct node references** — Source: ADR-0005 — Layer: Core
  Systems communicate through registries and shared base classes, not by reaching across folders for internal state.

- **Levels must be derived from XP, never stored directly** — Source: GDD: progression — Layer: Gameplay
  Player level is always computed from cumulative XP using the threshold array. No `/level` command; admin XP commands only.

## Forbidden Patterns

- **Do NOT re-add outdoor Area2D transitions or per-area scene swapping** — Source: ADR-0001 — Layer: World
  The outdoor world is a single continuous scene. Area2D triggers for region transitions must not be reintroduced for outdoor areas.

- **Do NOT casually unwind the transitional inheritance (OverworldController → HomesteadController → OutdoorAreaController)** — Source: ADR-0001 — Layer: World
  The inheritance chain is stable and intentional. Unwinding it must preserve every system, every save string, and every interaction — and must not be attempted without test guards.

- **Do NOT rename content IDs casually** — Source: ADR-0003 — Layer: Data
  Content IDs in `ContentIds` are part of the save contract. Renaming them silently breaks old saves. Display names may change freely; IDs must not.

- **Do NOT access systems from outside their intended layer** — Source: ADR-0005 — Layer: Core
  UI systems must not own game state. Gameplay systems must not access UI nodes directly. Data layer owns persistence, not gameplay logic.

- **Do NOT place objects on reserved spawn tile** — Source: GDD: building-placement — Layer: Gameplay
  The player spawn tile must remain unoccupied at all times to prevent save/load conflicts at startup.

- **Do NOT run admin commands on server** — Source: ADR-0002 — Layer: Network
  All `/give`, `/xp`, `/skillxp`, and `/skills` commands are ignored by the server process. Admin tools are offline-only, trust-based.

## Guardrails by Layer

### Foundation (Core/Engine)
- DO: Version-pin engine to Godot 4.6.3 as reference
- DO: Use Forward Plus renderer for all rendering
- DO: Use Godot Physics 2D at 60 Hz
- DO: Keep systems small and replaceable
- DO: Prefer data-driven content over hard-coded rules
- DON'T: Use Compatibility or Forward Mobile renderers
- DON'T: Add speculative frameworks until the game needs them

### Gameplay
- DO: Use InteractableSystem for all world-facing interactions
- DO: Use server-authoritative model for multiplayer actions
- DO: Derive player level from XP thresholds (never store directly)
- DO: Source all stable string IDs from ContentIds
- DO: Register every placeable in ObjectRegistry
- DON'T: Hardcode content IDs as string literals
- DON'T: Allow placement without material cost validation
- DON'T: Add hunger damage, depletion, or death mechanics

### UI
- DO: Use CanvasLayer for UI rendering above world
- DO: Show contextual "Press F to [action]" prompts
- DO: Display mode line (Explore/Placement/Edit/Move)
- DO: Keep build menu non-modal (walking continues)
- DO: Show material costs in placement preview
- DON'T: Own game state (read-only from systems)
- DON'T: Trap player input (Esc must always close)
- DON'T: Use harsh debug lines in normal gameplay

### Data
- DO: Use versioned JSON save format (current: v3)
- DO: Centralise content IDs in ContentIds
- DO: Provide automatic migration for older formats
- DO: Validate all registries with tools/validate_project.gd
- DON'T: Rename content IDs (breaks save compatibility)
- DON'T: Store player level directly (derive from XP)
- DON'T: Write inline string literals for stable IDs

### Network
- DO: Use ENet transport (Godot high-level multiplayer)
- DO: Keep client playable offline with zero config
- DO: Server-authoritative for placements, materials, gathering
- DO: Sanitize and normalize all data crossing the wire
- DON'T: Send client state as authoritative (except positions, documented exception)
- DON'T: Accept admin commands on server
- DON'T: Hardcode display strings in network messages (use content IDs)
