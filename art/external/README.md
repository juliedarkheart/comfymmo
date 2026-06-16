# External assets (third-party, license-tracked)

**Originals only — never edited, never wired directly.** One folder per asset:

```text
art/external/<source>/<asset_name>/
    <original files...>
    LICENSE  (or LICENSE.txt / LICENSE.md / COPYING)   <-- required
    asset.json (or README/SOURCE/CREDITS/ATTRIBUTION/NOTICE)  <-- required
```

`tools/validate_project.gd` fails if any folder here lacks a license file AND a
source/attribution file.

## Allowed licenses (personal, non-distributed project)

- CC0 / public domain
- CC-BY — attribution tracked in `docs/asset_credits.md` + the asset folder
- CC-BY-SA — attribution + license tracked

Forbidden: ripped assets, fan assets from existing IPs, unknown license,
non-commercial, no-derivatives, personal-use-only.

## How an external asset reaches the game

1. Drop originals here with license + source metadata.
2. Review: contact sheets in `art/review/` and the in-editor preview
   (`tools/art/asset_preview.tscn`).
3. Normalize chosen sprites into `art/generated/from_external/active/<mirror>`
   (never overwrite originals here).
4. Activate by listing them in `art/active_art_manifest.json`.

Until step 4, an asset here is **inert** — the game uses the generated
placeholders. See `docs/asset_review_workflow.md`.

## Imported so far

- `kenney/rpg-pack/` — Kenney RPG Pack spritesheet, **CC0** (verified). Imported
  + license-tracked but **not wired**: 2014 top-down 16px dungeon/RPG sheet that
  does not fit the cozy 64×32 isometric village. Awaiting an iso-matched pack.
