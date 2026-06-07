# Godot Import Checklist (Step 11)

Moving a cleaned asset from `assets/import_staging/` into the running game.

## Steps

1. **Name** the file per the convention (`asset_import_standards.md` → naming):
   `<category>_<name>_<variant>_<state>.png`.
2. **Place** it in the correct category folder: `assets/tiles|props|characters|creatures|ui|sprites/`.
3. **Sidecar:** drop the `<asset>.meta.json` alongside it (model, prompt file, seed,
   workflow, anchor, collision rect, cleanup notes).
4. **Import settings (Godot):**
   - Texture filter OFF for crisp pixel-adjacent assets; ON for soft backgrounds only.
   - Mipmaps off for sprites/UI; on for large tiling terrain.
   - Lossless compression for sprites/UI.
   - Apply the shared per-category import preset; don't hand-tweak per file.
5. **Wire** into the scene/system that currently draws the procedural placeholder
   (e.g. a `Sprite2D`/`TextureRect` replacing the `Polygon2D`), keeping the same
   node position/anchor so layout is unchanged.
6. **Verify in-engine at game scale:** boot, walk to it, check silhouette, alignment
   to the tile, y-sort vs the player, and that the mood tint still reads on top.
7. **Keep the placeholder** code path until the whole category is swapped (fallback).

## Do not

- Do not import raw/oversized generations into the project (stage + downscale first).
- Do not bake time-of-day tint into the sprite.
- Do not commit `.import` caches for assets you haven't actually wired yet.

## Acceptance for a swapped asset

- Reads cleanly at game scale, aligns to its anchor, no alpha halo, mood tint intact,
  no Godot import warnings, FPS unaffected.
