# Prompt Template — Crops

Inherits `hearthvale_master_style.md`.

Crops are tiny, high-frequency, **stateful** sprites. Readability of *growth stage*
at a glance is the whole job. Each crop needs a consistent set of stages that share
silhouette family but clearly differ.

## Category modifiers (append to Base Positive)

```
cozy isometric crop sprite, single plant in soil, top-down 2:1 iso angle,
clear growth stage, bright readable focal color, small tidy form, isolated,
consistent across a stage row, neutral background
```

## Category negatives (append to Base Negative)

```
field, multiple plants, landscape, characters, basket, harvested pile, realistic
botany detail, wilted horror, oversized
```

## Stage set (generate as one row per crop)

Each crop = 4 stages, left to right, identical angle/scale/light:

```
stage 1 empty tilled soil mound,
stage 2 small sprout seedling,
stage 3 leafy mid-growth,
stage 4 ripe ready-to-harvest with visible crop
```

- **Carrot:** ripe = orange `#d98c5a` shoulders peeking from soil, green feathery top.
- **Turnip:** ripe = purple-white bulb `#b58fd0` shoulder, broad leaves.
- **Berry:** ripe = small bush with red/pink berries `#d98c82`, rounded.

## Output expectations

- The in-engine `FarmingSystem` uses states `empty → planted_dry → planted_watered →
  grown`. Map art stages: stage1→empty, stage2→planted_dry, stage3→planted_watered,
  stage4→grown.
- A separate **watered-soil overlay** (darker damp soil) is generated once and reused
  across crops.
- Export each stage transparent at **2× target** (~48–64px), aligned to the same
  anchor so stages don't jump.
