# Systems

Cross-domain orchestration lives here.

Current placeholders:

- `game_bootstrap.gd` starts the minimal runtime services.
- `player_spawn_system.gd` spawns the controllable avatar.
- `building_placement_system.gd` handles local preview, placement, and persistence hooks.
- `local_save_system.gd` reads and writes local homestead state.
- `object_registry.gd` owns shared placeable and placeholder item definitions.
- `game_state_manager.gd` exposes versioned world, player, and task state sections.
- `interactable_system.gd` is the future interaction seam.
- `inventory_system.gd`, `farming_system.gd`, `creature_system.gd`, `survival_system.gd`, `task_integration_system.gd`, `combat_system.gd`, and `dungeon_system.gd` are scaffold systems only for now.
- `world_mood.gd` is the manual time-of-day mood utility.
- `dev_tool_state.gd` + `overworld_editor_system.gd` are the local, dev-only `F10` overlay (player/mouse world position, area label, zoom) and a seam for future world-building tools. Inert while disabled.
- `admin/moderation_models.gd` and `admin/audit_log.gd` are stubbed, local-only data models and an in-memory audit trail for a future family/friends moderation layer. No network, no persistence, not wired into gameplay yet. See `docs/backend_tools.md` and `docs/moderation.md`.
