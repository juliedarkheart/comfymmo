# World structure

One continuous outdoor overworld (no interiors, no scene swaps), organized as:

## Hearthvale Landing — Farmer Rowan's training farm (player start)

The spawn point. NPC-owned, never claimable, **open for practice building**
(it doubles as the tutorial build zone). Contains: welcome board, Farmer
Rowan (the tutorial NPC), the cottage (exterior; "inside coming soon" sign),
rest mat, wardrobe mirror, farm plots, hand-gather nodes for all four
materials, and the road east to town. **Players do not start with a home** —
they learn here, then claim a neighborhood lot.

## Town — the village square (public, protected)

The developed common area: fountain, market stall, notice board, villagers
(Maribel, Bram), and the new service stalls — General Store, Builder Supply,
Farming Supply, Wardrobe Stall (exterior kiosks with "coming soon" panels;
the economy comes later). The shrine sits at the forest edge as the community
landmark. **Town land is structurally unbuildable**: the placement grid only
exists over the Landing/neighborhood area, so no permission bug can ever let
someone build over the fountain.

## Neighborhood — the claimable lots (separate buildable region)

A real residential zone east and south of the farm, reached by a dirt road,
with an entrance sign + neighborhood board and Clerk Hazel the land clerk. Six
**homestead-sized** lots (7×6 / 6×6 tiles — full yards): Meadow 1–2 & Orchard
1–2 (east band), Creekside 1 & Grove 1 (south band). Each has a large sign,
corner posts, and a boundary outline. This is a **separate buildable region**
from the homestead core (`OverworldMap.is_tile_in_bounds` covers both); grid
tiles between lots are public neighborhood path. See docs/land_ownership.md.

## Wilderness — forest edge and beyond

Gathering tiers (hand nodes, chopping trees, boulders, clay deposits),
creatures, the shrine. Limited future building rules deferred.

## Terminology

- **Town** = public/common, protected.
- **Neighborhood** = the cluster of claimable plots.
- **Homestead** = your (eventually shared) plot.
- **Farmer training plot** = Rowan's NPC land, the tutorial zone.

Interiors remain deferred (docs/interiors_plan.md).
