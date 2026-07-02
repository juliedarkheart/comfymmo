# Story: First Plot Playtest Reporting

**Epic:** first-plot-vertical-slice
**Status:** Ready
**Priority:** Should Have
**Layer:** Gameplay
**Points:** 1

## Description

Each Julie manual First Plot test pass is captured as a lightweight playtest report so production decisions are based on observed behavior instead of chat memory or assumptions.

## Acceptance Criteria

- [ ] **AUTO:** `production/playtests/` contains dated First Plot reports using a consistent short template.
- [ ] **MANUAL:** Each report records build/session context, save condition, observed path, blockers, fixes needed, and acceptance status.
- [ ] **MANUAL:** Reports distinguish fresh-start results from stale-save results.
- [ ] **MANUAL:** Reports do not include secrets, personal credentials, screenshots, generated assets, or licensed asset copies.
- [ ] **MANUAL:** Current story status can be updated from report evidence without rereading chat transcripts.

## Technical Notes

- **GDD:** `design/gdd/farming.md`, `design/gdd/building-placement.md`, `design/gdd/interactions.md`
- **ADRs:** ADR-0003, ADR-0005
- **Files likely affected:** `production/playtests/report-YYYY-MM-DD-first-plot.md`, relevant story status fields.
- **Engine notes:** A report is evidence, not a substitute for automated smoke/validate checks.

## Dependencies

- None blocking.

## Test Strategy

- Unit tests: not applicable.
- Integration tests: not applicable.
- Manual tests: confirm the report contains enough detail for another agent to reproduce the issue or acceptance result.

## Verification Notes (2026-07-01)

- `production/playtests/first-plot-manual-acceptance-template.md` added: build/branch, date, tester, save condition (fresh / existing / stale-repaired), the First Plot checklist, supplies/land state observed, blockers, confusing moments, cozy notes, PASS/PARTIAL/FAIL verdict, and follow-ups.
- Convention: copy the template to `report-YYYY-MM-DD-first-plot.md` per pass; `production/playtests/report-2026-07-01-first-plot.md` remains the seed report (status: pending retest). Only observed results go in reports — no assumed outcomes.
