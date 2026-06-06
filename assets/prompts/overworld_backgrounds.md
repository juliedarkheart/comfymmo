# Prompt Template — Overworld Backgrounds

Inherits `hearthvale_master_style.md`.

These are the **distant / non-interactive** layers that fill the continuous overworld
beyond the playable strip (the backdrop, region tints, and natural borders currently
drawn procedurally in `world/overworld_map.gd`). They imply a larger world without
needing collision or detail.

## Category modifiers (append to Base Positive)

```
distant cozy landscape backdrop, soft atmospheric depth, low detail far terrain,
gentle layered silhouettes, calm muted distance palette, horizontal parallax band,
no focal subject, tileable horizontally, painterly soft
```

## Category negatives (append to Base Negative)

```
foreground detail, characters, readable props, busy, high contrast, sharp focus,
playable-looking objects, isometric tile grid, hard edges
```

## Background layers

- **Far backdrop fill:** `soft hazy meadow-and-sky gradient, warm calm, very low detail`
- **Northern mountains:** `distant rolling mountain range silhouette, soft grey-blue layers, gentle haze`
- **Eastern dense forest wall:** `deep distant pine forest mass, layered greens, soft depth`
- **Southern river band:** `wide calm river ribbon, muted teal, soft reflective sheen`
- **Western cliffs:** `soft eroded cliff face, warm grey stone, gentle moss`

## Composition rules

- Built as **horizontal parallax bands** that tile left-right (the overworld is a
  wide strip). Keep each band low-contrast so it never competes with the playable
  midground.
- Deliver each border as a long strip (e.g. 2048×512) with horizontally-seamless ends.
- These replace/augment the procedural `_build_natural_borders()` / backdrop shapes —
  keep the procedural version as a fallback until art is wired.

## Output expectations

- Generate wide (e.g. 1536×640) tiles, export horizontally-seamless strips, downscale
  to the parallax layer's working size. Far layers can be lower resolution.
