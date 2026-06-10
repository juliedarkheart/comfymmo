# Overworld Architecture (foundation)

This is the authoritative description of Hearthvale's outdoor world after the pivot
from paged regions to one continuous overworld. It exists so future work builds on a
clear foundation instead of re-deriving (or accidentally undoing) the model.

## What is the main outdoor scene?

`scenes/world/overworld.tscn` — a **single continuous scene** containing the
homestead, village square, and forest edge as connected areas with roads, natural
borders, and wilderness fill. **Outdoor traversal is walking; it never scene-swaps.**

- `world/overworld_controller.gd` (`OverworldController`) — the gameplay controller.
- `world/overworld_map.gd` (`OverworldMap`) — the terrain/colliders/camera.

The game boots: `scenes/main.tscn` → `game_bootstrap.gd` → `WorldRegionManager`
(`_load_starting_region` → `"overworld"`) → `overworld.tscn`.

## What is still legacy?

These remain on disk and **registered** in `WorldRegionManager`, but are **not loaded
for outdoor play**. Keep them as fallbacks / interior templates / reference:

- `scenes/world/regions/{homestead,village_square,forest_edge}/*_region.tscn`
- their `*_region_controller.gd`, `*_map.gd`, and `world/region/base_region_controller.gd`
- `scenes/world/homestead.tscn` (the original homestead scene; its controller/map are
  reused by the overworld via inheritance — see below)
- the outdoor Area2D transition areas inside the legacy region scenes (never triggered)

## What is intended for future dungeons / interiors / instances?

`WorldRegionManager` keeps its deferred-transition + cooldown + fade machinery for
**non-outdoor instances only**: dungeons, caves, interiors, special towns. Those will
`transition_to_region(<instance_id>)`; returning loads the overworld again. Save space
for them is reserved at `world.instances` (see Save Model). **Do not** re-add outdoor
Area2D paging.

## Inheritance (transitional, intentional)

Controller chain (after Foundation Chunk 10, phase 4 step 1):
`OverworldController` → `HomesteadController` → `OutdoorAreaController` → `Node2D`.
Map chain: `OverworldMap` → `HomesteadMap`.

- `world/outdoor_area_controller.gd` (`OutdoorAreaController`) is the shared base. It
  holds only **generic, gameplay-free** wiring:
  - lookups: `get_hud` / `get_save_system` / `get_interactable_system` /
    `get_player_avatar` / `get_camera`, a safe HUD call wrapper (`call_hud`), and
    `_mark_input_handled`.
  - the **observe/message panel lifecycle**: the `_observe_panel_open` state,
    `is_observe_panel_open()`, `_open_observe_panel(title, body[, footer])`, and
    `_close_observe_panel()`. These show/hide the shared HUD message panel and toggle
    interactions. Area-specific input suspension is delegated to two overridable
    hooks — `_set_area_input_suspended(bool)` and `_area_interactions_enabled()` —
    so the base stays gameplay-free.
  It owns **no** gameplay. It `extends Node2D` (not `BaseRegionController`) on purpose:
  the overworld must never be a swappable region, and adding region machinery here
  would change `WorldRegionManager`'s boot wiring.
- **Phase 1 (Chunk 7):** created the seam with the generic lookup helpers.
- **Phase 2 (Chunk 8):** moved the generic observe/message panel lifecycle to the
  base. `HomesteadController` provides the placement-aware hooks (it suspends
  building-placement input and keeps interactions disabled while decorating); the
  message *text* and the decision of *when* to open stay in the controllers.
- **Phase 3 (Chunk 9):** the base now owns the generic **interactable registration
  plumbing**: `register_world_interactable(id, node, type, prompt, callback, data)`
  wraps `InteractableSystem` registration and remembers an optional zero-arg bound
  `Callable` per id (plus optional data); `_dispatch_world_interactable(id)` invokes
  it; `unregister_world_interactable` / `has_world_interactable` /
  `get_world_interactable_data` round it out. Content adopted: homestead creatures +
  rest, and the overworld's villagers, notice board, shrine, and creatures all
  register with bound callbacks. `HomesteadController._on_interaction_requested`
  keeps its four panel/mode guards, matches mailbox (registered by
  `BuildingPlacementSystem`, no callback) and farm plots (farming-owned) explicitly,
  and its default branch dispatches everything else via the registry.
  `OverworldController`'s dispatch override was removed — its guard set was identical
  to the inherited one, so villager/notice/shrine now flow through the shared path
  with byte-identical behaviour. Content callbacks, villager data, flags, and text
  all stay in their controllers.
- **Phase 4 step 1 (Chunk 10):** two template-method hooks added to
  `OutdoorAreaController` as safe no-ops: `_setup_area_content(player)` and
  `_after_area_setup(player)`. `HomesteadController._ready` now calls
  `_setup_area_content(player)` in place of the inline `_spawn_ambient_creatures` /
  `_setup_rest_marker` calls, and calls `_after_area_setup(player)` at the very end.
  `HomesteadController` provides the override of `_setup_area_content` that runs those
  two calls. `OverworldController` is **unchanged**: it still does its post-super work
  (camera, village/forest content, dev overlay) directly in its own `_ready` after
  `super._ready()`. No gameplay or save changes.
- **Phase 4 step 2 (next):** move OverworldController's post-super work into its own
  `_setup_area_content` / `_after_area_setup` overrides, then switch
  `OverworldController` to extend `OutdoorAreaController` directly so the homestead is
  no longer load-bearing for the whole outdoor world. This must preserve every system
  and every save string and is **not** to be rushed.

This was the low-risk way to reuse the proven homestead gameplay stack during the
pivot. It is **stable and intentionally kept**. The eventual cleaner shape is a shared
`OutdoorAreaController` base (or component systems) plus shared map helpers — but that
refactor must preserve every system and is **not** to be attempted casually. Treat the
inheritance as a documented seam, not debt to rush.

### Shared helpers (Foundation Chunk 2)

To start decoupling without unwinding the inheritance, the reusable, behaviour-
identical pieces are extracted into stateless static helpers that the load-bearing
classes now delegate to (so the logic is no longer "owned" by the homestead and a
future non-homestead base can reuse it):

- `world/iso_map_helpers.gd` (`IsoMapHelpers`) — pure iso grid math:
  `grid_to_world`, `world_to_grid`, `tile_diamond`. `HomesteadMap` (and thus
  `OverworldMap` by inheritance) delegate to it; the math is unchanged, so placement,
  farming, and collision behave exactly as before.
- `world/outdoor_controller_helpers.gd` (`OutdoorControllerHelpers`) — the mechanical
  HUD/mood/day glue: `call_if_has`, `apply_mood`, `apply_day`, `cycle_mood`.
  `HomesteadController` delegates its mood/day HUD application to it.

These are deliberately small: only obviously-pure helpers were moved. The entangled,
stateful wiring (observe/rest panels, interactable registration, farming/placement
setup) stays in the controllers for now — extracting it is the next milestone and must
be test-guarded. The legacy region maps still keep their own inline grid copies (they
are not loaded for outdoor play); they may delegate to `IsoMapHelpers` later.

## System boundaries

Systems live as sibling nodes under the overworld scene root (see
`scenes/world/overworld.tscn`).

**Global (player-wide / world-wide, not area-specific):**

- `LocalSaveSystem` — JSON persistence (`user://homestead_save.json`).
- `GameStateManager` — exposes save sections.
- `InventorySystem`, `SurvivalSystem` (comfort) — `player.*`.
- Mood / day — `world.global_flags` (via `LocalSaveSystem`).
- `TaskIntegrationSystem` (mailbox/tasks) — `tasks.integration`.
- `ObjectRegistry` — shared definitions.

**Overworld-local (the one outdoor scene):**

- `InteractableSystem` — the single proximity/interaction registry for every
  interactable in the overworld (farm plots, rest marker, villagers, notice board,
  shrine, creatures).
- `CreatureSystem` — ambient creature records.
- The player avatar + `AvatarCamera` (zoom controls live here).
- Dev overlay (`OverworldEditorSystem`, local-only) and the dev marker layer.

**Homestead-area-only (origin grid):**

- `BuildingPlacementSystem` + `FarmingSystem` — placement/edit/move/remove and the 3
  farm plots use the inherited homestead **grid at the origin**. Placement/farming are
  meaningful only in the homestead area; the rest of the overworld is open terrain.

## Grid usage

The iso grid (`grid_to_world` / `world_to_grid`, blocked tiles) remains **only** for
placement, farming, and collision helpers in the homestead area. Movement and world
presentation are open and continuous — the world is not a boxed tile room.

## Dev / admin scaffolding

- Dev overlay (`F10`, `systems/overworld_editor_system.gd` + `dev_tool_state.gd` +
  `dev_world_marker.gd`) — **local-only** inspection + temporary markers. Not gameplay.
- Admin/moderation (`systems/admin/*`) — **stubbed** data models + in-memory audit log.
  No network, no backend, not wired into gameplay. See `docs/backend_tools.md`.

## Lightweight validation checklist

Run `tools/validate_project.gd` (in a real terminal) to confirm:

- `scenes/main.tscn` and `scenes/world/overworld.tscn` load/instantiate.
- Key scripts parse: overworld + homestead controller/map, `TerrainShapes`,
  `WorldRegionManager`, `LocalSaveSystem`, `GameStateManager`, dev + admin systems.
- Save helpers return safe defaults with no save file (`get_current_mood`,
  `get_day_count`, `get_overworld_flags`, `get_instance_state`).
- Legacy region scenes still parse.

By inspection (no engine needed): `class_name` globals are unique and resolve, and the
overworld scene mirrors `homestead.tscn`'s node structure (so inherited `@onready`
paths resolve).

## Do / don't for future agents

- **Do** add new outdoor content inside `overworld.tscn` / the overworld controller.
- **Do** use `ContentIds` for any id (items, crops, areas, flags, tasks, interaction
  types, actions, placeables, …) instead of inline string literals; the controllers'
  id constants, interaction-type matches, and action returns already derive from it.
  Note the two distinct id concepts: `INTERACTION_*` (what something *is*) vs
  `ACTION_*` (what the player can *do* with it). Runtime-generated interactable
  instance ids (e.g. `ow_maribel`, `homestead_rest`) have no stable id and stay local.
- **Do** use `ContentRegistry` for display names / metadata, but not as a gameplay
  authority (save/placement/farming/tasks still own live state).
- **Do** put new overworld-wide flags in `world.overworld.flags`
  (`LocalSaveSystem.set_overworld_flag`).
- **Don't** re-add outdoor Area2D transitions or per-area scene swapping.
- **Don't** broadly migrate legacy `world.regions.*` save paths (compatibility).
- **Don't** casually unwind the transitional inheritance.
