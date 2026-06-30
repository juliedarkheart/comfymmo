# Adoption Plan

> **Generated**: 2026-06-30
> **Project phase**: Production (inferred — no stage.txt)
> **Engine**: Godot 4.6 (detected from project.godot — NOT configured in HMGS technical-preferences.md)
> **Previous plan**: None

---

## Phase 1 — Project State Audit

**HMGS directory layout**: Not present. Project uses its own layout under `E:\github\comfymmo\`.

| Check | Status | Notes |
|---|---|---|
| `production/stage.txt` | ❌ Missing | No authoritative phase marker |
| `design/gdd/game-concept.md` | ❌ Missing | Concept not captured in HMGS format |
| `design/gdd/systems-index.md` | ❌ Missing | No system registry for gate-check |
| GDDs (design/gdd/*.md) | ❌ 0 found | 55 docs exist in `docs/` but none in HMGS GDD format |
| ADRs (docs/architecture/adr-*.md) | ❌ 0 found | `docs/architecture/` directory doesn't exist |
| Stories (production/epics/*.md) | ❌ 0 found | No story files |
| `docs/technical-preferences.md` | ❌ Missing | Engine/language not configured in HMGS format |
| `docs/engine-reference/` | ❌ Missing | No engine reference docs |
| Prior adoption plans | ❌ None found | First adoption run |

**Phase heuristic**: 79 source files in `systems/` + 55 docs + working prototype → **Production**.

---

## Phase 2 — Format Compliance Audit

### GDD Audit (0 files)
No HMGS GDD files exist. The project has **rich design documentation** (55 markdown files) that effectively serve as de facto design specifications, but none follow the HMGS 8-section GDD format (Overview, Player Fantasy, Detailed Rules, Formulas, Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria). Key content-rich docs that could become GDDs:

- `docs/farming.md` — farming system design
- `docs/crafting.md` — crafting system design
- `docs/building_placement.md` — building placement design
- `docs/progression.md` — player progression and skills
- `docs/interactions.md` — interaction system design
- `docs/resources_and_gathering.md` — gathering and resources
- `docs/survival_building.md` — survival/building costs
- `docs/land_ownership.md` — land/plot ownership
- `docs/tools_and_equipment.md` — tools and equipment
- `docs/items_equipment_weapons_wearables.md` — item definitions
- `docs/ui_hud.md` — UI/HUD design
- `docs/dungeon_instances.md` — dungeon design
- `docs/new_player_onboarding.md` — new player experience

### ADR Audit (0 files)
No ADR files exist. The project has documented several architectural decisions in prose form that could be converted to HMGS ADRs:

- `docs/server_architecture.md` — server architecture decisions
- `docs/overworld_architecture.md` — continuous overworld vs paged regions
- `docs/save_data_model.md` — save format and versioning
- `docs/networking_plan.md` — networking architecture
- `docs/system_architecture.md` — overall system architecture
- `docs/architecture.md` — architectural boundaries
- `docs/world_structure.md` — world layout decisions

### Infrastructure Audit

| Artifact | Status | Impact | Severity |
|---|---|---|---|
| `docs/architecture/tr-registry.yaml` | ❌ Missing | No stable requirement IDs | HIGH |
| `docs/architecture/control-manifest.md` | ❌ Missing | No layer rules for stories | HIGH |
| `docs/engine-reference/godot/VERSION.md` | ❌ Missing | ADR engine checks blind | HIGH |
| `docs/architecture/architecture-traceability.md` | ❌ Missing | No persistent traceability matrix | MEDIUM |
| `production/sprint-status.yaml` | ❌ Missing | Falls back to manual check | MEDIUM |
| `production/stage.txt` | ❌ Missing | Phase auto-detect unreliable | MEDIUM |
| Manifest version stamp | ❌ Absent | Staleness checks blind | MEDIUM |

### Technical Preferences Audit
`docs/technical-preferences.md` does not exist. All engine/language/rendering/physics fields are unconfigured.

---

## Phase 3 — Gap Classification

### BLOCKING — 1 gap
1. **No ADRs with ## Status fields**: Zero Architecture Decision Records exist. The story-readiness ADR status check silently passes all decisions — no architectural decisions are tracked in a format the framework can consume, making architecture-review and gate-check blind to past decisions.

### HIGH — 7 gaps
1. **No `docs/technical-preferences.md`**: Engine (Godot 4.6), Language (GDScript), Rendering (Forward Plus), Physics (2D) are unconfigured. ADR skills that check engine compatibility will not function.
2. **No `design/gdd/game-concept.md`**: The game concept ("cozy 2D isometric survival-building MMO") is not captured in a format HMGS concept skills can process.
3. **No `design/gdd/systems-index.md`**: System boundaries, layers, priorities, and statuses are undefined. Gate-check, create-stories, and architecture-review have no system registry to work with.
4. **No GDDs with Acceptance Criteria**: 13+ system designs exist as prose docs but lack structured Acceptance Criteria sections. Create-stories cannot generate stories from them.
5. **No `docs/engine-reference/[engine]/VERSION.md`**: Engine reference docs missing. ADR engine-compatibility checks have no version baseline to compare against.
6. **No `docs/architecture/tr-registry.yaml`**: No TR (Technical Requirement) registry. Requirement IDs and traceability cannot be established.
7. **No `docs/architecture/control-manifest.md`**: No manifest defining layer rules, naming conventions, or control boundaries for stories.

### MEDIUM — 4 gaps
1. **No `production/stage.txt`**: Phase auto-detection relies on heuristics; authoritative stage marker missing.
2. **No `production/sprint-status.yaml`**: Sprint tracking falls back to manual state checks.
3. **No `docs/architecture/architecture-traceability.md`**: No persistent traceability matrix linking requirements to implementations.
4. **No manifest version stamp**: Staleness tracking for stories is not possible.

### LOW — 1 gap
1. **No existing stories to audit**: Auto-passes format checks when absent. Stories can be generated after GDDs and ADRs are in place.

### Gap Totals

| Severity | Count | Impact |
|---|---|---|
| BLOCKING | 1 | Framework skills silently produce wrong results |
| HIGH | 7 | Infrastructure bootstrapping will fail |
| MEDIUM | 4 | Quality degradation |
| LOW | 1 | Optional improvements |

**Total gaps**: 13

---

## Phase 4 — Migration Plan

Work through these steps in order. Check off each item as you complete it.

---

### Step 1: Fix Blocking Gaps

#### 1.1 Create initial ADRs for key architectural decisions
**Problem**: Zero ADRs exist. Story-readiness, architecture-review, and gate-check cannot validate architectural decisions. Multiple critical decisions have been made (continuous overworld, server architecture, save format v3, ENet multiplayer, Forward Plus renderer) but none are recorded in HMGS-format ADRs.
**Fix**: Run `/architecture-decision create` or manually create ADR files in `docs/architecture/adr-*.md` format for each key decision. Recommended initial ADRs:

| ADR | Title | Based on existing doc |
|---|---|---|
| adr-0001 | Continuous Overworld Instead of Paged Regions | `docs/overworld_architecture.md` |
| adr-0002 | Server-Authoritative Multiplayer with ENet | `docs/server_architecture.md` |
| adr-0003 | Versioned JSON Save Format (v3) | `docs/save_data_model.md` |
| adr-0004 | Forward Plus Renderer for 2D Isometric | `project.godot` config |
| adr-0005 | Modular System Architecture with ObjectRegistry | `docs/system_architecture.md` |
| adr-0006 | Godot 4.6 as Target Engine | `project.godot` config |

Each ADR must include: `## Status`, `## ADR Dependencies`, `## Engine Compatibility`, `## GDD Requirements Addressed`, `## Performance Implications`.

**Time**: 30 min per ADR (~3 hours total for all 6)
- [ ] adr-0001: Continuous Overworld
- [ ] adr-0002: Server-Authoritative Multiplayer
- [ ] adr-0003: Versioned JSON Save Format
- [ ] adr-0004: Forward Plus Renderer
- [ ] adr-0005: Modular System Architecture
- [ ] adr-0006: Godot 4.6 Engine

---

### Step 2: Fix High-Priority Gaps

#### 2.1 Create `docs/technical-preferences.md`
**Problem**: Engine, language, rendering, physics, and project naming conventions are not configured in HMGS format. ADR skills and framework checks fail without this.
**Fix**: Run the `technical-preferences` skill or create the file manually:

```markdown
# Technical Preferences

## Engine
- Name: Godot
- Version: 4.6.3

## Language
- Primary: GDScript
- Version: Godot 4.x GDScript

## Rendering
- Renderer: Forward Plus
- Resolution: 1280x720 (stretch mode: canvas_items, aspect: expand)

## Physics
- Physics Engine: Godot Physics 2D
- Physics Ticks: 60 Hz

## Naming Conventions
- Files: snake_case
- Classes: PascalCase
- Constants: UPPER_SNAKE_CASE
- Signals: snake_case (prefixed with past-tense verb when appropriate)

## Performance Budgets
- Max draw calls: TBD
- Max active nodes: TBD
- Target FPS: 60
```

**Time**: 15 min
- [ ] `docs/technical-preferences.md` created

#### 2.2 Create `design/gdd/game-concept.md`
**Problem**: The game concept (cozy 2D isometric survival-building MMO) is documented implicitly across many files but not in a single HMGS-format concept document.
**Fix**: Create `design/gdd/game-concept.md` with the HMGS 8-section structure, synthesizing from README.md, docs/visual_identity.md, docs/world_structure.md, and other existing docs.

**Time**: 1 session
- [ ] `design/gdd/game-concept.md` created

#### 2.3 Create `design/gdd/systems-index.md`
**Problem**: No system registry exists for framework skills to consume. System boundaries, layers, priorities, and statuses are undefined.
**Fix**: Create `design/gdd/systems-index.md` with a table of all systems derived from `systems/` directory contents. Valid status values only: Not Started, In Progress, In Review, Designed, Approved, Needs Revision.

Proposed systems (derived from codebase):

| System | Layer | Priority | Status |
|---|---|---|---|
| GameStateManager | Core | P0 | Approved |
| WorldRegionManager | Core | P0 | Approved |
| OverworldController | World | P0 | Approved |
| HomesteadController | World | P0 | Approved |
| ObjectRegistry | Data | P0 | Approved |
| BuildingPlacementSystem | Gameplay | P0 | Approved |
| InteractableSystem | Gameplay | P0 | Approved |
| InventorySystem | Gameplay | P0 | Approved |
| FarmingSystem | Gameplay | P0 | Approved |
| CreatureSystem | Gameplay | P1 | Designed |
| SurvivalSystem | Gameplay | P1 | Designed |
| TaskIntegrationSystem | Gameplay | P0 | Approved |
| CombatSystem | Gameplay | P2 | In Progress |
| DungeonSystem | Gameplay | P2 | Not Started |
| RegionTransitionSystem | Core | P0 | Approved |
| PlayerSpawnSystem | Core | P0 | Approved |
| LocalSaveSystem | Data | P0 | Approved |
| NetworkSession | Network | P1 | Designed |
| WorldMood | World | P1 | Approved |
| AvatarCamera | Avatar | P0 | Approved |
| ContentRegistry | Data | P1 | Designed |
| CraftingSystem | Gameplay | P1 | Designed |
| PlayerProgression | Gameplay | P1 | Designed |
| Moderation scaffold | Admin | P2 | In Progress |
| CharacterArtRegistry | Art | P1 | Designed |

**Time**: 30 min
- [ ] `design/gdd/systems-index.md` created

#### 2.4 Bootstrap GDDs from existing design docs
**Problem**: 13+ system designs exist in `docs/` but none have the HMGS 8-section GDD format. Create-stories cannot generate stories from them.
**Fix**: For each key system, either create a GDD in `design/gdd/` or retrofit existing docs with the 8 required sections (Overview, Player Fantasy/Dream, Detailed Rules, Formulas, Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria). Start with the most gameplay-critical systems:

1. Farming — `docs/farming.md` → `design/gdd/farming.md`
2. Crafting — `docs/crafting.md` → `design/gdd/crafting.md`
3. Building Placement — `docs/building_placement.md` → `design/gdd/building-placement.md`
4. Progression & Skills — `docs/progression.md` → `design/gdd/progression.md`
5. Interactions — `docs/interactions.md` → `design/gdd/interactions.md`
6. Resources & Gathering — `docs/resources_and_gathering.md` → `design/gdd/resources-gathering.md`
7. Survival/Building Costs — `docs/survival_building.md` → `design/gdd/survival-building.md`
8. UI/HUD — `docs/ui_hud.md` → `design/gdd/ui-hud.md`

**Time**: 30 min per GDD (~4 hours for all 8)
- [ ] GDD: Farming
- [ ] GDD: Crafting
- [ ] GDD: Building Placement
- [ ] GDD: Progression & Skills
- [ ] GDD: Interactions
- [ ] GDD: Resources & Gathering
- [ ] GDD: Survival / Building Costs
- [ ] GDD: UI / HUD

#### 2.5 Create `docs/engine-reference/godot/VERSION.md`
**Problem**: Engine reference docs missing. ADR engine compatibility checks have no version baseline.
**Fix**: Create the engine reference file documenting Godot 4.6.3's API surface that the project depends on.

```markdown
# Engine Reference: Godot 4.6.3

## Version
Godot 4.6.3 (stable)
Download: https://godotengine.org/download/windows/
Release notes: https://github.com/godotengine/godot/releases/tag/4.6.3-stable

## Key API surfaces used
- Node2D / Node
- Area2D / CollisionShape2D
- CanvasLayer
- ColorRect
- Input / InputEvent
- SceneTree / MultiplayerAPI (ENet)
- JSON / FileAccess
- PackedScene / ResourceLoader

## Rendering
- Renderer: Forward Plus (compatibility: Forward Mobile not used)
- Stretch mode: canvas_items, aspect: expand
- Viewport: 1280x720

## Project anchor features
- config_version: 5
- Autoload: NetworkSession
```

**Time**: 10 min
- [ ] `docs/engine-reference/godot/VERSION.md` created

---

### Step 3: Bootstrap Infrastructure

#### 3a. Register existing requirements
Run `architecture-review` (after ADRs exist in Step 1.1) to bootstrap `docs/architecture/tr-registry.yaml`.
**Time**: 1 session
- [ ] `docs/architecture/tr-registry.yaml` created via architecture-review

#### 3b. Create control manifest
Run `create-control-manifest` to create `docs/architecture/control-manifest.md`.
**Time**: 30 min
- [ ] `docs/architecture/control-manifest.md` created

#### 3c. Set authoritative project stage
Run `gate-check production` to write `production/stage.txt`.
**Time**: 5 min
- [ ] `production/stage.txt` written

---

### Step 4: Medium-Priority Gaps

#### 4.1 Create `docs/architecture/architecture-traceability.md`
**Problem**: No persistent traceability matrix linking TR requirements to implementations.
**Fix**: Create the traceability document after TR registry exists (Step 3a).
**Time**: 30 min
- [ ] Traceability matrix created

#### 4.2 Create `production/sprint-status.yaml`
**Problem**: No sprint tracking file; falls back to manual state checks.
**Fix**: Create sprint status file with current milestone tracking.
**Time**: 15 min
- [ ] `production/sprint-status.yaml` created

#### 4.3 Add Manifest Version stamp to relevant files
**Problem**: No manifest version stamps for staleness tracking.
**Fix**: Add `Manifest Version: 1` header line to GDDs, ADRs, and control manifest as they are created.
**Time**: 5 min (done incrementally)
- [ ] Manifest version stamps added to all created artifacts

---

### Step 5: Optional Improvements

#### 5.1 Generate initial stories
**Problem**: No stories exist to audit. While auto-passing, the project has no framework stories for sprint tracking.
**Fix**: After GDDs and ADRs are in place (Steps 1-2), run `create-stories` to generate stories from approved GDDs.
**Note**: Existing stories continue to work with all framework skills — new format checks auto-pass when fields are absent. Stories won't benefit from TR-ID staleness tracking or manifest version checks until generated.
**Time**: 1 session
- [ ] Stories generated from approved GDDs

---

## Summary

| Severity | Count | Fix Order |
|---|---|---|
| ⛔ BLOCKING | 1 | Fix first — before any pipeline skill runs |
| 🔴 HIGH | 7 | Fix next — infrastructure before content |
| 🟡 MEDIUM | 4 | Fix after infrastructure bootstrapped |
| 🟢 LOW | 1 | Fix last — nice-to-have improvements |

**Estimated total remediation**: ~10-12 hours (spread across ~20 tasks)

The Hearthvale project has **substantial existing content** (55 docs, 79 source files, working prototype) but **zero HMGS-format artifacts**. The majority of the work is converting existing rich documentation into HMGS-compatible formats — not creating new content.

## Existing stories note

Existing stories continue to work with all framework skills — all new format checks auto-pass when the fields are absent. They won't benefit from TR-ID staleness tracking or manifest version checks until they're regenerated. This is intentional: do not regenerate stories that are already in progress.
