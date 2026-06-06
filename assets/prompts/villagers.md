# Prompt Template — Villagers

Inherits `hearthvale_master_style.md`.

Villagers are cozy, warm, readable characters with strong silhouettes and a single
memorable feature each. Generated as **character concept sheets** to support a
facing flip and gentle idle bob (matching the current `SimpleVillager` behavior).

## Category modifiers (append to Base Positive)

```
cozy stylized villager character, warm friendly, simple readable outfit, single
memorable feature, clean silhouette, 3/4 cozy view, full body standing, single
character, neutral background, consistent character turnaround, soft warm light,
family friendly, wholesome indie game npc
```

## Category negatives (append to Base Negative)

```
realistic face, anime, sexualized, armor, weapon, multiple characters, scene,
celebrity likeness, gritty, horror, exaggerated proportions beyond cozy chibi,
inconsistent design between views
```

## Character sheets (one per villager)

- **Maribel Tock** — calendar keeper / town helper:
  `warm middle-aged woman, rust dress with amber apron, hair in a side bun, half-frame
  reading glasses, small brass clock brooch, organized and kind`
- **Bram Nettle** — gentle groundskeeper / plaza gardener:
  `sturdy outdoorsy man, olive work jacket, wide-brim hat, light stubble, belt with
  buckle, practical and easygoing`

## Sheet layout

Front 3/4, side (facing flip reference), back optional, plus a head close-up for
expression. Identical height, scale, and light across views. Neutral relaxed pose.

## Animation handoff

- Match the procedural placeholder palettes/features in `villagers/*.gd` and the
  scene exports (`scenes/villagers/*.tscn`) so the swap is drop-in.
- Keep the brooch/glasses/hat as separable accents if cheap, for future expression
  variety.

## Output expectations

- Sheet at 1024²–1536², export each view transparent at **2× target** (villagers
  ~66px tall in-engine). Consistent ground-contact anchor for the idle bob.
