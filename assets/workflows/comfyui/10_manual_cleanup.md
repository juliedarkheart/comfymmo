# Manual Cleanup Checklist (Step 10)

Not a ComfyUI graph — the human pass between background removal/upscale and Godot
import. Hearthvale's "soft but not blurry / readable / no AI mush" identity is won or
lost here. Do this in any image editor (Krita, Photoshop, Aseprite for pixel-crisp).

## Minimum before an asset is committable

- [ ] **Alpha edges:** no halo/fringe, no semi-transparent fuzz, no leftover matte color.
- [ ] **Silhouette test:** fill the shape black, shrink to in-engine size (24–66px) — still reads.
- [ ] **Contact shadow:** consistent soft ellipse (or none) across a set; never a hard cast shadow.
- [ ] **Anchor:** ground-contact point matches siblings so the asset doesn't jump vs the placeholder.
- [ ] **Noise:** erase stray specks, double-lines, smudges, and AI artifacts.
- [ ] **Palette:** nudge toward the Hearthvale anchors (`hearthvale_master_style.md`).
- [ ] **Lighting:** key from upper-left, no baked dusk/morning tint (the mood system tints at runtime).
- [ ] **Perspective:** matches the set's iso/3-4 angle exactly.
- [ ] **Downscale last:** clean at high res, then downscale to 2× target with a soft filter.

## Per-category extras

- **Tiles:** verify 3×3 tessellation has no seam/obvious repeat before downscale.
- **Sheets (props/crops/creatures/villagers):** equalize scale + light across all cells.
- **UI icons:** check both 64px and the 24px silhouette; allow a touch more saturation.
- **Buildings:** keep roof overhang outside the collision footprint; mark the footprint.

## Record it

Update the asset sidecar (`asset_import_standards.md` → metadata convention) with what
cleanup was done, so a re-generation can reproduce or improve it.
