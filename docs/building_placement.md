# Building Placement

Hearthvale's first local decorating slice adds a couple of placeable object
types with a small modular architecture that can grow into furniture or
building pieces later.

## Current Scope

- five placeable object types:
  - wooden crate
  - cozy mailbox
  - small stool
  - porch lantern
  - cozy planter
- placement mode toggled with `B`
- `Tab` cycles the active placeable while in placement mode
- edit/removal mode toggled with `E`
- move selected object with `M` while in edit mode
- preview follows the mouse on the homestead grid
- left click or `Enter` confirms placement
- left click selects a hovered placed object in edit mode
- left click or `Enter` confirms a move on a valid tile
- `Delete`, `Backspace`, or left click on an already selected object removes it
- `Esc` cancels the current placement or edit mode, and restores the original tile during move preview
- placed objects save locally and reload on startup

## Design

The feature is split into three responsibilities:

- `world/homestead_map.gd`: grid conversion and placement validation rules
- `systems/object_registry.gd`: placeable definitions by `object_id`
- `systems/building_placement_system.gd`: preview, placement input, selection, removal, moving, and object instantiation
- `systems/local_save_system.gd`: local JSON persistence

The decorating system emits `decorating_mode_changed(active: bool)`, and the
homestead controller forwards that to the spawned avatar so movement is paused
whenever placement, edit, or move mode is active.

It also emits `decorating_mode_label_changed(mode_name, help_text)`, which the
homestead controller forwards to the prototype HUD so the player always sees the
current mode and its active controls.

A single reusable world-space hint node follows the placement or move preview
and shows `Valid` or a short blocked reason close to the active tile.

Placeable definitions now live in `ObjectRegistry`, keyed by `object_id`, so
the crate, mailbox, stool, lantern, and planter can all share the same
placement, save/load, move, and removal flow without branching into separate
systems.

This keeps the feature local-only while preserving boundaries for future
inventory, permissions, persistence layers, or multiplayer authority.

## Save Format

Current save path:

```text
user://homestead_save.json
```

Current record format:

```json
{
  "save_version": 3,
  "world": {
    "regions": {
      "homestead": {
        "placed_objects": [
          {
            "record_id": "crate_0001",
            "object_id": "crate",
            "tile_x": 6,
            "tile_y": 5
          },
          {
            "record_id": "mailbox_0002",
            "object_id": "mailbox",
            "tile_x": 7,
            "tile_y": 5
          },
          {
            "record_id": "stool_0003",
            "object_id": "stool",
            "tile_x": 8,
            "tile_y": 5
          }
        ]
      }
    }
  }
}
```

## Notes

- placed objects live in `GameplayLayer` so y-sort continues to work
- static blocked tiles come from the homestead map itself
- dynamic blocked tiles come from previously placed objects
- moving an object temporarily frees its old occupied tile until the move is confirmed or canceled
- all current placeables use a `1x1` footprint for now
- the player spawn tile is reserved to avoid save/load conflicts at startup
- placement mode, edit mode, and move-preview state are mutually exclusive
- avatar movement is paused while any decorating mode is active
- the HUD shows `Explore`, `Placement Mode`, `Edit Mode`, or `Move Mode` with matching controls and the active placeable during placement
- a world-space hint appears only during placement and move to show `Valid`, `Occupied`, `Reserved spawn`, `Out of bounds`, or a map blocker reason
