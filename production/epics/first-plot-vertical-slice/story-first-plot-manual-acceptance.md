# Story: First Plot Manual Acceptance

**Epic:** first-plot-vertical-slice
**Status:** Ready
**Priority:** Must Have
**Layer:** Gameplay
**Points:** 3

## Description

A real local play session can complete the First Plot path without hidden setup, admin shortcuts, or guessing: mailbox → farm → plant → water → rest → harvest → Rowan → Land Token → claim plot → place one cozy object.

## Acceptance Criteria

- [ ] **AUTO:** Existing smoke/validation coverage proves the tool-gated farming sequence reaches harvest and persists expected state.
- [ ] **MANUAL:** In a fresh local session, Inventory/Hotbar exposes Hoe, Seed Packet, Watering Can, Build Tool, and enough first-build materials.
- [ ] **MANUAL:** Player can till, plant, water, rest at the cottage door, and harvest a carrot using only player-facing prompts.
- [ ] **MANUAL:** Watering Can works immediately or the UI clearly explains any fill requirement; current First Plot expectation is no fill step.
- [ ] **MANUAL:** After harvest, Rowan/Land Token/plot claim/build flow remains discoverable and can place one simple cozy object.
- [ ] **MANUAL:** No quest system, economy, shop, multiplayer, carrot consumption, crafting XP, HUD redesign, or asset change is introduced for this story.

## Technical Notes

- **GDD:** `design/gdd/farming.md`, `design/gdd/building-placement.md`, `design/gdd/interactions.md`
- **ADRs:** ADR-0001, ADR-0003, ADR-0005, ADR-0006
- **Files likely affected:** `world/homestead_controller.gd`, `world/overworld_controller.gd`, `systems/farming_system.gd`, `systems/building_placement_system.gd`, `tools/smoke_homestead_loop.gd`, `tools/validate_project.gd`, `docs/playtest_readiness.md`
- **Engine notes:** Godot 4.6.3; verify with focused smoke scripts when implementation changes.

## Dependencies

- first-plot-vertical-slice/story-stale-save-starter-recovery — informational; fresh-start pass should not regress existing-save bootstrap.
- first-plot-vertical-slice/story-first-plot-playtest-reporting — informational; manual evidence should be recorded after each pass.

## Test Strategy

- Unit tests: FarmingSystem state transitions and prompts.
- Integration tests: Homestead smoke path, inventory grant/spend, save/load roundtrip, build placement handoff.
- Manual tests: Julie launches current local session and confirms the path works without admin intervention.
