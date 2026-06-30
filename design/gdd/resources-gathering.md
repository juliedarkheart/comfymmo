# GDD: Resources & Gathering

> **Manifest Version:** 2026-06-30-v1
> **Status:** Approved
> **Source docs:** `docs/resources_and_gathering.md`, `docs/survival_building.md`, `docs/progression.md`, `docs/overworld_architecture.md`

---

## 1. Overview

The gathering system provides renewable resource nodes across the overworld that players can harvest for crafting and building materials. Four resource types (wood, stone, fiber, clay) are available through hand-gather nodes and higher-yield tool-gather nodes. All nodes regenerate on a cooldown — no depletion, no deforestation. Gathering feeds directly into the inventory (offline) or server pouch (online) and trains the gathering and mining skills.

## 2. Player Fantasy / Dream

The world generously provides. Fallen branches, pebbles, fiber bushes, and clay patches are scattered across the landscape, ready to be gathered with a simple press of F. Chopping trees with an axe, mining boulders with a pickaxe, or digging clay with a shovel yields more — but the hand-gather floor ensures the player is never stuck. Nodes recover after a short rest, so the world never runs out. Gathering feels like a peaceful walk through a resource-rich countryside.

## 3. Detailed Rules

### Resource Types

| Resource | Hand Source | Tool Source | Skill XP | Overall XP |
|----------|-------------|-------------|----------|------------|
| Wood | Fallen branches (7 nodes) | Chopping trees (6 nodes, axe) | +2 gathering | +1 |
| Stone | Pebbles (scattered) | Boulders (pickaxe) | +2 mining | +1 |
| Fiber | Wild fiber bushes (everywhere) | — | +2 gathering | +1 |
| Clay | Soft clay patches | Clay deposit (shovel) | +2 mining | +1 |

### Node Locations

12 hand-gather nodes distributed across the overworld (homestead, village, forest areas):
- **Wood**: Fallen branches in Landing SW area and forest
- **Stone**: Pebbles in Landing E, village, forest areas
- **Fiber**: Wild fiber bushes across all areas
- **Clay**: Soft clay patches in Landing NE area and forest

6 tool-gather nodes:
- **Chopping trees** (axe): Marked with thick trunk + axe-notch visual across Landing/village/forest — 2–4 wood per gather
- **Boulders** (pickaxe): Mining nodes — 2–4 stone per gather
- **Clay deposit** (shovel): Rich clay source — 2–3 clay per gather

### Gathering Flow
1. Walk up to resource node
2. Press F: "+2 Wood" toast in chat log, auto-saved
3. Node enters recovery state (~20s cooldown, dimmed visual)
4. During recovery: "This spot is still recovering" message
5. After cooldown: node reactivates, ready to gather again

### Server-Authoritative Gathering (Connected)
- Client sends node id to server
- Server validates against `ResourceSpawnRegistry` + per-node cooldown
- Server grants materials to server pouch
- Toast from server reply
- Tool check (axe/pickaxe/shovel) enforced against server pouch contents
- Note: server-side cooldowns are in-memory and reset on server restart (temporary)

### XP
- Hand/tool gathering wood/fiber: +2 gathering skill, +1 overall XP
- Hand/tool gathering stone/clay: +2 mining skill, +1 overall XP

## 4. Formulas

### Gather Yield
```
gather(resource_node):
  if node.cooldown_active:
    return "Still recovering..."
  else:
    if node.is_hand_node:
      yield = random_range(1, 3)
    elif node.is_tool_node:
      yield = random_range(2, 4)  # (2-3 for clay)
    node.start_cooldown(20_000)  # ms
    grant_item(node.resource_id, yield)
    grant_gather_xp(node.resource_id)
    return "+" + str(yield) + " " + node.resource_name
```

### Cooldown
```
node_cooldown = 20000 ms (20s)
Server: in-memory, resets on restart
```

## 5. Edge Cases

- **Gather while inventory full**: No capacity limit currently; always succeeds
- **Tool gather without tool**: Hand yield fallback? Not implemented — tool nodes need tool check
- **Server restart**: In-memory cooldowns reset (documented temporary)
- **Node interacted with simultaneously by two players**: Server-authoritative prevents double-grant
- **Offline gather persistence**: Materials added to local inventory; immediate save
- **Chopping vs decorative trees**: Marked chopping trees (thick trunk + axe-notch) are gameplay trees; background trees remain decorative
- **Node at edge of world**: Nodes placed within overworld bounds

## 6. Dependencies

| Depends On | Reason |
|------------|--------|
| ResourceSpawnRegistry | Node definitions across overworld |
| InventorySystem | Material storage (offline) |
| LocalSaveSystem/NetworkSession | Persistence |
| InteractableSystem | Proximity interaction for nodes |
| PlayerProgression | Gathering/mining XP |
| NetworkSession | Server-authoritative validation |

## 7. Tuning Knobs

| Parameter | Location | Default | Notes |
|-----------|----------|---------|-------|
| Hand gather yield | `ResourceSpawnRegistry` | 1–3 | Per-resource-type |
| Tool gather yield | `ResourceSpawnRegistry` | 2–4 | Axe: 2-4, Pickaxe: 2-4, Shovel: 2-3 |
| Node cooldown | `ResourceSpawnRegistry` | 20s | In-memory (server) |
| Count of hand nodes | world scene | 12 | Spread across 3 areas |
| Count of tool nodes | world scene | 6 | Marked visually |
| XP per gather | `PlayerProgression` | +2 skill, +1 overall | Tune for progression pace |

## 8. Acceptance Criteria

1. Player walks to resource node and sees "Press F to gather" prompt
2. F gather adds material to inventory and shows toast
3. Node enters dimmed recovery state after gather
4. Gathering during cooldown shows "Still recovering" message
5. Node reactivates after cooldown
6. Tool nodes require tool in inventory (axe/pickaxe/shovel)
7. Tool nodes yield more than hand nodes
8. Server validates gather when connected (node id + cooldown)
9. Server grants materials to correct player pouch
10. XP awarded: gathering skill for wood/fiber, mining skill for stone/clay
11. All 4 resource types available across the overworld
12. Chopping trees visually distinct from decorative trees
