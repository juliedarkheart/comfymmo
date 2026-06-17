# Asset Credits

This pass imports **no third-party assets** into the committed repository. A
clean checkout uses project-local generated placeholder art (now
Pillow-rendered, anti-aliased, cozy); optional Sprout Lands art is local-only and
documented separately below.

## Project licensing context

Hearthvale is a **personal, non-distributed project** (never publicly released).
The owner has approved **CC-BY in addition to CC0 / public domain, provided
attribution is tracked**. See "License policy" below.

## External asset attempt (honest record)

Outbound HTTP reached asset homepages, but the asset CDN's direct binary
download returned **HTTP 403** (anti-bot / hotlink protection), so packs behind
that CDN can't be fetched/verified from here. **GitHub raw + codeload (zip) ARE
reachable (`200`)**, so a CC0/CC-BY pack hosted on GitHub (with a readable
`LICENSE`) can be fetched and verified. As of this note **nothing external is
imported yet** — awaiting a chosen source. The pipeline + validation are ready
for a verified drop-in with no code changes.

## Current Assets

| Asset group | Source | Author | License | Files | In-game? |
|---|---|---|---|---|---|
| Generated placeholder terrain, objects, icons | `tools/art/generate_placeholder_art.py` (Pillow) | Hearthvale project-local generation | Project-local placeholder art | `art/tiles/**`, `art/objects/**`, `art/ui/icons/**`, `art/placeholders/missing.png` | Yes (active) |
| Kenney RPG Pack (spritesheet) | [github.com/iwenzhou/kenney](https://github.com/iwenzhou/kenney) · orig [kenney.nl/assets/rpg-pack](https://kenney.nl/assets/rpg-pack) | Kenney (kenney.nl) | **CC0-1.0** (verified from bundled `LICENSE.txt`) | `art/external/kenney/rpg-pack/RPGpack_sheet.png`, `LICENSE.txt`, `asset.json` | Imported + verified; **not yet wired** |

The generated PNGs are made locally for this branch — not copied from commercial
games, fan packs, or unknown sources. The Kenney sheet is genuine CC0 (license
text stored locally and verified). It is kept as a tracked, license-verified
import but is **not wired into the game**: it is a 2014 dungeon/RPG sheet with an
unlabeled grid that can't be sliced into correct named sprites without visual
review. The cozy generated art stays active until a matching CC0/CC-BY pack is
chosen and reviewed in-editor.

## License policy

Allowed for this (personal, non-distributed) branch:

- **CC0 / public domain** — no obligations.
- **CC-BY** — allowed; attribution **must** be tracked (see below).
- **CC-BY-SA** — allowed; attribution tracked + share-alike noted.

Still **not** allowed, even for personal use:

- assets ripped from, or derived from, existing IPs (Stardew Valley, Animal
  Crossing, Chrono Trigger, Harvest Moon, Minecraft, ARK, Once Human, etc.) —
  those remain style references only;
- unknown / unstated license;
- assets whose license file cannot actually be read and verified.

Because the game is never released, no-derivatives or personal-use-only assets
are also tolerable in practice, but prefer CC0/CC-BY so the art stays reusable.

## Attribution tracking (required for CC-BY / CC-BY-SA)

For every CC-BY/CC-BY-SA asset, record — in **both** this file's "Current
Assets" table **and** the asset folder — the title, author, source URL, license
+ version, and what was changed.

External assets live under:

```text
art/external/<source>/<asset_name>/
```

Each external asset folder must include:

- a license file: `LICENSE`, `LICENSE.txt`, `LICENSE.md`, or `COPYING`;
- a source/attribution file: `README.md`, `SOURCE.txt`, `CREDITS.txt`,
  `ATTRIBUTION.txt`, `NOTICE`, or `asset.json` — carrying URL, author, license,
  files, and modified-flag.

`tools/validate_project.gd` fails if any folder under `art/external/` lacks both
a license file and a source/attribution file.

## Normalized derivatives + registry preference

Originals stay untouched under `art/external/`. Resized/cropped/padded
derivatives go under `art/generated/from_external/active/<mirrored path>`, with a
`art/generated/from_external/manifest.json` linking each derived file back to its
source. The art registries resolve **external derivative → generated placeholder
→ missing fallback**, so a verified asset dropped at the mirrored path is adopted
automatically (see docs/graphics_pipeline.md).

## Known Credit Gaps

No CC-BY/CC-BY-SA attribution is currently owed: the only import (Kenney RPG
pack) is CC0, and it is not wired. Final-production art for every category is
still deferred (placeholders only).

## Review + activation

External art only becomes live after human review and an explicit entry in
`art/active_art_manifest.json` (see docs/asset_review_workflow.md). Contact sheets
live in `art/review/`; the in-editor preview is `tools/art/asset_preview.tscn`.
The Kenney sheet is reviewable (`art/review/kenney_rpg-pack_contactsheet.png`,
64x64 cells) but **not activated** - it is medieval/RPG art that needs manual
semantic review before any cell could be trusted.

## Licensed (premium, local-only) — credit required

- **Sprout Lands** premium sprite pack — **by Cup Nooble** (https://cupnooble.itch.io/).
  *Credit (required): Assets — From: Sprout Lands — By: Cup Nooble.* Premium
  license: modify OK (incl. local recolors/tints), commercial/non-commercial OK,
  **non-redistributable**, no NFT/AI-training use. The pack files **and any locally
  modified Sprout derivatives** are **local-only and gitignored** - not in this
  repository. Wired locally: 10 objects + 6 icons + 6 licensed terrain + 3
  licensed_modified tint terrain + 2 UI ids. (Original Hearthvale top-down
  gap-fill art under `art/generated/hearthvale/` is committable and NOT derived
  from Sprout.) Full policy:
  docs/licensed_asset_policy.md.

Sprout UI kit files, UI contact sheets, normalized derivatives, local manifests,
the animation catalog, and the Sprout Sorry pack audio/contact-sheet catalog also
stay under gitignored `licensed_assets/`. The committed repo contains only docs,
templates, validation, and fallback/registry code; a clean checkout without
Sprout installed keeps using generated cozy UI and placeholder art.
