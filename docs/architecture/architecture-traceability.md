# Architecture Traceability Matrix

> **Manifest Version:** 2026-06-30-v1
> **Last updated:** 2026-06-30

This matrix links Technical Requirements (TR-IDs) from the TR registry to their implementing ADRs, GDDs, systems, and verification methods.

---

## ADR → Systems Mapping

| ADR | Title | Affected Systems | Verification |
|-----|-------|-----------------|-------------|
| ADR-0001 | Continuous Overworld | OverworldController, HomesteadController, OutdoorAreaController, WorldRegionManager, OverworldMap, WorldMood | No scene transitions between outdoor areas; walk between homestead/village/forest |
| ADR-0002 | Server-Authoritative Multiplayer with ENet | NetworkSession, server/*, CraftingSystem (server path), PlayerProgression (server XP) | F8 connects; server validates placements; positions sync; offline boots with no config |
| ADR-0003 | Versioned JSON Save Format (v3) | LocalSaveSystem, GameStateManager, ContentIds | Save_version=3 in file; old saves migrate; version mismatch handled |
| ADR-0004 | Forward Plus Renderer | (engine-level) | project.godot config; no mobile renderer fallbacks |
| ADR-0005 | Modular System Architecture with ObjectRegistry | ObjectRegistry, ContentIds, ContentRegistry, all 35+ systems | Systems are independent scene siblings; object definitions go through ObjectRegistry |
| ADR-0006 | Godot 4.6 as Target Engine | (global) | project.godot config; run-godot.ps1 targets 4.6.3 |

---

## TR-ID → Implementation Traceability

| TR-ID | Description | ADR Source | GDD Source | Implementing System(s) | Test/Validation |
|-------|-------------|------------|------------|----------------------|-----------------|
| TR-ARCH-001 | Single continuous overworld scene | ADR-0001 | game-concept | OverworldController, OverworldMap | Walk between areas without scene swap |
| TR-ARCH-002 | WorldRegionManager for instances only | ADR-0001 | game-concept | WorldRegionManager | No outdoor Area2D transitions |
| TR-ARCH-003 | Server-authoritative multiplayer | ADR-0002 | — | server/*, NetworkSession, server_main.tscn | Server validates placement; client requests only |
| TR-ARCH-004 | ENet transport | ADR-0002 | — | NetworkSession, server_config.gd | Port 8910, max 16 peers, ENet in config |
| TR-ARCH-005 | Offline play with no network config | ADR-0002 | game-concept | GameBootstrap, all gameplay systems | Game boots without server; full gameplay loop offline |
| TR-ARCH-006 | Versioned JSON save with migration | ADR-0003 | game-concept | LocalSaveSystem, GameStateManager | Save_version=3; old format migration |
| TR-ARCH-007 | Content IDs as save contract | ADR-0003 | — | ContentIds, validate_project.gd | IDs stable; validate_project.gd asserts constants |
| TR-ARCH-008 | ContentIds as single source of truth | ADR-0005 | — | ContentIds | All IDs from ContentIds; no inline literals |
| TR-ARCH-009 | Forward Plus renderer | ADR-0004 | — | project.godot config | Features include "Forward Plus" |
| TR-ARCH-010 | Godot 4.6.3 pinned | ADR-0006 | — | project.godot, run-godot.ps1 | Config version 5, features "4.6" |
| TR-ARCH-011 | ObjectRegistry for placeable definitions | ADR-0005 | building-placement | ObjectRegistry, BuildingPlacementSystem | All placeables registered; load from registry |
| TR-ARCH-012 | Narrow system APIs, no cross-domain refs | ADR-0005 | — | All systems | Code review: no reaching across folders |
| TR-GDD-001 | Proximity-based interactions (F) | — | interactions | InteractableSystem | Prompt shows near interactables; F triggers action |
| TR-GDD-002 | Farming stage model | — | farming | FarmingSystem, farm_plot.gd | empty→planted_dry→planted_watered→grown cycle |
| TR-GDD-003 | Gathering nodes regenerate on cooldown | — | resources-gathering | ResourceSpawnRegistry, resource nodes | Cooldown after gather; node reactivates |
| TR-GDD-004 | Build costs enforced at placement | — | survival-building, building-placement | BuildingPlacementSystem, build_costs.gd, InventorySystem | Ghost shows cost; insufficient materials blocked |
| TR-GDD-005 | Recipe gates (level + skill) | — | crafting, progression | CraftingRegistry, PlayerProgression | Level/skill requirements checked before craft |
| TR-GDD-006 | Level derived from XP thresholds | — | progression | PlayerProgression | XP→level computation; no stored level |
| TR-GDD-007 | Eight skills tracked | — | progression, game-concept | PlayerProgression | 8 skill IDs; each with XP tracking |
| TR-GDD-008 | Mode display and interaction prompts | — | ui-hud | HUD, prototype_hud.gd | Mode line updates; prompt shows interactable action |

---

## System → ADR/GDD Coverage

| System | ADR | GDD | TR-ID |
|--------|-----|-----|-------|
| GameStateManager | ADR-0003, ADR-0005 | game-concept | TR-ARCH-006 |
| WorldRegionManager | ADR-0001 | game-concept | TR-ARCH-002 |
| OverworldController | ADR-0001 | game-concept | TR-ARCH-001 |
| HomesteadController | ADR-0001 | building-placement, farming | TR-ARCH-001 |
| OutdoorAreaController | ADR-0001, ADR-0005 | interactions | TR-ARCH-001 |
| ObjectRegistry | ADR-0005 | building-placement | TR-ARCH-011 |
| BuildingPlacementSystem | ADR-0005 | building-placement, survival-building | TR-ARCH-004, TR-GDD-004 |
| InteractableSystem | ADR-0005 | interactions | TR-GDD-001 |
| InventorySystem | ADR-0005 | survival-building | TR-GDD-004 |
| FarmingSystem | ADR-0005 | farming | TR-GDD-002 |
| LocalSaveSystem | ADR-0003 | game-concept | TR-ARCH-006 |
| NetworkSession | ADR-0002 | game-concept | TR-ARCH-003, TR-ARCH-004, TR-ARCH-005 |
| CraftingSystem | ADR-0002 | crafting | TR-GDD-005 |
| PlayerProgression | ADR-0005 | progression | TR-GDD-005, TR-GDD-006, TR-GDD-007 |
| ContentIds | ADR-0003, ADR-0005 | game-concept | TR-ARCH-007, TR-ARCH-008 |
| WorldMood | ADR-0001 | game-concept | TR-ARCH-001 |
| HUD | — | ui-hud | TR-GDD-008 |
| ResourceSpawnRegistry | ADR-0002 | resources-gathering | TR-GDD-003 |
| BuildCosts | ADR-0005 | survival-building | TR-GDD-004 |
| GameBootstrap | ADR-0005, ADR-0006 | game-concept | TR-ARCH-005, TR-ARCH-010 |

---

## Gap Analysis

| System | ADR Coverage | GDD Coverage | TR-ID Coverage | Notes |
|--------|-------------|--------------|----------------|-------|
| CreatureSystem | Partial | Partial | None | Referenced in ADR-0005 (defined), GDD: interactions (observe) — needs dedicated GDD |
| DungeonSystem | Partial | None | None | Stub only; deferred |
| CombatSystem | None | None | None | Stub only; deferred |
| LandRegistry | None | Partial | None | Documented in world_structure.md, land_ownership.md — needs GDD |
| LandClaimSystem | None | Partial | None | Same as above |
| ModerationScaffold | None | None | None | Stub only; deferred |
| OverworldEditorSystem | None | None | None | Dev tool; not gameplay |
| CharacterArtRegistry | None | None | None | Art pipeline; not architecture |
