# Land ownership & plots (prototype)

## Plot layout (homestead-sized lots in a real neighborhood)

Six claimable **homestead-sized** lots (7×6 / 6×6 tiles each — a full yard,
many times a single object footprint) live in a **neighborhood** region east
and south of the farm, reached by a dirt road from the core:

- East band: Meadow Lot 1 & 2, Orchard Lot 1 & 2
- South band: Creekside Lot 1, Grove Lot 1

Each lot has a **large sign** (with its name on a plate), **corner posts**, and
a **boundary outline** so it reads as a real parcel. The original homestead
core stays **Rowan's Training Farm** (NPC-owned, tutorial-build). The
neighborhood is a separate buildable region (`OverworldMap.is_tile_in_bounds`
covers the core *and* the neighborhood rects); town/forest are off the grid and
structurally unbuildable. Iso note: a tile rect projects to a diamond, kept
small enough in tile-sum that lots stay within the walkable world.

You can claim a lot from its sign (land panel → Claim) or at the Land Office
(Clerk Hazel lists all lots + ids). The minimap (M) shows every lot tinted by
ownership.

## Model

- Static plot catalog: `systems/land/land_registry.gd` — tile rectangles on
  the buildable grid with `claimable`, `npc_owned`, `tutorial_build`,
  `price_tokens`, `area_id` metadata. Helpers: `all_plot_rects()`,
  `corner_tiles()`, `plot_at_tile()`.
- Ownership state: `systems/land/land_plot.gd` — per-plot
  `{status, owner_profile_id, owner_username, member_profile_ids, claimed_at}`
  with statuses unclaimed/reserved/owned/public/npc_owned/admin_locked.
- Rules: `systems/land/land_claim_system.gd` — ONE pure rulebook for claiming
  and build permission, shared verbatim by the offline controller and the
  server (the CraftingSystem pattern).

## Claiming

Cost: **1 Land Token** (quest item). Rowan hands you one on first talk
(offline); the server starter pack includes one. Walk to a plot sign, press F:
available + token → claimed (token spent, owner recorded, toast, stewardship
XP); owned → shows the owner; no token → friendly pointer to Rowan.

Persistence: offline under the save's overworld flags (`land_plots`);
connected, claims are **server-authoritative** — the server validates, spends
the token from your pouch, persists into the world file's `plots` section
(old worlds default to all-unclaimed), broadcasts the claim in chat, and syncs
plot state to every client.

## Build permission (enforced offline AND server-side)

| where | rule |
|---|---|
| town/village/forest | structurally unbuildable (off the placement grid) |
| Rowan's training farm | open practice building (tutorial zone) |
| public commons (grid outside plots) | everyone may build |
| unclaimed plot | denied: "Claim Meadow Lot 1 before building here" |
| owned plot | owner + members may build; others denied: "This is julie's plot" |
| admin / world-builder | bypasses everything (`/adminbuild` offline; `roles` map on server) |

## Shared plots / friends

Implemented (multiplayer). A plot owner runs **`/invite <username>`** in chat;
the server resolves the username via its `registered_users` registry, adds that
profile to the plot's `member_profile_ids`, persists, and notifies both
players. Members can then build on the plot (the permission rulebook already
honors `member_profile_ids` for owner and members alike). The plot's `/invite`
targets the lot you're standing on, or your first owned lot otherwise; the land
clerk and plot signs now show a "+N friends" member count.

Offline, `/invite` explains it needs a server — there's only one local identity
to build with solo. Only the **owner** may invite (validated); co-owner
promotion and member removal are the next small step (the role constants in
`land_plot.gd` are ready).

## No economy yet

Land tokens are the placeholder currency. Real pricing/reputation/trading is
documented future work — nothing money-like exists.
