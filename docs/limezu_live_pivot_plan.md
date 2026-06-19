# LimeZu Live Pivot Plan

Plan for moving Hearthvale's **live** visual provider from Sprout to LimeZu.

> **STATUS: PIVOTED.** `ArtProviderRegistry.LIVE_PROVIDER == "limezu"`. The live
> overworld opens into a curated LimeZu slice (`OverworldMap._build_limezu_slice()`),
> the UI is a Stardew/cozy-survival-INSPIRED layout built from real Modern UI 9-patch art
> (bottom hotbar, grid inventory, framed panels/dialogue/tabs) via `CozyUITheme` ->
> `LimeZuUITheme.*_texture_style()` with measured per-id margins (no stretching; flat tan
> only as fallback), and live human actors use the
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
> inventory/menus on a LimeZu-compatible UI that uses Modern UI texture-backed
> panels and controls. A boot audit + validation
> enforce `sprout=0`/`legacy=0` and LimeZu-dominant UI/world tiers in the opening.
> Forbidden in the live opening: any
> Sprout/old-generated/old-procedural/legacy visual — it must resolve to LimeZu, be a
> clean LimeZu UI element, or be hidden. The road/path must be the LimeZu path tile or hidden.

> **Playability (collision/interaction):** the LimeZu homestead has an explicit collision
> contract: barn polygons, tree trunk/base circles, and thin fence strips are solid; decor is visual-only,
> signs/NPCs/farm are interactable on F (`INTERACTION_RADIUS=78`). The player uses a compact
> feet collider, spawn `(7,11)` is open, and a tilled farm patch sits at `(6-8,15-17)`. A F7
> "Show Collision" debug overlay + "Clear Local Test Placements" support building/testing. See
> `docs/playtest_readiness.md` for the contract + manual checklist.
>
> **Asset-world metadata:** collision/interaction/minimap behaviour is declared in one
> authoritative commit-safe registry — `systems/world/asset_world_metadata.gd` — that the
> map/minimap/overlay read (no hand-patched blockers). The minimap runs in truth mode for the
> live slice (real features only). Collision shapes are curated/reviewed from local licensed
> PNG alpha, but committed metadata stores simplified shape data, never pixels. **Player-placed
> objects use the same model** via the shared `PlacedObjectCollision` builder (metadata shapes
> preferred; conservative proxy only for unmapped placeables), and feed the truth-mode minimap +
> F7 overlay (orange = placed, distinct from curated red).

> **Build/panel usability:** build menu ids now stay linked to selected visual ids before they
> reach collision metadata; the generic/missing box is a debug fallback only. Build/edit modes
> keep movement active while suppressing world interactions. Major popup panels use safe 1280x720
> docking positions until full draggable-window polish is scheduled.

> **Minimap readability + overlay clarity:** the live minimap remains truthful but now draws
> real current features as a tiny schematic: barn/farm footprints, path/fence strips, subtle
> tree dots, NPC dots, and sign dots. Phantom town/forest/plot markers stay out of the default
> player-facing minimap. The F7 collision overlay includes a legend: red solid asset collision,
> red hatch tile fallback/proxy, blue spawn, green farm patch, yellow interaction radius,
> purple minimap-visible feature; farm overlay rectangles are aligned to the centered LimeZu
> soil/crop visual tiles.

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

UI rewrite update: the live HUD, minimap, inventory backs, menus, slots, buttons,
close buttons, and tabs use the reviewed Modern UI texture slices through
`LimeZuUITheme`/`CozyUITheme`. Panel labels use dark ink on the parchment-like frame,
while button labels stay cream/gold on the dark button strips.

Layering update: the live LimeZu opening now treats grass/path/tilled soil as a true
ground layer below the y-sorted gameplay layer. The curated slice uses explicit visual
footprint exclusions for the barn, signs, crate/props, and trees, so path/soil cells
are skipped when they would bleed into building/object art. Future LimeZu expansion
should keep this terrain-below-props contract instead of adding path decals above
objects.

Small playable-area update: the first expansion after the screenshot cleanup is
bounded to the immediate homestead (`LIMEZU_PLAYABLE_AREA_BOUNDS`). It adds only
nearby LimeZu grass coverage, sparse edge clusters, and short approach path tiles so
walking a few steps from spawn remains coherent. It is not a village/forest/full-map
conversion; broader overworld, tameable creature, dungeon, and player-created
adventure-plot art remain future work.

Playability alignment update: the live barn collision now uses curated local-space
polygons for the visible lower body/silo instead of a tile rectangle or the older
hidden cottage collider. Tree blockers are compact trunk/base circles, fence blockers
are thin strips, visible crop beds align with the existing farm plot interactions,
and LimeZu prompts use a 32px-top-down interaction radius. The bottom-center quick
tools and compact inventory are sized around the smaller Modern UI control assets
instead of forcing the art to fit the old oversized prototype UI.

Depth/collision/animation update: LimeZu actors and foreground objects now share the
y-sorted gameplay band by feet/base instead of forcing actors above world props. Rowan,
Hazel, and SimpleVillager NPCs have compact metadata body collision while retaining the
larger talk interaction radius. Player animation is a minimal idle/walk state fallback
(bob/sway until reviewed sheets land), and held-tool display is selected-hotbar visual
state only, not RPG equipment slots.

Quickbar/icon update: the bottom bar is now a configurable 9-slot shortcut bar backed by
`player.quickbar`, with empty slots, `0`/same-slot unequip, inventory-click assignment, and
right-click clear. Icon completion stays narrow: mapped LimeZu icons win, original Hearthvale
generated review icons can be used locally from gitignored generator outputs, and committed
fallback icons/glyphs keep clean checkout safe.

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
