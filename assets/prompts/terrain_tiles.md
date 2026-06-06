# Prompt Template — Terrain Tiles

Inherits `hearthvale_master_style.md` (paste Base Positive + Base Negative first).

Terrain is the highest-volume, most readability-critical art. Tiles must tessellate
in a 2:1 isometric grid (64×32 logical, generated larger and downscaled) and read
calmly so props/characters pop on top.

## Category modifiers (append to Base Positive)

```
seamless isometric ground tile, 2:1 diamond tile, top-down 30 degree iso angle,
flat tileable texture, subtle organic variation, low contrast, no focal point,
even lighting, edge-safe for tiling
```

## Category negatives (append to Base Negative)

```
prop, object, building, character, strong shadow, directional light, vignette,
seams, hard tile borders, repeating obvious pattern
```

## Per-tile prompts

- **Grass (homestead):** `soft warm meadow grass, gentle green #739f67, faint clover and blade variation`
- **Dirt path:** `packed earth path, warm tan #b59872, soft pebble speckle, worn cozy trail`
- **Plaza stone (village):** `weathered flagstone, warm grey #c4b79a, soft mortar lines, swept clean`
- **Forest floor:** `shaded woodland floor, deep green #557f4d, scattered needles and moss`
- **Creek water:** `shallow calm creek water, muted teal #6fa8b0, gentle ripple, soft caustics`

## Output expectations

- Generate 1024², export the tileable center crop, downscale to **128×64** master
  (2× the in-engine 64×32 for crisper mip).
- Provide 2–3 variants per tile type for non-obvious repetition.
- Keep value range tight (mid-tones); terrain should never out-contrast props.

## Tiling workflow note

ComfyUI: enable seamless/tiling mode on the KSampler (or use a tiling VAE / circular
padding node). Validate by tiling 3×3 in an image editor before downscale. See
`docs/art_pipeline/comfyui_workflows.md` → "Isometric tile workflow".
