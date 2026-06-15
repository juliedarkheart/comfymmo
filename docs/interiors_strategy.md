# Interiors Strategy

Hearthvale now has a small prefab-interior prototype, but it is intentionally
limited.

## Current state

Some prefab structure shells can open an interior:

- cottage shell
- storage shed
- workshop hut
- barn shell

Those mappings live in `systems/building/prefab_interiors.gd`.

What the player gets today is not a full simulated indoor lot. It is a separate
interior scene/view, currently driven by `ui/interior_view.tscn`, opened from a
placed prefab door interaction. The player keeps their outdoor world position;
closing the view returns them right back outside.

Current interior controls:

- walk up to the prefab and press `F`
- press `F`, `Esc`, or click the Exit button to leave

Greenhouse and well shells do not currently expose interiors.

## Why modular interiors are deferred

The exterior building kit is moving toward a freeform, ARK / Once Human-style
construction set:

- foundations
- floors
- walls
- door walls
- window walls
- pillars
- roofs
- fences and gates

That is great for outdoor expression, but it creates a mismatch problem for
interiors. A hand-authored room scene cannot honestly represent every custom
exterior shape a player can assemble. If a player builds an L-shaped cottage,
an oversized workshop yard, or a tiny fenced shed nook, a single canned room
would feel wrong.

That is why modular custom buildings are exterior-only for now.

## What "separate scenes / instances" means here

The current prototype uses a separate interior scene/view instead of trying to
embed an indoor tilemap inside the overworld. The long-term instance model is
still expected to route through `systems/world_region_manager.gd`, which is the
reserved seam for non-outdoor spaces such as interiors, caves, and dungeons.

So the direction is:

- prefab exteriors can link to authored interiors
- modular exteriors stay outdoor-only until there is a real instance strategy
- future interior persistence should be modeled as its own scene/instance state,
  not as a magical room stuffed into a custom exterior footprint

## Recommended long-term shape

The safest long-term approach is separate interior instances or interior lots
owned by the same player/profile, not one procedural room per modular shell.
That keeps:

- exterior creativity intact
- save data simpler
- multiplayer authority clearer
- authored interior content reusable

## Scope boundaries for this branch

Implemented:

- prefab door interaction for supported shells
- safe metadata parsing for prefab interior definitions
- a shared interior scene/view that loads cleanly

Not implemented:

- interiors for modular custom buildings
- furniture persistence inside interiors
- multiplayer interior sync
- generated floorplans
- greenhouse/well interiors

That is intentional. The outdoor homestead loop remains the main game.
