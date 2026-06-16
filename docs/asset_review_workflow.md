# Asset Review Workflow

How an external art pack goes from "downloaded" to "in the game" — **only after a
human looks at it.** Nothing imported is wired automatically; unlabeled terrain
sheets are explicitly **not auto-wired**. The cozy generated placeholders stay
active until you choose otherwise.

## License policy (personal, non-distributed project)

Allowed: **CC0 / public domain**, **CC-BY** (attribution tracked), **CC-BY-SA**
(attribution + license tracked). Forbidden: ripped assets, fan assets from
existing IPs, unknown license, non-commercial, no-derivatives, personal-use-only.

## Folders

```text
art/external/<source>/<asset>/   originals + LICENSE + asset.json  (never edited)
art/review/                      contact sheets for human review   (not in-game)
art/generated/from_external/     normalized derivatives + manifest.json
art/generated/from_external/active/<mirror>   promoted derivatives (still inert
                                              until listed in the activation manifest)
art/active_art_manifest.json     the ONLY switch that makes external art live
```

## Steps

1. **Import** originals under `art/external/<source>/<asset>/` with a license file
   and a source/attribution file (`asset.json`). Validation fails without both.
2. **Stage + review.** Run `tools/art/import_asset_pack.py` (or the tools below).
   It writes a **contact sheet** to `art/review/`:
   - a *named* pack keeps its filenames as labels;
   - an *unlabeled* spritesheet gets a numbered grid overlay (cell indices) — you
     pick cells by number. It is **not auto-wired**.
   Also open `tools/art/asset_preview.tscn` in Godot and press **F6** to see the
   current active art (terrain / objects / icons) in-engine with id + source tags.
3. **Slice** chosen cells with `tools/art/slice_spritesheet.py` (writes numbered
   cells + `slices.json`). Confirm the real cell size first — e.g. the Kenney RPG
   pack is **64×64**, not 16×16.
4. **Normalize** the keepers into `art/generated/from_external/active/<mirror>`
   (mirror the generated path, e.g. `active/ui/icons/wood.png`), preserving alpha
   and the project pivot/size. Record source→derived in
   `art/generated/from_external/manifest.json`.
5. **Activate** by adding entries to **`art/active_art_manifest.json`**:
   `"ui/icons/wood.png": "generated/from_external/active/ui/icons/wood.png"`.
   The registries (`TerrainArtRegistry` / `ObjectArtRegistry` via `ArtActivation`)
   resolve **activated external → generated placeholder → missing.png**. An empty
   `active` map = everything generated (the safe default).

## Tools

- `tools/art/import_asset_pack.py` — checks metadata, builds the review contact
  sheet, optionally slices. No wiring, no overwrite of originals.
- `tools/art/make_asset_contact_sheet.py` — `folder` mode (labeled grid of PNGs)
  and `sheet` mode (numbered grid overlay for unlabeled sheets).
- `tools/art/slice_spritesheet.py` — slice a sheet into numbered cells + manifest.
- `tools/art/generate_placeholder_art.py` — the cozy generated fallback art.

## Why unlabeled sheets aren't auto-wired

A packed sheet has no semantic names — cell N could be a wall, a barrel, or a
roof corner. Wiring by guess (especially top-down art onto a 64×32 isometric
world) tends to look worse than the cozy generated art, and can't be judged
headlessly. So activation is always a deliberate, post-review step.

## ComfyUI / future art

The same path works for generated art: render sprites, drop them under
`art/generated/from_external/active/<mirror>` (or straight into `art/...` to
replace a placeholder), review via the contact sheet + preview scene, and
activate. No gameplay code changes — it's all data + the activation manifest.
