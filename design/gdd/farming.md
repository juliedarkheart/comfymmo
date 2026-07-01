# GDD: Farming

> **Manifest Version:** 2026-06-30-v2
> **Status:** Approved — synced to live tool-gated prototype
> **Source docs:** `docs/farming.md`, `docs/system_architecture.md`, `docs/save_data_model.md`

---

## 1. Overview

The farming system provides a gentle tool-gated plant/water/rest/harvest loop
across three fixed farm plots in the homestead training area. Each plot is
pre-assigned a crop type (carrot, turnip, or berry). The current live prototype
uses inventory/hotbar tools: Hoe to till, Seed Packet to plant, and Watering Can
to water. Watered crops grow when the player rests at the cottage door.

This system supports the First Plot vertical slice:

```text
mailbox → farm → plant → water → rest → harvest → Rowan → Land Token → claim plot → place cozy object
```

No seasons, economy, shop, water-source/fill system, or multiplayer farming sync
are part of the current First Plot scope.

## 2. Player Fantasy / Dream

The player tends a small training garden by choosing the right cozy tool for the
moment. The loop should feel readable and low-pressure: till the soil, plant a
seed, water it, rest to let it grow, then harvest a carrot for the mailbox task.
Prompts, feedback, and HUD hints should always answer "what do I do next?"
without adding a quest system.

## 3. Detailed Rules

### Plots

- Three fixed farm plots in the homestead area:
  - `farm_plot_carrot`
  - `farm_plot_turnip`
  - `farm_plot_berry`
- Each plot has a default crop type.
- Plot definitions use stable IDs from `ContentIds`.
- Plots register with `InteractableSystem` for proximity prompts and `F` actions.

### Current Player-Facing Loop

| Step | Required selection | Player action | Result |
|---|---|---|---|
| Empty plot | Worn Hoe | Press `F` | Plot becomes tilled soil |
| Tilled soil | Seed Packet | Press `F` | Seed is spent; crop is planted |
| Planted crop | Watering Can | Press `F` | Crop becomes watered; `Water the garden` can complete |
| Watered crop | none; rest interaction | Rest at cottage door | Crop advances growth stage |
| Ready crop | none | Press `F` | Harvest grants `+1` crop item; carrot harvest can complete mailbox task |

The Watering Can works immediately in the current prototype. There is no fill
step or water-source search in the First Plot slice.

### Internal Stage Model

Current canonical internal stages in `FarmingSystem`:

```text
empty → tilled_soil → planted_seed → crop_stage_2 → crop_stage_3 → tilled_soil
```

Growth can also pass through `crop_stage_1` in data/tools. The key rule is that
planted/growing stages carry a `watered` boolean:

| Internal state | Meaning |
|---|---|
| `empty` | untouched plot; Hoe can till |
| `tilled_soil` | prepared soil; Seed Packet can plant |
| `planted_seed` | planted but not mature |
| `crop_stage_1` | intermediate growth stage |
| `crop_stage_2` | later growth stage |
| `crop_stage_3` | mature / harvest-ready |
| `watered=true` | next rest can advance the crop |

Legacy stage strings are still accepted for save compatibility, but they are not
the current design model:

- `planted_dry` → normalized to `planted_seed`, `watered=false`
- `planted_watered` → normalized to `crop_stage_2`, `watered=true`
- `grown` → normalized to `crop_stage_3`

### Crop Types

| Plot ID | Crop ID | Inventory Item |
|---------|---------|----------------|
| `farm_plot_carrot` | `carrot` | `player.inventory.items.carrot` |
| `farm_plot_turnip` | `turnip` | `player.inventory.items.turnip` |
| `farm_plot_berry` | `berry` | `player.inventory.items.berry` |

### Current First Plot Acceptance

The First Plot farming acceptance path requires:

- starter access to Hoe, Seed Packet, and Watering Can
- clear prompt/feedback for each tool-gated action
- rest at the cottage door to grow watered crops
- harvestable carrot adds a carrot item to inventory
- harvested plot returns to `tilled_soil`, not `empty`
- water/harvest mailbox tasks can complete
- player can then talk to Rowan, receive/use Land Token, claim land, and place a
  simple cozy object

### Consumables

- Carrot consumption is **deferred / not required for First Plot**.
- Do not describe carrot eating as a current acceptance requirement.
- Turnips and berries are not currently part of a player-facing consumption loop.

### Architecture

- `systems/farming_system.gd` — state machine, normalization, prompts,
  `till_plot`, `plant_seed`, `water_plot`, `grow_plot`, `harvest_plot`
- `farming/farm_plot.gd` — visuals for soil, moisture, growth, and ready state
- `world/homestead_controller.gd` — plot registration, selected-hotbar gating,
  Seed Packet spending, inventory grants, mailbox task hooks, save routing
- `ui/quick_tools_bar.gd` — selected inventory shortcut used by farming actions
- `systems/inventory_system.gd` — tools, Seed Packets, materials, harvested crops
- `systems/task_integration_system.gd` — mailbox task state

## 4. Formulas / Transitions

### Current Stage Transitions

```text
empty + Hoe + F → tilled_soil
tilled_soil + Seed Packet + F → planted_seed [spend 1 seed packet]
planted/growing + Watering Can + F → same stage with watered=true
watered planted/growing + Rest → next growth stage, watered=false
crop_stage_3 + F → tilled_soil [grant +1 crop to inventory]
```

### Task Completion

```text
water(any_plot) → complete_task("mock_water_garden")
harvest(carrot_plot) → complete_task("mock_harvest_carrot")
```

### Deferred Comfort / Consumables

```text
consume(carrot) → deferred; not a First Plot requirement
```

## 5. Edge Cases

- **Wrong tool selected**: Shows a short prompt naming the needed tool.
- **No Seed Packets left**: Planting is blocked with a clear inventory/gathering prompt.
- **Already watered crop**: Player is told to rest at the cottage door to grow it.
- **Harvested crop**: Plot returns to `tilled_soil` so the player can replant without
  tilling again.
- **Save file missing plot state**: Initializes plot to empty with default crop.
- **Legacy save stage names**: Normalized into the current stage model on load.
- **Unknown crop ID in save**: Falls back toward safe default crop behavior.
- **Multiple players interacting**: Farming is currently local/offline; multiplayer
  farming sync is future work.
- **Build mode active**: Farming interaction is suppressed while placement/edit modes
  own input.
- **Harvest with full inventory**: No inventory capacity limit exists; `+1` succeeds.

## 6. Dependencies

| Depends On | Reason |
|------------|--------|
| InventorySystem | Stores tools, seed packets, harvested crops |
| QuickToolsBar | Selects the active farming item/tool |
| InteractableSystem | Proximity detection and `F` routing for plots |
| LocalSaveSystem | Persists plot state |
| TaskIntegrationSystem | Marks farming mailbox tasks complete |
| ContentIds / ContentRegistry | Stable crop, plot, item, and interaction IDs |

## 7. Tuning Knobs

| Parameter | Location | Current | Notes |
|-----------|----------|---------|-------|
| Starter Seed Packets | `HomesteadController.STARTER_SEED_PACKET_COUNT` | 9 | Supports manual First Plot testing |
| Starter materials | `HomesteadController.STARTER_FIRST_PLOT_MATERIALS` | 2 Wood, 2 Fiber | Enough for one simple cozy object |
| Harvest yield | `HomesteadController` inventory grant | 1 crop | Keep simple for First Plot |
| Growth trigger | Rest at cottage door | manual rest | No real-time timer yet |
| Watering fill step | none | immediate watering | Future water-source model can be added later |
| Plot count | world scene | 3 fixed | Training farm scope |

## 8. Acceptance Criteria

1. Player can select Worn Hoe and press `F` at an empty plot to till soil.
2. Tilled plot shows a distinct prepared-soil visual/prompt.
3. Player can select Seed Packet and press `F` to plant on tilled soil.
4. Planting spends one Seed Packet and gives clear feedback.
5. Player can select Watering Can and press `F` to water a planted crop.
6. Watering completes/advances the `Water the garden` mailbox task where applicable.
7. Watered crop prompt tells the player to rest at the cottage door.
8. Resting advances watered crops toward harvest-ready state.
9. Harvest-ready crop can be harvested with `F`.
10. Harvest adds `+1` crop item to inventory.
11. Harvesting carrot completes/advances the `Harvest a carrot` mailbox task where applicable.
12. Harvested plot returns to `tilled_soil`.
13. Plot state persists across save/load cycles.
14. Old saves with legacy stage names normalize into the current state model.
15. First Plot starter/bootstrap supplies expose Hoe, Seed Packet, Watering Can,
    and enough materials to later place one cozy object.

## 9. Deferred / Not First Plot

- carrot consumption as a required loop
- cooking, hunger/energy drain, crop quality, seasons, fertilizer, weather
- seed shops, money, crop economy, or market pricing
- watering-can filling, durability, wells, or irrigation
- multiplayer farming authority/sync
- broad farming progression beyond the small action XP already wired in code
