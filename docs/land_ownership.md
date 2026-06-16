# Land Ownership

## Plot layout

The claimable neighborhood is now **6 lots spread across distinct biome spots**,
not a tight cluster. Each has its own size, look (biome ground tint, sign
accent, and light decor), and place in the world.

Current claimable lots in `systems/land/land_registry.gd`:

| lot | biome | tile rect | size |
|---|---|---|---|
| Meadow Lot | meadow | `(24,15)` | 16×16 |
| Orchard Lot | orchard | `(26,37)` | 20×20 |
| Creekside Lot | creekside | `(10,40)` | 14×14 |
| Hilltop Lot | hilltop | `(24,-6)` | 16×16 |
| Grove Lot | grove | `(46,28)` | 16×16 |
| Brook Lot | brook | `(2,22)` | 14×14 |

The lots are pairwise disjoint and scattered (north hilltop, western
brook/creekside, southern orchard, eastern grove) so the neighborhood feels
varied rather than gridded. The player can walk and build across an entire lot,
right up to all four corners (validated). To fit the spread the overworld
movement walls and camera were pushed out: south to ~world_y 1820, west to
~world_x -1500, with the camera framing `Rect2i(-1560,-460,5380,2440)`.

Farmer Rowan's Training Farm remains a separate non-claimable tutorial plot in
the original homestead core.

### Editor-made (runtime) plots

The in-game world-builder can add, resize, and remove **runtime plots** live
(see docs/world_builder_tools.md). These behave exactly like built-in lots —
claimable, buildable, drawn, on the minimap — and persist to the offline save's
`runtime_plots` flag. They're kept in a runtime overlay on `LandRegistry` that
merges into every plot query; project validation only sees the static built-in
catalog.

## Large plot requirement

This branch treats "homestead-sized" as at least `16x16` (256 tiles). Four of
the six built-in lots meet that bar (meadow, orchard 20×20, hilltop, grove); the
creekside and brook lots are cozier `14x14` for variety. The validator requires
at least four claimable lots `16x16` or larger.

That requirement matters because the building kit is no longer just stools and
mailboxes. A real player lot now needs room for:

- a prefab shell
- paths and terrain overlays
- fences and gates
- stations and storage
- modular exterior experiments

The validator also checks that large plot centers are actually buildable, so
these are not just decorative rectangles on the map.

## Where building is allowed

The outdoor buildable area is:

- the training-farm core
- the neighborhood lot region

Town and forest remain structurally unbuildable because they are off the
placement grid.

## Claiming

Claiming still costs 1 Land Token.

The typical flow is:

1. get a token
2. walk to a plot sign or use the land flow
3. claim the lot
4. build inside that lot as the owner

Offline and server modes share the same rulebook in
`systems/land/land_claim_system.gd`.

## Build permission rules

- unclaimed lot: denied until claimed
- owned lot: owner can build
- shared lot: invited members can build
- someone else's lot: denied
- tutorial land: allowed as practice space
- public commons on the build grid outside plots: allowed
- admin/world-builder bypass: allowed

The validator covers the key cases:

- owner allowed inside a large plot
- non-owner denied inside another player's plot
- admin bypass allowed

## Sharing

Shared building is modeled through plot membership. The owner can invite another
player, and that invited member then gains build permission on the plot.

The low-level data path exists now; richer co-op management UI is still future
work.

## Current limitations

- plot economy is still token-based and simple
- plot sharing is functional but not fully surfaced through dedicated UI
- admin tools are stronger than normal player rules by design
- player-created adventure or dungeon plots are future work, not part of land
  ownership in this branch
