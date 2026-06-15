# Tools & equipment

Tools are ordinary inventory items (offline) / pouch entries (server), so they
persist through the existing save paths. "Equipped" is implicit — owning a
tool enables its jobs; an explicit loadout/hotbar UI is future work, so every
denial message names the missing tool instead.

## The six starter tools

| tool | job | hand-craft recipe |
|---|---|---|
| worn_axe | chop trees | 2 wood + 2 stone |
| worn_pickaxe | mine boulders | 2 wood + 2 stone |
| worn_hoe | plant crops | 2 wood + 1 fiber |
| watering_can | water crops | 2 clay + 1 fiber |
| simple_hammer | place anything non-terrain | 1 wood + 2 stone |
| basic_shovel | clay deposits, paths/terrain overlays | 2 wood + 1 clay |

All six: level 1, no station, raw hand-gatherable materials only (validated —
see docs/new_player_onboarding.md for the soft-lock guarantee). New profiles
start with the full kit; old saves receive it once on next boot.

## Enforcement points

- Resource nodes: `required_tool` in `ResourceNode.definitions()` — checked
  offline in the gather handler and server-side in the gather RPC.
- Farming: hoe to plant, can to water (harvest is bare-hands), checked before
  the plot interaction.
- Building: `ContentRegistry.placeable_required_tool()` — terrain category →
  shovel, everything else → hammer; checked in the placement ghost (red +
  "Requires Simple Hammer") and server-side on placement requests.
- Admin (`/adminbuild` offline, server `roles`) bypasses tool checks.

## Durability / upgrades

Deliberately absent. Tools never break (cozy, not punishing); copper/iron
tiers, durability, and a visible loadout HUD are future milestones.
