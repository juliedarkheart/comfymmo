# Fable Cozy v2 — character & world overhaul kit

Asset and style kit for the `art/fable-character-world-overhaul-v1` pass.
Everything is original, repo-safe, text-format (SVG / GDScript-drawn) — no
binary art, no external tools, nothing derivative of any commercial game.

## Palette (shared with `CharacterAppearanceRegistry.palette()`)

| id | hex | use |
|---|---|---|
| blush_pink | `#e8a0b4` | flowers, awnings, accents |
| moss_green | `#7da964` | default outfit, moss, leaves |
| sky_blue | `#8ab8d8` | water accents, notes |
| warm_brown | `#8a5a3a` | hair, wood, doors |
| lavender | `#b49ad0` | flowers, turnip accents |
| cream | `#f2e4c8` | shirts, paper, stem/speckles |
| terracotta | `#c87858` | mushroom caps, tiny hat, tunics |

Skin tones: peach `#f2c9a8`, honey `#d9a877`, umber `#9c6b4a`.
Supporting world tones: walls `#f2dfb8`, roof `#c97a6a`, trim `#d2ab7e`,
canopy `#6f9c5f` + highlight `#8cba74`, stone `#a8a49c`.

## Character style rules

- Chibi proportions: head ≈ half of total height, feet at y=0.
- Built from smooth ellipses (`CharacterVisualBuilder.ellipse`, 16 segments)
  — never hard diamonds for organic parts.
- Face: big dark dot eyes + white sparkle, blush ellipses, tiny smile.
- One silhouette read per character: hair shape + outfit shape carry identity.
- All characters (player + villagers) go through
  `systems/character/character_visual_builder.gd`; villager-specific details
  (glasses, brooch, stubble) are layered on in `_decorate()` overrides.

## Avatar part rules

- Slots: body_style, skin_tone, hair_style, hair_color, outfit_style,
  outfit_color, accessory, face_style — stable ids only, defined in
  `systems/character/character_appearance_registry.gd`.
- New options must: keep the silhouette readable at gameplay zoom, use the
  shared palette, and degrade safely (unknown ids fall back to defaults via
  `CharacterAppearance.normalized()`).

## UI style rules (carried from fable_cute_v1)

- Cream-on-warm-brown rounded panels (StyleBoxFlat, 16px radius, 3px border).
- 64x64 SVG icons, pastel fill + darker same-hue ~3px outline, one highlight.
- HUD icons live in `assets/generated/fable_cute_v1/ui/` and stay wired.

## Contents & wiring status

- `characters/avatar_default_reference.svg` — design spec for the default
  avatar. NOT wired; the in-game avatar is drawn by the visual builder.
- `buildings/cottage_reference.svg` — design spec for the homestead cottage.
  NOT wired; in-game cottage is drawn in `world/homestead_map.gd`.
- `ui/`, `terrain/`, `props/`, `creatures/`, `environment/` — reserved for
  future sprite exports once silhouettes are final.

## Import notes

SVGs import via Godot's native ThorVG importer as `Texture2D`. Reference SVGs
get `.import` sidecars too — harmless; commit them.

## Future character customization

Runtime/default-only today. Planned save shape: `player.appearance` dict of
ids inside the existing player save section, normalized on load so old saves
(no appearance key) and future saves (unknown ids) both resolve to safe
defaults. See `docs/character_customization.md`.

## Future ComfyUI / art pipeline

When a raster pipeline arrives, these reference SVGs + the palette table are
the prompt/style contract. Generated sprites should land in this folder tree,
go through manifest validation (`tools/validate_asset_manifests.ps1`), and
replace procedural drawers one prop at a time — never as a mass swap.
