# Game Concept: Hearthvale

> **Manifest Version:** 2026-06-30-v1
> **Status:** Approved
> **Last updated:** 2026-06-30

## 1. Overview

Hearthvale is a **cozy 2D isometric survival-building MMO** built in Godot 4.6.3. Players arrive at a gentle storybook village, claim a homestead lot, and build a life — farming crops, crafting items, decorating their home, gathering resources, and exploring a continuous outdoor world with neighbours. It is designed as a multiplayer-ready experience from day one, with a dedicated server model and offline-first architecture.

**Genre:** Cozy MMO / Life Simulation / Sandbox Building
**Target Platform:** Windows (desktop)
**Visual Style:** Warm 2D isometric storybook — Chrono Trigger readability, Harvest Moon rural charm, Animal Crossing soft toy-like friendliness, Stardew Valley UI conventions
**Target Audience:** Players seeking a non-violent, social, creative building and farming experience

## 2. Player Fantasy / Dream

The player dreams of a **gentle, persistent world where their creativity matters**. They arrive at Hearthvale Landing — Farmer Rowan's training farm — learn the basics of gathering, farming, and building, then claim a neighbourhood lot (one of six distinct biome spots) to make their own.

The core emotional loop:
- **Gather** resources from the world (wood, stone, fiber, clay) — regeneration-based, never depletion
- **Farm** crops through a simple plant/water/harvest cycle across three fixed plots
- **Craft** components and placeable objects from gathered and farmed materials
- **Build** and decorate their homestead with placed objects, structures, and furnishings
- **Socialise** with villagers (Maribel Tock, Bram Nettle) and neighbouring players
- **Progress** through 10 levels across 8 skills (gathering, mining, farming, crafting, building, social, exploration, stewardship)
- **Rest** in a gentle day/mood cycle — advance time, restore comfort, watch the world's mood shift from morning through afternoon to dusk

There is **no combat pressure, no hunger damage, no depletion, no griefing**. Comfort is the only survival pressure, and it is always recoverable. The server is authoritative for placements and materials; the world is persistent and shared. Offline play is fully supported.

## 3. Detailed Rules

### World Structure
- One continuous outdoor overworld scene — no scene transitions for outdoor traversal
- Four zones: **Hearthvale Landing** (tutorial/training farm), **Town** (public village square, unbuildable), **Neighbourhood** (6 claimable lots, 14×14 to 20×20, each with its own biome), **Wilderness** (forest edge with gathering nodes)
- `WorldRegionManager` reserved exclusively for future dungeons/interiors
- Grid-based placement (isometric diamond grid) only in the homestead/neighbourhood area; open terrain elsewhere

### Gathering
- 12 resource nodes across the overworld (wood, stone, fiber, clay × homestead/village/forest)
- Hand tier: 1–3 per gather (branches, pebbles, fiber, clay patches)
- Tool tier: 2–4 per gather (chopping trees with axe, boulders with pickaxe, clay deposits with shovel)
- Nodes regenerate on ~20s cooldown — no depletion
- Gathering is server-authoritative when connected

### Farming
- Three fixed farm plots in the homestead with assigned crop types (carrot, turnip, berry)
- Stage model: empty → planted_dry → planted_watered → grown
- `F` plants/waters/tends/harvests based on current stage
- Each harvest grants +1 of the plot's crop to inventory
- Crops feed crafting recipes (seed packets, cloth rolls, flower bundles)

### Building / Placement
- `B` toggles placement mode; `Tab` cycles active placeable
- `E` toggles edit mode; `M` moves selected objects; Delete/Backspace removes
- All placeables defined in `ObjectRegistry` by stable `object_id`
- Costs enforced via `build_costs.gd` (materials from inventory)
- Preview ghost shows validity; world-space hint displays reason when blocked
- Placement ghost turns red with "Needs X" materials when unaffordable

### Crafting
- `K` opens hand-crafting panel; station crafting via `F` at placed workbench/garden table
- 7 recipes spanning hand, workbench, and garden table tiers
- Components are ordinary inventory items (offline) or pouch entries (server)
- Recipe gates include player level and skill level requirements

### Progression
- One XP curve: levels 1–10 at cumulative XP 0/25/60/110/180/270/380/510/660/830
- 8 skills: gathering, mining, farming, crafting, building, social, exploration, stewardship
- XP sources wired from gather, farm, craft, build, socialise, explore, complete tasks
- Level and skill locks enforce recipe and placeable gates
- Progression panel at `P`; level-ups and skill-ups toast in chat

### Interactions
- `InteractableSystem` registry for proximity-based world interactions
- Types: mailbox, farm_plot, notice_board, shrine_marker, villager, ambient_creature, rest
- Nearest interactable shows `Press F to [action]` prompt
- Mailbox panel shows task messages with New/Seen/Done states
- Villagers have first-visit and rotating repeat dialogue lines

### Multiplayer
- Server-authoritative: dedicated headless Godot process owns world state
- ENet transport, port 8910, max 16 peers
- Syncs: join/leave, positions (~8 Hz), placements, gathering, chat
- Client-local: farming, mood/day, mailbox/tasks, villagers, creatures (to be networked)
- Offline play requires zero network configuration

## 4. Formulas

### XP Curve
```
Level 1: 0 XP      Level 6: 270 XP
Level 2: 25 XP     Level 7: 380 XP
Level 3: 60 XP     Level 8: 510 XP
Level 4: 110 XP    Level 9: 660 XP
Level 5: 180 XP    Level 10: 830 XP
```
Levels derived from XP — never stored directly.

### Skill XP Sources
| Action | Skill XP | Overall XP |
|--------|----------|------------|
| Gather wood/fiber | +2 gathering | +1 |
| Gather stone/clay | +2 mining | +1 |
| Plant/water crop | +1 farming | — |
| Harvest crop | +5 farming | +2 |
| Craft basic (planks, rope) | +2 crafting | +1 |
| Craft advanced (blocks, cloth…) | +3–5 crafting | +1–2 |
| Place simple object | +2 building | — |
| Place component-built object | +5 building | — |
| Complete mailbox task | +10 stewardship | +5 |
| Talk to villager (once/session) | +2 social | +1 |
| Observe creature (once/session) | +2 exploration | +1 |

### Build Costs
| Placeable | Cost |
|-----------|------|
| Crate | 2 wood |
| Lantern | 1 wood + 1 fiber |
| Planter | 2 clay |
| Fence | 1 wood |
| Workbench | 3 wood + 2 stone |
| Garden Table | 2 wood + 2 fiber |
| Garden Arch | 3 wood + 2 fiber |
| Path Lantern | 1 stone + 1 fiber |
| Picnic Blanket | 3 fiber |
| Tiny Pond | 3 stone + 2 clay |

### Survival / Comfort
- Comfort ranges 0–100, restored to 100 on rest
- Hunger/energy exist as stored values but have no drain mechanics yet
- Eating a carrot grants +5 comfort

## 5. Edge Cases

### Save / Load
- If save file is missing: initialise with defaults (stage empty, no placed objects, day 1, mood morning)
- If save file is from older version: automatic migration (v1 flat → v2 region-scoped → v3 versioned)
- If save file is corrupted: initialise defaults (no crash recovery)
- If placed object ID no longer exists in registry: skip on load, log warning
- If farm plot references unknown crop: reset to empty

### Multiplayer
- Client disconnects mid-placement: server retains its state, client re-syncs on reconnect
- Server restart: in-memory cooldowns reset (temporary — documented)
- Two clients with same display name: second gets "Name#2" deduplication
- Client connects with offline-only objects visible: server objects render alongside, no conflict

### Building
- Moving an object: temporarily frees old tile until move is confirmed or cancelled
- Cannot place on occupied/reserved/spawn tile — ghost shows reason
- Placement mode, edit mode, and move-preview are mutually exclusive
- Avatar movement paused while any decorating mode is active

### Interactions
- Multiple mailboxes: all show the same mailbox state (shared seen/completed state)
- Villager first-visit vs repeat: controlled by session and save flags
- Creature flee radius: 60px from player
- Mood cycling suppressed while any panel (mailbox, message, villager, notice, shrine, rest) is open

## 6. Dependencies

### Internal Dependencies
| System | Depends On |
|--------|------------|
| BuildingPlacementSystem | ObjectRegistry, LocalSaveSystem, InventorySystem |
| FarmingSystem | LocalSaveSystem, InventorySystem, TaskIntegrationSystem |
| CraftingSystem | InventorySystem, ObjectRegistry, PlayerProgression |
| InteractableSystem | (standalone registry) |
| GameStateManager | LocalSaveSystem |
| WorldRegionManager | GameStateManager |
| PlayerProgression | LocalSaveSystem |
| TaskIntegrationSystem | LocalSaveSystem |
| OutdoorAreaController | InteractableSystem, WorldMood |
| NetworkSession | (autoload) |

### External Dependencies
- Godot 4.6.3 (engine)
- ENet (built-in transport)
- LimeZu Modern UI assets (licensed, commercial use allowed)
- No external runtime libraries or services

## 7. Tuning Knobs

All tunable values are defined as constants in their respective system scripts:

| Parameter | Location | Default | Notes |
|-----------|----------|---------|-------|
| Crop stage timers | `FarmingSystem` | N/A (interaction-driven, no real-time) | Future: add growth duration constants |
| Gather yields | `resource_spawn_registry.gd` | 1–3 (hand), 2–4 (tool) | Per-resource-type config |
| Node cooldown | server-side | ~20s | In-memory, resets on restart |
| Build costs | `build_costs.gd` | See formulas | Dictionary per placeable |
| Recipe inputs/outputs | `crafting_registry.gd` | See recipes | Stable IDs |
| XP thresholds | `PlayerProgression` | 0/25/60/110/180/270/380/510/660/830 | Level derived from XP |
| Skill XP rewards | Per-system constants | See formulas | +2 gathering, etc. |
| Comfort restore on rest | `HomesteadController` | 100 | Full restore |
| Mood order | `WorldMood` | morning → afternoon → dusk | Fixed cycle |
| Creature flee radius | `ambient_creature.gd` | 60px | Per-creature override supported |
| Network port | `server_config.gd` | 8910 | Configurable |
| Max peers | `server_config.gd` | 16 | Prototype ceiling |
| Position sync rate | `NetworkSession` | ~8 Hz | Unreliable-ordered |
| Viewport resolution | `project.godot` | 1280x720 | Stretch: canvas_items, expand |

## 8. Acceptance Criteria

1. **Boot**: Project launches into a single continuous overworld scene with no scene transitions for outdoor areas
2. **Movement**: Player can walk between homestead, village square, and forest edge seamlessly
3. **Gathering**: 12 resource nodes across the world are interactable, grant materials, and recover on cooldown
4. **Farming**: Three farm plots support plant/water/tend/harvest cycle with crop-specific stages
5. **Building**: Placement mode (B), edit mode (E), move (M), delete, with grid validation and cost enforcement
6. **Crafting**: K opens hand-crafting panel; placed stations offer crafting; recipe gates (level/skill) enforced
7. **Progression**: XP earned from all sources; levels unlock recipes and placeables; skill levels gate specific recipes
8. **Interactions**: Mailbox, notice board, shrine, villagers, and rest marker all functional with prompt/HUD feedback
9. **Multiplayer (LAN)**: F8 panel connects; server validates placements and materials; positions sync; chat works
10. **Save**: Versioned JSON save persists all state; old saves migrate automatically; offline boot works with no save file
11. **Restart**: Reloading the project preserves placed objects, farm state, inventory, progression, and flags
12. **Offline**: The game boots and is fully playable without any network configuration or server process
