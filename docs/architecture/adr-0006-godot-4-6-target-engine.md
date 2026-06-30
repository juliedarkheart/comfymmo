# ADR-0006: Godot 4.6 as Target Engine

**Date:** 2026-06-30
**Manifest Version:** 2026-06-30-v1

## Status

Accepted

## Context

Hearthvale was created in Godot 4.x and has evolved through several minor versions. The project.godot config confirms `config_version=5` and `config/features=PackedStringArray("4.6", "Forward Plus")`. The development environment uses Godot 4.6.3-stable (detected from `README.md` and tooling references). The project needs to formally pin the engine version so ADR compatibility checks, dependency planning, and CI tooling all reference the same baseline.

## Decision

Pin Godot 4.6.3 as the target engine version. The project is developed and tested exclusively on this version. Future engine upgrades will be explicit ADR decisions with migration planning.

## Consequences

### Positive
- Single engine version for all development — no compatibility surprises
- ADR engine compatibility checks have a clear baseline
- Tooling (`run-godot.ps1`) references the same version
- Forward Plus renderer feature flag is confirmed working
- Uses GDScript (Godot 4.x) as primary language
- Godot Physics 2D for physics

### Negative
- Post-cutoff risk: LLM training data may not include Godot 4.6.3-specific API changes
- Engine upgrades require explicit ADR with migration plan
- Some APIs may differ from Godot 4.2/4.3 training data — verification needed for new code
- Cannot use Godot 4.4+ exclusive APIs without version pin update

## Options Considered

### Option 1: Godot 4.6.3 (Chosen)
Currently installed and tested version. Stable release with all needed features. Referenced in tooling and workflow.

### Option 2: Latest Godot 4.x (any stable)
Would always track latest stable. Risk of breaking changes between minor versions. Unstable for production development.

### Option 3: LTS / Godot 3.x
Godot 3.x has different API surface (no Forward Plus, different scene system). Would require significant rework. Not aligned with project architecture.

## ADR Dependencies

Depends on: None (foundation decision)
Used by: ADR-0002 (Server-Authoritative Multiplayer — ENet transport), ADR-0004 (Forward Plus Renderer), ADR-0005 (Modular System Architecture)

## Engine Compatibility

Godot 4.6.3-stable. Config: `config_version=5`, `config/features=PackedStringArray("4.6", "Forward Plus")`. Autoload: `NetworkSession`. Stretch mode: `canvas_items`, aspect: `expand`. Viewport: 1280x720.

## GDD Requirements Addressed

- **README.md**: Godot 4.x, project setup, tooling references to 4.6.3
- **project.godot**: Engine configuration confirms Godot 4.6 feature set
- **All GDDs**: Inherit engine version constraints from this decision

## Performance Implications

Godot 4.6.3 provides stable performance for 2D isometric games. The Forward Plus renderer with canvas_items stretch mode is well-suited for the target resolution (1280x720). No performance regressions expected within the pinned version's lifecycle.
