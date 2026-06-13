# Progression: player level + skills

```
gather / mine / farm / craft / build / socialize / explore / steward
→ skill XP + overall XP → levels → recipe & build unlocks
```

## Model

One curve for everything (`PlayerProgression`): levels 1–10 at cumulative XP
0 / 25 / 60 / 110 / 180 / 270 / 380 / 510 / 660 / 830. Levels are always
derived from XP — never stored — so nothing can desync.

Data shape (`SkillProgression`): `{total_xp, skills: {skill_id: xp}}`.
- Offline: `player.progression` in the local save. **Back-compat:** the
  earlier flat `{xp: N}` shape migrates into `total_xp` on read; missing data
  = level 1, all skills 0.
- Server: per profile in the world file's `known_profiles` (old flat `xp`
  fields migrate the same way). XP survives reconnects and restarts.

## Skills (stable ids)

gathering (wood/fiber) · mining (stone/clay) · farming (plant/water/harvest) ·
crafting (recipes) · building (placing) · social (villagers) · exploration
(creatures, shrine) · stewardship (mailbox tasks, notice board)

## XP sources wired

| action | skill XP | overall XP |
|---|---|---|
| gather wood/fiber | +2 gathering | +1 |
| gather stone/clay | +2 mining | +1 |
| plant / water crop | +1 farming | — |
| harvest crop | +5 farming | +2 |
| craft basic (planks, rope) | +2 crafting | +1 |
| craft advanced (blocks, cloth…) | +3–5 crafting | +1–2 |
| place simple object | +2 building | — |
| place component-built object | +5 building | — |
| complete mailbox task | +10 stewardship | +5 |
| talk to a villager (once/session each) | +2 social | +1 |
| observe a creature (once/session each) | +2 exploration | +1 |
| visit shrine / notice board (once/session) | +1 explore/steward | — |

All sources work offline AND server-side (gather/craft/build grants run on the
server when connected; the session-once social/exploration grants are
client-local for now). Chat-participation XP is deferred.

## Unlocks enforced now (demonstration set)

- Recipes: player-level ladder (Lv1 hand → Lv2 workbench → Lv3 garden table)
  plus skill locks: **Cloth Roll needs Crafting 2**, **Flower Bundle needs
  Gathering 2**.
- Placeables (`ProgressionRegistry.placeable_locks`): **Garden Arch needs
  Building 2**, **Tiny Pond needs Player Level 3**. The placement ghost turns
  red with "Requires Building Level 2"; the server enforces the same locks.

## UI

**P** opens the progression panel (player level + all 8 skills with XP-to-
next; Esc closes). Level-ups and skill-ups toast in the chat log; on a server,
player level-ups are announced to everyone.

## Admin testing (offline-only, trust-based)

`/xp [n]` · `/skillxp <skill> [n]` · `/skills` or `/progression` (summary) ·
`/give <id> [n]`. The server ignores all commands, so connected players
cannot self-grant. There is no `/level` — levels derive from XP by design.

## Future

Skill-specific perks (gather yield, craft batch sizes), unlock notifications
listing what opened, daily-reset for session-once XP, server-side social/
exploration validation, cosmetic unlocks.
