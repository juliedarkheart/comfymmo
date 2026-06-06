# World Regions

> **Architecture pivot (2026-06): continuous overworld.** Outdoor traversal is no
> longer paged. Homestead, village square, and forest edge now live together in one
> continuous scene, `scenes/world/overworld.tscn`, and the player walks between them
> with no scene swap, no Area2D transition, and no fade. `WorldRegionManager` boots
> straight into the overworld and is now reserved for *future instances* (dungeons,
> caves, interiors, special towns) — those will still scene-swap via the preserved
> deferred-transition machinery. The legacy paged region scenes below remain on disk
> as fallbacks / interior templates but are no longer loaded for outdoor play. See
> "Continuous Overworld" near the end of this document.

Historically Hearthvale treated the playable world as a set of named region scenes
swapped at the edges; that model now applies only to instanced, non-outdoor spaces.

## Current Regions

- `homestead`
- `village_square`
- `forest_edge`

`homestead` remains the only fully featured region for now. `village_square` is
a lightweight hub region, and `forest_edge` extends the seamless outdoor travel
pattern into a quieter nature-facing area.

## Runtime Shape

- `systems/world_region_manager.gd`
  loads the active region scene from save data and swaps regions on request
- `world/region/base_region_controller.gd`
  provides a small shared pattern for region ids, entry spawn ids, transition
  requests, region flags, and tiny local message panels
- `systems/region_transition_system.gd`
  is a tiny helper that region controllers use to request region swaps

## Region Scene Pattern

Each region is its own scene.

- `scenes/world/regions/homestead/homestead_region.tscn`
- `scenes/world/regions/village_square/village_square_region.tscn`
- `scenes/world/regions/forest_edge/forest_edge_region.tscn`

The current pattern is intentionally indie-sized:

- one active region loaded at a time
- region transitions are explicit scene swaps
- no chunk streaming yet
- no networking yet

## Save Shape

Region-local data now lives under:

```text
world.regions[region_id]
```

Current region-local sections:

- `placed_objects`
- `farming`
- `interactables`
- `region_flags`

The save layer now exposes reusable region helpers such as:

- `get_region_state(region_id)`
- `ensure_region_state(region_id)`
- `get_region_placed_objects(region_id)`
- `set_region_placed_objects(region_id, placed_objects)`
- `get_region_farming(region_id)`
- `set_region_farming(region_id, farming_state)`
- `get_region_flags(region_id)`
- `set_region_flag(region_id, key, value)`

The base region pattern now also exposes controller-level helpers such as:

- `get_region_state()`
- `get_region_flags()`
- `get_region_flag(key, default_value)`
- `set_region_flag(key, value)`
- `mark_region_flag_seen(key)`
- `show_region_message(title, body)`
- `hide_region_message()`
- `register_region_interactable(node, interactable_id, prompt, callback, interaction_type)`
- `unregister_region_interactable(interactable_id)`

Global player/task data remains outside region data:

- `player.inventory`
- `player.survival`
- `tasks.integration`

## Current Transition Flow

- the homestead road now opens into a seamless outdoor edge transition to `village_square`
- the village square road now opens into a seamless outdoor edge transition back to `homestead`
- the village square also opens eastward into `forest_edge`
- `forest_edge` returns to `village_square` through a matching trail edge
- outdoor travel no longer needs `F`
- `F` remains reserved for local interactables such as the mailbox, farm plot, and notice board
- the world region manager updates `world.current_region_id`
- a short transition cooldown prevents bounce loops while crossing region edges
- region swaps are deferred: a `body_entered` trigger only queues the target, and
  `WorldRegionManager._process_pending_transition` performs the unload/load/spawn on
  a `call_deferred` after the physics flush completes (so freeing the old region and
  spawning the player body never mutate physics state mid-query). Duplicate requests
  are ignored while a transition is pending.
- destination spawn points sit outside their return triggers, so arrivals do not
  immediately re-fire the opposite edge
- homestead state is preserved through existing immediate saves
- transition areas now sit close to the authored road or trail exits instead of far out in empty space

## Map Direction

The current region pass keeps one active scene at a time, but the authored maps
now aim for larger walkable outdoor spaces rather than tiny disconnected test
blocks.

- `homestead` reads as a broader yard and home approach with a visible road out
- `village_square` has a larger plaza footprint and road space for future shops,
  NPCs, and gathering points
- `forest_edge` acts as a cozy woodland border with trail space for future
  foraging, caves, or deeper forest routes
- `forest_edge` now includes one small old shrine marker that hints at a future
  adventure route without waking combat yet
- each region now uses tighter camera framing and limits so the player sees
  authored terrain instead of large void margins
- each map draws a full-bleed terrain **backdrop** (sized to the camera limits plus
  a margin) behind the iso ground, plus a ring of visual-only **apron** filler tiles
  around the authored core. Because the iso ground is a diamond and the camera bound
  is a rectangle, the backdrop guarantees the camera never reveals transparent void
  in the corners. The apron and backdrop carry no collision and are outside the
  gameplay/placement grid, so farming, placement, and movement are unchanged.
- the seamless transition `Area2D` bands were widened to `320x260` and centred over
  the road/path exits, so normal walking crosses them well before any boundary wall;
  destination spawns sit on the incoming path and outside the return trigger
- **continuity (streaming illusion) pass:** several lightweight techniques make the
  paged regions read as slices of one continuous outdoor world without real chunk
  streaming:
  - roads/trails are continued into the apron at each exit (`_apron_is_road`), so a
    road visibly runs off toward the next region rather than stopping at the edge,
    and the transition fires while the player is still walking on it
  - each map lines its non-exit edges with a visible vegetated border
    (`_build_edge_dressing`: shrubs/trees for homestead and village, a dense
    pine/rock treeline for forest), leaving openings at the road/path exits so the
    player intuitively reads where travel happens; these props carry no collision
  - camera limits were widened and `position_smoothing` enabled on `AvatarCamera`,
    so the camera keeps the player centred and drifts gently toward exits instead of
    hard-clamping at borders; `reset_smoothing()` on region entry avoids any swoop
  - `WorldRegionManager` owns a persistent full-screen fade overlay (on a high
    `CanvasLayer` that survives region swaps) and plays a brief ~0.32s fade-in after
    each swap, so travel reads as walking through rather than an instant teleport
    (no loading screen, deferred-transition and cooldown behaviour preserved)
- **scale / wilderness expansion pass:** the visible terrain footprint now greatly
  exceeds the gameplay footprint, moving toward an "authored anchor + generated
  wilderness" structure without real streaming:
  - each map runs `_build_wilderness()` — a deterministic, seeded
    (`WILDERNESS_SEED`) scatter of decorative props across the outer shell
    (`WILDERNESS_RADIUS` tiles beyond the core). It draws into the non-y-sorted
    ground layer (always behind gameplay, never occluding the play core) and uses
    helper drawers (`_add_decor_tree`/`_add_pine`/`_add_shrub`/`_add_rock`/
    `_add_flowers`/`_add_grass_tuft`, plus region flavour: homestead field fences,
    village distant cottages + road fragments, forest dense pine clusters). It is
    seed-friendly and helper-based rather than hardcoded tile lists, so future
    procedural regions can reuse the same approach
  - camera limits were widened further so the player reads as small in a broad
    landscape and the camera stays centred toward exits
  - apron rings were enlarged (`GROUND_APRON` 6 → 8) and roads continue further into
    the apron, tapering toward the edges so there are no abrupt endcaps
  - all wilderness is visual-only (no collision, outside the gameplay/placement
    grid), so farming, placement, interactables, travel, and saves are unaffected
- **terrain topology pass:** each map runs `_build_topology()` (between ground and
  wilderness) to add geographic shape using a tiny reusable primitive library,
  `world/terrain_shapes.gd` (`class_name TerrainShapes`: `ribbon()` for curved,
  tapering roads/streams/trails and `disc()` for plazas/treelines/rocks). Each cue
  is one or two large polygons, so the whole pass adds only ~40 nodes total:
  - homestead: a road curving toward the village exit, a shallow stream suggestion,
    distant field hedgerows, and two big foreground trees (placed beyond the walls)
  - village_square: a flagstone plaza disc making the fountain a landmark, roads
    branching to the west and east exits, two tapering side-street stubs, flower beds
  - forest_edge: layered distant treeline masses, a rocky ridge hint, a creek with a
    decorative crossing bridge, and a trail that curves in from the west and forks up
    to the tucked-away shrine
  - flat features draw in the ground layer (under props/player); the bridge and
    foreground trees are gameplay-layer occluders. Everything is decorative with no
    collision, so travel, interactions, farming, placement, and saves are unchanged
- future outdoor-adjacent regions should prefer edge/path travel
- interact-to-travel should be reserved for interiors, caves, portals, boats,
  and other explicit travel cases

## Village Square Proof

`village_square` now has a tiny region-specific interactable:

- a local notice board
- prompt: `Press F to read notice board`
- message: `Village Notice Board / Welcome to the village square.`
- optional seen state stored as:
  `world.regions.village_square.region_flags.notice_board_seen`
- this now uses the shared base region helpers rather than custom controller-only flag plumbing

## Forest Edge Proof

`forest_edge` now has a tiny adventure-facing point of interest:

- a local old shrine marker
- prompt: `Press F to inspect shrine`
- first message: `The path beyond is quiet... for now.`
- repeat message: `The marker still hums softly.`
- seen flag stored as:
  `world.regions.forest_edge.region_flags.adventure_marker_seen`
- this also uses the shared region message and region interactable helpers

## World Mood (All Regions)

A single global time-of-day mood applies consistently across every region. It is
manual, not a clock: press `T` to cycle `morning` → `afternoon` → `dusk` →
`morning`. Each phase applies a subtle cozy full-screen tint (warm gold, clear,
dusky purple) and the HUD shows the current phase on its `Time:` line.

The phase persists globally in `world.global_flags.current_mood`, so travelling
between `homestead`, `village_square`, and `forest_edge` keeps the same mood, and
it survives a restart. See `docs/system_architecture.md` for the implementation.

A global `Day:` number (`world.global_flags.day_count`, starting at 1) shows on the
HUD in every region. It advances only when the player rests at the homestead
cottage doorway (`Press F to rest`): resting steps morning → afternoon → dusk, and
resting at dusk rolls over to the next day's morning while restoring comfort. There
is no real-time clock, timer, or schedule — the day only moves when the player
chooses to rest.

## Village Square — Villager Presence

`village_square` has two named villager placeholders:

### Maribel Tock — calendar keeper / town helper
- Stands near the plaza, southwest of the notice board
- Prompt: `Press F to talk to Maribel`
- First visit: `Welcome to the village square. We keep plans, errands, and little celebrations pinned here.`
- Repeat visits: 3 rotating lines (visit count stored as `maribel_visit_count`)
- Seen flag: `world.regions.village_square.region_flags.maribel_intro_seen`
- Scene: `scenes/villagers/maribel_tock.tscn`

### Bram Nettle — gentle groundskeeper / plaza gardener
- Stands in the eastern garden area near the forest path
- Prompt: `Press F to talk to Bram`
- First visit: `Morning. I keep the paths trimmed and the flowerbeds from getting ideas.`
- Repeat visits: 3 rotating lines (visit count stored as `bram_visit_count`)
- Seen flag: `world.regions.village_square.region_flags.bram_intro_seen`
- Scene: `scenes/villagers/bram_nettle.tscn`

Neither villager has a schedule, pathfinding, inventory, or quest system.
Both idle gently with a soft bob animation.

## Ambient Life Presence

Each region has a small number of ambient creatures that wander, idle, and gently
flee the player. Creature count is intentionally low to keep the world cozy rather
than busy.

| Region | Creatures |
|---|---|
| `homestead` | 1 moss rabbit (quiet south garden) + 1 stump turtle (near the farm plots) |
| `village_square` | 1 moss rabbit (south plaza) |
| `forest_edge` | 3 moss rabbits + 2 lantern moths |

Creatures have no collision, no stats, no inventories, and no save data. They
reset to their spawn positions on each region load.

Walk near any creature and press `F` to observe it for a short flavor line.
Examples:
- "The moss rabbit twitches its ears."
- "The stump turtle blinks very slowly."
- "Tiny wings shimmer in the light."

## Continuous Overworld

`scenes/world/overworld.tscn` is the single outdoor scene. Its design reuses the
proven homestead stack by composition:

- `world/overworld_controller.gd` **extends `HomesteadController`** (the homestead
  controller now has `class_name HomesteadController`). It inherits the entire
  working homestead gameplay loop — farming, placement/edit/move/remove, mailbox,
  rest, mood/day cycling, comfort, inventory, ambient creatures, observe panels,
  and save — unchanged, then adds the village (Maribel, Bram, notice board, a
  rabbit) and forest (shrine, three rabbits, two moths) content into the same
  scene and `InteractableSystem`. It overrides `_on_interaction_requested` to add
  `villager` / `notice_board` / `shrine_marker` handling and delegates everything
  else to `super`.
- `world/overworld_map.gd` **extends `HomesteadMap`**, so the homestead grid,
  placement/collision helpers, and prop drawers are inherited. It overrides
  `_ready` to draw one continuous landscape: a screen-filling backdrop, broad
  region color tints, the detailed homestead yard at the origin, the village and
  forest areas at `VILLAGE_OFFSET (1500,120)` and `FOREST_OFFSET (3000,160)`,
  connecting roads, natural borders (north mountains, south river, east dense
  forest, west cliff), sparse seeded wilderness fill, the homestead colliders, and
  wide outer boundary walls. Camera framing is broad (`zoom 1.0`, wide limits).

Save compatibility is fully preserved because the overworld writes the same save
sections the paged regions used: homestead farming → `regions.homestead.farming`,
villager/notice flags → `regions.village_square.region_flags`, shrine flag →
`regions.forest_edge.region_flags`, plus the shared `player.*`, `world.global_flags`
(mood/day), and `tasks.integration`. No save version bump.

`WorldRegionManager` boots the overworld (`_load_starting_region` → `overworld`),
tolerates a non-`BaseRegionController` active scene, and keeps the deferred swap +
cooldown + fade machinery for future instance loading only.

## Notes

- the old homestead/village/forest region scenes still exist as legacy/fallback and
  future interior templates; they are not loaded for outdoor play
- the overworld reuses those regions' controllers/content by composition rather than
  rewriting them
- long-term direction: authored anchors (homestead/village/forest) with procedural
  wilderness generated between them inside this one continuous overworld
