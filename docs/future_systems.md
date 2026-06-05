# Future Systems

This milestone adds scaffolding, not live gameplay, for Hearthvale's broader
systems.

## Intentionally Not Implemented Yet

- inventory UI
- item pickups and drops
- crop growth simulation
- watering tools
- creature AI
- creature bonding gameplay
- survival penalties or buffs
- real external task/calendar sync
- combat actions
- dungeon maps and encounters
- networking

## What Exists Instead

- registry and lookup boundaries
- save data containers
- placeholder state stores
- minimal methods for future use
- scene-level system nodes already present in the homestead

## Suggested Build Order

1. Mailbox interaction slice through `InteractableSystem`
2. Local mock task loop through `TaskIntegrationSystem`
3. Simple inventory-backed item rewards
4. One farm plot interaction slice
5. One ambient creature slice

## Architecture Principle

Each new feature should attach to one or two of these scaffolds at a time. The
goal is to keep future milestones narrow, shippable, and easy to test rather
than waking every placeholder system at once.
