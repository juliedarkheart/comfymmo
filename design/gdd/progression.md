# GDD: Progression & Skills

> **Manifest Version:** 2026-06-30-v1
> **Status:** Approved
> **Source docs:** `docs/progression.md`, `docs/crafting.md`, `docs/farming.md`, `docs/building_placement.md`, `docs/survival_building.md`

---

## 1. Overview

The progression system tracks player advancement through a unified XP curve and eight independent skills. All XP-earning actions feed into both a skill-specific pool and an overall XP total. Player level is derived from overall XP (never stored directly), and levels unlock recipes, placeables, and station access. Skills gate specific recipes and placeables, creating a natural progression ladder across gameplay systems.

## 2. Player Fantasy / Dream

Every action the player takes — gathering a resource, planting a seed, crafting a plank, placing a decoration, talking to a villager — quietly builds their character's expertise. Level-ups and skill-ups toast as pleasant surprises rather than grindy targets. The progression panel (P) shows a clear picture of their journey across all eight skills, with the next milestone always visible.

## 3. Detailed Rules

### XP Curve
```
Level  1:     0 XP     (base, no XP required)
Level  2:    25 XP
Level  3:    60 XP
Level  4:   110 XP
Level  5:   180 XP
Level  6:   270 XP
Level  7:   380 XP
Level  8:   510 XP
Level  9:   660 XP
Level 10:   830 XP
```
Levels are always derived from XP — never stored — so nothing can desync.

### Data Model
- `SkillProgression` shape: `{total_xp, skills: {skill_id: xp}}`
- Offline: stored in `player.progression` in local save
- Server: per-profile in world file's `known_profiles`
- Backward compatibility: earlier flat `{xp: N}` shape migrates into `total_xp` on read
- Missing data defaults to level 1, all skills 0

### The Eight Skills

| Skill ID | Sources | XP Per Action |
|----------|---------|---------------|
| gathering | Gather wood, fiber | +2 skill, +1 overall |
| mining | Gather stone, clay | +2 skill, +1 overall |
| farming | Plant, water crop | +1 skill |
| crafting | Craft recipes (all tiers) | +2–5 skill, +1–2 overall |
| building | Place objects | +2–5 skill |
| social | Talk to villagers (once/session each) | +2 skill, +1 overall |
| exploration | Observe creatures (once/session each) | +2 skill, +1 overall |
| stewardship | Complete mailbox tasks, visit notice board | +10 skill, +5 overall |

### Sources Wired

| Action | Skill XP | Overall XP |
|--------|----------|------------|
| Gather wood/fiber | +2 gathering | +1 |
| Gather stone/clay | +2 mining | +1 |
| Plant / water crop | +1 farming | — |
| Harvest crop | +5 farming | +2 |
| Craft basic (planks, rope) | +2 crafting | +1 |
| Craft advanced (blocks, cloth…) | +3–5 crafting | +1–2 |
| Place simple object | +2 building | — |
| Place component-built object | +5 building | — |
| Complete mailbox task | +10 stewardship | +5 |
| Talk to villager (once/session each) | +2 social | +1 |
| Observe creature (once/session each) | +2 exploration | +1 |
| Visit shrine / notice board (once/session) | +1 explore/steward | — |

### Enforced Unlocks

**Recipe locks (player level):**
| Recipe | Level Required |
|--------|---------------|
| Planks, Fiber Rope | 1 |
| Stone Block, Clay Brick | 2 |
| Seed Packet | 2 |
| Cloth Roll | 3 |
| Flower Bundle | 3 |

**Recipe locks (skill level):**
| Recipe | Skill Requirement |
|--------|------------------|
| Cloth Roll | Crafting 2 |
| Flower Bundle | Gathering 2 |

**Placeable locks (from ProgressionRegistry):**
| Placeable | Requirement |
|-----------|-------------|
| Garden Arch | Building 2 |
| Tiny Pond | Player Level 3 |

### UI
- `P` opens progression panel: shows player level, all 8 skills with XP-to-next
- Level-ups toast in chat log
- Skill-ups toast in chat log
- On server: player level-ups announced to everyone
- Ghost previews for gated placeables show reason (red ghost with "Requires Building Level 2")

### Admin Testing (Offline-Only, Trust-Based)
- `/xp [n]` — grant overall XP
- `/skillxp <skill> [n]` — grant skill XP
- `/skills` or `/progression` — summary
- All commands ignored by server (no self-grant online)
- No `/level` command — levels derive from XP by design

## 4. Formulas

### Level From XP
```
level_from_xp(total_xp):
  thresholds = [0, 25, 60, 110, 180, 270, 380, 510, 660, 830]
  for i, threshold in enumerate(thresholds):
    if total_xp < threshold:
      return i + 1  # 1-indexed
  return 10  # max level
```

### XP to Next Level
```
xp_to_next_level(total_xp):
  level = level_from_xp(total_xp)
  if level >= 10: return 0
  return thresholds[level] - total_xp
```

### Skill XP to Next Level
```
skill_level_from_xp(skill_xp):
  # Same curve as overall: levels 1-10 at same thresholds
  return level_from_xp(skill_xp)
```

## 5. Edge Cases

- **No save file**: Default to level 1, all skills 0
- **Old flat XP format**: Migrated to `total_xp` on read automatically
- **Session-once XP sources**: Social and exploration XP grant only once per session per villager/creature; resets on restart
- **Level 10 max**: XP past 830 still tracked but doesn't increase level
- **Server restart**: XP persisted per profile in world file; survives reconnects
- **Admin XP grant beyond thresholds**: Valid; future unlocks may extend curve
- **Missing skill XP keys in save**: Default to 0 for that skill

## 6. Dependencies

| Depends On | Reason |
|------------|--------|
| LocalSaveSystem/NetworkSession | Persistence of progression data |
| CraftingSystem | Reads skill levels for recipe gates |
| BuildingPlacementSystem | Reads level/skill for placeable gates |
| InteractableSystem | Session-once social/exploration tracking |
| TaskIntegrationSystem | Stewardship XP sources |

## 7. Tuning Knobs

| Parameter | Location | Default | Notes |
|-----------|----------|---------|-------|
| XP thresholds | `PlayerProgression` | 0/25/60/110/180/270/380/510/660/830 | Controls progression speed |
| Skill XP rewards | Per-action constants | +1 to +10 | Tune per action type |
| Skill count | `PlayerProgression` | 8 | Add new skills by adding ID |
| Session-once flag expiry | On restart | Full reset | Future: daily reset |
| Max level | Threshold array length | 10 | Add more thresholds to extend |
| Placeable locks | `ProgressionRegistry` | See rules | Dictionary of placeable → requirement |

## 8. Acceptance Criteria

1. XP earned from gathering, farming, crafting, building, socialising, exploring, tasks
2. Player level displayed on HUD identity line and in progression panel
3. `P` opens progression panel with level and all 8 skills
4. Level-ups and skill-ups toast in chat
5. Recipe gates enforced: greyed out with requirement shown
6. Skill gates enforced: preview shows "Requires [Skill] Level N"
7. Placeable gates enforced: ghost turns red with reason
8. Progression data persists across save/load
9. Server persists progression per profile
10. Old flat XP save format migrates automatically
11. Social/exploration XP grants only once per session per entity
12. Chat level-ups announced on server (all players see it)
