# LimeZu Generator Workflow (local, license-conscious)

LimeZu ships **character/farmer generators** that can produce additional art (player
variants, NPCs, portraits). This doc is the safe workflow for using them. All
generator tools and their outputs are **licensed/derived local files** and must stay
under gitignored `licensed_assets/limezu/` — never committed.

## Local generators (no installer required — preferred)

The vendor `.exe` generators below are **OPTIONAL**. Three local Python tools cover
most needs without any installer, and all write only under gitignored
`licensed_assets/limezu/generator_outputs/` + `generator_manifests/`:

1. **Style analyzer** — `tools/art/limezu_style_analyzer.py`. Scans the installed
   extracted packs and writes a local **style profile**
   (`generator_manifests/limezu_style_profile.json`): palette, accent/outline/shadow
   colors, sizes, contrast/saturation, and crop/terrain/wood/stone/metal/fabric color
   clusters. `--dry-run` / `--preview` (preview also writes a palette swatch).
2. **Derivative generator** — `tools/art/limezu_derivative_generator.py`. Makes LOCAL
   dev assets that use **licensed LimeZu source pixels** (crop a cell, nearest-neighbor
   scale, recolor/HSV, outline, combine, icon-ify) into
   `generator_outputs/derivatives/{crops,props,terrain,ui,icons,wearables}/`. Reads
   only from `*/extracted/`; never edits a source file. `--dry-run` / `--preview` /
   `--all` / `--force` (force first timestamp-backs-up the output folder).
3. **Inspired generator** — `tools/art/limezu_inspired_generator.py`. Draws NEW
   **Hearthvale-original** pixel art procedurally, guided by the style profile (palette,
   outline, shadow, tile size) — it does **not** copy/slice any source sprite. Output in
   `generator_outputs/inspired/{crops,props,terrain,ui,icons,wearables,characters}/`.
   `--seed <int>` for deterministic, repeatable output names. Same flags as above.

A **simple original fallback** (`tools/art/hearthvale_icon_generator.py`,
`generate_hearthvale_gap_assets.py`) is used only to fill gaps when no style/source
reference is available.

Run `tools/art/limezu_generator_catalog.py --root licensed_assets/limezu` to report
all four paths (vendor GUI exports, derivative, inspired, simple original).

## Generators found

| Generator | Pack | File | Size | Type |
|-----------|------|------|------|------|
| Farmer Generator | modern_farm | `original/Farmer Generator Setup.exe` | ~29 MB | Windows **GUI installer** |
| Character Generator 2.0 | modern_interiors | `original/Character Generator 2.0 Setup.exe` | ~73 MB | Windows **GUI installer** (third-party tool by **0a3r** — see `moderninteriors-win/THIRD-PARTY TOOLS.txt`: https://0a3r.itch.io/modern-interiors-character-generation-tool) |

Both are `*Setup.exe` **installers** — they install a desktop GUI app, then you run
that app interactively to compose + export sprites. There is **no documented CLI**.

## Safety rules (followed this pass)

- **Not run automatically.** Per the hard rules, unknown/GUI installers are never
  executed blindly or headlessly. They require an interactive desktop session (and
  possibly admin rights) — not appropriate for automation here. They were inspected
  by filename + adjacent docs/licenses only.
- **License (LimeZu `LICENSE.txt`):** you MAY edit + use the assets in commercial or
  non-commercial projects; you MAY NOT resell or distribute the assets (edited or
  not); credit appreciated (limezu.itch.io). The Character Generator is a third-party
  tool with its own page/terms (0a3r). **Therefore: treat every generator output as a
  licensed derivative — local-only, gitignored, never committed.**

## Manual usage (when you want generated art)

1. Run the installer once on your desktop (outside this repo), launch the GUI app.
2. Compose the character/farmer/portrait you want.
3. Export PNGs into the matching gitignored folder:
   - players/farmers/NPCs → `licensed_assets/limezu/generator_outputs/characters/`
   - portraits → `licensed_assets/limezu/generator_outputs/portraits/`
   - UI/object exports → `.../generator_outputs/ui/` or `.../objects/`
   - rough/unsorted exports → `.../generator_outputs/review/`
   (A `.gdignore` in `generator_outputs/` keeps Godot from mass-importing these.)
4. Record what you exported in a local manifest under
   `licensed_assets/limezu/generator_manifests/` (gitignored).
5. To use one in the spike/live game: copy the reviewed frame into
   `licensed_assets/limezu/<pack>/normalized/generated_candidates/<id>.png`
   (importable), then add a logical-id mapping to the local
   `licensed_assets/limezu/limezu_active_manifest.json`. `LimeZuArtRegistry` reports
   these as the `limezu_generated_local` source tier (`list_generated_ids()`).

## What is allowed in live visual tests

- Only **reviewed, normalized** generator outputs mapped through the registry.
- Raw generator dumps stay in `generator_outputs/` (review only), never in a beauty
  shot until reviewed.

## Never commit

Installers, generator outputs (raw or normalized), generator manifests, contact
sheets, screenshots, or any path under `licensed_assets/limezu/`. Commit-safe = this
doc, the tool/provider code, templates, and validation only.

## Two distinct pipelines: LimeZu licensed art vs. original Hearthvale generation

This doc covers the **LimeZu character/portrait generators** (GUI tools that output LimeZu
licensed/derived art). A **separate, original** generation path — making our own
Hearthvale-compatible assets from procedural shapes + an original palette, *without copying
LimeZu* — lives in `docs/hearthvale_asset_generator_plan.md` (style profile + analyzer + icon
generator). Keep the two straight: LimeZu outputs are licensed derivatives; Hearthvale
generated originals are our own work. Both stay local/gitignored until a commit policy says
otherwise.

## Character / portrait pipeline (code, commit-safe)

There is now a real, code-backed pipeline so generated **characters and portraits** flow
into the game once you export them — no faking, GUI generators still run manually:

1. **Schema (committed):** `tools/art/templates/limezu_generator_manifest_template.json`
   documents the per-character entry: `display_name`, `kind` (player/npc),
   `sprite_sheet`, `sheet_cell`, `idle_frame_rect`, `walk_frame_rects`, `portrait_sheet`,
   `portrait_rect`, `notes`.
2. **Catalog tool (committed):** `python tools/art/limezu_generator_catalog.py --root licensed_assets/limezu`
   scans `generator_outputs/{player,npcs,portraits,characters}/` for PNGs, infers cell
   size, and writes the **local, gitignored** manifest
   `licensed_assets/limezu/generator_manifests/limezu_generator_manifest.json` (+ an
   optional review contact sheet under `generator_outputs/review/`). With no outputs it
   writes an empty manifest and prints the manual steps below.
3. **Registry (committed):** `systems/art/generator_character_registry.gd`
   (`GeneratorCharacterRegistry`) reads that local manifest and resolves a character id to
   a `portrait_texture()` (cropped `AtlasTexture`) or `sprite_sheet_texture()`. A clean
   checkout (no outputs/manifest) returns **null** so callers fall back safely — it never
   crashes. `is_available()` / `missing_reason()` report state.
4. **Usage + fallback (committed):**
   - **Nameplates** (`ui/nameplate.gd`) accept an optional `portrait_id`; when a portrait
     is cataloged it shows a small framed portrait chip (`LimeZuUITheme.portrait_frame_style`),
     otherwise nothing — opt-in, no clutter.
   - **Dialogue/tooltip** can use `LimeZuUITheme.portrait_frame_style()` as a framed
     portrait placeholder area; it shows a generated portrait when available.
   - Folder convention: `generator_outputs/player/`, `/npcs/`, `/portraits/`, `/characters/`.

### Exact manual steps to produce + activate generated characters
1. Run (with your approval) `licensed_assets/limezu/modern_farm/original/Farmer Generator Setup.exe`
   and/or `licensed_assets/limezu/modern_interiors/original/Character Generator 2.0 Setup.exe`.
2. In the GUI app, design characters and **export** sprite sheets / portraits.
3. Drop the PNGs into `licensed_assets/limezu/generator_outputs/{player,npcs,portraits,characters}/`.
4. Run the catalog tool (step 2 above). `GeneratorCharacterRegistry` picks them up next boot.
5. Edit the local manifest's rects (`portrait_rect`, `idle_frame_rect`, `walk_frame_rects`)
   to match the export layout, then pass the character id as `portrait_id` where wanted.

## Status this pass

No generator was run (GUI installers; not safe to automate, and none have a CLI). The
pipeline above is in place and validated: schema template, catalog tool, registry with
null fallback, portrait-aware nameplate, and the `{player,npcs,portraits,characters}`
folders + `.gdignore`. `generator_outputs/` is currently empty, so portraits resolve to
nothing and the UI falls back cleanly. The provider also still supports the
`limezu_generated_local` tier for reviewed sprite mappings via `LimeZuArtRegistry`.
