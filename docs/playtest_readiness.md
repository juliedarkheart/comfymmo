# Playtest Readiness

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
