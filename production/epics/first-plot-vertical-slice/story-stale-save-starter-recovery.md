# Story: Stale Save Starter Recovery

**Epic:** first-plot-vertical-slice
**Status:** Ready
**Priority:** Must Have
**Layer:** Gameplay
**Points:** 3

## Description

Julie’s existing local prototype save can recover from incomplete old First Plot state without wiping progress. If a save has old starter flags or stale land ownership but is missing core starter supplies, the game safely repairs only the missing minimums and gives clear next-step feedback.

## Acceptance Criteria

- [ ] **AUTO:** Bootstrap minimums include Hoe, Seed Packet, Watering Can, Build Tool, Wood, and Fiber.
- [ ] **AUTO:** Repair raises missing quantities to minimums instead of granting full bundles repeatedly.
- [ ] **AUTO:** Repair stops once the player has meaningful first-plot build progress.
- [ ] **MANUAL:** Julie’s current save receives missing tools/supplies if incomplete and does not lose inventory, land ownership, or placed objects.
- [ ] **MANUAL:** If the save already marks Julie as a landowner, Rowan/HUD directs her to build inside the claimed plot instead of asking her to claim again.
- [ ] **MANUAL:** Claim signs/plot feedback remain understandable; ownership is clarified, not reset.
- [ ] **MANUAL:** No save file is deleted, moved, cleaned, or automatically reset.

## Technical Notes

- **GDD:** `design/gdd/farming.md`, `design/gdd/building-placement.md`
- **ADRs:** ADR-0003, ADR-0005
- **Files likely affected:** `world/homestead_controller.gd`, `world/overworld_controller.gd`, `systems/local_save_system.gd`, `systems/land/land_registry.gd`, `systems/land/land_claim_system.gd`, `tools/validate_project.gd`
- **Engine notes:** Keep repair idempotent and local-save safe.

## Dependencies

- None blocking; this story protects real manual test reliability.

## Test Strategy

- Unit tests: inventory minimum repair, quickbar minimum repair, landowner hint selection.
- Integration tests: smoke/validate checks for bootstrap constants and no duplicate starter spam.
- Manual tests: use Julie’s existing save and confirm missing First Plot supplies appear without resetting land state.

## Verification Notes (2026-07-01)

- AUTO criteria covered: `HomesteadController.FIRST_PLOT_BOOTSTRAP_MINIMUMS` includes Hoe, Seed Packet, Watering Can, Build Tool, Wood, and Fiber; `_repair_first_plot_starter_kit_if_needed()` raises to minimums only and stops once any object is placed. Guarded by `tools/validate_project.gd` and exercised by `tools/smoke_homestead_loop.gd`.
- New this pass: fixed a stale-save dead loop — a save with `rowan_land_token_given` set but no Land Token and no owned plot had Rowan and the plot signs pointing at each other forever. Rowan now re-offers one token in exactly that state (`world/overworld_controller.gd::_talk_rowan`); holding a token or owning a plot blocks the re-grant, so it cannot be farmed. Guarded by `tools/validate_project.gd`.
- Status: **ready for Julie's manual test** on her real stale save. No save is deleted, moved, or reset by any of this.
