# Farming

Hearthvale's current farming slice is a small, local, tool-gated prototype loop
built around the First Plot vertical slice. It is implemented in the homestead /
landing training farm and is intentionally scoped for manual playtesting, not a
full seasons/economy system.

## Current Shipped / Prototype Behavior

- Three fixed farm plots exist in the homestead training farm:
  - carrot
  - turnip
  - berry
- Farming is tool-gated through inventory + hotbar shortcuts:
  - **Worn Hoe** tills an empty plot
  - **Seed Packet** plants on tilled soil
  - **Watering Can** waters a planted crop
- The Watering Can works immediately in the current slice. There is no separate
  fill-water step yet.
- Watered crops grow when the player rests at the cottage door.
- Harvesting grants `+1` of the plot's crop to local inventory and returns the
  plot to `tilled_soil` for replanting.
- Watering completes the local mailbox task `Water the garden`.
- Harvesting completes the local mailbox task `Harvest a carrot`.
- Prompts, feedback toasts, and the HUD "Today:" hint teach the next step.
- Plot state saves and loads locally.

## Player-Facing Loop

For the First Plot carrot path:

1. Check the mailbox.
2. Select **Worn Hoe** on the hotbar and press `F` at an empty plot to till it.
3. Select **Seed Packet** and press `F` at tilled soil to plant.
4. Select **Watering Can** and press `F` at the planted crop to water it.
5. Rest at the cottage door to grow watered crops.
6. Repeat water/rest as needed until the carrot is ready.
7. Press `F` to harvest the carrot.
8. Talk to Rowan, receive/use the Land Token, claim a plot, then place one cozy object.

The First Plot manual test depends on this path:

```text
mailbox → farm → plant → water → rest → harvest → Rowan → Land Token → claim plot → place cozy object
```

## Internal Crop-State Model

`systems/farming_system.gd` is the source of truth for crop state. The current
canonical internal stages are:

- `empty`
- `tilled_soil`
- `planted_seed`
- `crop_stage_1`
- `crop_stage_2`
- `crop_stage_3`

The player-facing state language is simpler:

| Player-facing state | Internal state / flag | Main action |
|---|---|---|
| Empty plot | `empty` | Hoe tills soil |
| Tilled soil | `tilled_soil` | Seed Packet plants crop |
| Planted crop | `planted_seed`, `crop_stage_1`, `crop_stage_2` with `watered=false` | Watering Can waters crop |
| Watered crop | growing stage with `watered=true` | Rest at cottage door grows crop |
| Ready crop | `crop_stage_3` | Harvest grants crop item |
| Post-harvest bed | `tilled_soil` | Plant again |

The legacy save-stage names still exist only for migration compatibility:

- `planted_dry` normalizes to `planted_seed`
- `planted_watered` normalizes to `crop_stage_2` with `watered=true`
- `grown` normalizes to `crop_stage_3`

Do not treat `empty → planted_dry → planted_watered → grown → empty` as the
current shipped model. It is an older documentation/save shape.

## Architecture

- `systems/farming_system.gd`
  owns crop-state normalization, plot prompts, `till_plot`, `plant_seed`,
  `water_plot`, `grow_plot`, and `harvest_plot`.
- `farming/farm_plot.gd`
  owns the visual representation for tilled soil, moisture, growth stages, and
  harvest-ready state.
- `world/homestead_controller.gd`
  registers plots with `InteractableSystem`, gates `F` interactions by selected
  hotbar item, spends Seed Packets, grants harvested crops, marks mailbox tasks,
  and saves farming state.
- `ui/quick_tools_bar.gd`
  exposes inventory items as quickbar shortcuts; the selected item drives the
  farming action.
- `systems/inventory_system.gd`
  stores tools, Seed Packets, materials, and harvested crop counts.
- `systems/task_integration_system.gd`
  marks the local mailbox tasks `Water the garden` and `Harvest a carrot`
  complete when the crop is watered or harvested.

## Save Model

Farm plot state lives in:

```text
world.regions.homestead.farming.plots
```

Example current-shape data:

```json
{
  "farm_plot_carrot": {
    "crop_id": "carrot",
    "stage": "crop_stage_3",
    "watered": false
  },
  "farm_plot_turnip": {
    "crop_id": "turnip",
    "stage": "planted_seed",
    "watered": true
  },
  "farm_plot_berry": {
    "crop_id": "berry",
    "stage": "tilled_soil",
    "watered": false
  }
}
```

Harvested crops are stored in:

```text
player.inventory.items.carrot
player.inventory.items.turnip
player.inventory.items.berry
```

Starter tools, Seed Packets, and first-build materials are ordinary inventory
items too. The First Plot starter kit/bootstrap is documented in
`docs/playtest_readiness.md`.

## First Plot Requirements

A first-session or repaired stale-save test must provide:

- Worn Hoe or access to the Hoe hotbar shortcut
- Seed Packet / carrot seeds for the first planting pass
- Watering Can or access to the Watering Can hotbar shortcut
- immediate watering behavior; no fill-water step in the current slice
- enough materials or rewards to place one simple cozy object after claiming land

## Deferred / Future Farming Features

These are not required for the current First Plot slice:

- carrot consumption as a required loop
- cooking or hunger/energy drain
- seed economy, shops, or money
- watering-can filling, durability, or water sources
- real-time growth timers, seasons, weather, fertilizer, or crop quality
- multiplayer farming sync
- broader farming progression beyond the small XP grants already wired for actions

## Test Coverage

Relevant checks include:

- `tools/smoke_homestead_loop.gd`
  - validates `empty → tilled_soil → planted_seed → crop_stage_2 → crop_stage_3`
  - validates prompt copy for Seed Packet, Watering Can, rest-growth, and harvest
  - validates harvest/save/load behavior
  - validates First Plot starter/bootstrap minimums
- `tools/validate_project.gd`
  - validates starter Seed Packet count and first-build material coverage
  - validates bootstrap requirements for Hoe, Watering Can, Build Tool, Seed Packet,
    and quickbar surfacing

## Notes

- Farming is local/offline for now.
- Each harvest currently grants exactly one crop item.
- Fixed crop type per plot keeps the prototype path simple.
- The docs should follow live tool-gated behavior; do not simplify the code back to
  the old F-only stage model just to match older GDD text.
