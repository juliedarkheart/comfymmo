# Land Ownership

## Plot layout

The claimable neighborhood now uses 4 large homestead lots, not the older small
strip of mini-plots.

Current claimable lots in `systems/land/land_registry.gd`:

- Meadow Lot 1
- Meadow Lot 2
- Orchard Lot 1
- Orchard Lot 2

Each claimable lot is `12x12` tiles, or 144 build tiles.

Farmer Rowan's Training Farm remains a separate non-claimable tutorial plot in
the original homestead core.

## Large plot requirement

This branch treats "homestead-sized" as at least `12x12`.

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
