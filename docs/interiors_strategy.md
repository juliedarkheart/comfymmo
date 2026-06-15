# Interiors strategy (DEFERRED — design doc, not implemented)

Hearthvale has **no walk-in interiors**, by deliberate decision. Buildings are
exterior shells; the cottage/structure door signs say "Interior coming later."
Nothing in boot, saves, or networking depends on interiors.

## Why interiors are deferred (the real tradeoff)

The building system is moving toward a freeform, ARK/Once Human-style **modular
exterior kit** (foundations, walls, doors, roofs, fences, decor on a grid).
Once players build arbitrary custom shapes, a traditional hand-authored fixed
interior scene **cannot match the exterior** — a 3×3 shed and a 12-tile
sprawling cottage would both open into the same canned room, which feels wrong.
So interiors are an instancing + content problem, not a "draw a room" problem,
and forcing them now would lock in save/network state we'd have to migrate.

## How exteriors work today

Structure shells (cottage, shed, workshop, barn, greenhouse, well) and modular
pieces (foundations, floors, walls, door/window walls, pillars, fences) are
ordinary persistent placeables with component costs and a hammer requirement.
They are decorated from the outside. Doors are visual + a "coming later" sign.

## Future options for player interiors (decide after the exterior loop is fun)

1. **Fixed interior templates** attached to specific shell types (a "cottage
   shell" always opens a chosen cottage template). Simple; ignores custom
   exterior shape.
2. **Separate instanced interior lots** the player decorates independently
   (the exterior is a façade; the interior is its own small plot). Most
   flexible; clearest mental model.
3. **Pocket-room interiors** generated from a tiny floorplan editor (player
   stamps a room footprint, then furnishes it).
4. **No walk-in interiors for custom modular builds** — only outdoor building
   plus furniture/decor, with interiors reserved for a few special template
   buildings.

The recommended path is **(2) instanced interior lots routed through
WorldRegionManager** (already reserved for instances), because it sidesteps the
exterior-mismatch problem entirely and reuses the plot ownership model.

## Why no interiors are required for the current release

The cozy loop — gather → craft → claim land → build an outdoor homestead →
decorate → invite friends — is complete and fun without ever going indoors.
Interiors are an expansion, not a dependency.
