# Farming

Hearthvale now has a first small local farming slice with multiple fixed-crop
plots inside the homestead.

## Current Scope

- three fixed farm plots in the homestead
- three crop types:
  - carrot
  - turnip
  - berry
- `F` plants when the plot is empty
- `F` waters when the crop is dry
- `F` tends when the crop is watered
- `F` harvests when the crop is grown
- harvest adds `+1` of the plot's crop to the local inventory
- `C` consumes one carrot for `+5 comfort`
- watering the crop completes the local mailbox task `Water the garden`
- harvesting the crop completes the local mailbox task `Harvest a carrot`
- plot state saves and loads locally

## State Model

Each plot uses a small stage model:

- `empty`
- `planted_dry`
- `planted_watered`
- `grown`

Current interaction flow:

1. `empty -> planted_dry`
2. `planted_dry -> planted_watered`
3. `planted_watered -> grown`
4. `grown -> empty`

This is intentionally interaction-driven for now. No real-time growth, seasons,
or tools are active yet.

## Architecture

- `systems/farming_system.gd`
  owns per-plot crop assignment, prompts, and simple stage transitions
- `farming/farm_plot.gd`
  owns placeholder visuals for soil, sprout, watered, and grown states, now
  with simple crop-specific color accents
- `world/homestead_controller.gd`
  registers all three plots with `InteractableSystem`, routes `F` interactions, and
  saves farming state back into the versioned save file
- `systems/inventory_system.gd`
  receives `+1` harvested crop item and persists those counts through the player
  save section
- `systems/task_integration_system.gd`
  marks the local mailbox tasks `Water the garden` and `Harvest a carrot`
  complete when the crop is watered or harvested

## Save Model

Farm plot state lives in:

```text
world.regions.homestead.farming.plots
```

Example:

```json
{
  "farm_plot_carrot": {
    "crop_id": "carrot",
    "stage": "grown"
  },
  "farm_plot_turnip": {
    "crop_id": "turnip",
    "stage": "planted_dry"
  },
  "farm_plot_berry": {
    "crop_id": "berry",
    "stage": "empty"
  }
}
```

Harvested crops are stored in:

```text
player.inventory.items.carrot
player.inventory.items.turnip
player.inventory.items.berry
```

Comfort is stored in:

```text
player.survival.comfort
```

## Notes

- the plots are local-only
- each harvest currently grants exactly one item
- carrots can be consumed locally for a small comfort boost
- no seed counts, money, tools, or timers exist yet
- fixed crop type per plot keeps the loop simple for now
- prompts update based on each plot's current crop and stage
