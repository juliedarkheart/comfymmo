# Resources & gathering

## Acquisition paths (every material/component has at least one)

| resource | hand source (no tool) | tool source | other |
|---|---|---|---|
| wood | fallen branches (Landing SW, forest) | **chop trees** (axe, 2–4) | tasks, /give |
| stone | pebbles (Landing E, village, forest) | **mine boulders** (pickaxe, 2–4) | /give |
| fiber | wild fiber bushes (everywhere) | — | tasks, /give |
| clay | soft clay patches (Landing NE, forest) | **clay deposit** (shovel, 2–3) | /give |
| crops | — | farm plots (hoe + watering can) | — |
| components | — | crafted (K / stations) | /give |

Wood is deliberately the easiest farm: 7 hand branch piles + **6 marked
chopping trees** across Landing/village/forest with double-or-better yields.

## Tiers

- **Hand tier** (12 nodes): branches, pebbles, fiber, clay patches — 1–3 per
  gather, the soft-lock-safe floor.
- **Tool tier** (9 nodes): chopping trees (axe), boulders (pickaxe), clay
  deposit (shovel) — 2–4 per gather.

All nodes regenerate on a ~20s cooldown (dimmed while recovering; no
deforestation/depletion — server cooldowns still reset on restart, documented
temporary). Connected gathering is server-authoritative including the tool
check against your server pouch.

## Which trees are choppable

The marked chopping trees (thick trunk, axe-notch visual) in every area are
the gameplay trees. The painterly background trees in the ground layer remain
decorative on purpose — they're depth dressing drawn beneath gameplay, and
converting hundreds of them would either flood the world with interactables
or require a tree-instancing pass; that conversion is listed future work.
Practical wood farming is already easier than any other material.

## XP

Hand/tool gathering trains Gathering (wood/fiber) or Mining (stone/clay): +2
skill, +1 overall per gather — docs/progression.md.
