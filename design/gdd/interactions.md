# GDD: Interactions

> **Manifest Version:** 2026-06-30-v1
> **Status:** Approved
> **Source docs:** `docs/interactions.md`, `docs/system_architecture.md`

---

## 1. Overview

The interactions system provides proximity-based world interaction through the `InteractableSystem` registry. Players approach an interactable object, see a "Press F to [action]" prompt, and press F to trigger the associated behaviour. Interactions power the mailbox loop, farming, notice board reading, shrine inspection, villager dialogue, creature observation, and rest mechanics.

## 2. Player Fantasy / Dream

The world responds to the player's presence. Walking near a mailbox shows a prompt; pressing `F` opens a message list. Passing a villager invites a chat. Approaching a farm plot offers to tend the crops. The prompts feel natural and contextual — the player never hunts for buttons or menus to engage with the world.

## 3. Detailed Rules

### Interactable System (`systems/interactable_system.gd`)

A small registry for world-facing interactions:
- Register an interactable with: id, node, interaction type, prompt text, callback, optional data
- System tracks nearest interactable in Explore mode
- HUD shows prompt when player is close enough
- `F` triggers the registered callback for the nearest interactable

### Interaction Types and Actions

| Interaction Type | Action ID | Description |
|-----------------|-----------|-------------|
| `generic` | `inspect` | Default observation |
| `mailbox` | `check_mail` | Open mailbox message panel |
| `farm_plot` | `tend_plot` | Plant/water/harvest based on stage |
| `notice_board` | `read_notice` | Open notice board panel |
| `shrine_marker` | `inspect_shrine` | Open shrine message panel |
| `task_board` | `review_tasks` | Open task review panel |
| `villager` | `talk` | Open villager dialogue |
| `rest` | `rest` | Open rest confirmation panel |
| `ambient_creature` | `observe` | Open creature observation panel |
| `station` | `craft` | Open crafting panel at station |

### Mailbox Interaction
- Placed mailboxes register with type `mailbox`
- Nearest prompt: "Press F to check mailbox"
- Opens mailbox panel showing task messages with state (New/Seen/Done)
- Opening marks all messages seen; state persisted in save
- Unseen mail → world-space signal on all placed mailboxes
- Watering/harvesting farm plots completes corresponding mailbox tasks

### Notice Board
- Village square notice board registers via `BaseRegionController`
- Prompt: "Press F to read notice board"
- Opens message panel; first read marks `notice_board_seen` flag
- Flag persisted in region save (`world.regions.village_square.region_flags`)

### Shrine
- Forest edge shrine registers via `BaseRegionController`
- Prompt: "Press F to inspect shrine"
- First inspection marks `adventure_marker_seen` flag
- Repeat visits show softer message

### Villager Interaction
- Villagers register with type `villager`
- First visit: shows `first_visit_text` and sets intro flag
- Repeat visits: rotating lines from `repeat_visit_lines` array
- Visit count tracked as integer region flag
- Day/mood-aware dialogue lines available (passage lines with count and phase)

### Rest Marker
- Homestead cottage doorway rest marker (type `rest`)
- Prompt: "Press F to rest"
- Opens two-phase panel: confirm (F = Rest, Esc = Cancel), then result
- Resting at dusk: increments day count, resets mood to morning
- Resting at other times: advances mood one phase
- Comfort restored to 100 on rest

### Creature Observation
- Ambient creatures register with type `ambient_creature`
- Opens observe panel with creature description
- Session-once per creature for exploration XP

### BaseRegionController Helpers
- `register_region_interactable(node, prompt, callback)` — register one-off interactable
- `unregister_region_interactable(id)` — remove earlier registration
- Used by notice board, shrine, rest marker

### OutdoorAreaController Interactable Plumbing
- `register_world_interactable(id, node, type, prompt, callback, data)` — wraps InteractableSystem registration
- `_dispatch_world_interactable(id)` — invokes bound callback
- `unregister_world_interactable(id)` / `has_world_interactable(id)` / `get_world_interactable_data(id)` — query helpers

## 4. Formulas

### Proximity Check
```
nearest_interactable(player_position):
  for each registered interactable:
    distance = player_position.distance_to(interactable.node.global_position)
    if distance < INTERACT_DISTANCE and distance < nearest.distance:
      nearest = interactable
  return nearest  # or null if none within range
```

### Prompt Display
```
if nearest_interactable:
  show_prompt("Press F to " + nearest_interactable.prompt)
else:
  hide_prompt()
```

### Mailbox State
```
mailbox_state():
  unseen = any(task.status == "pending" for task in tasks)
  if unseen: show_world_signal()  # all mailboxes
  else: hide_world_signal()
```

### Rest Transition
```
rest(current_mood, current_day):
  if current_mood == "dusk":
    new_mood = "morning"
    new_day = current_day + 1
  else:
    new_mood = WorldMood.next_mood(current_mood)
    new_day = current_day
  comfort = 100
  return (new_mood, new_day, comfort)
```

## 5. Edge Cases

- **No interactables in range**: Prompt hidden; F does nothing
- **Multiple mailboxes**: All share same mailbox state; one opens on F
- **Interaction while panel open**: F suppressed
- **Interaction while in build mode**: Suppressed (Explore mode only)
- **Villager first visit vs repeat**: Controlled by intro flag + visit count
- **Creature flee during interaction**: Creature continues its flee behaviour; interaction still works
- **Rest panel open when day/mood changes**: Mood cycling suppressed
- **Save missing interactable flags**: Default to unvisited/unseen
- **Server-client interaction differences**: Mailbox, notice board, shrine, rest are client-local

## 6. Dependencies

| Depends On | Reason |
|------------|--------|
| InteractableSystem | Core registry |
| HUD (prototype_hud) | Prompt display, panel rendering |
| LocalSaveSystem | Interaction state persistence |
| TaskIntegrationSystem | Mailbox message state |
| FarmingSystem | Farm plot interaction routing |
| OutdoorAreaController | Shared interactable plumbing |

## 7. Tuning Knobs

| Parameter | Location | Default | Notes |
|-----------|----------|---------|-------|
| Interact distance | `InteractableSystem` | ~60px context-dependent | Per-type override possible |
| Creature flee radius | `ambient_creature.gd` | 60px | Per-species override |
| Villager repeat lines | Per scene | 3 | PackedStringArray |
| Rest moods cycle | `WorldMood` | morning→afternoon→dusk | Fixed order |
| Mailbox message content | `TaskIntegrationSystem` | 3 mock messages | Future: dynamic task backend |

## 8. Acceptance Criteria

1. Mailbox shows "Press F to check mailbox" prompt; F opens mailbox panel
2. Mailbox panel shows messages with New/Seen/Done states
3. Opening mailbox marks all messages seen; state persists
4. Unseen mail shows world-space signal on all mailboxes
5. Farm plot shows contextual prompt (plant/water/tend/harvest)
6. Notice board shows "Press F to read notice board"; opens message panel
7. Shrine shows "Press F to inspect shrine"; opens message panel
8. Villager first visit shows intro text; repeat visits show rotating lines
9. Rest marker shows "Press F to rest"; rest at dusk advances day
10. Rest at non-dusk advances mood; comfort restored to 100
11. Creature observation shows panel with description
12. No prompt when no interactables in range
13. Interaction suppressed during build mode
14. F8 network panel does not conflict with interaction F key
