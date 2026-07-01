# Playtest Report: First Plot Manual Reliability

**Date:** 2026-07-01
**Area:** First Plot vertical slice
**Session type:** Manual-observation follow-up / production tracking seed
**Save condition:** Existing local prototype save suspected stale/incomplete; fresh-start path also in scope
**Build/branch:** `experiment/worldbuilding-tools-identity-v1`

## Acceptance Path Under Test

```text
mailbox → farm → plant → water → rest → harvest → Rowan → Land Token → claim plot → place cozy object
```

## Observed Issues From Latest Manual Pass

- No carrot seeds / Seed Packet available to test farming.
- No Watering Can available.
- No obvious way to add water to the Watering Can.
- Land system appeared to remember old test state: Julie was already a landowner from prior testing.
- Claimable parcels/signs appeared gone or unavailable, likely due to persisted old save state.

## Production Interpretation

- The First Plot path must work for both true fresh starts and stale local prototype saves.
- Starter-kit checks that only cover new-save code are insufficient for acceptance.
- Current Watering Can model should be explicitly immediate/no-fill unless a real water-source system is added later.
- Existing land ownership should not be wiped automatically; the game should clarify the next step for an already-landowner save.

## Follow-Up Stories

- `production/epics/first-plot-vertical-slice/story-first-plot-manual-acceptance.md`
- `production/epics/first-plot-vertical-slice/story-stale-save-starter-recovery.md`
- `production/epics/first-plot-vertical-slice/story-farming-doc-runtime-alignment.md`

## Current Acceptance Status

**Pending retest.** The next manual pass should verify:

- Fresh start has Hoe / Seed Packet / Watering Can / Build Tool.
- Julie's existing save receives missing First Plot minimums if incomplete.
- Watering works immediately or explains filling clearly; current intended behavior is immediate watering.
- Already-landowner state points Julie toward building inside her claimed plot.
- One simple cozy object can be placed inside the claimed plot.

## Notes / Safety

- Do not delete or reset saves automatically.
- Do not touch `licensed_assets/`.
- Do not add quest/economy/shop/multiplayer/progression scope to solve this slice.
