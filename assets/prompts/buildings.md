# Prompt Template — Buildings

Inherits `hearthvale_master_style.md`.

Buildings are landmark silhouettes. They anchor each area, so they need a strong,
instantly-readable shape and a consistent iso footprint that aligns to the grid.

## Category modifiers (append to Base Positive)

```
cozy isometric building, 2:1 iso angle, single structure, grounded footprint,
clear roof and wall planes, warm wood and plaster, soft thatched or shingle roof,
welcoming and lived-in, modular construction, props minimal, isolated on neutral bg
```

## Category negatives (append to Base Negative)

```
interior, cutaway, multiple buildings, town scene, ground tiles, characters,
clutter, ruined, dilapidated horror, exaggerated fantasy castle, floating
```

## Per-building prompts

- **Homestead cottage:** `small cozy farmhouse cottage, warm plaster walls, thatched roof, round door, two glowing windows, flower box, single chimney with soft smoke`
- **Market stall (placeholder):** `simple wooden market stall, striped cloth awning, empty counter, cozy village trade post`
- **Forest shrine (building-scale variant):** `small mossy stone shrine, weathered, gentle glowing rune, tucked in woodland`

## Footprint & alignment

- Author the building to a known tile footprint (cottage = 2×2 tiles). Generate the
  full structure, then in cleanup mark the **ground-contact anchor** (the diamond
  base) so Godot can align `position` to a tile.
- Keep the visual roof overhang *outside* the collision footprint; document the
  collision rectangle in the asset sidecar.

## Output expectations

- 1024² generation, export at **2× target** with transparent background.
- Provide a flat "day/neutral" lighting version; mood tinting is applied in-engine by
  the global mood system, so do **not** bake dusk/morning color into the sprite.
