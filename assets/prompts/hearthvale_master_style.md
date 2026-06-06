# Hearthvale — Master Style Prompt

The single source of truth for Hearthvale's visual identity. Every other prompt
file in `assets/prompts/` inherits from this. When generating in ComfyUI, paste the
**Base Positive** and **Base Negative** blocks first, then append the category
modifiers from the relevant prompt file.

## One-line identity

> Cozy stylized isometric fantasy village — soft painterly, pixel-adjacent, clean
> silhouettes, warm natural light, handcrafted indie-game feel.

## Pillars

- **Readable at game scale.** Forms must survive being shrunk to ~64px tile / ~96px
  prop. Silhouette first, detail second.
- **Soft, not blurry.** Gentle shading and rounded forms, but crisp edges and clear
  separation between shapes.
- **Colorful but grounded.** Warm, slightly desaturated naturals; saturation reserved
  for focal accents (crops, lanterns, UI).
- **Modular & sprite-friendly.** Single objects on flat/neutral backgrounds, isolated,
  consistent angle, ready for background removal and atlas packing.
- **Family-friendly & MMO-friendly.** Whimsical, practical, never gritty.

## Base Positive (paste first)

```
cozy stylized isometric fantasy village asset, soft painterly pixel-adjacent style,
clean readable silhouette, warm gentle lighting, soft ambient occlusion, rounded
handcrafted forms, gentle natural color palette, whimsical but practical, flat
neutral background, single isolated object, consistent 2:1 isometric angle,
crisp edges, game-ready sprite, indie cozy farming game art
```

## Base Negative (paste first)

```
photorealistic, hyperrealistic, 3d render, anime, manga, cel shaded outline-heavy,
over-rendered concept art, busy background, scene composition, multiple objects,
tiny noisy details, high-frequency noise, text, watermark, signature, harsh neon,
gritty, horror, blood, dark survival tone, inconsistent perspective, motion blur,
depth of field, lens flare, dramatic cinematic lighting, unreadable silhouette
```

## Global generation defaults

| Setting | Recommendation |
|---|---|
| Base model | SDXL (cozy/illustration checkpoint) for tiles & props; Flux for hero concepts |
| Resolution | 1024×1024 generation, downscale to target on import |
| Sampler | dpmpp_2m / euler_a, 25–35 steps, CFG 4.5–7 |
| Background | flat neutral (#9aa7a0 grey-green) or pure removable color, never a scene |
| Perspective | 2:1 isometric (≈30° tiles), 3/4 cozy view for characters/creatures |
| Seeds | record the seed in the asset sidecar (see asset_import_standards.md) |

## Palette anchors

- Homestead grass: `#739f67` / `#6f9d63`, path `#b59872`
- Village stone: `#c4b79a` / `#d2c6ab`, warm wood `#a8754a`
- Forest floor: `#557f4d` / `#4f7d44`, pine `#5d8e53` → `#79ab67`
- Water: `#6fa8b0` muted teal
- Focal warm accents: carrot orange `#d98c5a`, lantern gold `#e8d898`

## Do / Don't

| Do | Don't |
|---|---|
| One object, isolated, neutral bg | Full illustrated scenes |
| Strong single silhouette | Floating disconnected bits |
| Consistent iso angle across a set | Mixed perspectives in one atlas |
| Soft gradient + light AO | Hard airbrush gloss / plastic look |
| Leave headroom for cleanup | Bake shadows onto transparent edges |
