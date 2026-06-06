# Prompt Template — Creatures

Inherits `hearthvale_master_style.md`.

Hearthvale creatures are cozy, non-threatening ambient life. They are generated as
**concept sheets** (multiple poses/angles) to support simple in-engine animation
(idle, hop/flutter, facing flip). Toyetic, rounded, readable silhouette is key.

## Category modifiers (append to Base Positive)

```
cozy whimsical creature, toyetic rounded design, soft fur or smooth body, big gentle
eyes, friendly non-threatening, clean silhouette, 3/4 cozy iso view, single creature,
neutral background, consistent character sheet, soft warm light
```

## Category negatives (append to Base Negative)

```
scary, fanged, aggressive, realistic anatomy, gory, armored monster, multiple
creatures, scene, riding gear, weapon, oversized, inconsistent design between poses
```

## Creature concept-sheet layout

One sheet per creature: front 3/4, side (for facing flip), idle, action pose
(hop / wing-flutter), plus a small turnaround swatch. Identical scale and light.

- **Moss rabbit:** `small round rabbit, mossy grey-green fur #b4a485, soft ears, tiny tail, sleepy friendly`
- **Stump turtle:** `tiny slow turtle with a mossy tree-stump shell, sleepy half-closed eyes, stubby legs`
- **Lantern moth:** `small glowing moth, translucent pale-green wings, soft gold lantern glow at the body, gentle`
- **Berry fox cub (future):** `tiny fox cub, warm russet, berry-stained paws, curious`
- **Puffbird (future):** `round puffy little bird, soft pastel, oversized fluff`

## Animation handoff

- Provide separable parts where the engine animates (rabbit ears, moth wings, turtle
  head/shell) on their own transparent layers if cheap; otherwise deliver clean poses
  the animator can cut.
- Match the existing procedural placeholder palettes (see `creatures/*.gd`) so the
  swap is seamless.

## Output expectations

- Sheet at 1024²–1536², export each pose transparent at **2× target** (creatures
  ~28–48px in-engine). Keep the contact point at a consistent anchor.
