# Hearthvale Asset Generator Plan (original, LimeZu-compatible)

Hearthvale uses the **LimeZu** packs as the licensed art direction, but we should not be
*blocked* on manually slicing pack art (or on the GUI character generators) for every
icon/prop. This plan establishes how we generate our **own original** assets that sit
comfortably next to the LimeZu look — **without copying LimeZu art**.

## Licensed LimeZu art vs. original Hearthvale generation

- **LimeZu licensed art** (`licensed_assets/limezu/**`): paid, redistribution-forbidden.
  Sliced derivatives stay local/gitignored and are mapped through `LimeZuArtRegistry`.
  We may *use* it in our game; we may **not** copy/trace it into "new" assets.
- **Original Hearthvale generation**: procedurally drawn from primitives + an
  **original** palette and **measured style constraints** (sizes, outline px, padding,
  shadow/highlight direction). These are our own work and *could* be committed later under
  an explicit policy — but for now they stay local/gitignored until reviewed.

The point of analysis is to learn LimeZu's **production constraints** (pixel scale,
outline, spacing, framing, shadow rules), which are facts/conventions — not to reproduce
its pixels.

## Analysis (commit-safe tool, local-only report)

`python tools/art/hearthvale_palette_analyzer.py --root licensed_assets/limezu` measures a
sample of local LimeZu icons/UI and writes a **local gitignored** report
(`licensed_assets/limezu/generator_manifests/hearthvale_style_analysis.json`) with:
common canvas sizes, mean value/saturation, outline (dark-edge) ratio, fill ratio, and
dominant hue buckets. Latest run (200 samples) confirmed: dominant **16×16** cell, mean
value ≈ 0.48, mean saturation ≈ 0.39, thin (~1px) dark outlines. No pixels are copied into
committed files — only aggregate measurements (kept local) inform the profile below.

## Style profile (committed, original)

`tools/art/templates/hearthvale_generator_style_profile.json` is the commit-safe,
**original** rule set the generators read:

- **Pixel scale:** author at 16px; integer NEAREST upscale (2×/3×/4×); supported cells 16/32/48/64.
- **Outline:** 1px, a darker shade of the local fill (not pure black), selective.
- **Shadow:** top light → 1px-down soft shadow; contact ellipse under bottom-anchored props.
- **Highlight:** top/top-left facing surfaces.
- **Value/saturation:** 0.25–0.9 / 0.2–0.7 (warm, slightly desaturated cozy range).
- **Palette:** a hand-authored Hearthvale-original cozy palette (wood/leaf/soil/stone/
  parchment/gold/ink) — not LimeZu's palette.
- **UI spacing:** matches the live `LimeZuUITheme` margins so generated UI bits drop into the
  same frames cleanly.
- **Categories / naming / export folders.**

## Generators

| Category | Tool / status | Output (gitignored) |
|----------|---------------|----------------------|
| Item icons | `tools/art/hearthvale_icon_generator.py --preview` (working stub: log/stone/leaf/berry/acorn/coin) | `generator_outputs/hearthvale_generated/item_icons/` |
| Crop/resource icons | planned (same generator, `resource_icons` recipes) | `.../resource_icons/` |
| Furniture/prop variants | planned (32px, bottom-anchored) | `.../props/` |
| UI icon/badge | planned (framed glyphs) | `.../ui_badges/` |
| Portrait placeholder | planned (48px bust silhouette) | `.../portraits/` |
| Color-swap variant | planned (palette swap of **original** Hearthvale sources) | `.../variants/` |

`hearthvale_palette_analyzer.py` (analysis) and `hearthvale_icon_generator.py` (procedural
icons) are real and runnable; the other categories are recipes to add to the icon generator
or sibling tools. All draw from primitives — no traced/copied art.

## Output + review workflow

1. Run a generator with `--preview` → originals + a contact sheet land under gitignored
   `licensed_assets/limezu/generator_outputs/hearthvale_generated/<category>/` (+ `/review/`).
2. Review the contact sheet. Iterate the recipe / style profile.
3. To use one in-game: it's detected via the generated-assets catalog/registry path with a
   safe fallback when absent (a clean checkout has no outputs and must still boot).
4. **Commit policy:** generated originals stay **local/gitignored** until a dedicated policy
   doc explicitly allows committing them (separate review of originality + licensing).
   Never co-mingle generated originals with LimeZu licensed art folders' tracked status.

## Two generator families (both local + gitignored)

- **Derivative** (`tools/art/limezu_derivative_generator.py`): uses licensed LimeZu
  source pixels directly (crop/scale/recolor/outline/combine/icon). `source_type =
  licensed_limezu_derivative`. Treat exactly like licensed art — local-only, do NOT
  commit the PNGs.
- **Inspired** (`tools/art/limezu_inspired_generator.py`): NEW Hearthvale-original art
  drawn procedurally from the LimeZu **style profile**
  (`tools/art/limezu_style_analyzer.py` → palette/outline/shadow/scale/clusters). It
  does not copy source sprites. `source_type = hearthvale_limezu_inspired_original`.
  Kept local until manual art/license review; do not commit without explicit approval.
- **Simple original** (`hearthvale_icon_generator.py`, `generate_hearthvale_gap_assets.py`):
  last-resort gap filler when no style/source reference exists.

Runtime fallback order (see `systems/art/generator_asset_resolver.gd`):
reviewed direct LimeZu → local derivative → local inspired → Hearthvale simple
original → committed procedural/code fallback → glyph/text. Missing manifests/PNGs
are always safe — every lookup returns "" and the clean checkout still boots.

## Never commit

LimeZu licensed art, sliced/derivative outputs, inspired-original outputs (until
reviewed/approved), generator executables/outputs, local manifests, contact sheets,
screenshots, the local style-analysis profile, or any generated PNG. Commit only: tool
code, the style profile template, schema templates, and docs.
