# GDD: Crafting

> **Manifest Version:** 2026-06-30-v1
> **Status:** Approved
> **Source docs:** `docs/crafting.md`, `docs/progression.md`, `docs/survival_building.md`

---

## 1. Overview

The crafting system ties together gathering, farming, and building. Players gather raw materials (wood, stone, fiber, clay), farm crops (carrot, turnip, berry), and combine them into components and placeable objects through recipes. Crafting trains the crafting skill and contributes to overall player XP. Recipes are gated by player level and skill level, creating a natural progression ladder.

## 2. Player Fantasy / Dream

The player progresses from gathering raw resources to crafting useful components — Planks from wood, Rope from fiber, Stone Blocks from stone — and then combines those components into beautiful placeable objects for their homestead. Each crafted item represents visible progress: a workbench unlocks new recipes, a garden arch decorates the yard, a cozy chair makes the home feel lived in. Crafting is the bridge between "what the world provides" and "what the player creates."

## 3. Detailed Rules

### Recipe Tiers

| Tier | Station | Recipes | Level Requirement |
|------|---------|---------|-------------------|
| Hand | Anywhere (K) | Planks, Fiber Rope | 1 |
| Workbench | Placed workbench | Stone Block, Clay Brick | 2 |
| Garden Table | Placed garden table | Seed Packet, Cloth Roll, Flower Bundle | 2–3 |

### Recipe Table

| Recipe | Inputs | Output | Level | Station | Skill Lock | XP |
|--------|--------|--------|-------|---------|------------|----|
| Planks | 1 wood | 2 plank | 1 | hand | — | +2 |
| Fiber Rope | 2 fiber | 1 rope | 1 | hand | — | +2 |
| Stone Block | 2 stone | 1 block | 2 | workbench | — | +3 |
| Clay Brick | 2 clay | 1 brick | 2 | workbench | — | +3 |
| Seed Packet | 1 carrot + 1 turnip | 1 packet | 2 | garden table | — | +4 |
| Cloth Roll | 2 fiber + 1 berry | 1 roll | 3 | garden table | Crafting 2 | +5 |
| Flower Bundle | 1 fiber + 2 berries | 1 bundle | 3 | garden table | Gathering 2 | +5 |

### Stations
- **Workbench**: Costs 3 wood + 2 stone to build (raw materials)
- **Garden Table**: Costs 2 wood + 2 fiber to build (raw materials)
- Stations are outdoor placeables built in normal build mode
- A placed station offers "Press F to craft" within ~110 world units
- Hand recipes (planks, rope) work anywhere via K

### Server-Authoritative Crafting
- Connected: panel routes to server; re-checks recipe, level, materials, station proximity against server state
- Spends from server pouch, grants XP, persists, replies
- Client preview checks against server materials and server-committed stations only
- Offline: panel checks against local InventorySystem state

### Limitations (Current)
- Crop-input recipes (seed packet, cloth roll, flower bundle) report "Need..." when connected — crops not synced yet
- No networked remove/move/edit of stations
- No placement XP for building with components
- No first-time-craft bonus XP

## 4. Formulas

### Crafting Check
```
can_craft(player, recipe) → (bool, reason)
  requires: player.level >= recipe.level
         AND player.skill(recipe.skill) >= recipe.skill_requirement
         AND player.has_materials(recipe.inputs)
         AND (recipe.station == "hand" OR player.nearby_station(recipe.station))
```

### Craft Execution
```
craft(player, recipe):
  spend_materials(player, recipe.inputs)
  grant_items(player, recipe.outputs)
  grant_xp(player, recipe.xp_crafting, recipe.xp_overall)
  player.crafting_skill += recipe.xp_crafting
```

### Building Tiers
- **Starter tier** (raw materials): crate, stool, lantern, planter, fence, blanket, baskets, signs, shrubs, stations
- **Crafted tier** (needs components): table/bench (planks), cozy chair (planks + cloth roll), tea table (planks + brick), birdhouse (plank + rope), path lantern (stone block + rope), garden arch (planks + rope + flower bundle), flower bed (flower bundle + clay), tiny pond (stone blocks + clay)

## 5. Edge Cases

- **Recipe requires level above current**: Greyed out in panel with "Requires Level N" text
- **Skill lock not met**: Ghost turns red with "Requires [Skill] Level N"
- **Not enough materials**: Panel shows deficit; preview shows required amounts
- **Station out of range**: "Need a [station name] nearby" message
- **Server disconnected while panel open**: Panel closes, offline crafting not disrupted
- **Admin `/give` command**: Offline-only; server ignores all commands
- **No recipes unlocked**: Hand recipes always available from level 1

## 6. Dependencies

| Depends On | Reason |
|------------|--------|
| InventorySystem | Material storage (offline) |
| ObjectRegistry | Placeable definitions for stations |
| PlayerProgression | Level/skill gates, XP grants |
| BuildingPlacementSystem | Station placement |
| InteractableSystem | Station proximity detection |
| NetworkSession | Server-authoritative crafting |

## 7. Tuning Knobs

| Parameter | Location | Default | Notes |
|-----------|----------|---------|-------|
| Recipe inputs/outputs | `crafting_registry.gd` | Per recipe | Stable IDs, never rename |
| Station proximity range | `CraftingSystem` | ~110 world units | Per-station configurable |
| XP rewards | Per recipe | +2 to +5 crafting, +1 to +2 overall | Tune per recipe tier |
| Level requirements | Recipe definitions | 1–3 | Adjust progression curve |
| Skill requirements | Recipe definitions | 0–2 | Gate advanced recipes |
| Build costs (stations) | `build_costs.gd` | workbench: 3w+2s, garden table: 2w+2f | Raw-material cheap |

## 8. Acceptance Criteria

1. Player can open hand-crafting panel with `K`
2. Hand recipes (Planks, Fiber Rope) are available from level 1
3. Placed workbench offers station crafting on `F`
4. Workbench recipes require workbench proximity
5. Placed garden table offers its recipes on `F`
6. Recipe level gates are enforced (greyed out with reason)
7. Skill gates are enforced (preview shows requirement)
8. Crafting spends materials from inventory/pouch
9. Crafting grants output items
10. Crafting grants XP (crafting skill + overall)
11. Level-ups from crafting toast in chat
12. Server-authoritative crafting works when connected
