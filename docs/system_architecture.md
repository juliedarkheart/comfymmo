# System Architecture

Hearthvale now has a lightweight foundation for its next major gameplay layers
without changing the current prototype loop.

## Content Ids & Registries

`systems/content/` centralizes the previously-scattered content strings:

- `content_ids.gd` (`ContentIds`) — the single source of truth for stable string ids:
  items, crops, farm plots, placeables, creatures, villagers, interaction types,
  areas/region ids, region flags, task/message ids, and future instance categories.
- `content_registry.gd` (`ContentRegistry`) — lightweight, read-only **data**
  definitions keyed by those ids (display name, category, scene path, harvest item,
  etc.). It is intentionally **not** wired into the runtime systems yet; the live
  state still lives in `ObjectRegistry` / `FarmingSystem` / `TaskIntegrationSystem`.

These ids are part of **save compatibility** — see `docs/save_data_model.md`. They
must never be renamed casually; display names may change, ids must not. They will
also matter for multiplayer/backend/moderation, which will key off the same ids.

Adoption is incremental and value-preserving (every adopted string is identical, so
no save output changed):

- `ObjectRegistry` (placeable/item ids) and `TaskIntegrationSystem` (task ids).
- The controllers now point their **constant values** at `ContentIds` (the constant
  *names* are kept, since other code references them): `HomesteadController`'s region/
  item/crop/farm-plot ids and `OverworldController`'s region ids + villager/notice/
  shrine region-flag ids.
- **Interaction type ids are centralized** through `ContentIds.INTERACTION_*`:
  `InteractableSystem`'s `get_available_actions` / `_get_prompt_text` matches and its
  `register_interactable` default, plus the controllers' dispatch matches and
  `register_interactable` type args. Match patterns use the class constants directly
  (valid GDScript constant patterns); values are unchanged.
- `DevToolState.area_label` (display-only) resolves an area via `ContentIds` and gets
  its label from `ContentRegistry` — the displayed strings are unchanged.

`ContentRegistry` is safe for **display/metadata** only; it is **not** a gameplay
authority yet (save loading, placement scene loading, the farming state machine, and
task mutation still own their live state). A few literals intentionally remain:
runtime-generated interactable ids (`ow_maribel`, `homestead_rest`, …) that have no
stable id; the local `_villager_data` dict key `"villager"` (a data key, not an
interaction type); the mailbox *placeable* object id inside `placeable_mailbox.gd` /
`building_placement_system.gd` (a save id, not an interaction type, and outside this
pass's scope); and the legacy region controllers (not loaded for outdoor play).
`tools/validate_project.gd` asserts the adopted constants and every
`ContentIds.INTERACTION_*` still equal their original strings.

## Developer & Admin Scaffolding (local-only)

Local-only infrastructure prepared for future tooling. None of it adds networking,
accounts, servers, or persistence, and gameplay is unaffected when it is idle:

- **Runtime zoom controls** live on `AvatarCamera`: `PageUp`/`=`/`+` zoom in,
  `PageDown`/`-` zoom out, `R` resets to the region's base zoom. Zoom is clamped and
  only changes the camera zoom, so position smoothing and mouse/world-space
  transforms (placement coordinates, world hints) stay correct. The overworld's
  default zoom is `1.3` for 4K readability, and the project renders at 1920×1080.
- **Dev overlay + markers** (`systems/overworld_editor_system.gd`,
  `systems/dev_tool_state.gd`, `systems/dev_world_marker.gd`) toggles with `F10`. It
  inspects (player/mouse world position, area label, zoom) and lets you select a tool
  (`1`-`4`), drop temporary visual-only markers (`M` / left-click in Marker tool),
  clear them (`C`), and export them to `user://dev_marker_export.json` (`E`). Markers
  carry no collision and are never saved with the game. Dev keys are handled in
  `_input` and only consumed while dev mode is on, so they never collide with
  gameplay or building placement and nothing leaks while off. Placing/clearing
  markers appends to the local in-memory `AuditLog`. See `docs/dev_tools.md`.
- **Moderation scaffolding** (`systems/admin/moderation_models.gd`,
  `systems/admin/audit_log.gd`) provides stubbed data shapes (report model, admin
  action model, role placeholders) and an in-memory, append-only audit log for a
  future family/friends moderation layer. Nothing calls these yet. See
  `docs/backend_tools.md` and `docs/moderation.md` for the staged backend direction.

## Runtime Shape

> **Current model:** the outdoor world is **one continuous overworld scene**
> (`scenes/world/overworld.tscn`), not paged regions. Boot is
> `scenes/main.tscn` → `game_bootstrap.gd` → `WorldRegionManager`
> (`_load_starting_region` → `"overworld"`) → the overworld. Outdoor traversal is
> walking and **never scene-swaps**; `WorldRegionManager` is reserved for future
> instances (dungeons/interiors). The authoritative description of the outdoor
> architecture, system boundaries (global vs overworld-local vs homestead-area-only),
> and save model is **`docs/overworld_architecture.md`** — read it before changing
> outdoor structure. Shared, behaviour-identical helpers (`world/iso_map_helpers.gd`
> for grid math, `world/outdoor_controller_helpers.gd` for HUD/mood/day glue) are
> extracted and delegated to by the load-bearing classes, so the homestead↔overworld
> inheritance is now backed by reusable pieces rather than being the only home for
> that logic.

The notes below describe the original paged-region layer, which now applies only to
the legacy/fallback region scenes and to future instanced scenes:

- `WorldRegionManager`
- one active region scene at a time (legacy/instances only)
- a small shared region controller pattern (`BaseRegionController`, legacy/instances)

Each scene owns a set of local systems as sibling nodes:

- `GameStateManager`
- `ObjectRegistry`
- `PlayerSpawnSystem`
- `LocalSaveSystem`
- `BuildingPlacementSystem`
- `InteractableSystem`
- `InventorySystem`
- `FarmingSystem`
- `CreatureSystem`
- `SurvivalSystem`
- `TaskIntegrationSystem`
- `CombatSystem`
- `DungeonSystem`

This keeps each region scene self-contained while giving the project a clean
multi-region spine.

## Current Responsibilities

- `GameStateManager`
  Loads versioned save data, exposes world, player, and task sections, and
  tracks the active region id.
- `WorldRegionManager`
  Loads the starting region from save data and swaps between region scenes on
  request. Because requests arrive from an `Area2D` `body_entered` callback during
  the physics flush, `transition_to_region` only validates and queues; the actual
  unload/load/spawn runs in a deferred `_process_pending_transition` after the
  flush, and duplicate requests are ignored while one is pending.
- `RegionTransitionSystem`
  Tiny helper signal surface for explicit region travel.
- `ObjectRegistry`
  Central registry for placeable definitions by `object_id`, plus a small
  placeholder item catalog for later inventory and task hooks.
- `BuildingPlacementSystem`
  Owns placement, edit, move, remove, preview, and occupancy behavior while
  now reading object definitions from `ObjectRegistry`.
- `InteractableSystem`
  Placeholder registry for mailbox, task board, crop, and dungeon interactions.
- `InventorySystem`
  Placeholder item container with add/remove/query methods and no UI.
- `FarmingSystem`
  Placeholder plot state with `plant`, `water`, and `harvest` hooks.
- `CreatureSystem`
  Placeholder creature records for future spawning and bonding work.
- `AmbientCreature` / `MossRabbit` / `LanternMoth` / `StumpTurtle`
  Session-local ambient life nodes spawned by region controllers. No save
  persistence. State resets on region load.
- `SurvivalSystem`
  Placeholder stat store for `energy`, `hunger`, and `comfort`.
- `TaskIntegrationSystem`
  Local-only placeholder task ingestion surface for future reminder and mailbox
  loops.
- `CombatSystem`
  Stub encounter boundary for future combat entry and exit.
- `DungeonSystem`
  Stub dungeon registry and active dungeon state for future runs and interiors.

## Design Notes

- current gameplay still runs locally inside one active region scene at a time
- the homestead remains the only fully featured region
- the village square exists to prove region switching and save scoping
- no networking or external integrations were added
- no new player-facing UI was added beyond the existing prototype HUD
- each new system exposes a small surface rather than a broad framework

## World Mood

A lightweight, manual time-of-day mood lives in `systems/world_mood.gd`
(`class_name WorldMood`). It is a stateless utility — not a clock and not a
simulation:

- three phases in fixed order: `morning` → `afternoon` → `dusk` → `morning`
- `WorldMood.next_mood`, `display_name`, and `tint_color` describe each phase
- tints are subtle full-screen `ColorRect` colors with low alpha; afternoon is
  intentionally clear (alpha 0)

The current phase is global state stored in the save at
`world.global_flags.current_mood` via `LocalSaveSystem.get_current_mood` /
`set_current_mood`. There is no automatic advancement — pressing `T` cycles the
phase, persists it, and re-tints the world.

Rendering and display live in the shared HUD (`ui/prototype_hud.tscn`,
`prototype_hud.gd`):

- a `MoodTint` `ColorRect` is the first child of the HUD `CanvasLayer`, so it
  draws over the world but **under** the HUD panels (UI stays readable). It uses
  `mouse_filter = ignore` so it never intercepts placement clicks.
- `HUD.set_mood(mood_id)` applies the tint color and updates the `Time:` line.

Each region applies the saved mood on `_ready` and cycles it on `T`. The two
`BaseRegionController` regions (village square, forest edge) share `apply_saved_mood`
/ `cycle_mood` on the base, which reuse its existing `_get_region_save_system` /
`_get_region_hud` accessors; the standalone homestead controller keeps small local
equivalents. Because all three regions instance the same HUD scene, the tint and
label are consistent everywhere. Maribel and Bram in the village square optionally
reference the current day and phase in their rotating repeat lines (see Rest & Day
Passage below).

Mood cycling is gated to Explore play: the `T` key is suppressed while a mailbox,
message, villager, notice, shrine, or rest panel is open, and (in the homestead)
while a placement/edit/move decorating mode owns input. The non-blocking inventory
overlay does not suppress it, mirroring how carrot-consume also works with
inventory open.

## Rest & Day Passage (Gentle Passage)

A lightweight "finish a cozy day" loop, with no real-time, timers, or schedules.

- `world.global_flags.day_count` (default `1`) is the global day number, read/written
  via `LocalSaveSystem.get_day_count` / `set_day_count`. The HUD shows it on a `Day:`
  line via `HUD.set_day(n)`; every region applies it on load (`apply_saved_day` on
  the base, `_apply_saved_day` in the homestead).
- The homestead spawns a cozy doormat **rest marker** at the cottage doorway
  (`_setup_rest_marker`), registered with `InteractableSystem` as type `"rest"`
  (prompt `Press F to rest`). It has no collision and never blocks the player.
- Resting opens a tiny two-phase panel reusing the existing message panel:
  a *confirm* phase (`F = Rest   Esc = Cancel`) and a *result* phase (a short
  "morning arrives" line, `Esc to close`). Both phases route through the homestead
  `_unhandled_input` while `_rest_panel_open` is set, with interactions and
  placement input suspended exactly like the observe/mailbox panels.
- On confirm (`_confirm_rest`): if the current mood is `dusk`, `day_count`
  increments and the mood resets to `morning`; otherwise the mood advances one
  phase and the day is unchanged (`WorldMood.rest_increments_day` /
  `WorldMood.next_mood`). Comfort is restored to 100 via `SurvivalSystem.set_stat`,
  which saves and refreshes the HUD. Mood and day writes save immediately, so the
  new state is consistent across every region on the next load.

Villager repeat lines are now day/mood-aware: `_handle_villager_talk` takes an
optional `passage_line` `Callable(day_count, mood_id)`. Maribel and Bram each
supply three gentle, flavor-only passage lines that reference the day number and
current phase — no branching, no schedules.

## Villager Placeholders

Villager scripts live in `villagers/`. Scenes live in `scenes/villagers/`.

- `simple_villager.gd` — `Node2D` base: gentle sine-wave idle bob, `_build_visual()`
  for procedural art, exports `villager_name`, `first_visit_text`, `repeat_visit_text`,
  `repeat_visit_lines: PackedStringArray`. `get_repeat_line(visit_count)` returns the
  correct rotating line, falling back to `repeat_visit_text` if the array is empty.
- `bram_villager.gd` — extends `SimpleVillager`, overrides `_build_visual()` to draw
  Bram's hat, work jacket, and stubble. All dialogue data lives in the `.tscn`.
- `scenes/villagers/maribel_tock.tscn` — Maribel Tock. Sets name, first-visit text,
  and three rotating repeat lines.
- `scenes/villagers/bram_nettle.tscn` — Bram Nettle. Same structure, different values.

Villagers are registered with `register_region_interactable` using type `"villager"`.
The shared `_handle_villager_talk(villager, intro_flag, count_flag)` helper in the
village square controller handles first-visit check, flag write, and rotating line
selection from a single code path. Visit counts are stored as integer region flags
and persist via `LocalSaveSystem.set_region_flag` without a save version bump.

## Ambient Life

Ambient creatures live in `creatures/`:

- `ambient_creature.gd` — base class: idle/wander/flee state machine, no physics
  collision, no navmesh. Uses `Node2D` position updates only.
- `moss_rabbit.gd` — ground creature with procedural visual and hop animation.
- `lantern_moth.gd` — slow drifting creature with wing flutter and glow pulse.
- `stump_turtle.gd` — very slow ground creature with long idle pauses, a mossy
  stump shell, and a gentle shell wobble / head bob. Sets slower speed and longer
  idle exports before `super._ready()`, so it shares the base flee logic but
  retreats softly rather than darting like the rabbit.

Each creature is instantiated via code and added to the region's `gameplay_layer`.
`configure_creature(player)` gives the creature a player reference for flee
detection. Creatures observe the player distance every frame (no signals) and
switch to gentle flee when the player enters a 60px radius.

Observe interactions are registered with `InteractableSystem` using type
`"ambient_creature"`. Region controllers using `BaseRegionController` wire the
callback through `register_region_interactable`. The homestead uses its own
`_open_observe_panel` helper that mirrors the base pattern.

Creature state is session-local. Save compatibility is fully preserved — no new
save sections or migrations are needed.

## Near-Term Direction

The next useful step is to move one more homestead-specific responsibility into
a reusable region-scoped pattern, likely region-local placeables or region-local
farming helpers, while keeping chunk streaming and larger world systems dormant.
