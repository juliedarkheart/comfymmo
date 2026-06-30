# Systems Index

> **Manifest Version:** 2026-06-30-v1
> **Status:** Approved
> **Last updated:** 2026-06-30
> **Source:** Derived from `systems/` directory contents and existing documentation

## Legend

- **Layer**: Core (foundation/shared), World (environment), Gameplay (player systems), Data (persistence), Network (multiplayer), Avatar (player character), Admin (tooling/backoffice), Art (visual assets)
- **Priority**: P0 (must-have, currently wired), P1 (important, designed, partially wired), P2 (future, stubbed), P3 (not started)
- **Status**: Valid values: Not Started, In Progress, In Review, Designed, Approved, Needs Revision
- **Source files**: Key implementation files in `systems/` and related directories

## Systems

| # | System | Layer | Priority | Status | Description | Source Files |
|---|--------|-------|----------|--------|-------------|--------------|
| 1 | GameStateManager | Core | P0 | Approved | Loads versioned save data, exposes world/player/task sections, tracks active region id | `systems/game_state_manager.gd` |
| 2 | WorldRegionManager | Core | P0 | Approved | Manages region loading, deferred transitions, starting region from save | `systems/world_region_manager.gd` |
| 3 | OverworldController | World | P0 | Approved | Gameplay controller for the single continuous overworld scene | `world/overworld_controller.gd` |
| 4 | HomesteadController | World | P0 | Approved | Gameplay controller for the homestead area (legacy, reused via inheritance) | `world/homestead_controller.gd` |
| 5 | OutdoorAreaController | Core | P0 | Approved | Shared base for outdoor controllers: generic lookup helpers, message panel lifecycle, interactable registration | `world/outdoor_area_controller.gd` |
| 6 | ObjectRegistry | Data | P0 | Approved | Central registry for placeable definitions by stable object_id | `systems/object_registry.gd` |
| 7 | BuildingPlacementSystem | Gameplay | P0 | Approved | Placement, edit, move, remove, preview, occupancy, mode state machine | `systems/building_placement_system.gd` |
| 8 | InteractableSystem | Gameplay | P0 | Approved | Proximity/interaction registry, nearest interactable tracking, action dispatch | `systems/interactable_system.gd` |
| 9 | InventorySystem | Gameplay | P0 | Approved | Item container with add/remove/query methods, persisted in player save section | `systems/inventory_system.gd` |
| 10 | FarmingSystem | Gameplay | P0 | Approved | Per-plot crop assignment, stage transitions, prompts | `systems/farming_system.gd` |
| 11 | LocalSaveSystem | Data | P0 | Approved | JSON persistence, versioned envelope, migration engine | `systems/local_save_system.gd` |
| 12 | RegionTransitionSystem | Core | P0 | Approved | Signal surface for explicit region travel | `systems/region_transition_system.gd` |
| 13 | PlayerSpawnSystem | Core | P0 | Approved | Player spawn position management | `systems/player_spawn_system.gd` |
| 14 | TaskIntegrationSystem | Gameplay | P0 | Approved | Mailbox/task lifecycle, message state, seen/completed tracking | `systems/task_integration_system.gd` |
| 15 | WorldMood | World | P1 | Approved | Time-of-day mood utility: three-phase cycle, tint colors, display names | `systems/world_mood.gd` |
| 16 | AvatarCamera | Avatar | P0 | Approved | Camera zoom controls (PageUp/Down, R to reset), clamp to region bounds | (in world controllers) |
| 17 | CreatureSystem | Gameplay | P1 | Designed | Ambient creature records, future spawning and bonding | `systems/creature_system.gd` |
| 18 | SurvivalSystem | Gameplay | P1 | Designed | Comfort stat store (energy, hunger, comfort), restore on rest | `systems/survival_system.gd` |
| 19 | NetworkSession | Network | P1 | Designed | Autoload for ENet transport, RPC node path, mode (offline/client/server) | `systems/network/network_session.gd` |
| 20 | CraftingSystem | Gameplay | P1 | Designed | Shared check/spend/grant logic for offline and server crafting | `systems/crafting/crafting_system.gd` |
| 21 | CraftingRegistry | Data | P1 | Designed | All recipe definitions with stable IDs | `systems/crafting/crafting_registry.gd` |
| 22 | PlayerProgression | Gameplay | P1 | Designed | XP curve, skills, level/skill gates, unlock enforcement | `systems/progression/player_progression.gd` |
| 23 | ContentRegistry | Data | P1 | Designed | Read-only data definitions keyed by ContentIds (display name, category, scene path) | `systems/content/content_registry.gd` |
| 24 | ContentIds | Data | P0 | Approved | Single source of truth for all stable string IDs (items, crops, placeables, etc.) | `systems/content/content_ids.gd` |
| 25 | BuildCosts | Data | P1 | Approved | Material costs per placeable, validation against known material IDs | `systems/building/build_costs.gd` |
| 26 | LandRegistry | Gameplay | P1 | Approved | Plot definitions (6 built-in lots), runtime plot overlay, plot queries | `systems/land/land_registry.gd` |
| 27 | LandClaimSystem | Gameplay | P1 | Designed | Claiming flow, build permission rules, plot membership | `systems/land/land_claim_system.gd` |
| 28 | ResourceSpawnRegistry | Data | P1 | Approved | Gather node definitions across overworld | `systems/resources/resource_spawn_registry.gd` |
| 29 | CombatSystem | Gameplay | P2 | In Progress | Stub encounter boundary for future combat entry/exit | `systems/combat_system.gd` |
| 30 | DungeonSystem | Gameplay | P2 | Not Started | Stub dungeon registry and active dungeon state | `systems/dungeon_system.gd` |
| 31 | ModerationScaffold | Admin | P2 | In Progress | Stubbed data models, in-memory audit log | `systems/admin/moderation_models.gd`, `systems/admin/audit_log.gd` |
| 32 | CharacterArtRegistry | Art | P1 | Designed | Registry for character appearance sprites (LimeZu) | `systems/art/limezu_art_registry.gd`, `systems/character/character_appearance_registry.gd` |
| 33 | OverworldEditorSystem | Admin | P2 | In Progress | Dev overlay for inspection, markers, export | `systems/overworld_editor_system.gd` |
| 34 | WorldMood | World | P1 | Approved | Manual time-of-day cycling, tint application | `systems/world_mood.gd` |
| 35 | GameBootstrap | Core | P0 | Approved | Boot sequence: main → bootstrap → WorldRegionManager → overworld | `systems/game_bootstrap.gd` |

## Systems Listed by Layer

### Core (Foundation)
GameStateManager, WorldRegionManager, OutdoorAreaController, RegionTransitionSystem, PlayerSpawnSystem, GameBootstrap

### World (Environment)
OverworldController, HomesteadController, WorldMood

### Gameplay (Player Systems)
BuildingPlacementSystem, InteractableSystem, InventorySystem, FarmingSystem, TaskIntegrationSystem, CreatureSystem, SurvivalSystem, CraftingSystem, PlayerProgression, LandRegistry, LandClaimSystem, CombatSystem, DungeonSystem

### Data (Persistence & Registry)
ObjectRegistry, LocalSaveSystem, ContentIds, ContentRegistry, CraftingRegistry, BuildCosts, ResourceSpawnRegistry

### Network (Multiplayer)
NetworkSession

### Avatar (Player Character)
AvatarCamera

### Admin (Tooling)
ModerationScaffold, OverworldEditorSystem

### Art (Visual Assets)
CharacterArtRegistry, LimeZuArtRegistry

## Status Distribution
- **Approved**: 21 systems
- **Designed**: 6 systems
- **In Progress**: 3 systems
- **Not Started**: 1 system
