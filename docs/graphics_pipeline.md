# Hearthvale Graphics Pipeline

This branch establishes a Godot-ready graphics foundation without changing
gameplay scope. The current art is generated local placeholder PNG art, routed
through registries so final ComfyUI/manual sprites or verified CC0 assets can
replace it later without rewriting placement, land, building, or map systems.

## Visual Target

Hearthvale should read as a cozy 2D isometric village toybox: warm colors,
chunky silhouettes, clear tile meanings, soft shadows, and friendly UI. The
reference games are direction only. Do not copy, trace, rip, or use fan assets
from existing IP.

Building logic can borrow the idea of gather, craft, place, move, rotate, and
delete from survival builders, but the visual style stays cute, readable, and
storybook-like.

## Folders

Game-facing art lives under `art/`:

```text
art/tiles/terrain/     transition and edge scaffold tiles
art/tiles/biomes/      meadow, forest, orchard, town, farmland, etc.
art/tiles/paths/       dirt, stone, tilled soil, plot markers
art/tiles/water/       water, creek, water edge
art/objects/building/  modular pieces, prefabs, workbench, storage
art/objects/nature/    trees, rocks, bushes, flowers, crops
art/objects/decor/     fence, gate, sign, mailbox
art/ui/icons/          resource, tool, build/edit icons
art/placeholders/      safe missing-art fallback
art/generated/         notes for locally generated placeholders
art/generated/from_external/  normalized derivatives of imported assets
art/generated/from_external/active/  resized/cropped derivatives the registries prefer
art/external/          third-party CC0/public-domain imports only (with license + source)
```

The generator script is `tools/art/generate_placeholder_art.py`. It now renders
with **Pillow at 4x supersampling** and downsamples with LANCZOS, so the
placeholders are soft, anti-aliased, and cozy (storybook toybox) instead of
hard-edged polygons — tiles get a subtle 3D lip and per-biome texture, objects
get soft shading + contact shadows, icons sit on a parchment chip. Output paths,
canvas sizes, and pivots are unchanged, so the registries and map/placeable
rendering keep working with no code changes. Run it with
`python tools/art/generate_placeholder_art.py` (needs `pip install Pillow`).

## Sizes And Anchors

Current placeholder targets:

- Terrain tile PNG: `64x48`, centered on the isometric tile.
- Object sprite PNG: `96x96`, bottom/center-friendly, contact shadow near the
  parent tile origin.
- UI icon PNG: `64x64`, centered.

Anchor rules:

- Terrain sprites are centered on the tile origin.
- Floor/foundation sprites sit close to the terrain plane.
- Upright objects use a negative Y offset so their contact shadow lands on the
  tile origin.
- Final art should preserve the same visible contact point even if resolution
  changes.

## Godot Import Settings

Let Godot import PNGs normally, then keep settings consistent by category:

- Sprites/UI: lossless PNG, no mipmaps, nearest or carefully chosen filter.
- Terrain tiles: no mipmaps for the current small tiles; revisit if large
  terrain sheets arrive.
- Transparent assets: RGBA PNG with clean alpha edges and no matte halo.
- Do not wire raw generation outputs directly into scenes. Promote cleaned art
  into `art/` or documented asset bundles first.

## Registries

`systems/art/terrain_art_registry.gd` maps terrain and biome ids to tile PNGs.
It provides:

- required terrain ids
- safe path lookup
- texture lookup
- invalid-id fallback to `art/placeholders/missing.png`
- stable tile variation index
- first-pass transition helper for grass/path/water/farmland/biome edges

`systems/art/object_art_registry.gd` maps content ids, nature ids, resources,
tools, and UI action ids to sprites/icons. It provides:

- required object/icon ids
- safe path lookup
- texture lookup
- invalid-id fallback to `art/placeholders/missing.png`
- sprite creation with simple anchor/z-index rules

Map code and placeable visuals should ask these registries for art paths. Avoid
scattering raw `res://art/...` paths through gameplay systems.

## Fallback Strategy

Both registries resolve every id through one preference order
(`TerrainArtRegistry.resolve_path` / `ObjectArtRegistry.resolve_path`):

1. **External derivative** — an imported/normalized CC0 file mirrored at the same
   relative path under `art/generated/from_external/active/` (e.g.
   `.../active/tiles/biomes/meadow.png`). If present, it wins. No id-table edits
   are needed to adopt a verified asset — just drop the normalized PNG there.
2. **Generated placeholder** — the local Pillow output under `art/...`.
3. **Missing fallback** — `art/placeholders/missing.png`, intentionally obvious
   but always safe to load.

`source_of(path)` reports which tier won (`external` / `generated` / `missing`),
which the inventory icons and validation use. Every lookup fails safe:

- Unknown terrain/object ids return the missing-art placeholder.
- Existing map polygons remain as fallback *under* terrain sprites.
- Decor with no mapped sprite keeps its existing procedural drawing.
- Missing external metadata fails validation before those assets can become
  trusted project inputs.

### Importing a verified CC0/public-domain asset later

1. Put originals under `art/external/<source>/<asset>/` with a `LICENSE` (CC0 /
   public-domain text) and a source file (`README.md`/`SOURCE.txt`/`asset.json`
   with URL, author, license, files, modified?). Validation **fails** if either
   is missing.
2. Normalize (resize/crop/pad to the tile/object/icon size, clean alpha, correct
   pivot) into `art/generated/from_external/active/<mirrored path>` and record
   source→derived in `art/generated/from_external/manifest.json`.
3. No registry/gameplay code changes — the resolver prefers it automatically.

## Terrain Transitions

This pass adds transition assets and a helper, not a full autotiling system.
Current transition scaffold ids are:

- `grass_to_path`
- `grass_to_water`
- `grass_to_farmland`
- `biome_soft_edge`
- `path_edge`
- `water_edge`

Future work can replace the simple helper with neighbor-aware autotiling after
the final terrain set exists.

## Replacement Order

Recommended final-art pass order:

1. Terrain tiles
2. Paths and water
3. Trees, rocks, bushes, crops
4. Building pieces
5. Prefab cottages and sheds
6. UI icons

Keep replacement changes data-only where possible: swap PNGs and registry paths
before touching gameplay code.
