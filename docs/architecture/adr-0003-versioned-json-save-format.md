# ADR-0003: Versioned JSON Save Format (v3)

**Date:** 2026-06-30
**Manifest Version:** 2026-06-30-v1

## Status

Accepted

## Context

Hearthvale's save system evolved organically from a simple flat placed_objects list to a richer model encompassing farming, inventory, survival, tasks, mood, and multiple regions. Without versioning, old saves would silently break or produce undefined behaviour when the schema changed. The project needed a structured, versioned save format that could migrate forward while preserving backward compatibility.

## Decision

Adopt a versioned JSON save envelope at `user://homestead_save.json` with `save_version = 3`. The save structure uses region-scoped world data under `world.regions`, player data under `player`, and task data under `tasks`. A migration engine upgrades older formats (v1 flat list, v2 region-scoped) to the current version on load.

## Consequences

### Positive
- Schema evolution is safe — old saves are migrated automatically on load
- Clear separation of concerns: world state, player state, task state
- Stable content IDs (centralized in `ContentIds`) are part of the save contract
- Region-scoped data keeps each area's state isolated
- Overworld compatibility layer preserves existing save paths without a version bump
- Automatic migration handles three legacy formats (flat list, homestead-only, v2)

### Negative
- JSON read/write is not atomic — corruption possible on crash during save
- Full save written on every meaningful change (placement, farming, inventory)
- Migration code must be maintained for every version bump
- Content IDs must never be renamed casually (breaks old saves)
- No server-side save format distinction from local saves

## Options Considered

### Option 1: Versioned JSON with Migration (Chosen)
Current approach with `save_version = 3`, automatic migration, versioned envelope. Full detail in `docs/save_data_model.md`.

### Option 2: Binary / Resource Format
Godot `.res` or custom binary format. Faster load/save and atomic writes, but opaque to debugging and harder to migrate. Would break the current workflow of inspecting saves as JSON.

### Option 3: Database (SQLite)
Structured queryable storage. Overkill for current scope — adds a dependency, complicates migration, and doesn't match the project's "small systems, avoid speculative frameworks" principle.

## ADR Dependencies

Depends on: ADR-0005 (Modular System Architecture with ObjectRegistry — centralized content IDs are essential for save contract stability)
Used by: None

## Engine Compatibility

Godot 4.6.3 — JSON/FileAccess API, packed scene serialization. Save path uses `user://` which resolves to platform-specific app data directory.

## GDD Requirements Addressed

- **Save Data Model** (docs/save_data_model.md): Save path, current version, structure, backward compatibility, migration rules
- **Building Placement** (docs/building_placement.md): Placed objects save format
- **Farming** (docs/farming.md): Farm plot state save model
- **Progression** (docs/progression.md): Player progression save shape

## Performance Implications

JSON serialization at current scale (dozens of placed objects, single-figure inventory counts) completes in under 10ms on modern hardware. Full-save-on-every-change is acceptable at prototype scale but may need throttling (debounced auto-save) in production. No measurable frame-time impact.
