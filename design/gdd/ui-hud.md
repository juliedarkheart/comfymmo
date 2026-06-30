# GDD: UI / HUD

> **Manifest Version:** 2026-06-30-v1
> **Status:** Approved
> **Source docs:** `docs/ui_hud.md`, `docs/visual_identity.md`, `docs/system_architecture.md`

---

## 1. Overview

The UI/HUD system provides all player-facing interface elements: the persistent HUD status bar, build menu, inventory panel, crafting panel, progression panel, minimap, quick tools bar, interaction prompts, mailbox panels, dialogs, system menu, admin panel, and chat. The visual direction is warm storybook — parchment, honey, and wood — with readable, low-noise presentation.

## 2. Player Fantasy / Dream

The UI feels like a natural part of the cozy world — not a debug overlay. Status lines at the top show identity, location, materials, and comfort at a glance. The build menu (B) is a friendly catalogue of possibilities. Panels open cleanly with smooth transitions and close without trapping the player. The player always knows their mode (Explore/Placement/Edit/Move), what they can afford, and what to press next.

## 3. Detailed Rules

### Always-On HUD (Top Line)

```
@username (Display Name) | Offline/Server | Lv N
[Area / Plot Status]
Wood: N  Stone: N  Fiber: N  Clay: N  Tokens: N
Comfort: N/100
[Mode/Help Line: Explore / Placement Mode / Edit Mode / Move Mode]
```

### Panels

| Key | Panel | Description |
|-----|-------|-------------|
| `B` | Build Menu | Category-based placeable selection, cost display |
| `I` | Inventory | Item grid, category tabs (future) |
| `K` | Crafting | Recipe list, inputs/outputs, craft button |
| `P` | Progression | Player level, 8 skills with XP-to-next |
| `M` | Minimap | Schematic world readout with player marker |
| `H` | Help | Controls reference and key bindings |
| `Esc` | System Menu | Resume, toggle fullscreen, quit to desktop |
| `Enter` | Chat | Text input, message display |
| `F7` | Admin Panel | World-builder controls, overlay toggle |
| `F8` | Multiplayer | Server connect/disconnect, profile |
| `F9` | Wardrobe | Character appearance editor |

### Build Menu (B)

Non-modal panel that stays open while walking. Categories:

1. Foundations
2. Walls
3. Doors & Windows
4. Roofs
5. Fences & Gates
6. Structures
7. Crafting & Utilities
8. Storage
9. Farming
10. Paths & Terrain
11. Furniture
12. Decor

Each row shows: name, cost, required tool, footprint size, availability status.
`Select` arms the piece. `Tab` cycles while placement mode active.

### Edit Toolbar (E)

Bottom-center toolbar with visible buttons:
- Select / Move / Rotate / Delete / Cancel
- Selected-object summary text
- Feedback/denial text
- **Rotate** currently reports "coming later" for placed pieces

### Interaction Prompts

Contextual "Press F to [action]" text near the nearest interactable.
Hides when no interactables in range.

### Mood Tint

Full-screen ColorRect as first child of HUD CanvasLayer:
- Renders over world, under UI panels
- `mouse_filter = ignore` (never intercepts clicks)
- Applied by `HUD.set_mood(mood_id)` with tint color and "Time:" label update

### Chat

- `Enter` opens chat input (movement suspended while typing)
- `Esc` closes chat
- System messages (toasts) for: level-ups, skill-ups, gather results, join/leave
- Server: broadcasts with identity-state name, sanitized (trimmed, ≤200 chars)
- Offline: local system-message log only

### System Menu (Esc)

- Resume / Close — hide menu, resume movement and interactions
- Toggle Fullscreen / Windowed — same as F11, persisted
- Quit to Desktop

Movement and interactions pause while menu open.

### Minimap (M)

- Schematic world readout
- Live player marker while moving
- Plot ownership colouring
- Landmark dots
- Clipped to frame

### Quick Tools Bar

- 8 starter tool/item slots in bottom-center hotbar
- Compact slot sizing for LimeZu Modern UI assets
- Shows ownership/readiness state

## 4. Formulas

### HUD Material Display
```
materials_line(inventory):
  text = ""
  for material in [wood, stone, fiber, clay, tokens]:
    text += material.name + ": " + inventory.get_count(material.id) + "  "
  return text
```

### Prompt Positioning
```
prompt_position(interactable_node):
  return interactable_node.global_position + Vector2(0, -PROMPT_OFFSET_Y)
```

### Mode Line
```
mode_line(state):
  match state:
    "explore": return "Explore"
    "placement": return "Placement Mode — " + active_placeable.name + " (" + cost_string + ")"
    "edit": return "Edit Mode"
    "move": return "Move Mode"
```

## 5. Edge Cases

- **Build menu open while moving**: Non-modal; walking continues
- **Esc press in sub-panel**: Closes current panel first, then system menu on next Esc
- **F pressed with panel open**: Suppressed (panel input takes priority)
- **Chat open during build**: Movement suspended while typing
- **Inventory open during placement**: Commands are separate; F (eat) works with inventory open
- **Mood cycling while panel open**: Suppressed (T key ignored)
- **Fullscreen toggle during gameplay**: Persisted via `display_settings.gd`
- **No interactable in range**: Prompt hidden, F does nothing
- **Missing profile data (offline)**: Shows `@local_user (Player) | Offline`
- **Help panel shows all key bindings**: Includes Esc/F11/Quit for accessibility

## 6. Dependencies

| Depends On | Reason |
|------------|--------|
| InteractableSystem | Prompt display |
| InventorySystem | Material counts |
| PlayerProgression | Level/skill display |
| SurvivalSystem | Comfort display |
| BuildingPlacementSystem | Build menu, mode display |
| WorldMood | Mood tint application |
| NetworkSession | Server/offline status display |
| TaskIntegrationSystem | Mailbox panel content |

## 7. Tuning Knobs

| Parameter | Location | Default | Notes |
|-----------|----------|---------|-------|
| Viewport resolution | `project.godot` | 1280×720 | Stretch: canvas_items, expand |
| Overworld default zoom | `AvatarCamera` | 1.3 | For 4K readability |
| Chat message length limit | `ChatMessage` | 200 chars | Server-enforced |
| Chat trim | `ChatMessage` | Trimmed, single line | Server-sanitized |
| Mood tint alpha | `WorldMood` | 0 (afternoon) → ~0.15 (dusk) | Per-mood configurable |
| Prompt offset | `InteractableSystem` | -30px Y | Above interactable |
| Build menu categories | `BuildMenuPanel` | 12 | Add/remove categories |

## 8. Acceptance Criteria

1. HUD shows identity line, area, materials, comfort, mode
2. `B` opens build menu; categories functional; `Select` arms placeable
3. `Tab` cycles active placeable in placement mode
4. `E` opens edit toolbar; Select/Move/Delete/Cancel buttons functional
5. `I` toggles inventory panel
6. `K` toggles crafting panel
7. `P` shows progression (level + all 8 skills)
8. `M` toggles minimap with player marker
9. `H` shows help overlay with all key bindings
10. `Esc` opens system menu; Resume/Fullscreen/Quit functional
11. Interaction prompt shows contextual "Press F to [action]"
12. Mood tint renders between world and UI
13. Chat opens on Enter; messages toast on gather/level-up/join
14. Quick tools bar shows 8 slots with item readiness
15. Mode line updates for Explore/Placement/Edit/Move
16. Server/Offline status line reflects connection state
