# Milestones

These milestones are intentionally small. Each should produce a playable or
verifiable slice before the next one begins.

## M0: Foundation

- Godot project opens and runs.
- Repository layout is established.
- Architecture and standards are documented.
- Placeholder module boundaries exist.

## M1: Isometric Prototype

- Basic isometric test map.
- Avatar can move on the map.
- Camera follows the avatar.
- Basic collision blocks homestead obstacles.
- Coordinate conversion is covered by tests or validation tools.

## M2: World Interaction

- Place and remove a simple building.
- Validate footprint and blocked tiles.
- Save and load a local test world.

## M3: Multiplayer Spike

- Host and client can connect locally.
- Avatar movement uses an authority model.
- Replicated state is visible to another client.

## M4: Content Loop

- Add one creature type.
- Add one gatherable resource.
- Add one craftable or placeable object.
- Keep the loop narrow and playable.

## Later

Persistence, account services, moderation, economy, chat, social systems, and
live operations should wait until the core loop proves itself.
