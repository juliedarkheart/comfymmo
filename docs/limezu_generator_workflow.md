# LimeZu Generator Workflow (local, license-conscious)

LimeZu ships **character/farmer generators** that can produce additional art (player
variants, NPCs, portraits). This doc is the safe workflow for using them. All
generator tools and their outputs are **licensed/derived local files** and must stay
under gitignored `licensed_assets/limezu/` — never committed.

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

## Status this pass

No generator was run (GUI installers; not safe to automate). The output folder
structure + `.gdignore` + this workflow are in place so generated art can be added
safely later. The provider already supports a `limezu_generated_local` tier for when
outputs are reviewed and mapped.
