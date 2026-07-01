# Epic: First Plot Vertical Slice

**Slug:** first-plot-vertical-slice
**Layer:** Gameplay
**Priority:** MVP

## Description

Make the First Plot path reliable enough for Julie to manually accept in a real local play session: check the mailbox, farm a carrot with the live tool-gated farming model, rest to grow it, harvest, talk to Rowan, receive/use a Land Token, claim a plot, and place one cozy object. This epic is intentionally a lightweight production tracking bridge for the active vertical slice; it does not introduce quests, economy, shops, multiplayer, crafting XP, carrot consumption, or broad save/load rewrites.

## Systems Included

- FarmingSystem — `design/gdd/farming.md` — tool-gated plot state, prompts, rest-growth, harvest behavior.
- HomesteadController — `design/gdd/farming.md`, `design/gdd/interactions.md` — routes farm interactions, starter/bootstrap supplies, mailbox task hooks, inventory grants.
- TaskIntegrationSystem — `design/gdd/interactions.md` — mailbox tutorial messages and water/harvest completion state.
- InventorySystem — `design/gdd/survival-building.md`, `design/gdd/farming.md` — carries tools, seed packets, crop items, and first-build materials.
- LandRegistry / LandClaimSystem — `design/gdd/building-placement.md` — claimable plots, land ownership, build permission checks.
- BuildingPlacementSystem — `design/gdd/building-placement.md` — place one cozy object inside the claimed plot.
- QuickToolsBar / HUD prompt surfaces — `design/gdd/ui-hud.md` — selected tool visibility, current-step hint, and feedback copy.
- LocalSaveSystem — `docs/architecture/adr-0003-versioned-json-save-format.md` — existing-save repair safety and persistence.

## Dependencies

- [ ] core-save-and-content — existing versioned save, stable ContentIds, and inventory persistence must remain compatible.
- [ ] building-placement — build costs, preview validity, and placement persistence must remain intact.
- [ ] ui-hud-feedback — prompts/hotbar/HUD hints must make the next action discoverable.

## ADR References

- ADR-0001 — Continuous Overworld
- ADR-0003 — Versioned JSON Save Format
- ADR-0005 — Modular System Architecture with ObjectRegistry
- ADR-0006 — Godot 4.6 Target Engine

## Stories

- [ ] story-first-plot-manual-acceptance — 3 — Must Have
- [ ] story-stale-save-starter-recovery — 3 — Must Have
- [ ] story-farming-doc-runtime-alignment — 1 — Should Have
- [ ] story-first-plot-playtest-reporting — 1 — Should Have

## Interface Notes

- Farming consumes the selected quickbar item from the HUD/hotbar layer but keeps state transitions inside `FarmingSystem`.
- Starter repair uses existing inventory and save flags; it must raise missing minimums without duplicating supplies or resetting player progress.
- Land ownership remains owned-state data; stale ownership should be clarified with feedback, not automatically wiped.
- Manual playtest evidence belongs under `production/playtests/` and should reference exact build/session behavior, not assumptions.

## Out of Scope

- Quest system
- Crafting XP
- Carrot consumption
- Economy or shops
- Multiplayer farming sync
- HUD redesign
- Broad save/load rewrite
- Licensed asset changes
