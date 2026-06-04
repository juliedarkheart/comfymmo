# Hearthvale

Hearthvale is a Godot-based 2D isometric multiplayer game project.

This repository is the starting foundation only. It establishes project shape,
ownership boundaries, and conventions for future development without building
the MMO before the design has earned that complexity.

## Project Goals

- Godot-first 2D isometric structure
- Multiplayer-ready architecture
- Modular gameplay systems
- Scalable folder organization
- Production-ready repository habits from day one

## Current Status

First playable prototype. The project launches into a small isometric homestead
with a controllable character, camera follow, basic collision, and placeholder
visuals.

## Repository Layout

```text
assets/          Source and imported art, audio, fonts, and VFX
avatar/          Player avatar data, control, appearance, and animation
buildings/       Placeable structures and building-related rules
creatures/       NPCs, monsters, critters, and creature definitions
docs/            Architecture, standards, milestones, and pipelines
integrations/    External service adapters and platform boundaries
multiplayer/     Networking contracts, replication, and session logic
scenes/          Godot entry scenes and shared scene composition
systems/         Modular game systems and domain services
tools/           Editor scripts, validation tools, and build helpers
ui/              Interface scenes, themes, and presentation logic
world/           Maps, regions, tile data, and world simulation
```

## Getting Started

1. Install Godot 4.x.
2. Open this folder as a Godot project.
3. Run the `main` scene from `scenes/main.tscn`.

## Prototype Controls

- Move with `WASD` or arrow keys.
- Walk into the cottage, trees, or fence to verify collision.
- The camera follows the character and stays inside the homestead bounds.

## Development Principles

- Keep systems small and replaceable.
- Prefer data-driven content over hard-coded world rules.
- Keep multiplayer authority boundaries explicit.
- Avoid speculative frameworks until the game needs them.
- Document decisions that affect future contributors.

## Documentation

- [Architecture](docs/architecture.md)
- [Milestones](docs/milestones.md)
- [Coding Standards](docs/coding_standards.md)
- [Asset Pipeline](docs/asset_pipeline.md)
- [Prototype Playtest](docs/prototype_playtest.md)
