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
