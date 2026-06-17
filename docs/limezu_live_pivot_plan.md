# LimeZu Live Pivot Plan

Plan for moving Hearthvale's **live** visual provider from Sprout to LimeZu.

> **STATUS: PIVOTED.** `ArtProviderRegistry.LIVE_PROVIDER == "limezu"`. The live
> overworld opens into a curated LimeZu slice (`OverworldMap._build_limezu_slice()`),
> the UI re-skins to Modern UI (`CozyUITheme._ui_box`), and live human actors use the
> LimeZu farmer (`CharacterArtRegistry`). Validation + offline/server boot pass. Sprout
> stays integrated as a secondary/comparison provider (not deleted). Gameplay
> (movement/placement/farming/delete-twice/data/networking) is unchanged. The sections
> below record the plan; the checklist items in scope this pass are done, the rest
> (full-world LimeZu beyond the opening slice, Exteriors/Interiors tiling, Modern UI
> buttons/close, creature/dungeon art) remain follow-ups.

## Why LimeZu looks better for Hearthvale

The LimeZu visual spike (`scenes/visual_spikes/limezu_homestead_slice.tscn`) renders a
coherent, higher-fidelity Modern pixel-art homestead from a single pack (Modern Farm)
plus a real Modern UI kit — clean grass, a barn focal point, apple trees, a fenced
tilled garden with crops, farmer/chicken/cow, and a Modern-UI-framed inventory with
real item icons. It reads as a polished farming game; the Sprout curated slice was
flatter and more procedural. LimeZu also has dedicated UI, exteriors, interiors, and
office packs that cover far more of Hearthvale's scope.

## Live systems that must change to pivot (visual only)

- **Visual provider selection** — flip `ArtProviderRegistry.LIVE_PROVIDER` to
  `"limezu"` and route the live renderer/registries through the LimeZu provider for
  the selected ids (behind the flag, with Sprout as fallback).
- **Terrain ids** — map the live terrain ids (meadow/grass, dirt_path, tilled_soil,
  water, etc.) to LimeZu tiles (sliced from `1_Terrains_16x16.png` / autotiles).
- **Object ids** — trees, fences, crops, buildings, props → LimeZu single files /
  sliced sheets.
- **Character/animal ids** — player/NPC/creature ids → LimeZu character + animal
  frames (or generator outputs).
- **UI provider** — panels/slots/buttons/close → LimeZu Modern UI (some already
  sliced for the spike: `ui.panel`, `ui.inventory_panel`, `ui.slot`, `ui.slot_selected`).
- **Inventory icons** — item icons → LimeZu Modern Farm icon singles.
- **Curated start slice** — rebuild the live curated opening slice with LimeZu art
  (the spike is the prototype for this).
- **Validation** — extend live checks to assert LimeZu live ids resolve (mirroring the
  current Sprout-required checks).

## Must remain unchanged (no gameplay churn)

Gameplay systems, networking/server, farming/save data, placement/edit/delete-twice
behavior, land/plots, profiles, and any future real-life integrations. The pivot is a
**presentation-layer swap**, not a gameplay change. Sprout integration stays in the
repo as a fallback provider; do not delete it.

## Where generator outputs could help

- Player/farmer variants + NPC bodies (Farmer / Character Generator).
- Character portraits for dialogue UI.
- UI variants (if exported).
- Decorative props, if a generator supports them.
All generator outputs are licensed-local (see docs/limezu_generator_workflow.md).

## Risks

- **License handling** — LimeZu forbids redistribution; every derivative/screenshot
  stays gitignored. A clean checkout must still run (missing-assets path), like Sprout.
- **Too many raw files / Godot import bloat** — packs hold 8k–53k files; only sliced
  `normalized/` derivatives may be imported (`.gdignore` guards `extracted/`).
- **Generator outputs need review** before use; never beauty-shot raw dumps.
- **Mixed tile sizes** (16/32/48) — normalize display scale per id.
- **Fantasy/taming creatures gap** — LimeZu has farm animals + enemy battlers +
  fungus monsters, but no cozy tameable-companion set. Still a custom-art gap.

## Recommended next step

Pivot the **live curated start slice** to LimeZu in a dedicated later pass: add a
LimeZu live manifest, route terrain/object/UI/icon ids through the provider behind
`LIVE_PROVIDER`, keep Sprout as fallback, and keep validation + offline/server boot
green at every step.
