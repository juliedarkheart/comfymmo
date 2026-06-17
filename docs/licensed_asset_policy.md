# Licensed Asset Policy

Some Hearthvale art is **premium, paid, non-redistributable** and must stay
**local-only** — never committed, never pushed. This is separate from the
CC0/CC-BY "external" pipeline (docs/asset_review_workflow.md), which *can* be
committed.

> **Sprout-required live build.** The playable visual prototype now *requires* the
> Sprout pack. With `licensed_assets/` absent the live world refuses to mount and
> shows a missing-assets screen (`ui/missing_assets_screen.gd`) — the generated
> fallback is no longer the shipped live look, only a diagnostic/dev and
> non-visual-smoke-test prop. See `systems/visual/sprout_asset_requirement.gd`.

## LimeZu (Modern ecosystem) — premium, local only, UNDER EVALUATION

LimeZu's Modern packs (`modern_farm`, `modern_ui`, `modern_exteriors`,
`modern_interiors`, `modern_office`, `fungus_cave`, and `rpg_arsenal` = the "Fantasy
Battlers" pack) are being evaluated as a possible new main visual ecosystem. They
follow the **same local-only rules as Sprout**:

- The entire `licensed_assets/limezu/` vault — original zips, the `.exe` generators,
  extracted packs, `normalized/`/`modified/` derivatives, contact sheets, per-pack
  inventory/candidate manifests, and the local `limezu_active_manifest.json` — is
  gitignored and **never committed**. `git check-ignore` confirms every pack's
  `original/` is excluded; `git ls-files licensed_assets` is empty.
- Commit-safe only: `tools/art/limezu_integrate.py`, provider code
  (`systems/art/limezu_art_registry.gd`, `art_provider_registry.gd`), the visual spike
  scene, `tools/art/templates/limezu_manifest_template.json` (empty `active`), and docs.
- `.gdignore` in each pack's `original/`, `extracted/`, `contact_sheets/`, and
  `manifests/` stops Godot importing the raw licensed PNGs; only reviewed
  `normalized/` derivatives import.
- Sprout remains the live provider; LimeZu is spike-only. `ArtProviderRegistry.LIVE_PROVIDER`
  is the single intended pivot point if LimeZu is later chosen. See
  docs/limezu_visual_spike.md and docs/limezu_asset_mapping.md.

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
    original/            the purchased zip + extracted originals (never edited, .gdignore'd)
    normalized/          resized/cropped derivatives mirrored on art ids (Godot imports these)
    modified/            locally MODIFIED licensed derivatives (recolors/tints; licensed_modified tier)
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

## Resolution order (registries via `ArtActivation` / `UIArtRegistry`)

1. **local licensed** — `sprout_active_manifest.json` → `normalized/...`
   (gitignored; absent on a clean clone). Source tier: `licensed`.
2. **local licensed_modified** — manifest values that point into `modified/...`
   (recolors/tints of licensed art). Source tier: `licensed_modified`.
3. **redistributable external** — `art/active_art_manifest.json` (tracked).
4. **generated** — original Hearthvale top-down tiles
   (`art/generated/hearthvale/...`, tracked, committable) then the legacy
   `art/...` placeholders. Source tier: `generated`.
5. **missing.png**.

Source tiers reported by `source_of`: `licensed`, `licensed_modified`,
`external`, `generated`, `missing` (UI adds `licensed_ui`). A clean checkout (no
`licensed_assets/`) still resolves the registries to the generated
Hearthvale/legacy art for non-visual smoke tests and validation
(`tools/validate_project.gd` stays green), but the **live visual build is
Sprout-required**: it boots to the missing-assets screen rather than presenting
that fallback as the game. Validation does not demand no-Sprout playability.

## What is wired from Sprout (this pass)

Regenerate locally with `python tools/art/sprout_integrate.py`. Activated ids:

- **objects (licensed, 10):** `tree, fruit_tree, bush, rock, flower_patch, well,
  sign, fence, storage_chest, workbench` (workbench = Cup Nooble's "work
  station", a confidently-named single object).
- **icons (licensed, 6):** `watering_can, worn_axe, simple_hammer, fiber, wood,
  stone`.
- **terrain (licensed, 6):** `meadow, orchard, grove, creekside` (pre-cut,
  descriptively-named grass cutout tiles) + `water, creek`.
- **terrain (licensed_modified, 3):** `forest, hilltop, town` — local recolor/
  tint variants of the licensed Sprout grass tile, written under `modified/`.
- **UI (licensed_ui, 2):** `panel` (Sprout `dialog box` nine-slice) and `close`
  (the X icon).

Terrain activation stays disciplined: only Cup Nooble's pre-cut single tiles are
used directly; everything else (soil, paths, tilled, plot markers) is original
Hearthvale generated art, not a blind crop off a bitmask sheet. Licensed and
licensed_modified terrain are blocked from the legacy `iso_64x32` mode so Sprout
art never flattens into the old diamond grid.

## Adding more / installing on another machine

1. Buy + download Sprout Lands; put the zip/extract under
   `licensed_assets/sprout_lands/original/`.
2. `python tools/art/sprout_integrate.py` (review the contact sheets first).
3. The registries pick it up via the local manifest. Nothing to commit.

## UI kit and animation catalog

The UI pack is extracted locally to
`licensed_assets/sprout_lands/original/extracted_ui/`. Contact sheets live under
`licensed_assets/sprout_lands/contact_sheets/ui/`, and the local
`sprout_ui_manifest.json` lists reviewed `candidates` plus an `active` map +
nine-patch `margins`. This pass activates the two confidently-identifiable
assets — `panel` (Sprout `dialog box`) and `close` (the X) — normalized under
`normalized/ui/`. `CozyUITheme` swaps panels to the Sprout nine-patch when active
and falls back to the cozy code-drawn UI otherwise (so a clean checkout is
unchanged). Button/slot sheets that don't divide cleanly stay catalog-only.

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
