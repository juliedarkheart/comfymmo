# Prompt Template — UI Icons

Inherits `hearthvale_master_style.md`, with one deliberate exception: UI may use
slightly higher saturation and crisper rim light for legibility on the HUD.

## Category modifiers (append to Base Positive)

```
cozy game ui icon, single centered symbol, bold clean silhouette, flat soft shading,
gentle inner gradient, subtle rim light, consistent icon set, square framing with
padding, neutral or transparent background, readable at 32px, warm friendly
```

## Category negatives (append to Base Negative)

```
realistic, photoreal, scene, multiple symbols, tiny details, busy, text label,
3d bevel overload, drop shadow heavy, inconsistent style across set, harsh outline
```

## Icon set (one consistent batch)

Generate as ONE sheet so style/light/scale match exactly:

- **Mailbox** — small mailbox with flag up (matches mail/new-mail signal)
- **Inventory** — open satchel or basket
- **Comfort** — soft heart / hearth flame (cozy stat)
- **Day / time** — small sun-and-moon or calendar leaf (mood/day line)
- **Crop icons** — carrot, turnip, berry (match inventory counts)

## Consistency rules

- Single shared light direction (top-left), single shared corner radius and padding.
- Two-tier readability: full-color at 64px, must still read as a silhouette at 24px.
- UI accent saturation is allowed; avoid full neon except intentional alert states.

## Output expectations

- Generate at 1024² sheet, export each icon transparent and square at **64×64** and
  **32×32** (both, for HUD scaling). Icons live in `assets/ui/` and import as
  `Texture2D` with **filter off** if pixel-crisp, or on if soft — decide per set and
  record it (see asset_import_standards.md).
