# Story: Farming Doc Runtime Alignment

**Epic:** first-plot-vertical-slice
**Status:** Ready
**Priority:** Should Have
**Layer:** Gameplay
**Points:** 1

## Description

Farming docs and GDDs describe the live tool-gated First Plot farming model instead of the older F-only model, so future agents and playtesters do not accidentally regress implementation or acceptance criteria.

## Acceptance Criteria

- [ ] **AUTO:** Changed farming docs mention Hoe, Seed Packet, Watering Can, rest-growth, and current internal crop states.
- [ ] **AUTO:** Docs mark `planted_dry`, `planted_watered`, and `grown` as legacy/migration names, not the current model.
- [ ] **AUTO:** Docs-only verification confirms no non-markdown implementation files changed in a docs-only pass.
- [ ] **MANUAL:** A future agent can read `design/gdd/farming.md` and understand that carrot consumption, shops, economy, and crafting XP are deferred/not First Plot requirements.
- [ ] **MANUAL:** Playtest instructions match the actual current flow used by Julie.

## Technical Notes

- **GDD:** `design/gdd/farming.md`
- **ADRs:** ADR-0005, ADR-0006
- **Files likely affected:** `docs/farming.md`, `design/gdd/farming.md`, `design/gdd/game-concept.md`, `docs/playtest_readiness.md`, architecture trace docs if they cite farming stages.
- **Engine notes:** Docs-only passes do not require Godot test suite unless implementation files change.

## Dependencies

- None blocking.

## Test Strategy

- Unit tests: not applicable for docs-only changes.
- Integration tests: not applicable unless implementation changes.
- Manual tests: read docs against `systems/farming_system.gd` and verify claims match current code.
