# UI And HUD

## Always-on HUD

The shared HUD still carries the core status lines:

- identity line: `@username (Display Name) | Offline/Server | Lv N`
- area line: current area or plot status
- materials line: wood / stone / fiber / clay / tokens
- comfort line
- mode/help line for explore, placement, edit, or move state

The minimap and quick tools continue to live as lightweight side panels rather
than full-screen systems.

## Build menu panel

The biggest UI addition in this branch is `ui/build_menu_panel.tscn`.

How it behaves:

- pressing `B` enters placement mode and shows the build menu
- the panel stays non-modal so walking can continue while it is open
- `Esc` hides the panel
- the `Close (Esc)` button hides the panel
- `Compact` toggles a shorter item summary view

The build menu categories are:

1. Foundations
2. Walls
3. Doors & Windows
4. Roofs
5. Fences & Gates
6. Structures
7. Crafting & Utilities
8. Storage
9. Farming
10. Paths & Terrain
11. Furniture
12. Decor

Each item row shows:

- name
- cost
- required tool
- footprint size
- interior status for prefabs
- unavailable reason when blocked

`Select` arms that piece immediately. `Tab` still cycles the active piece from
the keyboard while placement mode is active.

## Other panels

- `I`: inventory
- `K`: crafting
- `P`: progression
- `M`: minimap
- `H`: controls/help
- `F7`: admin panel
- `F8`: multiplayer/profile
- `F9`: wardrobe/creator
- `Enter`: chat

## Interior view

Placed supported prefabs can open `ui/interior_view.tscn`.

This is a separate interior scene/view, not an extension of the outdoor tilemap.
Current exit paths:

- `F`
- `Esc`
- Exit button

## Quick tools and minimap

Quick tools:

- shows ownership/readiness for the starter tools
- does not yet act as an active-tool hotbar

Minimap:

- schematic world readout
- live player marker
- plot ownership coloring
- landmark dots

## Manual UI checklist

- confirm the HUD mode text changes for Explore, Placement, Edit, and Move
- confirm the build menu opens on `B` and closes on `Esc`
- confirm category buttons, `Compact`, and `Select` all work
- confirm blocked pieces explain why they are unavailable
- confirm minimap updates after a claim change
- confirm quick tools update after gathering/crafting/inventory changes
- confirm prefab interior view opens and closes cleanly
