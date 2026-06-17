# LimeZu Live Pivot Plan

Plan for moving Hearthvale's **live** visual provider from Sprout to LimeZu.

> **STATUS: PIVOTED.** `ArtProviderRegistry.LIVE_PROVIDER == "limezu"`. The live
> overworld opens into a curated LimeZu slice (`OverworldMap._build_limezu_slice()`),
> the UI re-skins to Modern UI (`CozyUITheme._ui_box`), and live human actors use the
> LimeZu farmer (`CharacterArtRegistry`). Validation + offline/server boot pass. Sprout
> stays integrated as a secondary/comparison provider (not deleted). Gameplay
> (movement/placement/farming/delete-twice/data/networking) is unchanged. The sections
> below record the plan; the checklist items in scope this pass are done, including
> Modern UI button/close mapping and hiding generated homestead creatures from the
> opening. The rest (full-world LimeZu beyond the opening slice, Exteriors/Interiors
> tiling, broader creature art, dungeon art) remain follow-ups.
>
> **Source-purge + full UI conversion (latest):** the opening view is now source-pure —
> the Sprout neighborhood/plot grounds + generated dirt/stone roads, village/forest
> decor, plot-skirt decor, and the wardrobe mirror are suppressed in LimeZu mode;
> resource nodes are re-skinned to LimeZu; and the HUD/minimap/toolbelt joined the
> inventory/menus on a clean flat LimeZu-compatible UI. A boot audit + validation
> enforce `sprout=0`/`legacy=0` and LimeZu-dominant UI/world tiers in the opening.
> Forbidden in the live opening: any
> Sprout/old-generated/old-procedural/legacy visual — it must resolve to LimeZu, be a
> clean LimeZu UI element, or be hidden. The road/path must be the LimeZu path tile or hidden.

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

Live polish update: `ui.button`, `ui.button_hover`, `ui.close`, `ui.close_hover`,
and `ui.tab` are now sliced/mapped locally in addition to panel and slot frames. The
opening also hides old farm-plot soil marks, the old rest-marker doormat diamond,
and generated homestead woodland creatures; broader creature-family coverage remains
a custom-art gap.

UI rewrite update: those Modern UI slices are no longer stretched over large live
panels. The live HUD, minimap, toolbelt, inventory, and menus use `LimeZuUITheme`
`StyleBoxFlat` frames in dark wood/gold/cream so text stays readable and frames do
not warp. The slices remain mapped for audits, references, and possible small native
uses.

Layering update: the live LimeZu opening now treats grass/path/tilled soil as a true
ground layer below the y-sorted gameplay layer. The curated slice uses explicit visual
footprint exclusions for the barn, signs, crate/props, and trees, so path/soil cells
are skipped when they would bleed into building/object art. Future LimeZu expansion
should keep this terrain-below-props contract instead of adding path decals above
objects.

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
