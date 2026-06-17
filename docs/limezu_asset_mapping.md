# LimeZu Asset Mapping (logical ids)

LimeZu is being **evaluated** as a possible future main visual ecosystem for
Hearthvale. Sprout remains the live provider; LimeZu is wired only through a separate
visual spike for now. All LimeZu media is **local-only** under gitignored
`licensed_assets/limezu/` — nothing here is committed except this doc, the manifest
*template*, the integration tool, and the provider/spike code.

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
4. `systems/art/limezu_art_registry.gd` resolves logical ids → local files; the spike
   scene (`scenes/visual_spikes/limezu_homestead_slice.tscn`) renders them. Missing
   ids show a clear missing-assets marker instead of crashing.

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
UI: `ui.panel`, `ui.button`, `ui.slot`, `ui.dialogue_box`, `ui.quest_box`,
`ui.close`. (`ui.quest_box` is visual-only — no quest gameplay is added.)
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
UI (`ui.panel/ui.slot/ui.button/ui.close`) is **not yet mapped** — Modern UI ships as
big style sheets; a 16px review grid (`modern_ui/contact_sheets/style1_16grid.png`) and
candidate element boxes were generated for manual selection. `--analyze-ui` re-prints them.

## Rules

- Never commit LimeZu zips, `.exe` generators, extracted PNGs/GIFs, normalized or
  modified derivatives, contact sheets, or the local activation manifest.
- Never write LimeZu media into `art/`, `scenes/`, or any tracked path.
- A clean checkout without LimeZu must not crash; the spike shows a missing-assets
  message and the live Sprout game is unaffected.
