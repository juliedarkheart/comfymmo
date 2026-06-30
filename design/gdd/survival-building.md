# GDD: Survival & Building Costs

> **Manifest Version:** 2026-06-30-v1
> **Status:** Approved
> **Source docs:** `docs/survival_building.md`, `docs/crafting.md`, `docs/building_placement.md`, `docs/farming.md`

---

## 1. Overview

The survival and building costs system provides a gentle resource economy for placement. Materials are standard inventory items gathered from the world. Every placeable has a defined material cost enforced at placement time. Comfort is the only survival pressure — a cosy stat that restores on rest. There is no hunger damage, no depletion, and no death. This is a "cozy survival" model: gather, build, restore, repeat.

## 2. Player Fantasy / Dream

Resources flow naturally from the world to the player's inventory to the built environment. The loop is satisfying but never punishing: gather wood/fiber/stone/clay from renewable nodes, spend them to build and decorate, rest to restore comfort. The HUD shows materials at a glance, and the placement ghost always explains exactly what's needed. The comfort stat encourages returning home to rest, but there are no drains or penalties.

## 3. Detailed Rules

### Materials

| Resource ID | Source | Offline Storage | Server Storage |
|-------------|--------|-----------------|----------------|
| wood | Log piles, chopping trees | `player.inventory.items.wood` | Server pouch |
| stone | Pebbles, boulders | `player.inventory.items.stone` | Server pouch |
| fiber | Fiber bushes | `player.inventory.items.fiber` | Server pouch |
| clay | Clay pits, deposits | `player.inventory.items.clay` | Server pouch |
| plank | Crafted (1 wood → 2 planks) | `player.inventory.items.plank` | Server pouch |
| rope | Crafted (2 fiber → 1 rope) | `player.inventory.items.rope` | Server pouch |
| stone_block | Crafted (2 stone → 1 block) | `player.inventory.items.stone_block` | Server pouch |
| clay_brick | Crafted (2 clay → 1 brick) | `player.inventory.items.clay_brick` | Server pouch |
| cloth_roll | Crafted | `player.inventory.items.cloth_roll` | Server pouch |
| flower_bundle | Crafted | `player.inventory.items.flower_bundle` | Server pouch |

### Build Costs (from `systems/building/build_costs.gd`)

| Placeable ID | Material Costs |
|-------------|----------------|
| crate | 2 wood |
| mailbox | 2 wood |
| stool | 2 wood |
| lantern | 1 wood + 1 fiber |
| planter | 2 clay |
| fence | 1 wood |
| blanket | 2 fiber |
| basket | 2 fiber |
| sign | 1 wood |
| shrub | 1 fiber |
| workbench | 3 wood + 2 stone |
| garden_table | 2 wood + 2 fiber |
| table | 2 plank |
| bench | 2 plank |
| cozy_chair | 2 plank + 1 cloth_roll |
| tea_table | 2 plank + 1 clay_brick |
| birdhouse | 1 plank + 1 rope |
| path_lantern | 1 stone_block + 1 rope |
| garden_arch | 2 plank + 1 rope + 1 flower_bundle |
| flower_bed | 1 flower_bundle + 2 clay |
| tiny_pond | 3 stone_block + 2 clay |

### Comfort System
- Comfort stat: 0–100, stored in `player.survival.comfort`
- Restored to 100 on rest (at cottage rest marker)
- Consuming a carrot: +5 comfort
- No automatic drain — comfort only decreases via future planned activities
- Displays on HUD comfort line

### Cost Enforcement
- Offline: placement ghost turns red with "Needs X Wood, Y Fiber" when unaffordable
- Placing spends materials from `InventorySystem`
- Server: validates against server pouch; denies with friendly message
- Materials line in HUD shows current counts
- Mode line shows active item's cost during placement
- Legacy region scenes (non-overworld) stay free — no inventory available

## 4. Formulas

### Cost Check
```
can_afford(placeable_id, inventory):
  cost = build_costs[placeable_id]
  for material_id, amount in cost:
    if inventory.get_item_count(material_id) < amount:
      return false
  return true
```

### Cost Spend
```
spend_cost(placeable_id, inventory):
  cost = build_costs[placeable_id]
  for material_id, amount in cost:
    inventory.remove_item(material_id, amount)
```

### Comfort Restore
```
rest(comfort) → 100  (full restore)
consume(carrot) → comfort = min(100, comfort + 5)
```

## 5. Edge Cases

- **Place with insufficient materials**: Ghost red, hint shows exact deficit, placement denied
- **Place with exactly enough materials**: Succeeds; inventory updated correctly to zero
- **Remove placed object**: No material refund (deliberate — prevents exploit loops)
- **Server pouch vs local inventory**: Server authoritative when connected; offline uses local
- **Admin bypass**: World-builder panel bypasses cost checks (trust-based, offline-only)
- **Legacy region build**: No cost enforcement (no inventory available in those scenes)
- **Comfort > 100**: Clamped at max; cannot exceed via carrot consume
- **Rest with full comfort**: Still allowed; mood/day advance as normal, comfort stays 100

## 6. Dependencies

| Depends On | Reason |
|------------|--------|
| InventorySystem | Offline material storage |
| LocalSaveSystem | Persistence of inventory and survival stats |
| BuildingPlacementSystem | Cost check/apply during placement |
| SurvivalSystem | Comfort stat storage |
| ObjectRegistry | Placeable definitions (validates all entries have costs) |
| InteractableSystem | Rest marker interaction |

## 7. Tuning Knobs

| Parameter | Location | Default | Notes |
|-----------|----------|---------|-------|
| Build costs | `build_costs.gd` | Per placeable | Dictionary, validated against known material IDs |
| Starter material counts | `InventorySystem` / server startup | TBD | Future: starter pack |
| Comfort max | `SurvivalSystem` | 100 | Clamp value |
| Comfort per carrot | `HomesteadController` | +5 | Easy to tune |
| Rest restore amount | `SurvivalSystem` | 100 (full) | Could be partial in future |
| Tool-node yields | `ResourceSpawnRegistry` | 2–4 | Higher than hand (1–3) |

## 8. Acceptance Criteria

1. All placeables have defined material costs in `build_costs.gd`
2. Materials are stored as standard inventory items
3. Placement checks material availability before allowing
4. Insufficient materials: ghost red, hint shows needed amounts
5. Placement spends correct materials from inventory
6. Server validates and spends from pouch when connected
7. Server denial returns friendly message (no state change)
8. Comfort stat displays on HUD
9. Rest restores comfort to 100
10. Carrot consume grants +5 comfort (clamped to 100)
11. All registry entries validated against known material IDs
12. Legacy region scenes have no cost enforcement
