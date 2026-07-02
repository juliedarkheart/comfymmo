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

## Verification Notes (2026-07-01)

- Docs were synced to the live tool-gated flow in the prior pass (`docs: sync farming flow and track first plot slice`); `FarmingSystem._normalize_plot_state` migrates the legacy `planted_dry` / `planted_watered` / `grown` names on load and the current model is `empty → tilled_soil → planted_seed → crop_stage_1..3`.
- `docs/playtest_readiness.md` now also documents the manual retest/recording procedure (2026-07-01 entry). Remaining MANUAL criterion is a read-through against Julie's actual play session.
