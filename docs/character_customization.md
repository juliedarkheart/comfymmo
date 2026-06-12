# Character customization — foundation (v1)

Status: **data + visual builder only.** No UI, no save integration yet.
Nothing in this system touches `LocalSaveSystem` or existing save files.

## Pieces

- `systems/character/character_appearance_registry.gd` — all options as
  stable string ids with display names, plus the shared pastel palette and
  skin tones. Ids are the contract; display names may change freely.
- `systems/character/character_appearance.gd` — the appearance data model:
  a plain Dictionary, one id per slot, with `default_appearance()` and
  `normalized()` (fills missing slots, replaces unknown ids with defaults).
- `systems/character/character_visual_builder.gd` — turns an appearance dict
  into Polygon2D children: chibi proportions, three hair styles, three
  outfits, three accessories, shared face.
- `avatar/avatar_visual.gd` — the player's `Body` node; builds the default
  appearance in `_ready()` and exposes `rebuild(appearance)` for a future
  character creator.
- Villagers (`villagers/simple_villager.gd`, `bram_villager.gd`) use the same
  builder with their own `_get_appearance()` + `_decorate()` overrides, so
  every new appearance option automatically works for NPCs too.

## Slots and current options

| slot | options (ids) | default |
|---|---|---|
| body_style | cozy_default | cozy_default |
| skin_tone | peach, honey, umber | peach |
| hair_style | round_bob, fluffy_short, soft_curls | round_bob |
| hair_color | blush_pink, moss_green, sky_blue, warm_brown, lavender, cream, terracotta | warm_brown |
| outfit_style | starter_overalls, cozy_tunic, forest_apron | starter_overalls |
| outfit_color | (same palette as hair_color) | moss_green |
| accessory | none, leaf_clip, tiny_hat | none |
| face_style | happy | happy |

## Future save integration (not implemented)

Planned shape: a `player.appearance` dictionary of slot→id stored alongside
existing player data. Rules when we do it:

1. Read with `CharacterAppearance.normalized(save_dict)` — old saves with no
   appearance key get the default look; saves written by newer builds with
   unknown ids degrade per-slot instead of failing.
2. Write only ids, never display names or colors.
3. Never remove an id from the registry once shipped in a save; retire by
   mapping it to a successor inside `normalized()`.

## Future character creator UI (not implemented)

A dev-only panel can be built safely on top of what exists: enumerate options
from the registry, build a candidate dict, call `AvatarVisual.rebuild()` for
live preview. No other system needs to change.
