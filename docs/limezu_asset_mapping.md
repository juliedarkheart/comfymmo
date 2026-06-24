# LimeZu Asset Mapping (logical ids)

LimeZu is the current live visual ecosystem for this branch, with Sprout kept as a
secondary/comparison provider. LimeZu is also still available through the separate
visual spike scene for focused review. All LimeZu media is **local-only** under gitignored
`licensed_assets/limezu/` — nothing here is committed except this doc, the manifest
*template*, the integration tool, and the provider/spike code.

## Live visual policy — LimeZu-family only (2026-06-24 quarantine pass)

Normal local dev **live** mode renders **only** LimeZu-family sources. Old legacy /
procedural / Sprout visuals are quarantined to clean-checkout emergency fallback or
explicit debug mode — they must not appear in the opening view when LimeZu is usable.

- **Allowed live source tiers** (`LiveVisualPolicy.LIVE_ALLOWED_SOURCE_TIERS`):
  `limezu_reviewed`, `limezu_raw` (hand-reviewed raw single-file crops), `limezu_derivative`,
  `limezu_inspired`, `limezu_generated_local`.
- **Disallowed in live mode** (`LIVE_DISALLOWED_SOURCE_TIERS`): `legacy_generated`,
  `procedural` (for world art), `sprout`, `blank`, `missing`, `unknown`, and unreviewed
  random raw sheet cells.
- **Resolution order** (`LimeZuArtRegistry.texture_path`): active manifest → **reviewed
  raw single-file mapping (`RAW_PACK_FALLBACKS`)** → local generator derivative/inspired
  → safe missing fallback. The reviewed raw mapping now wins over the unreviewed generator
  slices for **every** id. *(This is the fence-post-scatter fix: the generator
  `fence_variant` derivative used to out-rank the curated `Wooden_Fence_*` single file and
  many object ids aliased onto it, producing repeated giant fence posts.)*
- **Sprout** is optional / manual / reference-only. The LimeZu live path never auto-mixes
  Sprout, even when local Sprout manifests exist.
- **Raw LimeZu cells must be semantically reviewed** before live use; the curated
  `RAW_PACK_FALLBACKS` map is that review. **Inspired/derivative** outputs are the preferred
  gap-fillers for ids without a reviewed raw mapping.
- **HUD icons**: day/comfort status icons resolve to semantic LimeZu-family icons
  (`icon.day`→`family_calendar_icon`, `icon.comfort`→`comfort_token_icon`, both inspired),
  **never** an empty UI slot/blank texture.
- **Actors/NPCs**: player, Farmer Rowan, and other NPCs render the raw LimeZu farmer frame
  (`Characters_16x16/Farmer_1_16x16.png`), cropped to a 16x32 frame.
- **Known deferrals (allowed, documented):** (1) the ground fill `terrain.grass` resolves to
  the `limezu_derivative` `path_tile_variant` tile — no flat grass single exists in the packs,
  so a reviewed raw grass tile is a follow-up; (2) FarmPlot draws procedural soil/crop
  polygons live until a reviewed LimeZu farm-plot asset replaces them.
- **Enforcement:** `tools/validate_project.gd` fails if any live id resolves to a disallowed
  tier, if the HUD day/comfort icons resolve to a slot/blank, or if distinct world props
  collapse onto one shared texture (the bad-generic-mapping guard). `tools/audit_live_visuals.gd`
  prints the per-id source-tier audit.

## Object contracts + placed-object art (2026-06-24)

- Each live asset id also has a behavior contract in `systems/world/asset_world_metadata.gd`
  (category, collision, F interaction). The crate is now a SOLID storage prop (blocks + "The
  crate is empty."), not pass-through decor — see [docs/playtest_readiness.md](playtest_readiness.md).
- **Placed build objects** (`PlaceableCrate`) render the LimeZu sprite for any placeable that
  maps to a reviewed LimeZu asset (`AssetWorldMetadata.PLACEABLE_TO_ASSET`), anchored exactly
  like the curated world prop. So a placed crate/sign/fence matches the world instead of showing
  legacy planks, and save-restored placements stay visible (`BuildingPlacementSystem` no longer
  hides LimeZu-mapped objects). Collision + interaction are rebuilt from the saved `object_id`.

## Layered player avatar — Character_Generator (2026-06-25)

- The player renders as composited layers from the **Modern Interiors Character_Generator**
  (`2_Characters/Character_Generator/{Bodies,Eyes,Outfits,Hairstyles,Accessories}/16x16`), order
  **body → eyes → outfit → hair → accessory**, every layer region-cropped at the shared 16×32
  idle cell pasted at **(0,0)**. Body sheets are 927×656 (extra 31px right margin, ignored);
  others are 896×656. All layers classify as `limezu_raw`.
- Curated starter parts + Julie default live in the gitignored
  `generator_manifests/hearthvale_curated_avatar_parts_manifest.json`; `CharacterPartLibrary`
  reads it and gates layered mode behind `LAYOUT_VERIFIED` + a live texture-load sanity check.
  `licensed_assets/limezu/review_screenshots/layered_avatar_*` hold the local composite previews.
- NPCs stay on the Modern Farm farmer sheets (Farmer_1/Farmer_2/Body_2); only the player uses the
  layered generator. Clean checkout (no pack) falls back to the full-body farmer sheet.

## Animation + terrain completion (2026-06-24)

- **Terrain:** `terrain.grass` → reviewed solid grass cell `1_Terrains_16x16.png` rect `[48,32,16,16]`
  (Modern Farm terrains autotile); `terrain.dirt_path` → ME dirt single; `terrain.tilled_soil` →
  `Soil_Wet_1`. All three resolve to `limezu_raw`. The old derivative `path_tile_variant` ground is
  retired. A per-id texture cache (`LimeZuArtRegistry._texture_cache`) keeps the 651-tile grass
  ground decoding the source sheet once.
- **Character sheets:** added `character.farmer2_idle` + `character.body2_idle` raw frames;
  `LimeZuArtRegistry.resolve_full_sheet()` returns the uncropped sheet for region/animation use.
  Reviewed directional frames + hand sockets live in `CharacterAnimationRegistry` (down/up wired,
  side mirrored; full walk cycles deferred).
- **Animation catalog:** `tools/audit_limezu_animations.gd` scans the character/animal folders and
  writes the gitignored `generator_manifests/limezu_animation_manifest.json` (frame counts, dims,
  likely directions, usable-now flag). Cow/chicken animation sheets exist and are cataloged for a
  later light-idle pass; the live animals are static-with-collision for now.

## How it works

1. The licensed packs live under `licensed_assets/limezu/<pack>/original/` (zips +
   `.exe` generators). Packs: `modern_farm`, `modern_ui`, `modern_exteriors`,
   `modern_interiors`, `modern_office`, `fungus_cave`, `rpg_arsenal`.
2. `python tools/art/limezu_integrate.py --all` extracts each zip into
   `<pack>/extracted/`, writes a per-pack `manifests/inventory.json`, sampled
   `contact_sheets/<category>.png`, and `manifests/candidates.json` (logical-id →
   candidate source files), and creates an empty local
   `licensed_assets/limezu/limezu_active_manifest.json`. A `.gdignore` is placed in
   `original/`, `extracted/`, `contact_sheets/`, and `manifests/` so Godot never
   imports the thousands of raw licensed PNGs (only `normalized/` + `modified/` are
   importable).
3. A human reviews the contact sheets + candidates, copies/normalizes the chosen
   cells into `<pack>/normalized/...`, and maps logical ids in the **local**
   `limezu_active_manifest.json` (gitignored).
4. `systems/art/limezu_art_registry.gd` resolves logical ids to local files; the
   spike scene (`scenes/visual_spikes/limezu_homestead_slice.tscn`) renders them.
   Missing ids fail safe instead of crashing, and live boot falls back to committed visuals.

## Manifest format (local, gitignored)

```json
{
  "provider": "limezu",
  "active": {
    "terrain.grass": "modern_farm/normalized/terrain/grass.png",
    "ui.panel": "modern_ui/normalized/ui/panel.png"
  }
}
```

Values are relative to `licensed_assets/limezu/` (or a full `res://` path). The
tracked template `tools/art/templates/limezu_manifest_template.json` keeps `active`
empty and documents every logical id.

## Logical ids

Terrain: `terrain.grass`, `terrain.dirt_path`, `terrain.tilled_soil`, `terrain.water`.
Objects: `object.house`, `object.barn`, `object.fence`, `object.tree`,
`object.crop_carrot`, `object.crop_wheat`, `object.chest`, `object.mailbox`,
`object.workbench`.
Animals: `animal.chicken`, `animal.cow`, `animal.dog`.
Characters: `character.player_idle`.
UI: `ui.panel`, `ui.inventory_panel`, `ui.button`, `ui.button_hover`, `ui.slot`,
`ui.slot_selected`, `ui.tab`, `ui.dialogue_box`, `ui.quest_box`, `ui.close`,
`ui.close_hover`. (`ui.quest_box` is visual-only — no quest gameplay is added.)
Icons: `icon.seed`, `icon.carrot`, `icon.wood`, `icon.stone`, `icon.tool_hoe`,
`icon.tool_axe`.
Cave: `cave.floor`, `cave.wall`, `cave.fungus_creature`.

## Mapped spike ids (local, this pass)

30 ids are mapped to real Modern Farm art via
`tools/art/limezu_slice_spike_assets.py --all` (writes `modern_farm/normalized/spike/`
+ updates the local `limezu_active_manifest.json`):

- **terrain.*** grass, dirt_path, water (uniform-fill cells auto-picked from
  `1_Terrains_16x16.png`), tilled_soil (`Soil_Wet_1` single file).
- **object.*** barn, tree, tree_small, fence_horizontal/vertical/post, flower/flower2/
  flower3, crate, sign — all complete single files from `0_Complete_Tileset_Singles_16x16`.
- **crop.*** carrot, carrot_stage1, cauliflower, watermelon — complete `Crop_*` singles.
- **animal.*** chicken, cow — first frame sliced + trimmed from the animation sheets.
- **character.farmer_idle** — first non-empty 16×32 frame from `Farmer_1_16x16`.
- **icon.*** carrot, seed, wood, tool_axe, tool_watering_can, tool_shovel, egg, cheese
  — `Icons_16x16_Singles` files.

Re-generate any time with `python tools/art/limezu_slice_spike_assets.py --root licensed_assets/limezu --all`.
Modern UI review now maps compact runtime controls (`ui.slot`, `ui.slot_selected`,
`ui.button`, `ui.button_hover`, `ui.close`, `ui.close_hover`, and `ui.tab`) plus panel
runtime panel/control slices. Live panels, HUD cards, slots, buttons, close buttons,
and tabs use the texture slices; layouts are kept compact so their small source size
fits the UI.

## Rules

- Never commit LimeZu zips, `.exe` generators, extracted PNGs/GIFs, normalized or
  modified derivatives, contact sheets, or the local activation manifest.
- Never write LimeZu media into `art/`, `scenes/`, or any tracked path.
- A clean checkout without LimeZu must not crash; live boot falls back to committed
  generated/procedural visuals.
