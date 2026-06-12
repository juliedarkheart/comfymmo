# Playtest readiness

## Verified automatically (headless, tools/validate_project.gd + boots)

- project imports clean; all scripts/scenes in the validation list load
- offline boot of scenes/main.tscn runs without errors
- every placeable (20) has registry fields, a loadable scene, a PlaceableCrate
  root, and a valid material cost
- MaterialInventory math (filtering, overspend, spend)
- profile create/normalize; expanded customization ids normalize
- server world default shape, occupancy rules, persistence normalization
- PlayerIdentity sanitation; offline-mode default; F8/F9 input actions
- dedicated server boots, creates user://server_worlds/default_world.json

## Needs live human verification

- two clients connected simultaneously (architecture supports 16; only the
  protocol logic is machine-verified, not real concurrent input)
- position smoothness at ~8 Hz under real movement
- placement race: two clients targeting the same tile (server serializes —
  second gets "That spot is taken" — but eyes-on confirmation wanted)
- server restart persistence from a client's point of view
- F8 panel UX on 1080p and 4K

## Known rough edges (accepted for this slice)

- server validates occupancy, not full terrain rules: a connected client can
  place on tiles the offline map would refuse (e.g. inside the cottage
  footprint on another client's view). Top of the fix list.
- network objects are display-only on clients: no remove/move, and they
  overlap visually with your own offline objects in the homestead area.
- movement is client-trusted; a hacked client could teleport. Fine for LAN.
- gathering is offline-only inventory; connected building uses the separate
  server pouch (starter pack) — intentional, documented in survival doc.
- wardrobe mirror tile is not placement-blocked; you can build a crate under
  the mirror. Cosmetic.
- profiles file is per-machine: two instances on one PC share it.

## Suggested 15-minute playtest script

1. Offline: boot → welcome panel → gather each material → build a bench →
   restart → bench + materials persisted.
2. Wardrobe: mirror → change everything → restart → look persisted.
3. Server: start it → connect → build → see "Server:" pouch drop →
   second client → wave at yourself → both see the build →
   kill server → restart → reconnect → still there.
