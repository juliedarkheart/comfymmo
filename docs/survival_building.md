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

Twelve `ResourceNode` spots across the overworld (wood/stone/fiber/clay ×
homestead/village/forest), defined in `resource_spawn_registry.gd` — the same
catalog the server validates against. Walk up, press F: a "+2 Wood" toast in
the chat log, auto-saved. Each node then **recovers for 20 seconds** (dimmed;
"This spot is still recovering") instead of depleting — regeneration, never
punishment.

Connected to a server, gathering is **server-authoritative**: the client sends
the node id, the server validates it against the registry and its own per-node
cooldown, grants the materials into your server pouch, and the toast comes
from the server's reply. Note: server-side gather cooldowns are in-memory and
reset when the server restarts (temporary, documented).

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
