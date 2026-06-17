# Character customization — foundation (v1)

Status: **data + wardrobe/dev panel + save integration + profile integration +
network sync + registry-backed live sprites.** The F9 panel doubles as the player-facing
Wardrobe (mirror beside the cottage, "Press F to open wardrobe"); appearance
persists in `player.appearance` AND the active local profile, and is sent to
the server in the multiplayer join payload so other players see your look.

Option set (this pass): 6 hair styles (round_bob, fluffy_short, soft_curls,
leafy_pigtails, cozy_bun, wavy_shag), 6 outfits (starter_overalls, cozy_tunic,
forest_apron, village_dress, mushroom_sweater, gardener_jacket), 6 accessories
(none, leaf_clip, tiny_hat, flower_pin, round_glasses, acorn_cap), 13 palette
colors (original 7 + butter_yellow, berry_red, pond_blue, lilac, soft_black,
warm_white), 3 skin tones.

Appearance precedence (see also docs/profile_and_accounts.md): explicit
save `player.appearance` wins at boot; otherwise the active profile seeds it;
the wardrobe/F9 panel writes both thereafter.

## Pieces

- `systems/character/character_appearance_registry.gd` — all options as
  stable string ids with display names, plus the shared pastel palette and
  skin tones. Ids are the contract; display names may change freely.
- `systems/character/character_appearance.gd` — the appearance data model:
  a plain Dictionary, one id per slot, with `default_appearance()` and
  `normalized()` (fills missing slots, replaces unknown ids with defaults).
- `systems/art/character_art_registry.gd` — live actor sprite lookup for the
  player, remote players, villagers, and ambient creatures. It resolves original
  generated sprites under `art/generated/hearthvale/{characters,creatures}/`.
- `systems/character/character_visual_builder.gd` — legacy/dev fallback that
  turns an appearance dict into Polygon2D children. It is no longer the normal
  live render path.
- `avatar/avatar_visual.gd` — the player's `Body` node; rebuilds on wardrobe
  changes but uses the `CharacterArtRegistry` player sprite first.
- Villagers (`villagers/simple_villager.gd`, `bram_villager.gd`) carry a
  `visual_id` and use `CharacterArtRegistry` first. Their `_get_appearance()` /
  `_decorate()` hooks remain fallback-only.

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

## Save integration (implemented)

Appearance lives at `player.appearance` in `user://homestead_save.json` as a
flat dict of slot→id strings, e.g.:

```json
"player": {
	"inventory": { ... },
	"survival": { ... },
	"appearance": {
		"body_style": "cozy_default",
		"skin_tone": "peach",
		"hair_style": "round_bob",
		"hair_color": "warm_brown",
		"outfit_style": "starter_overalls",
		"outfit_color": "moss_green",
		"accessory": "none",
		"face_style": "happy"
	}
}
```

Rules (enforced by `LocalSaveSystem.get/set_player_appearance` and checked by
`tools/validate_project.gd`):

1. The key is optional — old saves without it load the default look. No save
   version bump; migration passes the `player` section through untouched.
2. Reads and writes both go through `CharacterAppearance.normalized()`, so
   unknown ids (e.g. from a newer build) degrade per-slot to defaults.
3. Write only ids, never display names or colors.
4. Never remove an id from the registry once shipped in a save; retire by
   mapping it to a successor inside `normalized()`.

## Dev character creator panel (implemented)

`ui/dev_character_creator_panel.tscn` — toggled with **F9** in the overworld.
Prev/next buttons per slot (hair style/color, skin tone, outfit style/color,
accessory), plus Reset Default and Close. Every change still applies via
`AvatarVisual.rebuild()` and persists immediately, but the current live sprite
is a fixed registry-backed actor sprite until final character sheet variants are
available. It is instanced by
`OverworldController._setup_dev_overlay`, which also applies the saved
appearance to the avatar at boot. The panel touches no gameplay state — it is
an overlay only, and the real player-facing character creator remains future
work.
