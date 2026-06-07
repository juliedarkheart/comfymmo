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

Playable local prototype. The project launches into **one continuous isometric
overworld** (`scenes/world/overworld.tscn`) containing a homestead, village square,
and forest edge as connected areas — you walk between them with no scene transition.
It includes farming, object placement/edit/move, a mailbox/task loop, inventory,
comfort, a rest/day/mood cycle, villagers, ambient creatures, a shrine and notice
board, 4K zoom controls, and a local-only `F10` dev overlay. Outdoor travel never
scene-swaps; `WorldRegionManager` is reserved for future dungeons/interiors.

See **[Overworld Architecture](docs/overworld_architecture.md)** for the
authoritative outdoor model, system boundaries, and save layout — read it before
changing outdoor structure.

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

You can also launch the project from PowerShell with the local helper:

```powershell
.\tools\run-godot.ps1 -Editor
```

The helper defaults to `D:\Tools\Godot_v4.6.3-stable_win64.exe`, which may be
either the executable or an unpacked install folder containing the executable.
To use a different Godot install, pass `-GodotExe "C:\Path\To\Godot.exe"`.

For safe automated checks from a terminal or Codex session, use managed helper commands with a timeout:

```powershell
.\tools\run-godot.ps1 -Headless -TimeoutSeconds 15 -GodotArgs "--version"
.\tools\run-godot.ps1 -Headless -TimeoutSeconds 15 -GodotArgs "--help"
.\tools\run-godot.ps1 -SmokeTest -TimeoutSeconds 30
```

These checks are trusted for tool and project-load validation. Full gameplay acceptance still belongs in the editor.

## Prototype Controls

- Move with `WASD` or arrow keys.
- Press `B` to toggle local placement mode.
- Place with left click or `Enter`.
- Cancel placement mode with `Esc`.
- Walk into the cottage, trees, or fence to verify collision.
- The camera follows the character and stays inside the homestead bounds.

## Development Principles

- Keep systems small and replaceable.
- Prefer data-driven content over hard-coded world rules.
- Keep multiplayer authority boundaries explicit.
- Avoid speculative frameworks until the game needs them.
- Document decisions that affect future contributors.

## Documentation

- [Overworld Architecture](docs/overworld_architecture.md) — main outdoor model (start here)
- [System Architecture](docs/system_architecture.md)
- [Save Data Model](docs/save_data_model.md)
- [Dev Tools](docs/dev_tools.md) · [Backend Tools](docs/backend_tools.md) · [Moderation](docs/moderation.md)
- [Architecture](docs/architecture.md)
- [Milestones](docs/milestones.md)
- [Coding Standards](docs/coding_standards.md)
- [Asset Pipeline](docs/asset_pipeline.md)
- [Prototype Playtest](docs/prototype_playtest.md)
- [Building Placement](docs/building_placement.md)

### Art Pipeline (ComfyUI)

- [Art Pipeline Overview / ComfyUI Workflows](docs/art_pipeline/comfyui_workflows.md)
- [Style Guide](docs/art_pipeline/style_guide.md)
- [Asset Import Standards](docs/art_pipeline/asset_import_standards.md)
- [Alpha 0.1 Asset Targets](docs/art_pipeline/alpha_01_asset_targets.md)
- [Prompt Templates](assets/prompts/) — start from `hearthvale_master_style.md`
