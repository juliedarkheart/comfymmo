# Engine Reference: Godot 4.6.3

> **Manifest Version:** 2026-06-30-v1
> **Last updated:** 2026-06-30

## Version

- **Engine:** Godot 4.6.3 (stable)
- **Configuration:** config_version=5
- **Download:** https://godotengine.org/download/windows/
- **Release notes:** https://github.com/godotengine/godot/releases/tag/4.6.3-stable

## Key API Surfaces Used

| API | Usage | Location |
|-----|-------|----------|
| Node2D / Node | Base classes for all controllers, systems, and gameplay objects | Everywhere |
| Area2D / CollisionShape2D | Proximity detection for interactables, region transitions | InteractableSystem, WorldRegionManager |
| CanvasLayer | UI rendering layer above world | HUD, panels |
| ColorRect | Mood tint overlay, UI backgrounds | prototype_hud.tscn |
| Input / InputEvent | WASD movement, interaction keys, placement controls | Controllers, BuildingPlacementSystem |
| SceneTree / MultiplayerAPI | ENet transport, RPCs, network mode | NetworkSession |
| JSON / FileAccess | Save/load versioned JSON | LocalSaveSystem |
| PackedScene / ResourceLoader | Scene instantiation for placed objects | BuildingPlacementSystem |
| @onready | Lazy node references | All controllers and systems |
| class_name | Global script registration | All systems and registries |
| AnimatedSprite2D | Creature and character animations | Creatures, villagers |
| Tween | Smooth transitions (mood, creature motion) | WorldMood, ambient creatures |
| Callable | Deferred callbacks, signal connections | Various |

## Rendering

- **Renderer:** Forward Plus (clustered)
- **Feature flags:** `"4.6"`, `"Forward Plus"`
- **Stretch mode:** `canvas_items`
- **Aspect mode:** `expand`
- **Viewport:** 1280×720 (window base size)
- **Target FPS:** 60

## Project Anchor Features

- **Autoload:** `NetworkSession` → `systems/network/network_session.gd`
- **Main scene:** `res://scenes/main.tscn`
- **Boot sequence:** `main.tscn` → `game_bootstrap.gd` → `WorldRegionManager` → `overworld.tscn`
- **Save path:** `user://homestead_save.json`
- **Server save path:** `user://server_worlds/<world>.json`

## Physics

- **Physics engine:** Godot Physics 2D
- **Physics ticks:** 60 Hz
- **Collision layers:** `GameplayLayer` (y-sorted), dedicated layers for interactables

## Godot 4.6-Specific Features Used

- **@export annotations** for inspector-exposed variables on creatures, villagers, and placeables
- **Callable** for type-safe callback references (interactable registration, deferred transitions)
- **PackedStringArray** for configuration features and villager repeat lines
- **InputEventKey.keycode** for keyboard input mapping

## Post-Cutoff Advisory

Godot 4.6.3 is newer than LLM training data. Verify specific API calls against the engine documentation before implementation, particularly:
- Any `MultiplayerAPI` changes between 4.2 and 4.6
- `JSON` and `FileAccess` API surface (may differ from Godot 4.2/4.3)
- `StretchMode` and `Viewport` configuration options
- `InputEventKey.keycode` vs `physical_keycode` semantics
