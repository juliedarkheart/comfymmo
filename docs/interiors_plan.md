# Interiors plan (DEFERRED — not in the current build)

Hearthvale currently has **no house interiors**, by explicit scope decision.
The world is one continuous outdoor overworld; the cottage door has a sign
("Inside coming soon!") and never teleports the player. Nothing in boot, save
data, or networking depends on interiors existing.

## Why deferred

Interiors are an instancing problem, not a decorating problem. Doing them
properly needs ownership, permissions, per-interior save data, indoor
placement rules, server instance routing, enter/exit transitions, and
networked players sharing an interior — each a real system. A teleporting door
without those would create save/network state we'd have to migrate later.

## Future architecture (when we build it)

- Interiors become **server-backed instances** loaded through
  `WorldRegionManager`, which has been reserved for exactly this since the
  continuous-overworld pivot (see its header comment and
  docs/overworld_architecture.md). Outdoor traversal stays continuous walking
  and never scene-swaps; doors are the only instance boundary.
- Each interior needs:
  - **ownership** (owner_profile_id, like placed objects already have)
  - **permissions** (owner / friends / everyone, server-enforced)
  - **interior save data** (its own placed_objects list, keyed by instance id,
    in the server world file under `world.instances`— the save section already
    reserved for this)
  - **indoor placement rules** (wall-aware grid, distinct from outdoor terrain
    rules)
  - **server instance routing** (join/leave an interior = subscribe to its
    state; the snapshot flow generalizes)
  - **enter/exit transitions** (the WorldRegionManager fade machinery already
    exists and is kept for this)
  - **networked co-presence** (position sync scoped per instance — the first
    real interest-management problem)

## Current-pass guardrails (enforced now)

- The cottage door sign interaction opens a message panel only.
- No interior scenes exist or are loaded at boot.
- No save field references interiors beyond the long-reserved empty
  `world.instances` section.
- `NetworkSession` assumes a single shared outdoor space.
