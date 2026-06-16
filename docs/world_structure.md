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

A residential zone reached by dirt roads, with an entrance sign + neighborhood
board and Clerk Hazel the land clerk. **Six lots spread across distinct biome
spots** rather than a tight grid — meadow, orchard (20×20), creekside, hilltop
(to the north), grove (east), and brook (west) — sizes 14×14 to 20×20. Each lot
carries its biome ground tint, a large readable sign, four corner posts, a soft
boundary outline, and light biome decor (orchard/grove trees, creekside/brook
ponds, meadow/hilltop flowers and rocks). This is a **separate buildable region**
from the homestead core: `OverworldMap.is_tile_in_bounds` covers the core AND
every plot rect (grown by a path margin), querying `LandRegistry.all_plot_rects()`
so **editor-made plots become buildable the moment they're created**. Tiles
around the lots are public neighborhood path. The overworld movement walls and
camera were expanded south (~world_y 1820) and west (~world_x -1500) to hold the
spread. See docs/land_ownership.md and docs/world_builder_tools.md.

## Wilderness — forest edge and beyond

Gathering tiers (hand nodes, chopping trees, boulders, clay deposits),
creatures, the shrine. Limited future building rules deferred.

## Terminology

- **Town** = public/common, protected.
- **Neighborhood** = the cluster of claimable plots.
- **Homestead** = your (eventually shared) plot.
- **Farmer training plot** = Rowan's NPC land, the tutorial zone.

Interiors remain deferred (docs/interiors_plan.md).
