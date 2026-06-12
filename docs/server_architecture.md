# Server architecture (prototype slice)

Hearthvale's first persistent-world slice. A dedicated headless Godot process
owns the shared world; the normal game is the client and stays fully playable
offline.

## Honest status

This is a private-playtest prototype: no auth, no encryption, no anti-cheat,
trust-the-LAN networking. It is architected toward a real server model
(server-authoritative state, request/validate/commit/broadcast flow, separate
persistence), but nothing here is production security.

## Processes

- **Client** — `scenes/main.tscn` (unchanged boot). Offline by default;
  connects via the F8 panel.
- **Server** — `server/server_main.tscn` run headless. Never loads the game
  world/UI; it is data-authoritative only.

Both share the `NetworkSession` autoload (`systems/network/network_session.gd`),
which gives client and server the identical RPC node path Godot's high-level
multiplayer requires. ENet transport, default port 8910, max 16 peers
(multi-client supported by design; two simultaneous clients is what's been
reasoned about, see docs/playtest_readiness.md for validation status).

## Server owns (authoritative)

- connected players (`server/server_player_state.gd`): sanitized identity,
  display name, appearance, session position
- per-player material pouches (`MaterialInventory`), seeded with a starter
  pack on first join, persisted per profile across reconnects/restarts
- placement validation: known content id → tile occupancy → material cost
- the persistent world: `server/server_world_state.gd` in memory,
  `server/server_save_system.gd` on disk
- world save/load: `user://server_worlds/<world>.json`, written on every
  committed placement and on join/leave

## Client owns

- input, camera, HUD, all UI panels
- the local offline save (never touched by multiplayer)
- placement *requests* (no prediction: the ghost preview is local, the commit
  arrives from the server)
- rendering of remote players and server-committed objects

## Data flow

```
client                          server
  | connect (ENet)                |
  | _rpc_join_request(identity) ->| sanitize, seed/load materials
  |<- _rpc_world_snapshot         | placed_objects + players + your materials
  |<- _rpc_player_joined (others) |
  | _rpc_submit_position (~8/s) ->| update state
  |<- _rpc_sync_positions (~8/s)  | broadcast all positions
  | _rpc_request_place ---------->| validate id/tile/cost
  |<- _rpc_placement_committed    | (all clients) or _rpc_place_denied (requester)
  |<- _rpc_materials_update       | requester's new pouch
```

## Known limitations / next steps

- Server placement validation checks occupancy only — not the offline map's
  terrain/footprint rules (cottage, trees, bounds). Port `HomesteadMap`'s
  rules into a headless-safe validator next.
- No networked remove/move/edit; no farming/mood/day sync; villagers and
  creatures are client-local ambience.
- Position sync is unreliable-ordered with client-trusted positions.
- One world per server process; world selection via `--world=`.
- Real backend milestone: session tokens, persistent player ids, interest
  management, and a tick-based authoritative sim.
