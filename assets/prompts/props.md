# Prompt Template — Props

Inherits `hearthvale_master_style.md`.

Props are the modular vocabulary of the world (placeables, dressing, landmarks).
They are generated as **prop sheets** (a grid of related items) for efficiency, then
sliced. Each item must be independently isolatable.

## Category modifiers (append to Base Positive)

```
cozy isometric prop, single small object, 2:1 iso angle, clear silhouette,
sits flat on the ground, soft drop of contact shadow, handcrafted, isolated,
evenly spaced prop sheet grid, neutral background, consistent scale and angle
```

## Category negatives (append to Base Negative)

```
scene, ground texture under props, characters, buildings, inconsistent scale,
overlapping objects, dramatic shadow, perspective drift between cells
```

## Prop groups (one sheet each)

- **Homestead dressing:** `crate, stool, hanging lantern, plant pot, mailbox, doormat`
- **Village dressing:** `fountain, notice board, flower bed, barrel, hanging sign, lamp post`
- **Forest dressing:** `mossy rock, mushroom cluster, fallen log, fern, stone cairn, small wooden bridge segment`

## Prop sheet rules

- 3×3 or 4×4 evenly spaced cells, identical iso angle and light direction across all
  cells, generous padding for clean slicing.
- One material family per sheet (wood sheet, stone sheet) keeps lighting consistent.
- Contact shadow is a **separate soft ellipse** the engine can place, OR a very light
  baked shadow that survives background removal — never a hard cast shadow.

## Output expectations

- Generate the sheet at 1024²–1536², slice in the prop-sheet workflow, export each
  prop transparent at **2× target** (most props 96–160px tall in-engine).
