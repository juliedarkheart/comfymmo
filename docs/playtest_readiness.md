# Playtest Readiness

## Visual/UI foundation checks

This branch now has a first reusable Hearthvale visual direction:

- `docs/visual_identity.md` defines the cozy 2D storybook target; the live view
  is now Sprout-compatible top-down / gentle 3/4, with the older 64x32 iso view
  kept as a fallback.
- `docs/ui_style_guide.md` defines shared parchment/wood/honey panel styling,
  slots, tabs, selected states, and close-path expectations.
- `docs/world_art_direction.md` defines terrain, biome, path, water, road, and
  plot-boundary readability.
- `docs/building_art_direction.md` defines the cozy survival-builder kit rules
  for modular pieces, prefabs, and interior deferrals.
- `docs/graphics_pipeline.md` defines the generated placeholder pipeline,
  registry routing, tile/object/icon sizes, fallback behavior, and replacement
  order.
- `docs/asset_credits.md` records that this pass imported no third-party art
  and explains the CC0/public-domain metadata rules for future imports.

Manual visual pass:

1. Open the system menu, inventory, build menu, land panel, admin panel, edit
   toolbar, quick tools, and minimap.
2. Confirm the panels share parchment/wood/honey styling and readable text.
3. Confirm important panels have visible Close/Resume/Cancel paths.
4. Confirm inventory categories read as item slots rather than a plain text dump.
5. Confirm build-menu tabs, selected item info, costs, unavailable states, and
   controls are visible.
6. Confirm the minimap is clipped, styled like a small map object, and uses
   readable plot/player/landmark markers.
7. Walk meadow, forest, orchard, creekside, hilltop, grove, town, and farmland
   areas and confirm terrain and HUD labels are distinguishable.
8. Paint dirt path, stone path, water, and farmland through admin terrain tools
   and confirm the same sprite palette appears in-world.
9. Place crate, mailbox, fence/gate, wall, floor/foundation, roof, workbench,
   cottage shell, and shed and confirm mapped registry sprites appear where
   available while old procedural decor still remains readable.

## Verified automatically

The project validator and boot checks cover the following for this branch:

- project import completes
- offline boot of `scenes/main.tscn` succeeds
- dedicated server boot of `server/server_main.tscn` succeeds
- build menu scene loads and instantiates
- build menu categories match `systems/building/build_categories.gd`
- build menu has both a close button path and an `Esc` close path
- build menu item sources resolve to valid content ids
- build costs resolve to valid placeables and valid item/resource ids
- at least 4 claimable plots are `16x16` or larger (true homestead yards)
- the 6 built-in plots are spread, disjoint, and each declares a known biome
- large plot centers AND all four corners are buildable for the owner
- runtime (editor-made) plots merge into every plot query, round-trip through the
  `runtime_plots` save data, skip corrupt records, and clear back to the static
  catalog with no leakage
- the system/pause menu scene loads and exposes open/close + a quit handler
- the `toggle_system_menu` (Esc) input action exists alongside F7–F11/I/H/M
- owner / non-owner / admin-bypass land rules behave correctly
- the 5 new modular pieces are wired through ids, registry, costs, and scenes
- prefab interior metadata parses safely
- at least one prefab interior mapping exists
- the shared interior scene loads
- invalid or missing prefab interior metadata fails closed
- modular/custom pieces are not required to have interiors
- graphics docs and asset credits exist
- required `art/` folders and generated PNG placeholders exist
- terrain and object art registries load and safely resolve required ids
- invalid terrain/object ids fall back to the missing-art placeholder
- map renderer exposes terrain visual resolution helpers
- external asset folders, if any, include license/source metadata

## Window controls & quitting

The game can now be closed without Alt+F4:

- **Esc** (when no panel is open) opens the system/pause menu: Resume, Toggle
  Fullscreen/Windowed, Quit to Desktop, Close.
- The **Quit to Desktop** button calls `get_tree().quit()` and works even in a
  borderless window where OS chrome is hidden.
- **F11** still toggles fullscreen/windowed (persisted via
  `ui/display_settings.gd`); the menu's toggle does the same.
- Esc still closes any open panel *first* (build/inventory/land/etc.); only with
  nothing open does it reach the system menu. While building, Esc still exits
  placement/edit mode instead of opening the menu.

## The "grey line" fix

A grey-blue stripe used to run across the map. Root cause: it was the **border
river** in `world/overworld_map.gd::_build_natural_borders` (a desaturated
blue-grey ribbon near world_y 980). When the south movement wall was pushed down
to fit the bigger lots, the playable/neighborhood area extended *past* this
border, so the river ended up cutting through the map. Fix: the river was moved
well south of the play area (world_y ~1980, below the ~1820 south wall) and
recolored a softer water-blue, so it now reads as a distant water border rather
than a grey line. Plot boundaries remain a subtle soft-yellow outline plus
corner posts (not grey, not a debug line).

## Known limitations

- prefab interiors are prototype-grade scene views, not full persistent indoor
  lots
- only selected prefab shells have interiors; greenhouse and well remain
  exterior-only
- modular custom buildings are exterior-only for now
- dungeons are future separate instances
- player-created dungeons or adventure plots are future work
- connected clients still depend on a simpler server-side terrain check than the
  richer offline map rules
- network-placed objects are still display-oriented on clients compared with the
  fully local edit/remove flow
- minimap and quick tools are intentionally lightweight UI, not full builder
  control surfaces
- the current PNG art is placeholder foundation art, not final production art
- terrain transitions are scaffolded assets/helpers, not full autotiling
- Sprout UI kit and animation catalog outputs are local review artifacts only;
  the committed build must still run with generated placeholders when
  `licensed_assets/` is absent.

## Manual test checklist

Run this list with a real player session after major building/UI changes:

1. Offline boot into the overworld and confirm `B` opens placement with the
   build menu visible.
2. Check every build-menu category button and confirm the list changes.
3. Toggle `Compact`, select a piece, and confirm the active piece changes.
4. Close the build menu with both the button and `Esc`.
5. Place at least one modular piece, one terrain piece, and one prefab shell.
6. Claim a large neighborhood plot and confirm building works inside it.
7. Stand inside another claimed plot and confirm normal building is denied.
8. Toggle admin/world-builder mode and confirm the same denied tile becomes
   placeable.
9. Place a prefab with an interior, walk to its door, press `F`, and exit with
   `F`, `Esc`, and the Exit button.
10. Place a modular custom shape and confirm there is no required interior flow.
11. Connect to a server and confirm the builder HUD, pouch counts, and placement
   behavior still read correctly.
12. Walk the spread lots (hilltop north, brook/creekside west, orchard south,
   grove east) and confirm each reads with its own biome ground + decor.
13. Open F7 → Toggle World Overlay (or `/overlay`) and confirm every plot's
   bounds, name, size, corners, the training-core grid, and any markers draw.
14. `/newplot grove 16` where you stand; confirm a claimable lot appears with
   ground/posts/sign, shows on the minimap and overlay, and a teleport button
   appears in F7. Claim it, build on it, then `/resizeplot 2` and `/delplot`.
15. `/marker resource Pine` (or F7 Place Marker), confirm the gem + label draw,
   reload the game, and confirm the plot and marker persisted. `/delmarker`
   removes the nearest one.

## Readiness summary

This branch is ready for focused manual playtests of:

- the build menu
- large-plot claiming and building
- prefab-door interior entry
- the cozy 2D isometric modular/prefab building loop

It is not claiming readiness for:

- dungeon gameplay
- combat
- player-authored adventure instances
- full modular interior simulation

## Graphics / asset pass status

- Generated placeholder art was upgraded to Pillow (4x supersampled,
  anti-aliased, cozy): biome tiles, paths, water, nature/building objects,
  prefabs, and UI icons. Validation asserts every required PNG exists and that
  the terrain/object registries resolve required ids and fall back safely.
- **No external assets were imported.** Outbound HTTP reached asset homepages,
  but a direct binary download returned HTTP 403 and no license file could be
  fetched/verified, so per the hard rule nothing external was added. The import
  pipeline (`art/external/` + license/source enforcement, `from_external/active`
  derivative mirror, registry external→generated→missing order) is ready for a
  verified CC0 drop-in later.
- Inventory slots now show registry icons. Build-menu per-row icons and a
  build/edit toolbar icon strip are a deferred, low-risk next step (icons +
  registry already resolve).
- Still placeholder / deferred: final production art for every category, a
  player/character sprite, neighbor-aware terrain autotiling (only a simple
  deterministic edge-hint scaffold exists today).

## Asset review workflow

- There is now a review-before-wiring pipeline: `tools/art/` slicer +
  contact-sheet + importer, contact sheets under `art/review/`, an in-editor
  preview scene (`tools/art/asset_preview.tscn`, F6), and a manifest-driven
  activation layer (`art/active_art_manifest.json` + `ArtActivation`). The
  registries only use an external derivative when it's listed in the manifest, so
  imported packs can't blind-replace the cozy generated art.
- The Kenney CC0 RPG sheet has a review contact sheet (64x64 cells) but is **not
  activated** (medieval/RPG cells still need semantic review). No redistributable
  external art is active. Validation asserts the review docs/dir, the activation
  manifest parses, and the safe generated default works.

## Licensed assets (Sprout Lands, local-only)

- The premium **Sprout Lands** pack (Cup Nooble) is integrated **locally and
  gitignored** - never committed (non-redistributable license; credit required,
  in docs/asset_credits.md). Wired locally: 10 objects, 6 icons, 6 licensed
  terrain tiles (meadow/orchard/grove/creekside/water/creek), 3 `licensed_modified`
  tint terrains (forest/hilltop/town), and 2 UI ids (panel + close). Clean
  checkout falls back safely.
- **Original Hearthvale top-down gap-fill** (`art/generated/hearthvale/`,
  committable, from `tools/art/generate_hearthvale_gap_assets.py`) gives every
  terrain id a real 32x32 top-down tile, so a no-Sprout checkout still reads as a
  coherent top-down farming world (soil/paths/plot markers look intentional). UI
  resolves licensed Sprout → generated Hearthvale shape → cozy code-drawn theme.
- Projection compatibility lives in `systems/world/world_projection.gd`. The live
  overworld uses `sprout_topdown` on the same gameplay grid; `iso_64x32` remains a
  legacy/fallback projection. Source tiers: `licensed` / `licensed_modified` /
  `licensed_ui` / `generated` / `missing` (inspect with F6 asset preview).
- **Manual visual review still owed:** the recolor tints (forest/hilltop/town),
  the Sprout panel nine-patch margins, and which Sprout button/slot sheet cells
  to wire (catalog-only for now). Audio + animations remain cataloged, not wired.
- Sprout UI kit review is local-only. `tools/art/sprout_integrate.py` extracts
  the UI pack, writes a gitignored `sprout_ui_manifest.json`, and generates UI
  contact sheets; `UIArtRegistry` falls back to cozy code-drawn panels and
  generated icons unless a reviewed local manifest activates specific sprites.
- Sprout animation sheets are cataloged locally under
  `licensed_assets/sprout_lands/manifests/animations_inventory.json` with
  contact sheets under `contact_sheets/animations/`. They are not wired into
  runtime animation yet.
- If the local Sprout Sorry pack zip is present, it is cataloged under
  `contact_sheets/sorry/` and `manifests/audio_inventory.json` only. This does
  not add runtime audio, combat, enemies, dungeon gameplay, quests, or economy.
- Sprout terrain is deliberately limited to reviewed single-tile mappings
  (`meadow`, `water`, `creek`) and only in Sprout-compatible projection modes.
  Modular/custom building pieces still do not require interiors or Sprout art.
- Validation asserts `licensed_assets/` is gitignored, the tracked template
  manifest has no real mappings, a present pack has license metadata + existing
  mapped files, and (proven by hiding the manifest) a clean checkout with no
  pack still passes and falls back to generated. Inspect in-engine via
  `tools/art/asset_preview.tscn` (F6) — Sprout ids show a "licensed" tag.
