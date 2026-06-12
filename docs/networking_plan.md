# Networking plan

## What exists now (this pass)

Transport: Godot high-level multiplayer over ENet, RPCs on the
`NetworkSession` autoload. Modes (`systems/network/network_mode.gd`):
`offline` (default, always boots), `client`, `server`.

### Syncs today
- player join/leave presence
- display name + appearance (sent in the join request, sanitized server-side
  by `PlayerIdentity.normalized`)
- player positions (~8 Hz, unreliable-ordered, lerped client-side via
  `RemotePlayer`)
- placements: request → server validate (id, occupancy, materials) → commit →
  broadcast → persist
- per-player server materials (private to each requester)

### Does NOT sync yet (client-local)
- offline placed objects (your homestead save is yours; server objects render
  alongside them)
- remove/move/edit of placed objects
- farming, day/mood, comfort, mailbox/tasks
- villagers, creatures, gathering yields (offline inventory only)
- chat (none exists)

### Message reference
See `systems/network/network_messages.gd` for every payload shape, including
the placed-object record:
`{instance_id, content_id, tile_x, tile_y, owner_profile_id,
owner_display_name, placed_at}`.

## Design rules going forward

1. Server-authoritative: clients send requests, never state (positions are the
   pragmatic exception for now).
2. Everything crossing the wire is normalized on receipt (`PlayerIdentity`,
   `CharacterAppearance.normalized`, `NetworkMessages.is_valid_placed_object`).
3. Stable content ids on the wire, never display strings.
4. Offline must keep booting with zero network configuration.

## Roadmap

1. Server-side terrain/footprint validation (port map rules headless).
2. Networked remove/move with ownership checks (owner_profile_id is already
   stored on every record).
3. Server-authoritative gathering (resource node ids + cooldowns).
4. Shared day/mood clock from the server.
5. Session tokens + reconnect identity (replacing trust-the-LAN).
6. Interest management once worlds outgrow one screen of players.
