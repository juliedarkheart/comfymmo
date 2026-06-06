# Hearthvale Art Style Guide

The art bible. Pairs with `assets/prompts/hearthvale_master_style.md` (the prompt
form of these rules). When a generated asset and this guide disagree, the guide wins.

## Identity

Cozy stylized isometric fantasy village. Soft painterly, pixel-adjacent. Handcrafted
indie warmth, MMO-friendly, family-friendly. The feeling target: *"I finished a cozy
little day."*

## The five rules

1. **Silhouette first.** If it doesn't read as a black shape at game scale, it fails.
2. **Soft, not blurry.** Gentle shading, crisp edges, clear shape separation.
3. **Colorful but grounded.** Warm, slightly desaturated naturals; saturation for focal accents only.
4. **Consistent perspective.** 2:1 isometric (~30°) for world/tiles/props; 3/4 cozy view for characters/creatures. Never mix within a set.
5. **Modular & neutral.** One object, isolated, neutral/removable background, consistent anchor — ready to atlas.

## Perspective & scale

- **Tiles:** 2:1 isometric diamond, in-engine 64×32 (authored/exported at 2× = 128×64).
- **Props:** stand on the tile, soft contact shadow, ~96–160px in-engine.
- **Buildings:** grid-aligned footprint (cottage 2×2 tiles), roof overhang outside collision.
- **Creatures:** ~28–48px, toyetic, rounded.
- **Villagers:** ~66px, strong single feature each.
- **UI icons:** read at 32px and 24px silhouette.

## Color

- Anchor palette lives in `hearthvale_master_style.md` (homestead green, village
  stone/wood, forest greens, muted water, warm accents).
- **Region separation by hue/value:** homestead = warm meadow green; village = warmer
  tan/stone; forest = cooler, darker green. The continuous overworld leans on this.
- **Do not bake time-of-day lighting** into sprites. The global mood system tints the
  world (morning gold / afternoon clear / dusk purple) at runtime; ship neutral/day art.

## Lighting

- Single soft key from upper-left, gentle ambient fill, light contact AO.
- No dramatic cinematic light, rim-blasts, lens flare, or hard cast shadows.

## Readability checklist (every asset)

- [ ] Reads as a clean silhouette at game scale (do the 24–48px squint test).
- [ ] Edges crisp; no AI halo or fuzz on the alpha.
- [ ] Palette nudged toward Hearthvale anchors.
- [ ] Perspective matches its set.
- [ ] Neutral/day lighting (no baked dusk).
- [ ] Consistent ground-contact anchor with its siblings.

## Anti-patterns (auto-reject)

- Photoreal / 3D-render look, anime overload, over-rendered concept art that can't
  become an asset.
- Tiny noisy detail, AI mush, unreadable or floating silhouettes.
- Inconsistent perspective across an atlas, harsh neon (except intentional UI alerts),
  gritty / survival-horror tone.

## Consistency-over-time discipline

- Lock the SDXL checkpoint + LoRAs per asset category; record them in sidecars.
- Generate related assets in **one sheet/batch** so light and scale match.
- Re-run the master style prompt as the base every time; never freehand the style.
