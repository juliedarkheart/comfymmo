# Save Data Model

Hearthvale now uses a versioned local save envelope with region-scoped world
data while remaining compatible with older decorating-era saves.

## Save Path

```text
user://homestead_save.json
```

## Current Version

```text
save_version = 3
```

## Current Structure

```json
{
  "save_version": 3,
  "world": {
    "current_region_id": "homestead",
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
            "record_id": "lantern_0003",
            "object_id": "lantern",
            "tile_x": 8,
            "tile_y": 5
          }
        ],
        "farming": {
          "plots": {
            "farm_plot_carrot": {
              "crop_id": "carrot",
              "stage": "planted_watered"
            },
            "farm_plot_turnip": {
              "crop_id": "turnip",
              "stage": "grown"
            },
            "farm_plot_berry": {
              "crop_id": "berry",
              "stage": "empty"
            }
          }
        },
        "interactables": {},
        "region_flags": {}
      },
      "village_square": {
        "placed_objects": [],
        "farming": {
          "plots": {}
        },
        "interactables": {},
        "region_flags": {
          "notice_board_seen": true
        }
      },
      "forest_edge": {
        "placed_objects": [],
        "farming": {
          "plots": {}
        },
        "interactables": {},
        "region_flags": {}
      }
    },
    "creatures": {
      "creatures": []
    },
    "dungeons": {
      "active_dungeon_id": ""
    },
    "global_flags": {
      "current_mood": "morning",
      "day_count": 1
    },
    "overworld": {
      "flags": {}
    },
    "instances": {}
  },
  "player": {
    "inventory": {
      "items": {
        "carrot": 2,
        "turnip": 1,
        "berry": 3
      }
    },
    "survival": {
      "energy": 100.0,
      "hunger": 100.0,
      "comfort": 55.0
    }
  },
  "tasks": {
    "integration": {
      "mock_tasks": [
        {
          "id": "mock_groceries",
          "title": "Pick up groceries",
          "body": "Market board reminder",
          "source": "mock",
          "status": "pending"
        }
      ],
      "mailbox_message_state": {
        "mock_groceries": {
          "seen": true
        },
        "mock_water_garden": {
          "seen": true,
          "completed": true
        },
        "mock_harvest_carrot": {
          "seen": true,
          "completed": true
        }
      }
    }
  }
}
```

## Backward Compatibility

Older save files that look like this:

```json
{
  "placed_objects": [
    {
      "record_id": "crate_0001",
      "object_id": "crate",
      "tile_x": 6,
      "tile_y": 5
    }
  ]
}
```

or this:

```json
{
  "homestead": {
    "placed_objects": []
  },
  "world": {
    "current_world_id": "homestead",
    "farming": {
      "plots": {}
    }
  }
}
```

are migrated automatically into the new versioned format on load.

## Stable Content Ids

The string ids written into saves and used as dictionary keys are centralized in
`systems/content/content_ids.gd` (`ContentIds`) — items (`carrot`/`turnip`/`berry`/…),
placeables (`crate`/`mailbox`/`stool`/`lantern`/`planter`), farm plots
(`farm_plot_carrot`/…), region/area ids (`homestead`/`village_square`/`forest_edge`),
region flags (`maribel_intro_seen`/…), and task ids (`mock_water_garden`/…).

**These ids are part of the save contract. Never rename them casually** — a rename
silently breaks old saves. Display names (e.g. "Carrot") may change freely; the ids
behind them must not. The controllers' id constants (e.g.
`HomesteadController.CARROT_ITEM_ID`, `OverworldController.VILLAGE_REGION_ID`, the
farm-plot and region-flag ids) now derive their values from `ContentIds`, so the
save strings have a single source of truth. `tools/validate_project.gd` asserts both
`ContentIds` and these adopted controller constants still equal their save strings.
New content should add ids to `ContentIds` rather than inventing inline literals.

## Overworld, Instances, and Legacy Compatibility Paths

After the pivot to a single continuous overworld (`docs/overworld_architecture.md`),
the save model is intentionally a **compatibility layer**, not a broad migration:

- `world.overworld.flags` — the clean home for **new** overworld-wide flags. Read/write
  via `LocalSaveSystem.get_overworld_flags` / `get_overworld_flag` / `set_overworld_flag`
  / `ensure_overworld_state`. Empty by default.
- `world.instances` — reserved for **future** instanced, scene-swapped spaces
  (dungeons/caves/interiors). Read/write via `get_instance_state` / `set_instance_state`.
  Empty by default; outdoor play never scene-swaps.
- **Legacy compatibility paths (still in use, do not migrate):** the overworld keeps
  reading/writing the original region-scoped sections so old saves keep working with no
  wipe and no version bump:
  - homestead farming → `world.regions.homestead.farming`
  - villager intro/visit + notice-board flags → `world.regions.village_square.region_flags`
  - shrine seen flag → `world.regions.forest_edge.region_flags`
  - placed objects → `world.regions.homestead.placed_objects`

  These remain the source of truth for that state for now. Migrating them into
  `world.overworld` would be a fragile broad change for no functional gain, so it is
  deliberately deferred.

Both `world.overworld` and `world.instances` are added additively (default save +
migration ensures they exist) with **no `save_version` bump**; helpers default safely
when absent.

## World Mood / Global Flags

`world.global_flags` holds small global, non-region-scoped state:

- `current_mood` — the manual time-of-day phase (`morning`, `afternoon`, `dusk`).
  Read with `LocalSaveSystem.get_current_mood()` (defaults to `morning`); written
  with `set_current_mood(mood_id)` when the player presses `T` or rests.
- `day_count` — the global day number, starting at `1`. Read with
  `get_day_count()` (defaults to `1`); written with `set_day_count(n)` (clamped to
  a minimum of 1). It increments **only** when the player rests at dusk; nothing
  advances it automatically.

Both fields are additive and **do not bump `save_version`**: older saves without
`global_flags` (or without one of the keys) simply default to `morning` / day `1`
until the first mood change or rest is saved.

## Migration Rule

- if root-level `placed_objects` exists, treat the save as a legacy decorating save
- copy those records into `world.regions.homestead.placed_objects`
- if legacy `homestead.placed_objects` exists, copy it into `world.regions.homestead.placed_objects`
- if legacy `world.farming` exists, copy it into `world.regions.homestead.farming`
- if legacy `world.current_world_id` exists, normalize it into `world.current_region_id`
- initialize missing region sections with defaults
- migrate legacy `farm_plot_main` into the newer homestead carrot plot slot when the homestead controller loads
- initialize `tasks.integration.mailbox_message_state` when absent
- preserve older mailbox state records and normalize the legacy `mock_garden` id to `mock_water_garden`
- stamp the result with the current `save_version`

## Current Scope

Homestead placed objects, homestead farming state, mailbox state, player
inventory, and player survival are actively written by gameplay now. The
village square exists as a second formal region with a tiny notice board
seen-flag in its region-local state, and `forest_edge` now exists as a third
formal outdoor region with default region-local save containers ready.

The mailbox world signal is derived from saved seen-state, not stored
separately. If any current mailbox messages remain unseen, placed mailboxes show
the active signal on load.

The village notice board uses the same region-local save shape through
`region_flags`, but its controller now reaches that state through shared
`BaseRegionController` helpers instead of region-specific save calls.
