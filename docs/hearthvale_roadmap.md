# Hearthvale Roadmap

## North Star

Hearthvale is a cozy online homestead MMO: a warm persistent world where players build villages, raise creatures, master professions, decorate homes, care for each other, and eventually adventure together.

The playful shorthand is: **World of Warcraft with carrots**.

This does not mean copying World of Warcraft. It means aiming for the same sense of persistent world, social identity, roles, progression, and shared adventure, but with Hearthvale’s center of gravity in cozy survival, farming, building, town life, creature care, and community.

## Product Framing

Current framing:

> A cozy multiplayer homestead prototype growing toward a persistent cozy MMO.

Pitch framing:

> A cozy online homestead MMO where players build villages, raise creatures, master professions, and adventure together in a warm persistent world.

## Design Principles

- Comfort survival, not punishment survival.
- Social first, but solo-friendly.
- Building and decorating are core gameplay, not side content.
- Professions should create identity and interdependence.
- Real-life integrations are optional ambient helpers, never guilt systems.
- Dungeons and danger can exist, but home remains emotionally central.
- MMO scope grows in phases. The prototype should be fun before it is huge.

## Phase 1: Homestead Core

Goal: make the small starting area feel playable, readable, and coherent.

Core work:

- Movement and collision that feel correct at the LimeZu visual scale.
- Interaction range and F-targeting calibrated for nearby objects.
- Clear farming patch near spawn.
- Working inventory and bottom hotbar.
- Placement, edit, and delete loop with delete safety.
- Admin/worldbuilder tools for building and cleaning test areas.
- Clean LimeZu UI using real Modern UI assets.
- Readable prompts, nameplates, and basic NPC interaction.
- Local save cleanup/reset tools for old test clutter.

Success criteria:

- The player can walk around, interact, farm, open inventory, place and remove an object, and understand the UI without fighting the prototype.
- Nearby visuals remain LimeZu-coherent.
- No obvious Sprout/generated/legacy leaks in the curated playable area.

## Phase 2: Neighborhood Prototype

Goal: make the world feel inhabited by multiple homes and shared spaces.

Core work:

- Multiple homestead plots.
- Shared town square.
- Player visiting flow.
- Local permissions for build/edit access.
- Shared placement persistence.
- Small chat and presence features.
- Basic player nameplate polish.
- Admin tools for clearing, resetting, and composing zones.
- Two-player local/server test.

Success criteria:

- Two or more players can exist in the same area, recognize each other, and collaborate around a small shared town space.

## Phase 3: Professions and Roles

Goal: introduce identity and long-term progression without combat-first design.

Possible cozy roles:

- **Gardener:** crops, soil quality, greenhouses, seed improvement.
- **Builder:** structures, furniture, town projects, repairs.
- **Forager:** herbs, mushrooms, wood, wild resources.
- **Cook:** meals, buffs, comfort food, festivals.
- **Rancher:** creature care, breeding, barns, companionship.
- **Tailor:** clothing, avatar cosmetics, dyes.
- **Tinker:** tools, workstations, automation-lite.
- **Warden:** exploration, shrines, wilderness safety, dungeon preparation.

Success criteria:

- Players can specialize in ways that feel socially useful and expressive.
- Roles create reasons to trade, visit, help, and collaborate.

## Phase 4: Cozy World Events

Goal: create MMO-style shared moments without requiring raid-scale combat.

Event examples:

- Harvest festival.
- Town restoration project.
- Storm cleanup.
- Lost creature rescue.
- Community feast.
- Traveling merchant fair.
- Shrine awakening.
- Winter lantern event.
- Giant crop contest.
- Bridge or greenhouse rebuild.

Success criteria:

- Players have reasons to gather, contribute, and celebrate together.
- Events create world memory and community identity.

## Phase 5: Adventure and Dungeons

Goal: add danger, mystery, and cooperative adventure while keeping home central.

Possible adventure spaces:

- Mines.
- Old ruins.
- Enchanted forest pockets.
- Root cellar dungeons.
- Dream caves.
- Storm-buried shrines.
- Corrupted gardens.
- Creature rescue expeditions.

Combat direction:

- Combat can exist, but should not become the whole identity.
- Tone should feel like protecting the village and exploring mystery, not grinding monsters for gear math.
- Dungeon rewards should support home, town, professions, creatures, and cosmetics.

Success criteria:

- Adventure expands the world without replacing the cozy core.

## Phase 6: Persistent MMO Infrastructure

Goal: move from multiplayer prototype toward real persistent online operation.

Needed systems:

- Accounts and authentication.
- Authoritative server model.
- Persistent database.
- Inventory persistence.
- Placement persistence.
- World instance or shard model.
- Chat and moderation tools.
- Permissions and safety controls.
- Patch/update pipeline.
- Logging and admin dashboards.

Success criteria:

- The game can support persistent shared towns with safe moderation and recoverable data.

## Engine Direction

Godot remains the right client/prototype engine for now because Hearthvale is 2D, UI-heavy, indie-scale, tool-heavy, and benefits from open-source flexibility.

Caution:

- Godot does not magically provide full MMO infrastructure.
- Use Godot for the client, gameplay prototype, tooling, and early dedicated server experiments.
- Treat the real MMO backend as its own future system.

## Near-Term Priority Order

1. Commit stable LimeZu UI reconstruction work.
2. Fix collision alignment for barn, trees, fences, and solid props.
3. Fix F-interaction range and target selection.
4. Make the farm patch obvious and testable.
5. Make build/edit/admin tools reliable for manual area creation.
6. Add local cleanup/reset tools for old test placements.
7. Polish left-side/build/admin UI so it does not look scaffold-like.
8. Center inventory/hotbar icons correctly within LimeZu slot frames.
9. Expand generator pipeline for original Hearthvale-compatible assets.
10. Add small co-op/server playtest support after the single-player loop feels good.

## Generator Direction

Use the included LimeZu generators for character and portrait outputs where appropriate, but keep outputs local and gitignored.

Build Hearthvale-owned generators for original assets that match the project’s pixel-production grammar:

- item icons
- crop/resource icons
- furniture and prop variants
- UI badges/icons
- portrait placeholders
- color variants
- generated review sheets

Important rule:

Do not copy LimeZu paid art into generated assets. Analyze style constraints such as size, padding, palette direction, outline thickness, and shadow rules, then generate original Hearthvale-compatible assets.

## Current Reality Check

The dream is MMO-scale, but the next success is humble:

> A small, charming homestead where the player can move, interact, farm, build, open clean UI, and feel the future world trying to breathe.

Once that tiny place feels good, Hearthvale can safely grow outward into the carrot-powered world-serpent it wants to become.
