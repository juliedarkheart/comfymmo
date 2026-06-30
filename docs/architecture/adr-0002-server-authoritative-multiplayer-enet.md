# ADR-0002: Server-Authoritative Multiplayer with ENet

**Date:** 2026-06-30
**Manifest Version:** 2026-06-30-v1

## Status

Accepted

## Context

Hearthvale needs multiplayer support for its cozy MMO vision. The project had a fully local prototype. The architectural choice was between peer-to-peer (one client hosts), client-authoritative (client sends state), and server-authoritative (dedicated process owns world state). The prototype targets private playtests with trusted players, but the architecture must support future production security.

## Decision

Adopt server-authoritative multiplayer using Godot's high-level multiplayer API over ENet transport. A dedicated headless Godot process owns the shared world; the normal game client stays fully playable offline. The NetworkSession autoload (`systems/network/network_session.gd`) runs identically on client and server to satisfy Godot's RPC node path requirements.

## Consequences

### Positive
- Server owns authoritative state: placements, materials, player state, world persistence
- Client requests actions instead of asserting state — anti-cheat foundation
- Offline play continues to work with zero network configuration
- Existing local systems (save, placement, farming) are untouched by networking code
- Shared CraftingSystem check/spend/grant logic works both offline and server-side
- Chat sanitization and identity normalization happen server-side

### Negative
- Current implementation is trust-the-LAN (no auth, encryption, or anti-cheat yet)
- Server placement validation checks occupancy only — not terrain/footprint rules
- Position sync is unreliable-ordered with client-trusted positions (documented exception)
- No networked remove/move/edit; no farming/mood/day sync yet
- Crop inputs for recipes don't sync, so three crop-input recipes are offline-only when connected

## Options Considered

### Option 1: Server-Authoritative (Chosen)
Dedicated headless server process owns all authoritative state. Clients send requests. Described in detail in `docs/server_architecture.md`.

### Option 2: Peer-to-Peer / Listen Server
One client hosts and acts as server. Simpler deployment but introduces host advantage and requires the host to stay online. Incompatible with persistent world goals.

### Option 3: Client-Authoritative
Client owns its state and sends it to others. Simplest initial implementation but offers no anti-cheat foundation and contradicts the project's multiplayer-ready posture.

## ADR Dependencies

Depends on: ADR-0006 (Godot 4.6 as Target Engine — provides ENet transport)
Used by: None — downstream implementation ADRs expected

## Engine Compatibility

Godot 4.6.3 — ENet transport is built into Godot's high-level multiplayer API (`SceneTree.multiplayer`). Works in headless mode. Port 8910, max 16 peers.

## GDD Requirements Addressed

- **Server Architecture** (docs/server_architecture.md): Processes, authoritative state ownership, data flow, known limitations
- **Networking Plan** (docs/networking_plan.md): Transport choice, sync scope, design rules, roadmap
- **Crafting** (docs/crafting.md): Server-authoritative crafting flow, pouch validation
- **Progression** (docs/progression.md): Server-side XP grants for gather/craft/build

## Performance Implications

ENet is UDP-based with reliability layers, suitable for real-time game networking. Current prototype syncs positions at ~8 Hz (unreliable-ordered) with client-side lerp. Placement requests are reliable RPCs. At 16 concurrent peers with current gameplay scope, bandwidth and CPU are negligible. Interest management will be needed as world scale and player count grow.
