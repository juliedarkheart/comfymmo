# Survival-lite building

Cozy, Minecraft-inspired loop: gather → pouch fills → build spends. Comfort
survival, not punishment survival — no hunger damage, no death, no depletion.

## Materials (`systems/resources/resource_ids.gd`)

| id | from | offline storage |
|---|---|---|
| wood | log piles (homestead SW, forest) | `player.inventory.items.wood` |
| stone | stone outcrops (homestead E, forest) | `...items.stone` |
| fiber | fiber bushes (homestead NE, village, forest) | `...items.fiber` |
| clay | clay pits (homestead NE, forest) | `...items.clay` |

Materials are ordinary inventory items, so they persist through the existing
player save with zero migration; the HUD shows them on their own line.

## Gathering

Eight `ResourceNode` spots across the overworld (wood/stone/fiber/clay ×
homestead/village/forest). Walk up, press F: 1–3 of the material, a friendly
panel, auto-saved. Nodes are infinite for now — respawn timers/cooldowns are
listed future work, deliberately skipped to stay un-punishing.

## Build costs (`systems/building/build_costs.gd`)

Every placeable has a cost in stable ids — examples: crate 2 wood, lantern
1 wood + 1 fiber, planter 2 clay, fence 1 wood, garden arch 3 wood + 2 fiber,
path lantern 1 stone + 1 fiber, picnic blanket 3 fiber, tiny pond 3 stone +
2 clay. Full table in the script; validation asserts every registered
placeable has an entry using known material ids.

## Enforcement

- **Offline**: the placement ghost turns red with "Needs 2 Wood, 1 Fiber" when
  you can't afford it; placing spends the materials. The mode line shows the
  active item's cost. Wired only where an inventory exists (homestead /
  overworld); legacy region scenes stay free.
- **Connected**: the server owns your pouch (starter pack on first join,
  persisted per profile). The server validates and spends; denials come back
  as a friendly message; the HUD materials line shows the server counts.

## Deliberately not done

Hunger/energy drains, tool durability, node depletion, crafting chains.
The comfort stat remains the only "survival" pressure.
