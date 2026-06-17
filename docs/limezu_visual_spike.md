# LimeZu Visual Spike — Feature Coverage Report

> **Update:** the evaluation succeeded and LimeZu is **now the live visual provider**
> — the live game opens into a curated LimeZu homestead (see
> docs/limezu_live_pivot_plan.md). This document remains the coverage/feature report;
> this standalone spike scene is kept as the art/style reference. Sprout stays
> integrated as a secondary/comparison provider.

LimeZu ("Modern" ecosystem) was **evaluated** as a possible new main visual direction
for Hearthvale. This work extracted + cataloged the local packs, added a LimeZu art
provider + a visual spike scene, and assessed coverage. All LimeZu media stays
local-only under gitignored `licensed_assets/limezu/`.

## Packs found & extracted (all succeeded)

| Pack | Zip | Files extracted | Dominant categories (cataloged) |
|------|-----|-----------------|----------------------------------|
| modern_farm | Modern_Farm_v1.2.zip | 8,096 | terrain 2578, buildings 1503, crops 1492, animals 467, animation 439, characters 264, icons 215 |
| modern_exteriors | modernexteriors-win.zip | 40,483 | buildings 38,683, office 1061, characters 213, ui 162, autotiles 84 |
| modern_interiors | moderninteriors-win.zip | 52,969 | interiors 50,221, characters 2706 |
| modern_office | Modern_Office_Revamped_v1.2.zip | 1,055 | office 1044, interiors 11 |
| modern_ui | modernuserinterface-win.zip | 982 | ui 982 (16/32/48px + Animated + Portrait_Generator) |
| fungus_cave | Fungus Cave [16x16].zip | 79 | characters 70 (fungus creatures), cave 9 |
| rpg_arsenal | Fantasy Battlers - Complete.zip | 251 | characters 251 (monster/enemy battler sheets) |

Two `.exe` generators (Farmer Generator, Character Generator) are present but **not**
extracted (skipped — only `.zip` is unzipped). Category counts are heuristic
(keyword-on-path) — see each pack's local `manifests/inventory.json`.

Output locations (all local/gitignored):
- Extracted: `licensed_assets/limezu/<pack>/extracted/` (`.gdignore`d — Godot does not import these).
- Inventory: `licensed_assets/limezu/<pack>/manifests/inventory.json`.
- Candidates: `licensed_assets/limezu/<pack>/manifests/candidates.json`.
- Contact sheets: `licensed_assets/limezu/<pack>/contact_sheets/<category>.png`.
- Active manifest: `licensed_assets/limezu/limezu_active_manifest.json` (4 reviewed icons mapped so far).

## Usefulness for Hearthvale features (honest)

- **Farming / homestead:** ✅ Strong. modern_farm has terrain, crop growth stages,
  farm buildings, livestock, vehicles, and **individual icon singles** (crops,
  seeds, tools, resources). Best single pack for the core loop.
- **Building / village / outdoor:** ✅ Strong. modern_exteriors is huge (38k building
  tiles) — houses, roofs, walls, fences, streets. Plenty for a village.
- **Interiors / player housing:** ✅ Strong. modern_interiors is the largest pack
  (50k interior tiles) + thousands of character sprites (the generator output).
- **Real-life task / work rooms (office):** ✅ Good. modern_office (desks, computers,
  office furniture) fits "real-life task room" spaces.
- **UI / inventory / dialogue:** ✅ Strong. modern_ui is a dedicated kit at 16/32/48px
  with animated elements and a portrait generator — clearly enough for HUD, panels,
  slots, buttons, and dialogue boxes. (Quest box = visual only; no quest gameplay.)
- **Icons / rewards:** ◑ Partial. Good crop/seed/tool/resource icons live in
  **modern_farm** (mapped 4 already). The pack literally named "RPG Arsenal" here is
  **Fantasy Battlers** — monster/enemy character sheets, **not** item/reward icons.
- **Taming / domestic animals:** ◑ Mixed. modern_farm covers normal farm livestock
  (chickens, cows, etc.) well. There is **no dedicated tameable-companion art**; the
  "creatures" available are farm animals (domestic) or enemy/monster battlers.
- **Wild / fantasy taming:** ⚠ Weak. fungus_cave (70 fungus-creature sheets) and
  rpg_arsenal (251 fantasy battlers) are **enemies/monsters**, not designed cozy
  tameable companions. Usable as fantasy creatures, but taming is a design+art gap.
- **Dungeons / caves:** ⚠ Weak as a tileset. fungus_cave has only ~9 cave tiles
  (mostly creature sheets); modern_exteriors has some rock/cave-tagged tiles. A cozy
  dungeon would need a fuller cave tileset (custom or another pack).

## Can LimeZu support the larger Hearthvale project?

**Yes for the cozy-life core** (farming, building, village, interiors, office rooms,
UI/inventory). LimeZu's Modern ecosystem is consistent, large, and higher-fidelity
than the current Sprout slice, and it has a true dedicated UI kit. The main gaps are
**creature taming/companions**, **cozy dungeon/cave tilesets**, and a distinct
**Hearthvale identity** — those still need custom or supplementary art.

## What still needs custom art later

- Tameable companion creatures (LimeZu only ships farm animals + monster battlers).
- A cohesive cozy dungeon/cave tileset.
- Hearthvale-specific landmarks / story props.
- Sliced, reviewed tile/object/UI derivatives: the packs are big spritesheets, so
  terrain/objects/UI panels must be **cut from sheets** into `normalized/` and mapped
  in `limezu_active_manifest.json` before the spike renders them (the spike currently
  shows labelled missing markers for unmapped logical ids, plus 4 real mapped icons).

## Real-art spike pass (30 ids mapped)

The spike now renders **real LimeZu Modern Farm art** (not markers). Sliced/copied by
`tools/art/limezu_slice_spike_assets.py` into `modern_farm/normalized/spike/` and
mapped in the local `limezu_active_manifest.json`. Source pack: **modern_farm** for all
30. Verified live (`30/30 spike ids resolve`, captured screenshot at
`licensed_assets/limezu/review_screenshots/limezu_homestead_slice.png`).

| Category | ids | how |
|----------|-----|-----|
| terrain (4) | grass, dirt_path, water, tilled_soil | grass/dirt/water = most-uniform opaque cell of the right hue picked from `1_Terrains_16x16.png`; tilled_soil = `Soil_Wet_1` single file |
| object (11) | barn, tree, tree_small, fence_horizontal/vertical/post, flower×3, crate, sign | complete single files from `0_Complete_Tileset_Singles_16x16` (`Barn_Small`, `Fruit_Tree_Apple_Ripe`, `Wooden_Fence_*`, `Grass_Tufts_Flowers_*`, `Crate_Brown_Apples`, `Sign_Carrot`) |
| crop (4) | carrot, carrot_stage1, cauliflower, watermelon | complete single `Crop_*_Ripe/Stage_1` files |
| animal (2) | chicken, cow | first frame sliced from `Chicken_Brown_16x16` (16×16) / `Cow_16x16` (32×32), alpha-trimmed |
| character (1) | farmer_idle | first non-empty 16×32 frame sliced from `Farmer_1_16x16` atlas |
| icon (8) | carrot, seed, wood, tool_axe, tool_watering_can, tool_shovel, egg, cheese | single `Icons_16x16_Singles` files |

**Single-file vs sliced:** 26 are complete single files (copied as-is); 4 are sliced
(grass/dirt/water cells + the 3 animal/character first-frames). No blind cell guessing
— terrain uses uniform-fill detection, actors use first-non-empty-frame detection.

**Still needs manual review:** Modern **UI** panel/slot/button 9-patch frames. Modern
UI ships as big style sheets (`Modern_UI_Style_1.png` 976×688); a 16px review grid was
written to `modern_ui/contact_sheets/style1_16grid.png` and candidate element boxes
were logged, but slicing a clean 9-patch panel/slot is left for visual review rather
than guessed. The inventory mock therefore uses **real LimeZu item icons** in a clean
compact frame (not a Sprout/parchment wall, not debug) — it already looks better than
the current live Sprout inventory; swapping in sliced Modern UI frames is the next step.

### Honest assessment (this pass)

- **Modern UI replacing Sprout UI:** promising — the icon grid + compact window read
  well, and Modern UI is a true dedicated kit. But the panel/slot frames still need
  slicing before a fair head-to-head; not yet proven, but on track.
- **Modern Farm for farming/homestead:** yes — terrain, crops, trees, fences, barn,
  farmer, and animals all came from this one pack and compose a coherent farm.
- **Exteriors/Interiors for a live pivot:** likely needed for a real village/housing
  (Modern Farm alone covers the homestead; exteriors=38k building tiles,
  interiors=50k tiles cover town + indoors). Not used in this farm spike.
- **Animals for a first taming prototype:** good for *domestic* animals (chicken, cow,
  dog, etc. are clean and animated). No tameable-companion/creature design art.
- **Fantasy/tameable creatures gap:** unchanged — `rpg_arsenal` is Fantasy Battlers
  (enemy/monster sheets), `fungus_cave` is fungus creatures + ~9 cave tiles. Neither
  is a cozy-companion taming set; that remains a custom-art gap.

## Spike status

`scenes/visual_spikes/limezu_homestead_slice.tscn` composes a homestead via
`LimeZuArtRegistry` logical ids. With assets unmapped it shows clear per-id markers;
with the 4 mapped Modern-Farm icons it renders real LimeZu art in the Modern UI
inventory mock. It never mixes Sprout and never crashes when assets are missing.
