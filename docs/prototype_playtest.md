# Prototype Playtest

## Setup

1. Install Godot 4.x.
2. Open the repository folder as a Godot project.
3. Run `scenes/main.tscn`.

## Acceptance Checks

- The game launches into the homestead map.
- The character moves smoothly with `WASD` or arrow keys.
- The camera follows the character and respects map limits.
- The cottage, trees, and fence block movement.
- The scene remains organized around map, player spawning, avatar, camera, and UI modules.

## Current Scope

Included:

- Small 2D isometric homestead map
- Controllable placeholder character
- Camera follow
- Basic obstacle collision
- Placeholder polygon visuals

Not included:

- combat
- crafting
- networking
- persistence
- MMO-scale systems

## Recommended Next Milestone

Build a narrow world interaction slice:

- add one placeable object
- validate placement against blocked tiles
- save and reload the local homestead state
- keep networking out until the local authority model is clear

