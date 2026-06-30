# GDD: Building Placement

> **Manifest Version:** 2026-06-30-v1
> **Status:** Approved
> **Source docs:** `docs/building_placement.md`, `docs/survival_building.md`, `docs/save_data_model.md`, `docs/system_architecture.md`

---

## 1. Overview

The building placement system allows players to place, edit, move, and remove objects in the homestead/neighbourhood area using an isometric grid. Objects are defined in a central ObjectRegistry with stable IDs, placed objects persist via the versioned JSON save format, and placement is gated by material costs enforced from the player's inventory (offline) or server pouch (online).

## 2. Player Fantasy / Dream

The player expresses their creativity by decorating their homestead with placed objects — from simple crates and lanterns to crafted furniture, garden arches, and tiny ponds. Build mode feels responsive: the preview follows the mouse with immediate validity feedback, placement is one click, and every object can be freely moved or removed. The homestead becomes a reflection of the player's journey and effort.

## 3. Detailed Rules

### Modes
| Key | Mode | Description |
|-----|------|-------------|
| `B` | Placement Mode | Select and place objects from build menu |
| `Tab` | Cycle Placeable | Switch active placeable in placement mode |
| `E` | Edit Mode | Select placed objects for operations |
| `M` | Move Mode | Reposition a selected object |
| `Delete`/`Backspace` | Remove | Delete selected placed object |

### Placement Flow
1. Press `B` → enters placement mode, shows build menu
2. `Tab` or build menu `Select` → chooses placeable type
3. Mouse moves → preview follows isometric grid, shows validity hint
4. Left click / `Enter` → confirms placement if valid
5. Materials are spent from inventory; object appears in world
6. `Esc` → cancels placement mode

### Edit/Remove Flow
1. Press `E` → enters edit mode, shows edit toolbar
2. Left click on placed object → selects it
3. `M` → enters move mode (preview follows mouse)
4. Left click / `Enter` → confirms new position
5. `Delete`/`Backspace` → removes object (no material refund)
6. `Esc` → cancels edit/move mode

### Grid Rules
- Isometric diamond grid defined in `IsoMapHelpers.grid_to_world` / `world_to_grid`
- Grid exists only in homestead/neighbourhood buildable area
- Static blocked tiles from map terrain
- Dynamic blocked tiles from previously placed objects
- Moving an object: temporarily frees old tile until confirmed/cancelled
- Player spawn tile is reserved (no placement allowed)
- All current placeables use 1×1 footprint

### Cost Enforcement
- Offline: checked against `InventorySystem`; ghost turns red with "Needs X" when unaffordable
- Connected: checked against server pouch; server validates and spends; denial returns friendly message
- HUD shows current material counts; materials line shows active item cost
- Legacy region scenes stay free (no inventory available)

### Save Format
See `docs/save_data_model.md` for full structure. Placed objects stored in `world.regions.<region_id>.placed_objects[]`.

### Current Placeables
| Object ID | Cost | Tier |
|-----------|------|------|
| crate | 2 wood | Starter |
| mailbox | 2 wood | Starter |
| stool | 2 wood | Starter |
| lantern | 1 wood + 1 fiber | Starter |
| planter | 2 clay | Starter |
| fence | 1 wood | Starter |
| workbench | 3 wood + 2 stone | Crafted |
| garden_table | 2 wood + 2 fiber | Crafted |
| table | 2 plank | Component |
| bench | 2 plank | Component |
| cozy_chair | 2 plank + 1 cloth_roll | Component |
| tea_table | 2 plank + 1 clay_brick | Component |
| birdhouse | 1 plank + 1 rope | Component |
| path_lantern | 1 stone_block + 1 rope | Component |
| garden_arch | 2 plank + 1 rope + 1 flower_bundle | Component |
| flower_bed | 1 flower_bundle + 2 clay | Component |
| tiny_pond | 3 stone_block + 2 clay | Component |

## 4. Formulas

### Placement Validation
```
can_place(placeable_id, tile_x, tile_y) → (bool, reason)
  requires: tile in buildable_bounds(tile_x, tile_y)
         AND not tile_blocked(tile_x, tile_y)        # map terrain
         AND not tile_occupied(tile_x, tile_y)        # dynamic placement
         AND not tile_is_spawn(tile_x, tile_y)
         AND has_materials(placeable_id)              # inventory or pouch check
```

### Move Validation
```
can_move(instance, new_tile_x, new_tile_y) → (bool, reason)
  requires: new_tile != instance.current_tile
         AND can_place(instance.object_id, new_tile_x, new_tile_y)
         # Temporary: old tile freed during move preview
```

### Cost Spending
```
place(placeable_id, tile_x, tile_y):
  cost = build_costs[placeable_id]
  spend_materials(cost.materials)
  create_instance(placeable_id, tile_x, tile_y)
  save_world_state()
```

## 5. Edge Cases

- **Placement while avatar moving**: Movement paused; placement mode suspends avatar controls
- **Placement with insufficient materials**: Ghost turns red; hint shows "Needs X Wood, Y Fiber"
- **Placement on occupied tile**: Hint shows "Occupied"
- **Placement on spawn tile**: Hint shows "Reserved spawn"
- **Placement out of bounds**: Hint shows "Out of bounds"
- **Move to same tile**: No-op (rejected early)
- **Avatar at spawn on load**: Reserved tile ensures no conflict
- **Dual-mode conflict**: Placement mode, edit mode, and move-preview are mutually exclusive
- **Missing object_id in save**: Skip on load, log warning
- **Server denies placement**: Friendly message, no state change, materials not spent

## 6. Dependencies

| Depends On | Reason |
|------------|--------|
| ObjectRegistry | Placeable definitions (scenes, IDs, metadata) |
| InventorySystem | Material spending (offline) |
| LocalSaveSystem | Persist placed objects |
| InteractableSystem | Mailbox registration for placed mailboxes |
| IsoMapHelpers | Grid coordinate conversion |
| BuildCosts | Material cost definitions |
| PlayerProgression | Level gates on placeables |

## 7. Tuning Knobs

| Parameter | Location | Default | Notes |
|-----------|----------|---------|-------|
| Build costs | `build_costs.gd` | Per placeable | Dictionary of material IDs → count |
| Placeable definitions | `ObjectRegistry` | Per object | Scene path, footprint, category |
| Footprint size | Per placeable | 1×1 | Future: variable footprints |
| Buildable bounds | `OverworldMap` | Homestead core + neighbourhood plots | Expanded via LandRegistry |
| Grid resolution | `IsoMapHelpers` | Isometric diamond | Fixed for project |

## 8. Acceptance Criteria

1. `B` opens build menu and enters placement mode
2. `Tab` cycles through available placeables
3. Preview follows mouse on grid with validity colour (green/red)
4. Left click places object on valid tile
5. Materials deducted from inventory on placement
6. `E` enters edit mode; click selects placed object
7. Selected object shows highlight/selection visual
8. `M` moves selected object; preview shows new position
9. Left click confirms move; old tile freed
10. `Delete` removes selected object
11. `Esc` cancels current mode without changes
12. Objects persist across save/load
13. Build menu shows cost, footprint, and availability per item
14. Server validates and enforces placement when connected
