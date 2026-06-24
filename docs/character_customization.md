# Character customization — foundation (v1)

Status: **data + wardrobe/dev panel + save integration + profile integration +
network sync + registry-backed live sprites.** The F9 panel doubles as the player-facing
Wardrobe (mirror beside the cottage, "Press F to open wardrobe"); appearance
persists in `player.appearance` AND the active local profile, and is sent to
the server in the multiplayer join payload so other players see your look.

**Current reality (2026-06-24):** LimeZu Modern Farm only provides full-body character
sheets (Farmer_1, Farmer_2, Body_2). All three are male-presenting farmers — there is
no true female/feminine body in any LimeZu pack. There are NO separate layered sprites
for hair, outfit, hat, skin, or accessories — everything is baked into the sheet.
The ONLY customization that visibly works is **body_presentation** (which selects
the base sheet) and **outfit_color** (which applies as a palette tint/modulate).
All other controls (hair_style, hair_color, outfit_style, skin_tone, accessory)
are DISABLED in the F9 panel with "(unavailable)" labels because they cannot
affect the rendered sprite on full-body sheets.

To get true layered customization, the LimeZu Modern Interiors "Character Generator"
GUI tool must be run to produce layered PNG outputs, and the sprite renderer must
be updated to composite those layers. This is documented as future scope.

## Body/presentation presets

Three body_presentation options exist:

| option | LimeZu sheet | description |
|---|---|---|
| `neutral` | Farmer_2 | Middle-ground. Default for Julie. No hat on sheet. |
| `feminine` | Body_2 | Closest available silhouette to neutral/feminine. Documented limitation: still a male-presenting base body — no true female body exists in any LimeZu pack. Tinted with warm palette. |
| `masculine` | Farmer_1 | Classic farmer — most masculine-presenting. Has a hat (cannot be removed). |

Each body_presentation changes the player's base LimeZu sheet immediately. The
default is `neutral` (Farmer_2) so the player does not default to masculine.

## Option set (this pass)

**Real (visibly changes the rendered sprite):**
- `body_presentation`: feminine, masculine, neutral (3 options, sheet swap)
- `outfit_color`: 13 shared pastel palette colors applied as sprite modulate tint

**Disabled / unavailable (baked into full-body sheets, cannot affect rendering):**
- `hair_style` (6 options, "(unavailable)" in F9)
- `hair_color` (13 colors, "(unavailable)")
- `outfit_style` (6 options, "(unavailable)")
- `skin_tone` (3 tones, "(unavailable)" — tinting the whole sheet would also tint skin)
- `accessory` (6 options, "(unavailable)")
- `body_style` (1 option, cozy_default)

**Still in data model for future layered support:**
- `face_style` (1 option, happy)

## How customization works (current full-body sheet path)

1. The F9 panel's body_presentation < > buttons change `_appearance["body_presentation"]`
2. `_apply_appearance()` calls `AvatarVisual.rebuild()` which calls `CharacterProfileRegistry.apply_player_appearance()`
3. The profile maps `body_presentation` → LimeZu sheet ID (Farmer_2 / Body_2 / Farmer_1)
4. `AvatarVisual.rebuild()` then creates the sprite via `CharacterArtRegistry`, which reads the updated sheet from the profile
5. For `outfit_color`, the palette tint is applied as `sprite.modulate` immediately
6. Changes persist to `player.appearance` in the save

## Hat removal

Hat removal is NOT supported. Farmer_1 has a hat baked into the sheet — there is
no hatless variant. Farmer_2 and Body_2 already have no hat. Choosing a presentation
with a hatless sheet is the only "hat removal" available. A fake hat toggle is
not exposed.

## Clothing, hair, and accessories

Clothing, hair, and accessories are baked into the full-body sheets. Different
sheets show different outfits/hair (e.g. Farmer_1 has red shirt + hat, Farmer_2
has green shirt + no hat, Body_2 has blue shirt). To "change outfit" or "change hair",
switch body_presentation. True individual layering requires the LimeZu Interiors
Character Generator (GUI tool) to produce composited character outputs.

## How to test

**Save/load:**
1. Open F9 wardrobe, change body_presentation and outfit_color
2. Walk around — the sprite should visibly change (different sheet + tint)
3. Quit and relaunch — the appearance should persist
4. Check `user://homestead_save.json` → `player.appearance` has body_presentation

**Downward movement animation:**
1. Walk down/south — the player should visibly step (2-frame walk cycle + 3px body bob)
2. Stop — the player settles to down idle facing
3. Walk up/north — the player faces back (single frame + bob)
4. Walk left/right — the player mirrors the front frame + bob

**NPC isolation:**
1. Customize player via F9 — confirm Rowan still looks like Farmer_1, Hazel like Body_2
2. Player signature (sheet + palette) must differ from every NPC signature

## Smoke tests

- `tools/smoke_character_identity.gd` — profiles load, player≠Rowan, NPCs varied
- `tools/smoke_avatar_customization.gd` — body_presentation presets, palette changes, save/load round-trip, NPC isolation, animation frames
- `tools/smoke_homestead_loop.gd` — farming save/load with customization preserved

## Layered avatar customization — REAL (2026-06-25)

The F9 wardrobe now actually changes the visible player. The player avatar renders as composited
**layers** from the LimeZu Modern Interiors **Character_Generator** (body + eyes + outfit + hair +
accessory), so changing a field swaps a real layer.

- **Compositor rule:** every layer is region-cropped at the SAME 16×32 cell pasted at origin
  **(0,0)**. Body sheets are 927×656 (an extra 31px right margin); other layers are 896×656 — the
  margin is ignored (the crop is 16px wide), so layers line up. The earlier "blob" was a
  compositor bug (16×16 cells + per-layer first-content rows), not bad assets.
- **Curated starter set** (local, gitignored
  `licensed_assets/limezu/generator_manifests/hearthvale_curated_avatar_parts_manifest.json`):
  3 bodies (skin tones), 6 hairstyles, 6 outfits, 4 accessories + None, 3 eyes. **Julie default**
  is a neutral-feminine cozy look (Body_03 + Hairstyle_22_04 + Outfit_14_03 + Eyes_02 +
  Ladybug) — never forced masculine.
- **Real F9 controls:** Body (presentation → skin/body), Hair, Outfit, Accessory (incl. **None**,
  which removes the accessory layer). **Deferred/disabled:** Palette tint (would recolour skin on
  a layered composite — colour comes from the chosen part), Eyes selector (fixed Eyes_02), Hair/Skin
  separate colour pickers. Disabled controls are greyed out — no fake controls.
- **Bodies are skin tones, not gendered;** presentation comes from hair/outfit/accessory.
- **Fallback:** on a clean checkout (no manifest/pack) `CharacterPartLibrary.layered_ready()` is
  false and the avatar falls back to the full-body LimeZu farmer sheet + presentation/tint. The
  full-body fallback is preserved; layered mode never renders a fallback sprite underneath.
- **Save/load:** the selected body/hair/outfit/accessory persist in `player.appearance`; restart
  keeps the look. **NPCs are unaffected** — Rowan/Hazel/villagers keep their farmer-sheet profiles.
- **Animation:** the layered player uses the verified interiors idle-down (0,0)/idle-up (1,0)
  frames with a 2-frame **down** walk step (fixes downward animation); up/side reuse the facing
  idle + bob (full directional walk cycles deferred). Tool sockets/facing/flip unchanged.
- **How to test F9:** open F9 by the cottage mirror → cycle Body/Hair/Outfit/Accessory → the avatar
  changes immediately; set Accessory to None → the accessory disappears; Close, reopen, restart →
  the look persists. Walking down shows front-facing movement.
- **Verification:** `tools/smoke_avatar_layered_parts.gd`, `tools/smoke_avatar_customization.gd`,
  and `tools/validate_project.gd` assert every editor field changes the render signature, None
  removes a layer, the default isn't masculine, and player changes never touch NPC signatures.

## Actor visual identity & uniqueness (LimeZu, 2026-06-24)

The LimeZu graphics repair made all actors render the SAME `Farmer_1` idle frame
(`CharacterArtRegistry._limezu_actor_sprite` ignored the actor id) — player and every NPC
looked identical. Fixed with a central profile layer:

- `systems/character/character_profile_registry.gd` (`CharacterProfileRegistry`) — one VISUAL
  PROFILE per actor id: a base LimeZu **sheet** (`Farmer_1` / `Farmer_2` / `Body_2`), a pale
  palette **tint**, display name/role, and descriptive hair/outfit/accessory tags. A
  `signature()` (sheet + palette) proves uniqueness. Player uses **Farmer_2**, Rowan **Farmer_1**,
  villagers vary by sheet + tint, so no two named actors share a signature and the player is
  never the Rowan/NPC clone.
- In LimeZu live mode, `_limezu_actor_sprite` reads the profile: it resolves the sheet (falling
  back to `Farmer_1` on a partial pack) and applies the tint as `modulate`. Clean-checkout safe:
  profiles only NAME LimeZu logical ids; a checkout without the packs still boots the generated
  `art/generated/hearthvale/characters/` art.
- **Player customization → live look:** `CharacterProfileRegistry.apply_player_appearance()`
  derives the player's sheet from `body_presentation` and the tint from `outfit_color`.
  `AvatarVisual.rebuild()` applies the profile BEFORE building the sprite, and applies
  the tint immediately via `modulate`, so the F9 Wardrobe choices show in the world immediately.
  Missing/default customization falls back to the default Julie profile (neutral/Farmer_2).
- **Testing uniqueness:** `tools/smoke_character_identity.gd` (profiles load, player≠Rowan,
  NPCs varied, customization round-trips + falls back) and `tools/audit_live_visuals.gd`
  (`ACTOR IDENTITIES` table + duplicate-signature flag). `tools/validate_project.gd` fails on
  missing/blank actor art, a player==Rowan signature, all-named-actors-identical, a non-LimeZu
  actor tier, a missing required profile, or a missing customization default.
- **Temporary vs. future:** body_presentation sheet swaps + palette tints are the lightweight
  FOUNDATION. A full layered character creator (per-part hair/outfit/skin sprites composited
  over a LimeZu body) is future scope — the appearance data model + F9 panel already exist
  to grow into it. The slot data (hair_style, outfit_style, accessory, skin_tone) is preserved
  in saves for backward compatibility when layered rendering arrives.

## Facing, animation & held-tool sockets (2026-06-24)

- `systems/character/character_animation_registry.gd` (`CharacterAnimationRegistry`) — reviewed
  directional FRAME cells + per-facing hand SOCKETS for the LimeZu base character sheets
  (Farmer_1/Farmer_2/Body_2, 16x32 frames). Wired now: DOWN (front, cell col1) and UP (back,
  col4) idle, a 2-frame DOWN walk, and SIDE = the down frame mirrored. The avatar
  (`avatar/avatar_visual.gd`) swaps the body sprite's `region_rect` by facing/walk and reads the
  hand socket so held tools sit on the hand (drawn behind the body when facing up).
  Downward walk adds a 3px body bob for visible stepping.
- Full per-direction walk cycles and the action atlases (chopping/watering/etc.) are CATALOGED,
  not yet wired — run `tools/audit_limezu_animations.gd` to (re)build the gitignored
  `licensed_assets/limezu/generator_manifests/limezu_animation_manifest.json`. This keeps a
  wrong-frame guess from shipping: anything unreviewed renders the safe single idle pose.
- Character uniqueness profiles still drive the base sheet + palette per actor, so facing/anim
  layers on top of identity without changing it.

## Pieces

- `systems/character/character_appearance.gd` — the appearance data model:
  a plain Dictionary, one id per slot, with `default_appearance()` and
  `normalized()` (fills missing slots, replaces unknown ids with defaults).
  Now includes `body_presentation` as the first slot.
- `systems/character/character_appearance_registry.gd` — all options as
  stable string ids with display names, plus the shared pastel palette and
  skin tones. Now includes `body_presentations()` (feminine/masculine/neutral)
  and `body_presentation_sheet()` mapping to LimeZu sheet IDs.
- `systems/character/character_profile_registry.gd` — per-actor VISUAL PROFILES.
  `apply_player_appearance()` now reads `body_presentation` to select the base
  sheet AND `outfit_color` to set the palette tint.
- `systems/art/character_art_registry.gd` — live actor sprite lookup for the
  player, remote players, villagers, and ambient creatures.
- `avatar/avatar_visual.gd` — the player's `Body` node; `rebuild()` now applies
  the appearance to the profile BEFORE building the sprite, and applies the
  palette tint immediately via `modulate`.
- Villagers (`villagers/simple_villager.gd`, `bram_villager.gd`) carry a
  `visual_id` and use `CharacterArtRegistry` first. They are NOT affected by
  player customization.

## Slots and current options

| slot | options (ids) | default | visible? |
|---|---|---|---|
| body_presentation | feminine, masculine, neutral | neutral | YES — changes the LimeZu base sheet |
| outfit_color | (13 shared pastel colors) | moss_green | YES — applied as modulate tint |
| outfit_style | starter_overalls, cozy_tunic, ... | starter_overalls | NO — baked into full-body sheet |
| hair_style | round_bob, fluffy_short, ... | round_bob | NO — baked into full-body sheet |
| hair_color | (13 shared pastel colors) | warm_brown | NO — not applied separately |
| skin_tone | peach, honey, umber | peach | NO — would tint whole sprite |
| accessory | none, leaf_clip, ... | none | NO — baked into full-body sheet |
| body_style | cozy_default | cozy_default | NO — single option |
| face_style | happy | happy | NO — future scope |

## Save integration (implemented)

Appearance lives at `player.appearance` in `user://homestead_save.json` as a
flat dict of slot→id strings, e.g.:

```json
"player": {
	"inventory": { ... },
	"survival": { ... },
	"appearance": {
		"body_presentation": "neutral",
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
5. Saves without `body_presentation` (pre-this-pass) default to `neutral`.

## Dev character creator panel (implemented)

`ui/dev_character_creator_panel.tscn` — toggled with **F9** in the overworld.
Controls per slot: **Body** (body_presentation cycling) and **Palette** (outfit_color
cycling) are active and visibly change the player sprite. All other slots (Outfit,
Hair Style, Hair Color, Skin Tone, Accessory) show "(unavailable)" and their
buttons are disabled — they are baked into the full-body LimeZu sheets and
cannot affect rendering. Reset Default and Close work as before.

Every change applies via `AvatarVisual.rebuild()` and persists immediately to
the save. The panel touches no gameplay state — it is an overlay only, and the
real player-facing character creator remains future work.
