# Asset Import Standards — Godot

How cleaned art enters the Godot project so it imports cleanly, stays organized, and
remains traceable to its prompt. Pairs with the broader `docs/asset_pipeline.md`.

## File format

- **Props / characters / creatures / crops / buildings / UI:** PNG, RGBA, transparent
  background, premultiplied-safe (no edge halo).
- **Tiles:** PNG, RGB (opaque) unless the tile intentionally has transparent cutouts.
- **Backgrounds / parallax:** PNG, horizontally-seamless strips.
- No JPG for game assets (artifacts on alpha edges). Source `.psd`/layered files (if
  any) live outside the imported tree or in `assets/concepts/`, not in the category folders.

## Resolution targets (authored at 2× in-engine, downscaled on import)

| Asset | In-engine | Authored / exported |
|---|---|---|
| Ground tile | 64×32 | 128×64 |
| Small prop | 64–96px | 2× |
| Building | per footprint | 2× |
| Crop stage | 48–64px | 2× |
| Creature | 28–48px | 2× |
| Villager | ~66px | 2× |
| UI icon | 32 / 64px | export both 32×32 and 64×64 |

Always generate large (1024²+) and **downscale**; never upscale to fit.

## Consistent isometric angle

- World art: 2:1 isometric, ~30°, light from upper-left, identical across a set.
- Each asset has a defined **ground-contact anchor** (where it meets the tile) so the
  engine `position` aligns. Document the anchor + (for buildings/props) the collision
  rect in the sidecar.

## Naming convention

```
<category>_<name>_<variant>_<state>@<scale>.png
```
Examples: `tile_grass_a.png`, `prop_mailbox.png`, `crop_carrot_grown.png`,
`creature_moss_rabbit_idle.png`, `villager_maribel_front.png`, `ui_icon_comfort_64.png`.

- lower_snake_case, no spaces, ASCII only.
- `state` matches the system enum where relevant (crops: `empty|planted_dry|planted_watered|grown`).
- `@2x` suffix optional if multiple scales are shipped.

## Folder convention

```
assets/
  workflows/comfyui/   ComfyUI .json workflow graph exports (versioned)
  prompts/             prompt templates (versioned)
  style_reference/     pinned reference images / mood boards (curated, few)
  concepts/            raw exploration, layered source (not imported by Godot)
  import_staging/      cleaned PNGs awaiting wiring → then moved out
  tiles/               final ground tiles
  props/               final props / placeables
  characters/          final villagers / player
  creatures/           final creatures
  sprites/             misc / shared sprite atlases
  ui/                  final UI icons
```

Final game assets live in the category folders; `import_staging/` is transient.

## Versioning convention

- Asset revisions bump a suffix: `prop_mailbox_v2.png`, and the old one is removed in
  the same commit (don't accumulate). Significant style reworks note the date + reason
  in the commit and the sidecar.
- Commit **only** final, cleaned, downscaled assets + workflow `.json` + prompts.
  Raw multi-MB generations and upscales are **not** committed.

## Source prompt metadata convention (sidecar)

Every committed game asset ships a sidecar `<asset>.meta.json`:

```json
{
  "asset": "prop_mailbox.png",
  "category": "props",
  "model": "sdxl_cozy_v1",
  "loras": [],
  "prompt_file": "assets/prompts/props.md#homestead-dressing",
  "prompt_overrides": "mailbox with flag up",
  "seed": 123456789,
  "sampler": "dpmpp_2m", "steps": 30, "cfg": 6.0,
  "workflow": "assets/workflows/comfyui/06_prop_sheet.json",
  "anchor": [48, 92],
  "collision_rect": [ -16, -8, 32, 16 ],
  "in_engine_px": 96,
  "manual_cleanup": "alpha matte, unified contact shadow, palette nudge",
  "date": "2026-06-12"
}
```

## Godot import settings

- **Texture filter:** OFF (nearest) for crisp pixel-adjacent assets; ON (linear) only
  for soft backgrounds/parallax. Record the choice per category and apply via a
  shared import preset (`.godot/imported` / `*.import`).
- **Mipmaps:** off for UI/sprites, on for large tiling terrain only.
- **Compression:** lossless for sprites/UI; VRAM-compressed acceptable for big
  backgrounds.
- Keep `import_staging/` files out of scenes until verified in-engine at game scale.

## Manual cleanup notes

See `assets/workflows/comfyui/10_manual_cleanup.md`. Minimum before commit: alpha halo
removed, contact shadow consistent, anchor aligned to siblings, stray noise erased,
palette nudged to anchors, silhouette verified at 24–48px.

## Non-regression

- These are `.md` / `.json` / `.png` files. They do not touch GDScript or scenes, so
  the project must still open with no parser errors. Do not place importable images in
  the project until a category is actually wired; staging keeps WIP out of the engine.
