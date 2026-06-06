# ComfyUI Workflows — Hearthvale

How we produce Hearthvale art with ComfyUI, from concept to Godot import. This pass
defines the **process**; the actual `.json` workflow graph exports live in
`assets/workflows/comfyui/` (one file per workflow, named to match the sections
below). Prompts come from `assets/prompts/`.

> Scope: this is scaffolding. No final images are generated here. The workflows are
> described so any contributor with ComfyUI can reproduce the pipeline.

## Pipeline overview

```
concept ──► refine ──► extract sprite ──► remove bg ──► upscale ──► manual cleanup ──► stage ──► Godot import
(SDXL/Flux)            (slice sheets)     (alpha)       (2x)       (fix edges)        import_staging/
```

Two production lanes:
- **Volume lane** (tiles, props, crops, icons): SDXL, sheet-based, batch, light cleanup.
- **Hero lane** (buildings, villagers, signature creatures): Flux or SDXL-refiner,
  single subject, more manual cleanup.

## Workflow catalog

### 1. SDXL concept workflow (`01_sdxl_concept.json`)
Base lane. Load cozy/illustration SDXL checkpoint → CLIP encode (Base Positive +
category modifiers) → KSampler (euler_a/dpmpp_2m, 25–35 steps, CFG 4.5–7) → VAE
decode → save. 1024². Use for tiles, props, crops, icons, most creatures/villagers.

### 2. Flux concept workflow (`02_flux_concept.json`)
Hero lane. Flux (dev) checkpoint for buildings and signature characters where form
fidelity matters. Lower CFG/guidance, fewer negatives (Flux ignores most). Use
sparingly (slower); downstream steps are identical.

### 3. Sprite/asset extraction workflow (`03_sprite_extraction.json`)
Slices a generated **sheet** (prop sheet, crop stage row, character/creature
turnaround) into individual cells. Grid crop nodes + per-cell save with padding.
Output: one PNG per asset, still on background.

### 4. Background removal workflow (`04_background_removal.json`)
RemBG / SAM-based alpha cutout → matte cleanup → premultiplied-safe export. Validate
no halo on edges. Output: transparent PNG. (Tiles skip this — they stay opaque.)

### 5. Isometric tile workflow (`05_iso_tile.json`)
Seamless/tiling sampler (circular padding or tiling VAE) → center crop → 3×3 tile
preview check → downscale to **128×64** master. Produces edge-safe diamond ground
tiles. Generate 2–3 variants per type.

### 6. Prop sheet workflow (`06_prop_sheet.json`)
SDXL concept tuned for an evenly-spaced grid of one material family → extraction (#3)
→ background removal (#4). Enforces identical angle/scale/light per sheet.

### 7. Creature concept sheet workflow (`07_creature_sheet.json`)
Multi-pose creature turnaround (front 3/4, side, idle, action) on one sheet →
extraction → bg removal. Keeps design consistent across poses for animation.

### 8. Character/villager concept workflow (`08_character_sheet.json`)
Villager turnaround (front 3/4, side, head close-up). Hero lane optional. → extraction
→ bg removal. Matches existing placeholder palettes for drop-in swap.

### 9. Upscaling workflow (`09_upscale.json`)
Model upscale (e.g. 4x-UltraSharp or a soft-illustration ESRGAN) → downscale to **2×
target** for crispness without AI noise. Avoid over-sharpening; Hearthvale is "soft
not blurry".

### 10. Manual cleanup workflow (`10_manual_cleanup.md`)
Not a ComfyUI graph — a checklist for the human pass (see that file / the section in
this doc): fix alpha halos, unify contact shadows, align anchors, remove stray noise,
nudge palette to the Hearthvale anchors, verify silhouette at game scale.

### 11. Godot import workflow (`11_godot_import.md`)
Move cleaned PNGs from `assets/import_staging/` into the correct `assets/<category>/`
folder, apply the import preset (see `asset_import_standards.md`), wire into the
relevant scene/system, and verify in-engine at game scale. Record source prompt +
seed in the sidecar.

## Reproducibility rules

- Every saved asset gets a **sidecar** (`<asset>.meta.json` or `.txt`) with: model,
  prompt file + overrides, seed, sampler/steps/CFG, workflow file used, date.
- Workflow `.json` exports are versioned in git; image outputs are **not** committed
  raw — only the final, cleaned, downscaled game assets are committed.
- Keep generation at 1024²+, downscale on import. Never upscale a low-res asset to fit.

## Negatives reminder

Hearthvale fails most often toward **AI mush / over-detail / unreadable silhouette**.
The Base Negative plus a 3×3-at-game-scale silhouette check catches it before import.
