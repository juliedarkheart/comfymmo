# Playtest Report: First Plot Manual Acceptance — TEMPLATE

Copy this file to `report-YYYY-MM-DD-first-plot.md`, fill it in during/after the
session, and do not record results you did not personally observe.

**Date:** YYYY-MM-DD
**Tester:** Julie
**Build/branch:** (branch name + `git rev-parse --short HEAD`)
**Session type:** Manual acceptance
**Save condition:** fresh / existing / stale-repaired (delete as appropriate)

## Acceptance Path Under Test

```text
mailbox → farm → plant → water → rest → harvest → Rowan → Land Token → claim plot → place cozy object
```

## First Plot Checklist

- [ ] Mailbox opens and shows today's notes.
- [ ] Inventory (`I`) shows Hoe, Seed Packet, Watering Can, Build Tool, Wood x2+, Fiber x2+.
- [ ] Hotbar exposes Hoe / Seed Packet / Watering Can / Build Tool.
- [ ] Hoe tills an empty plot (prompt-guided, no guessing).
- [ ] Seed Packet plants a carrot (count decreases by 1).
- [ ] Watering Can waters immediately — no fill step needed or implied.
- [ ] Rest at the cottage door grows the watered crop.
- [ ] Harvest gives +1 Carrot with clear feedback.
- [ ] Rowan gives (or re-offers, if lost) a Land Token — or points at building if a plot is already owned.
- [ ] A plot sign claims the plot for one Land Token.
- [ ] One cozy object (e.g. stool) places inside the claimed plot using starter materials.

## Supplies Observed

(what the inventory/hotbar actually contained at boot)

## Land State Observed

(unclaimed / already landowner / stale; what Rowan and the signs said)

## Blockers

(anything that stopped the path — be specific)

## Confusing Moments

(anything that required guessing, even if it didn't block)

## Cozy / Fun Notes

(what felt good — keep track of the warmth, not just the bugs)

## Verdict

**PASS / PARTIAL / FAIL**

## Follow-Up Actions

- [ ] (file or update stories under `production/epics/first-plot-vertical-slice/` from this evidence)

## Safety

- No saves were deleted or reset. No screenshots, secrets, or licensed assets in this report.
