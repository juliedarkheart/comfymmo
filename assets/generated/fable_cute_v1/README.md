# Fable Cute v1 — generated art kit

Hand-generated vector-style assets for the cozy "toy village" visual overhaul
(branch `art/fable-cute-overhaul-v1`). Everything here is original, repo-safe,
text-format SVG that Godot 4 imports natively as `Texture2D` — no binary art,
no external tools, no copyrighted material.

Style rules for anything added to this kit:
- Rounded, chunky silhouettes; soft toy-like proportions.
- Warm pastel fills with a darker same-hue outline (~3px at 64x64).
- One small highlight per shape, no gradients, no noise.
- Must read clearly at 24px in the HUD and on 4K displays.

## Contents

- `ui/` — HUD icons (64x64 SVG): comfort heart, day/time sun, inventory basket,
  mailbox, carrot, turnip, berry. Wired into `ui/prototype_hud.tscn`.
- `props/` — reserved. World props (mailbox, crate, lantern, farm plots,
  shrine, notice board, fountain, cottage) currently stay procedural
  (Polygon2D in `world/*.gd` and `scenes/buildings/*.tscn`) because they carry
  collision shapes and y-sort behaviour; swapping them for sprites is a later
  milestone. TODO: sprite versions once silhouettes are final.
- `creatures/` — reserved. Moss rabbit / lantern moth / stump turtle are
  procedurally drawn and animated in `creatures/*.gd`; replacing them with
  textures would lose the hop/flutter/wobble animation joints. TODO: revisit
  with AnimatedSprite2D sheets.
- `terrain/` — reserved. Ground is procedural iso diamonds + TerrainShapes
  ribbons/discs; texture tiles are a later milestone.
