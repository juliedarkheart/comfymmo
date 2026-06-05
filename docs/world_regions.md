# World Regions

Hearthvale now treats the playable world as a set of named regions instead of a
single always-loaded map scene.

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

## Notes

- the old homestead scene still contains the live homestead gameplay logic
- the new homestead region wraps that scene rather than rewriting it
- future regions should follow the region scene pattern before any chunking work
