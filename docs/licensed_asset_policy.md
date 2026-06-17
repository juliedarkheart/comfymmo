# Licensed Asset Policy

Some Hearthvale art is **premium, paid, non-redistributable** and must stay
**local-only** — never committed, never pushed. This is separate from the
CC0/CC-BY "external" pipeline (docs/asset_review_workflow.md), which *can* be
committed.

## Sprout Lands (Cup Nooble) — premium, local only

- **Pack:** Sprout Lands premium sprite pack by **Cup Nooble**.
- **License (per the pack `read_me.txt`):** modification allowed; commercial &
  non-commercial use allowed (no NFT / AI-training use); **you may NOT
  redistribute or resell the pack itself, even modified**; **credit Cup Nooble is
  required**.
- **Consequence for this repo:** originals, normalized derivatives, contact
  sheets, and the local activation manifest are all **gitignored**. Only scripts,
  docs, validation, registry support, and the *template* manifest are committed.

### Credit (required)

> Assets — From: Sprout Lands — By: Cup Nooble (https://cupnooble.itch.io/)

Also recorded in `docs/asset_credits.md`.

## Folders (all gitignored)

```text
licensed_assets/sprout_lands/
    original/            the purchased zip + extracted originals (never edited)
    normalized/          resized/cropped derivatives mirrored on art ids
    contact_sheets/      review images
    contact_sheets/ui/   local UI kit contact sheets
    contact_sheets/animations/ local animation catalog contact sheets
    contact_sheets/sorry/ local Sprout Sorry pack catalog contact sheets
    sprout_active_manifest.json   LOCAL activation manifest (what is live)
    sprout_ui_manifest.json       LOCAL UI kit manifest (safe to keep active empty)
    manifests/animations_inventory.json  LOCAL catalog only, not runtime wiring
    manifests/audio_inventory.json       LOCAL catalog only, not runtime wiring
    CREDIT_AND_LICENSE.txt        preserved credit + license text
```

`.gitignore` ignores `licensed_assets/` and `art/licensed_local/`, plus
`*.aseprite`. `git check-ignore` confirms these are excluded.

## Resolution order (registries via `ArtActivation`)

1. **local licensed** — `licensed_assets/sprout_lands/sprout_active_manifest.json`
   (gitignored; absent on a clean clone)
2. **redistributable external** — `art/active_art_manifest.json` (tracked)
3. **generated placeholder** — `art/...` (tracked, cozy fallback)
4. **missing.png**

A clean checkout (no `licensed_assets/`) resolves everything to the generated
placeholders and runs identically — validated by `tools/validate_project.gd`.

## What is wired from Sprout (this pass)

Regenerate locally with `python tools/art/sprout_integrate.py`. Activated ids
(18): objects - `tree, fruit_tree, bush, rock, flower_patch, well, sign, fence,
storage_chest`; icons - `watering_can, worn_axe, simple_hammer, fiber, wood,
stone`; reviewed Sprout/top-down terrain - `meadow`, `water`, `creek`.

Terrain activation is deliberately narrow. Only obvious single-tile top-down
terrain is live in the primary `sprout_topdown` renderer. Multi-cell soil,
stone, tilled, biome, and decorative terrain sheets stay catalog/review-only
until a human chooses safe cells. Licensed terrain is blocked from legacy
`iso_64x32` so square Sprout art cannot flatten into the old diamond grid.

## Adding more / installing on another machine

1. Buy + download Sprout Lands; put the zip/extract under
   `licensed_assets/sprout_lands/original/`.
2. `python tools/art/sprout_integrate.py` (review the contact sheets first).
3. The registries pick it up via the local manifest. Nothing to commit.

## UI kit and animation catalog

The UI pack is extracted locally to
`licensed_assets/sprout_lands/original/extracted_ui/`. Contact sheets live under
`licensed_assets/sprout_lands/contact_sheets/ui/`, and the local
`sprout_ui_manifest.json` lists reviewed candidates. Its `active` map stays
empty by default, so `UIArtRegistry` falls back to cozy code-drawn panels and
generated icons.

Animation inventory is catalog-only. The local
`manifests/animations_inventory.json` and
`contact_sheets/animations/` cover water, crops, trees, tools, characters, and
doors/chests/mailbox. No runtime animation wiring, combat, dungeon, or creature
work is included.

If `Sprout Sorry pack.zip` is present locally, `tools/art/sprout_integrate.py`
also writes `manifests/audio_inventory.json` and contact sheets under
`contact_sheets/sorry/`. Those files are catalog-only. They do not add runtime
audio, dungeon gameplay, enemies, combat, quests, economy, or player-created
adventure plots.
