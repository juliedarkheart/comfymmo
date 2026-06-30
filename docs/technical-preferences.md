# Technical Preferences

> **Manifest Version:** 2026-06-30-v1
> **Last updated:** 2026-06-30

## Engine
- Name: Godot
- Version: 4.6.3
- Config version: 5

## Language
- Primary: GDScript
- Version: Godot 4.x GDScript
- File convention: snake_case for files, PascalCase for classes/types

## Rendering
- Renderer: Forward Plus
- Resolution: 1280x720 (viewport)
- Stretch mode: canvas_items
- Aspect mode: expand
- Feature flags: "4.6", "Forward Plus"

## Physics
- Physics Engine: Godot Physics 2D
- Physics Ticks: 60 Hz

## Naming Conventions
- Files: snake_case
- Classes (class_name): PascalCase
- Constants: UPPER_SNAKE_CASE
- Signals: snake_case (prefixed with past-tense verb when appropriate)
- Functions/methods: snake_case
- Variables: snake_case
- Content IDs: snake_case (centralised in ContentIds)

## Performance Budgets
- Max draw calls: TBD (currently unmeasured)
- Max active nodes: TBD (currently unmeasured)
- Target FPS: 60
- Max concurrent players: 16 (prototype ceiling)
- Position sync rate: ~8 Hz (unreliable-ordered)

## Project Layout
- `systems/` — Modular game systems and domain services
- `world/` — Maps, regions, tile data, and world simulation
- `avatar/` — Player avatar data, control, appearance, animation
- `ui/` — Interface scenes, themes, and presentation logic
- `scenes/` — Entry scenes and shared scene composition
- `creatures/` — NPCs, monsters, critters, and creature definitions
- `buildings/` — Placeable structures and building rules
- `multiplayer/` — Networking contracts, replication, session logic
- `integrations/` — External service adapters and platform boundaries
- `tools/` — Editor scripts, validation helpers, build helpers
- `assets/` — Source and imported art, audio, fonts, VFX
- `docs/` — Architecture, standards, milestones, pipelines

## Server Configuration
- Port: 8910
- Max peers: 16
- Transport: ENet (Godot high-level multiplayer)
- Mode: Headless dedicated process
- Save path: `user://server_worlds/<world>.json`
