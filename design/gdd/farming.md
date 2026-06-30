# GDD: Farming

> **Manifest Version:** 2026-06-30-v1
> **Status:** Approved
> **Source docs:** `docs/farming.md`, `docs/system_architecture.md`, `docs/save_data_model.md`

---

## 1. Overview

The farming system provides a gentle plant/water/harvest loop across three fixed farm plots in the homestead area. Each plot is pre-assigned a crop type (carrot, turnip, or berry). The loop is entirely interaction-driven — no real-time growth, seasons, tools, or timers. Farming feeds into the crafting system (crops as recipe inputs) and the task system (watering/harvesting completes mailbox tasks).

## 2. Player Fantasy / Dream

The player tends their homestead garden with simple, satisfying interactions. They walk up to a plot, press `F` to plant, water, or harvest depending on the current stage, and watch their crops grow through visible visual states (bare soil → sprout → watered → ready to harvest). Each harvest yields a crop item that can be consumed for comfort or used in crafting recipes. It is a low-pressure, meditative loop at the heart of the cozy experience.

## 3. Detailed Rules

### Plots
- Three fixed farm plots in the homestead area: `farm_plot_carrot`, `farm_plot_turnip`, `farm_plot_berry`
- Each plot is permanently assigned its crop type
- Plot definitions are in `systems/farming_system.gd` with IDs in `ContentIds`
- Plots register with `InteractableSystem` for proximity interaction

### Stage Model
```
empty → planted_dry → planted_watered → grown → empty
```

| Stage | Interaction | Result |
|-------|-------------|--------|
| empty | `F` (plant) | Transitions to planted_dry |
| planted_dry | `F` (water) | Transitions to planted_watered; completes "Water the garden" task |
| planted_watered | `F` (tend) | Transitions to grown |
| grown | `F` (harvest) | Returns to empty; +1 crop item to inventory; completes "Harvest a carrot" task |

### Crop Types
| Plot ID | Crop ID | Inventory Item |
|---------|---------|----------------|
| farm_plot_carrot | carrot | `player.inventory.items.carrot` |
| farm_plot_turnip | turnip | `player.inventory.items.turnip` |
| farm_plot_berry | berry | `player.inventory.items.berry` |

### Consumables
- Carrots can be consumed (`C`) for +5 comfort
- Turnips and berries are currently not consumable (future: cooking)

### Architecture
- `systems/farming_system.gd` — per-plot state machine, prompts, transitions
- `farming/farm_plot.gd` — placeholder visuals (soil, sprout, watered, grown) with crop-specific color accents
- `world/homestead_controller.gd` — registers plots, routes `F` interactions, saves farming state
- `systems/inventory_system.gd` — receives harvested items
- `systems/task_integration_system.gd` — marks mailbox tasks complete

## 4. Formulas

### Stage Transitions
```
empty + F → planted_dry
planted_dry + F → planted_watered
planted_watered + F → grown
grown + F → empty [grants +1 crop to inventory]
```

### Comfort from Consumables
```
consume(carrot) → +5 comfort
```

### Task Completion
```
water(any_plot) → complete_task("mock_water_garden")
harvest(carrot_plot) → complete_task("mock_harvest_carrot")
```

## 5. Edge Cases

- **Plot at empty stage with no crop assigned**: Shows "Press F to plant [crop]" prompt; empty plot defaults to its assigned crop
- **Save file missing plot state**: Initializes all plots to empty stage with default crop assignments
- **Unknown crop ID in save**: Resets plot to empty on load
- **Multiple players interacting**: Currently local-only; no multiplayer farming sync
- **Plot interaction while in build mode**: Suppressed — placement/edit/move modes take priority
- **Harvest with full inventory**: Currently no capacity limit; +1 always succeeds

## 6. Dependencies

| Depends On | Reason |
|------------|--------|
| InventorySystem | Stores harvested crops |
| InteractableSystem | Proximity detection for plots |
| LocalSaveSystem | Persists plot state |
| TaskIntegrationSystem | Marks farming tasks complete |
| ContentIds | Crop and plot IDs |

## 7. Tuning Knobs

| Parameter | Location | Default | Notes |
|-----------|----------|---------|-------|
| Crop types per plot | `FarmingSystem` constants | 3 fixed | Add new crop IDs to extend |
| Harvest yield | `FarmingSystem` | 1 per harvest | Future: variable yields |
| Comfort from carrot | `HomesteadController` | +5 | Tune for game feel |
| Stage progression | `FarmingSystem` | Interaction-driven | Future: add growth timers |
| Plot count | world scene | 3 | Fixed in homestead |

## 8. Acceptance Criteria

1. Player can walk up to an empty plot and press `F` to plant
2. Planted plot shows different visual state from empty (sprout)
3. Watering transitions to watered state and completes mailbox task
4. Watered plot shows different visual state (watered)
5. Tending grows the crop to harvest-ready state
6. Harvest adds +1 crop item to inventory
7. Harvested plot returns to empty for replanting
8. Carrot can be consumed for +5 comfort
9. Plot state persists across save/load cycles
10. Old saves without farming state initialize with defaults
