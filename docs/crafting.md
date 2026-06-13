# Crafting

The loop that ties everything together:

```
gather / farm / complete tasks  →  craft components  →  build prettier things  →  XP  →  unlock recipes
```

## Pieces

- `systems/crafting/crafting_recipe.gd` — recipe schema + validator
- `systems/crafting/crafting_registry.gd` — all recipes (stable ids)
- `systems/crafting/crafting_system.gd` — shared check/spend/grant logic used
  by BOTH offline (InventorySystem) and server (MaterialInventory pouch)
- `systems/progression/player_progression.gd` — XP → level (1–5, cumulative
  thresholds 0/25/60/110/180)
- `ui/crafting_panel.tscn` — the panel (K for hand-crafting, or press F at a
  placed station; Esc closes)

## Components & recipes

| recipe | inputs | output | level | station | XP |
|---|---|---|---|---|---|
| Planks | 1 wood | 2 plank | 1 | hand | +2 |
| Fiber Rope | 2 fiber | 1 rope | 1 | hand | +2 |
| Stone Block | 2 stone | 1 block | 2 | workbench | +3 |
| Clay Brick | 2 clay | 1 brick | 2 | workbench | +3 |
| Seed Packet | 1 carrot + 1 turnip | 1 packet | 2 | garden table | +4 |
| Cloth Roll | 2 fiber + 1 berry | 1 roll | 3 | garden table | +5 |
| Flower Bundle | 1 fiber + 2 berries | 1 bundle | 3 | garden table | +5 |

Components are ordinary inventory items offline (auto-persisted) and pouch
entries on the server (persisted per profile). Crops as inputs are the
farming bridge — no farming code changed.

## Stations

**Workbench** (3 wood + 2 stone) and **Garden Table** (2 wood + 2 fiber) are
outdoor placeables built in normal build mode — raw-material costs so crafting
can bootstrap. A placed station offers "Press F to craft"; station recipes
need one within ~110 world units. Hand recipes (planks, rope) work anywhere
via K.

## Building tiers (BuildCosts)

Starter tier stays raw-material cheap (crate, stool, lantern, planter, fence,
blanket, baskets, signs, shrubs, stations). The crafted tier needs components:
tables/bench (planks), cozy chair (planks + cloth roll), tea table (planks +
clay brick), birdhouse (plank + rope), path lantern (stone block + rope),
garden arch (planks + rope + flower bundle), flower bed (flower bundle +
clay), tiny pond (stone blocks + clay).

## XP & levels

Crafting trains the **crafting skill** by the recipe's reward (overall XP is
roughly half), within the full skill system — see docs/progression.md for the
curve, all eight skills, and every XP source. Recipe gates now include skill
locks: Cloth Roll requires Crafting 2, Flower Bundle requires Gathering 2.
Level-ups are announced in chat.

## Tasks & farming

Completing the mailbox tasks (water garden, harvest carrot) now rewards
+2 wood, +2 fiber, +10 XP with a toast — the quest-like source for now.
Crops feed the seed packet / cloth / flower recipes directly.

## Server-authoritative crafting

Connected, the panel routes to the server: it re-checks recipe, level,
materials, and station proximity against ITS state, spends from the server
pouch, grants XP, persists, and replies. The client panel previews with the
same shared `CraftingSystem.check`, against server materials/XP and
server-committed stations only, so preview and authority agree.

**Limitation:** the server pouch holds materials/components only — crops do
not sync yet, so the three crop-input recipes (seed packet, cloth roll,
flower bundle) report "Need ..." while connected. Craft those offline for
now; crop sync is the documented next step.

## Admin / world-builder

Trust-based prototype (same model as F10 dev tools): the chat command
`/give <id> [amount]` grants materials/components **offline only** — the
server ignores commands, so connected players cannot self-grant. There are no
admin-only recipes yet; admin crafting therefore awards no XP it shouldn't.

## Deferred

- crop/item sync to the server pouch (unblocks crop recipes online)
- placement XP for building with components
- recipe unlock notifications beyond level-up chat lines
- kiln/loom/cooking stations and glass/hardware components (no greenhouse yet)
- first-time-craft bonus XP
