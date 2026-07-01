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
