# Playtest Readiness

## Nameplates + full dev wardrobe (2026-06-25)

- **Name labels** (player + NPCs) now sit clearly **above** the avatar's head/hat (offset derived
  from the avatar bounds incl. the tallest accessory; chef hat/beanie no longer get sliced), use
  the UI's warm cream + outline style (`CozyUITheme.apply_nameplate_label`), and never jitter while
  walking (the plate is on the character root). *Test:* equip a chef hat in F9 — the name still
  clears it; names read cleanly over grass/path/water.
- **Dev wardrobe is complete:** F9 exposes **every** compatible adult Modern Interiors part for
  testing (9 bodies, 7 eyes, 29 hair styles ×7 colours, 33 outfits ×colours, 85 accessories incl.
  None). Themed accessories are available in dev but tagged for later release gating. Kid assets
  are deferred (incompatible layout). The release game will gate assets via shops/quests/etc later.

## Layered avatar customization — F9 actually works (2026-06-25)

The player avatar now renders as composited LimeZu Modern Interiors layers (body + eyes + outfit +
hair + accessory) so the F9 wardrobe genuinely changes the visible character. Julie defaults to a
neutral-feminine cozy look (Body_03 / Hairstyle_22_04 / Outfit_14_03 / Eyes_02 / Ladybug).

- **How to test:** open **F9** (the cottage mirror, "Press F to open wardrobe"). Cycle **Body**,
  **Hair**, **Outfit**, **Accessory** with `<`/`>` — the avatar updates immediately. Set
  **Accessory → None** and the accessory disappears. **Close → reopen** shows the current look;
  **quit → relaunch** keeps it (saved in `player.appearance`).
- **What's real:** Body / Hair / Outfit / Accessory. **Disabled (greyed, no fake controls):**
  Palette tint, separate Hair/Skin colour, Eyes selector (fixed Eyes_02) — deferred.
- **Confirm:** no huge head/body block; no farmer fallback sprite underneath the layers;
  Rowan/Hazel/villagers are unchanged when you customise; walking down shows front-facing
  movement; tools still attach to the hand; UI readable. See
  [docs/character_customization.md](character_customization.md) for the full policy.
- **Clean checkout:** with no licensed pack/manifest the avatar falls back to the full-body LimeZu
  farmer sheet (still distinct from NPCs) — layered mode is local-only.

## Animation, facing, tool sockets, terrain & collision (2026-06-24)

- **Character facing/animation:** the player body now uses the LimeZu sheet with a region rect
  selected by facing — DOWN shows the front frame, UP the back frame, LEFT/RIGHT the front frame
  mirrored. DOWN walk cycles a 2-frame step; UP/SIDE walk use the facing frame plus a body bob.
  Data + reviewed frames live in `systems/character/character_animation_registry.gd`. Full
  per-direction walk cycles (and the action atlases) are CATALOGED for a future reviewed pass —
  see `tools/audit_limezu_animations.gd` + `licensed_assets/limezu/generator_manifests/limezu_animation_manifest.json`.
  - *Manual test:* walk up/down/left/right — the player faces the right way (back when going up),
    visibly steps when moving down, and settles to idle facing when stopped. NPCs keep their unique
    profiles (Rowan Farmer_1, Hazel Body_2, etc.) and render the down idle.
- **Held-tool sockets:** equipped tools (hoe/axe/watering can/shovel) attach to a per-facing hand
  socket (`CharacterAnimationRegistry.HAND_SOCKET`) instead of floating; the tool draws behind the
  body when facing up, and mirrors with the body for left/right. *Test:* equip a tool from the
  quickbar and walk in each direction — it stays on the hand and hides when unequipped.
- **Terrain:** `terrain.grass` now resolves to a real LimeZu grass tile (Modern Farm terrains
  autotile cell), not the old mislabeled derivative path tile; `dirt_path`/`tilled_soil` are
  reviewed LimeZu tiles. *Test:* the ground reads as coherent grass with a dirt path, no path-tile
  ground. **Deferral:** FarmPlot soil/crop are still procedural polygons (budgeted ≤28, audited).
- **Collision:** cows and signs now block at a small base collider (you bump them, can't walk
  through, never get trapped); fences, tree trunks, barn base, and crates also block; chickens and
  flowers stay pass-through. *Test:* walk into the cow / a sign — blocked; walk through a flower —
  pass. F7 "Show Collision" overlay shows the cow + sign + crate colliders.
- **Animals:** cow/chicken animation sheets are cataloged (the analyzer found them) but the live
  animals stay static-with-collision for now (documented deferral — no behavior added).

## Actor identity & customization (2026-06-24)

The LimeZu repair had made every actor render the same `Farmer_1` farmer. Now each named actor
has a distinct visual profile (`systems/character/character_profile_registry.gd`): a different
LimeZu base sheet + a pale palette tint.

- **Manual check (opening scene):** Julie (player) renders the `Farmer_2` sheet with a soft
  garden tint; Farmer Rowan renders the classic `Farmer_1`; the land clerk (Hazel) renders
  `Body_2` with a lilac tint; Maribel/Bram differ by sheet + tint. They should look like
  different people, name labels still aligned, scale unchanged.
- **Customization (body_presentation + palette):** the F9 Wardrobe now has ONLY two working
  controls: **Body** (body_presentation: feminine/masculine/neutral, changes the LimeZu base
  sheet immediately) and **Palette** (outfit_color: 13 pastel colors, applied as modulate
  tint immediately). All other slots (Outfit, Hair Style, Hair Color, Skin Tone, Accessory)
  show "(unavailable)" with disabled buttons — they are baked into the full-body LimeZu
  sheets and cannot affect the rendered sprite. See `docs/character_customization.md` for
  the full slot table and rationale.
- **Body/presentation presets:** feminine → Body_2 (closest available silhouette to
  neutral/feminine, documented limitation: still male-presenting, no true female body exists
  in LimeZu packs), masculine → Farmer_1 (classic farmer, has a hat), neutral → Farmer_2
  (default). Default Julie uses neutral, not masculine.
- **Hat removal:** Not supported. Farmer_1 has a hat baked into the sheet (no hatless variant).
  Farmer_2 and Body_2 already have no hat. Choosing a hatless presentation is the only "hat
  removal" available. No fake hat toggle is exposed.
- **How to test customization:** open F9, cycle Body and Palette — the player sprite should
  visibly change immediately. Changing Body swaps the LimeZu sheet; changing Palette applies
  a new color tint. Quit and relaunch — the appearance persists in `player.appearance`.
  Press Reset to return to defaults. All NPCs should remain visually distinct.
- **How to test headless:** `tools/smoke_avatar_customization.gd` (body_presentation presets,
  palette changes, save/load round-trip, NPC isolation, animation frames, default is not
  masculine) and `tools/smoke_character_identity.gd` (profiles load, player≠Rowan, NPCs
  varied). `tools/validate_project.gd` fails on any actor clone, missing/blank actor art,
  a missing required profile/customization default, or fake/disabled controls that don't
  match the registry.

## Object contracts: collision + interaction (2026-06-24)

Every visible/playable object has a contract in [`AssetWorldMetadata`](../systems/world/asset_world_metadata.gd)
(`object_category`, `collision_type`/`collision_shapes`, `interaction_kind`/`interaction_prompt`/
`interaction_response`). This is what fixed the ambiguous **crate next to spawn** that had no F
prompt and could be walked through.

- **Physical (blocks the player):** barn (building), apple tree (trunk), fence (rail line),
  **crate** (storage), well, workbench, mailbox, NPC body. The map builds their colliders from
  `collision_shapes` via `PlacedObjectCollision`; their tiles are also added to placement/spawn
  blocking. Toggle the F7 **Show Collision** overlay to see them (crate now included).
- **Pass-through decor (intentionally non-solid):** flowers, grass tufts, small/edge trees,
  paths, crops, ambient animals (so they never trap the player).
- **Interactive (F prompt + action):** sign (read), farm plot (tend), NPC (talk), and the
  contract props **crate → "The crate is empty."**, well → "Cool, clear water.",
  workbench → crafting hint, mailbox → "No mail right now." A prompt only shows when there is a
  real action — decor never shows a fake prompt, and F is never silent.
- **How F prompts get wired:** the live map spawns contract props via `OverworldMap._limezu_prop`
  and exposes the interactable ones; `OverworldController._register_limezu_world_props()` binds
  each to its contract response. Placed objects get the same treatment in
  `BuildingPlacementSystem` (a placed crate also blocks + inspects).
- **How to test F interactions:** walk next to the crate by spawn → "Press F to check the crate"
  → F shows "The crate is empty." Walk into it → you are blocked. Walk into a flower → you pass
  through (no prompt).
- **How to test placed-object persistence:** press B, place a crate/sign/fence (it renders LimeZu
  art now, not legacy planks), then quit and relaunch. The object persists with its art,
  collision, and (crate) interaction — rebuilt from its saved `object_id`. Verified headless by
  [`tools/smoke_object_contracts.gd`](../tools/smoke_object_contracts.gd).

## LimeZu live visual quarantine (2026-06-24)

Normal local dev live mode is **LimeZu-family only**; old legacy/procedural/Sprout art is
quarantined out of the opening view (see [docs/limezu_asset_mapping.md](limezu_asset_mapping.md)
for the full policy and tiers).

- **Root fixes this pass:** (1) *giant fence-post scatter* — `LimeZuArtRegistry.texture_path`
  now prefers the reviewed raw single-file mapping over the unreviewed generator derivative
  slices, so fences/crates/flowers/props render their correct LimeZu single files instead of
  one repeated `fence_variant` cell; (2) *blank HUD icons* — the day/comfort icons used empty
  UI slot frames; they now use semantic LimeZu-inspired icons (`family_calendar_icon`,
  `comfort_token_icon`); (3) the world sign renders the LimeZu `Sign_1_16x16` prop.
- **Manual visual confirmation (run `--path . ` and look at the opening):**
  - No giant fence-post scatter; fences/posts/signs/trees/props are visually distinct.
  - HUD day + comfort icons are visible (a calendar + a comfort token), not blank slots.
  - Old sign board is replaced by the LimeZu sign; no old legacy generated world art on camera.
  - No Sprout-looking assets in live mode.
  - Player and Farmer Rowan are visible (LimeZu farmer sprite), correct scale, names aligned.
  - Nearest-neighbour filtering, consistent 16→32px (x2) scale; no blur, no giant/tiny mismatch.
- **Dev growth helper:** press `F7` → admin panel → **Grow Crops** advances all crop stages
  for fast farm playtests.
- **Save/load test:** hoe→plant→grow→harvest, place a crate, then quit and relaunch; farm
  plot stage, watered/tilled state, inventory counts, and the placed crate persist
  (verified headless by `tools/smoke_homestead_loop.gd`).
- **Known deferrals (allowed, documented):** the ground fill `terrain.grass` is the
  `limezu_derivative` `path_tile_variant` tile (no flat-grass single in the packs — reviewed
  raw grass tile is a follow-up); FarmPlot still draws procedural soil/crop polygons until a
  reviewed LimeZu farm-plot asset replaces them. A small number of off-camera legacy sprites
  remain in the deferred broad overworld (outside the opening view).
- **Checks:** `tools/validate_project.gd` (live allowlist + HUD-icon + generic-mapping guards),
  `tools/audit_live_visuals.gd` (per-id source-tier audit), `tools/smoke_homestead_loop.gd`.

## Build placement, panels, and farm usability (2026-06-18 follow-up 7)

- **Build id -> visual id -> metadata:** build menu cards keep the selected content id unchanged; `ObjectRegistry` loads that id's scene; `PlaceableDecor.decor_id` now reports the selected id through the placeable art path; `ObjectArtRegistry` supplies selected sprites where mapped; `DecorVisuals` supplies explicit custom visuals for procedural decor; `AssetWorldMetadata.asset_id_for_placeable()` still supplies collision/minimap metadata.
- **Generic box policy:** a generic/missing-looking box is a debug fallback only. Fence, sign, crate, floor/path, barn shell, and wall pieces must not resolve to the missing-art fallback. Flower bed/shrub custom visuals are accepted when they draw non-selection geometry and do not mark fallback.
- **Build/edit movement:** build, edit, and move modes should not freeze the player. Interactions are paused while decorating so F does not fight placement, but WASD/arrow movement and camera follow remain active.
- **Popup policy at 1280x720:** HUD stays top-left, minimap top-right, hotbar bottom-center. Build docks lower-right, inventory docks center-right, admin/worldbuilder docks center-left, and land stays centered so panels avoid the HUD/minimap/hotbar pile-up without rewriting UI.
- **Visible farm patch:** the MVP LimeZu farm test patch is now the clear 3x3 tilled-soil block at tiles `(6-8,15-17)`, with interactable plots at `(6,15)`, `(7,16)`, and `(8,15)`. It is near spawn `(7,11)`, outside static blockers, and should show the F prompt within a short walk.
- **Manual check:** press `B`, select fence/sign/crate, confirm the preview and placed object match the selection; press `E`, select/move/delete with two-press safety; open inventory/build/admin/land and confirm safe panel positions; walk to the farm patch and press `F` to plant/water/harvest or see a clear tool-gate message.
- **Deferrals:** full draggable panels, polished per-piece ghost art, broader farm-system polish, and complete build catalog art coverage remain follow-ups.

## Placed-object instance collision + minimap (2026-06-18 follow-up 6)

Player-PLACED/build objects now use the **same** `AssetWorldMetadata` collision model as
curated world objects — not a separate placement proxy.

- **Shared builder:** `systems/world/placed_object_collision.gd` (`PlacedObjectCollision`)
  instantiates collision shapes (circle/rect/line/polygon; multi-* via repeats) from
  `AssetWorldMetadata.collision_shapes`. Both `HomesteadMap` (curated) and
  `BuildingPlacementSystem` (placed) call it — one source of truth.
- **Placement → collision:** on place, `BuildingPlacementSystem._apply_placed_object_collision`
  maps the placeable content id to a world-asset id (`AssetWorldMetadata.asset_id_for_placeable`)
  and, when mapped, builds metadata shapes at the footprint bottom-centre and **retires the
  generic proxy**. `metadata_none` assets (placed sign/crate/flower/decor) become intentionally
  **non-blocking**; `metadata_blocking` (fence/barn-shell) use real shapes; **unmapped
  placeables keep the conservative proxy** (documented fallback).
- **Move/delete/clear/save:** shapes are children of the body, so **move** carries them (the
  proxy is re-retired after move); **delete-twice** and **Clear Local Test Placements** free the
  body + shapes together (no ghost collision); **load** rebuilds collision through the same path.
- **Minimap:** `BuildingPlacementSystem.minimap_features()` feeds visible placed objects to the
  truth-mode minimap via metadata; hidden/save-restored clutter stays off; deleted/moved objects
  update.
- **F7 overlay:** placed objects draw in **orange** (solid = metadata-shaped, lighter = fallback
  proxy, outline-only = non-blocking decor) — distinct from curated **red**, plus blue spawn,
  green farm, yellow interaction, purple minimap-visible.
- **Buildable coverage:** crate/berry_basket/wood_pile → `object.crate`; signpost → `object.sign`;
  fence_segment/fence_corner → `object.fence_horizontal`; barn_shell → `object.barn`;
  dirt_path/floor_deck → `terrain.dirt_path`; flower_bed → `object.flower`; decor_shrub →
  `object.tree_small`. Walls/foundations/well/sheds/gate/workbench → conservative proxy (fallback).

## UI: Stardew-style LimeZu reconstruction (2026-06-18)

The live UI was rebuilt to use the real LimeZu **Modern UI** kit as proper 9-patch art —
a **Stardew/Minecraft/cozy-survival INSPIRED layout, not copied**: a bottom **hotbar** of
framed slots (number keys, tool icons, gold selected slot, held-item name), a **grid-first
inventory** (square slot frames + count overlays + a hover detail line), and framed
HUD / minimap / menus / build kit / dialogue / prompts, plus clean nameplates (soft shadow,
no dark blob). Default window is **1280x720**. Frames are sliced **x2** with **measured
per-id texture margins** so corners stay crisp and nothing stretches; flat fills are only
interior fallbacks when a texture id is missing. See `docs/ui_style_guide.md`.

Player collision (CharacterBody2D capsule, layer/mask 1) is correct.

## UI polish + generators + collision/interaction (2026-06-18 follow-up)

- **UI polish:** the hotbar now sits in a framed wood **rail** (cohesive, not loose
  buttons); the HUD dropped its long controls line (now a clean status card; controls live
  in Help/H); the inventory gained a header **divider** + a sized framed **detail** area +
  fitting Close button; the build menu's truncated **"Cards"/"Close"** buttons are fixed.
  Validation enforces the rail, bottom-centred hotbar, and grid inventory.
- **Generators:** the GUI installers (`Farmer Generator`, `Character Generator 2.0`) cannot
  be automated. A real code pipeline is in place — `GeneratorCharacterRegistry` + the
  `limezu_generator_catalog.py` tool + a commit-safe manifest schema + portrait-aware
  nameplate with null fallback. **Outputs do not exist yet**, so portraits resolve to
  nothing and the UI falls back cleanly. To activate: run the generators (GUI), drop PNGs
  into `generator_outputs/{player,npcs,portraits,characters}/`, run the catalog. See
  `docs/limezu_generator_workflow.md`.
- **Collision:** the LimeZu **barn/tree/fence colliders already exist and align** with their
  visual footprints (`_build_homestead_colliders` + `get_static_blocked_tiles`); validation
  now also asserts the **player spawn tile is not inside any blocking collider**.
- **Interaction:** reach is calibrated for the 2x LimeZu scale (`INTERACTION_RADIUS = 78`,
  with `interaction_point_offset` for tall sprites + nearest-target selection); validation
  asserts the radius stays >= 70 in LimeZu mode.
- **Farm patch:** a tilled-soil test bed with crops sits at tiles (6-8, 15-17), inside the
  playable area near spawn; validation asserts it stays within the playable bounds.

## UI alignment + asset-generator planning (2026-06-18 follow-up 2)

- **Inventory/hotbar icon centering fixed:** icons were drawn native-size top-left (default
  `EXPAND_KEEP_SIZE`), so a big icon overflowed and sizes were inconsistent. Both now use the
  shared `LimeZuUITheme.slot_inner_rect` / `apply_slot_icon_layout` / `apply_slot_count_layout`
  helpers — centred in the slot cavity, consistent size, count bottom-right. Validation checks
  both panels use the shared helper.
- **Scaffold left menu fixed:** the F7 world-builder panel was a raw button wall. It is now a
  composed menu — header + framed Close, framed status sub-panel, section dividers, and
  evenly-sized non-truncating row buttons (was "Gro/Shr/Re").
- **Original-asset generators:** added `tools/art/hearthvale_palette_analyzer.py` (measures
  LimeZu style constraints → local report), the committed `hearthvale_generator_style_profile.json`
  (original rules/palette), `tools/art/hearthvale_icon_generator.py --preview` (procedural
  ORIGINAL icons), and `docs/hearthvale_asset_generator_plan.md`. Generated PNGs stay local/
  gitignored under `generator_outputs/hearthvale_generated/`; `GeneratorCharacterRegistry`
  detects them (fail-safe 0 when absent). We are no longer blocked only on manual slicing.

## Top-left HUD status-card polish (2026-06-18 follow-up 3)

The top-left "Hearthvale" HUD was a flat 7-line text stack. It is now a **composed status
card** (`ui/prototype_hud.gd` `_compose_card`): gold title header + wood divider, primary
rows (day/time + comfort with small cozy sun/heart icons), the materials line, a second
divider, then **muted secondary** area + mode lines. The long controls hint stays hidden
(controls live in Help/H + the system menu); 1280×720 remains the target. Validation asserts
the controls line is hidden by default, the "Hearthvale" title header exists, the card stays
compact (≤ 8 visible rows), and it is composed (`_compose_card`/`_insert_hud_divider_after`).
The hotbar, inventory, admin panel, and generator pipeline were not touched.

## Asset-world metadata (collision/interaction/minimap registry) — 2026-06-18 follow-up 5

`systems/world/asset_world_metadata.gd` (`AssetWorldMetadata`) is now the **single
authoritative contract** for how each live LimeZu asset behaves: `collision_type`
(none/circle/rect/multi_rect/polygon/multi_polygon/line) plus authored shape data,
placement-only tile proxies, `interaction_enabled` + label + point offset, and
`minimap_visible` + kind + colour. The map/minimap/overlay **read** it instead of hand-patched
blockers. Collision is **curated against sprite alpha/silhouette data, never auto-derived from
PNG alpha at runtime** (alpha analysis is an offline authoring aid only). Commit-safe (pure
shape data + helpers, no copied pixels); clean checkout
+ Sprout unaffected.

- **Collision is registry-driven:** `OverworldMap` instantiates barn polygons, tree trunk/base
  circles, and fence strips from `AssetWorldMetadata.collision_shapes(...)`, and gates
  blockers on `is_blocking(...)`. The barn `collision_tile_proxy` is only a conservative
  placement/build proxy, not final runtime physics.
- **Tree classification is explicit:** `object.tree` = foreground trunk blocker (the 5
  `TREE_TILES`); `object.tree_small` / `object.tree_edge` = background/edge **visual-only**
  decoration (no collider, no prompt) — no more "some trees block, some don't" by accident.
- **Minimap truth:** in the live LimeZu slice the minimap is in **truth mode** — it maps the
  actual playable bounds and draws only real features (player + the two NPCs + barn + farm
  patch, coloured from metadata). The phantom town/forest bands and broad-overworld plot
  squares are suppressed (kept for admin/debug only). It no longer shows things that don't
  exist.
- **Debug overlay (F7 -> Show Collision) colours:** red solid = asset collision, red hatch =
  tile fallback/proxy, blue = spawn, green = farm patch, **yellow = interaction radius**
  (metadata-interactable farm), **purple = minimap-visible object** (barn). Off by default.

## Minimap schematic + overlay legend (2026-06-18 follow-up 6)

The live LimeZu minimap is still in truth mode, but it is no longer just sparse dots. Default
live mode frames `LIMEZU_PLAYABLE_AREA_BOUNDS` and draws a simplified schematic of real current
features only: the player/NPC/signs are dots, the barn draws as a footprint, the farm draws as a
patch, and path/fence/tree features come from the same curated LimeZu slice data that spawns the
visible world. Phantom town/forest bands and broad-overworld LandRegistry plot squares remain
debug/schematic-only unless those features visibly exist in the live world.
Visible in-session player placements can appear as generic placed-object dots; save-restored
objects hidden for LimeZu source-purity remain hidden on the minimap too.

F7 -> **Show Collision** now includes an on-screen legend: red solid = asset collision, red
hatch = tile fallback/proxy, blue = spawn, green = farm patch, yellow = interaction radius,
purple = minimap-visible feature. The green farm overlay uses centered LimeZu visual tile
rects so it lines up with the visible soil/crops; the minimap remains schematic and should not
be used to judge collision precision.

## Depth, body collision, animation, and held tools (2026-06-18 follow-up 7)

The live LimeZu world now treats depth as a shared feet/base contract: terrain/path/farm ground
stays on the non-y-sorted ground layer, while player, NPCs, animals, foreground trees,
buildings, fences, and visible placed foreground objects live in the y-sorted gameplay layer.
Actor and foreground object sprites no longer force themselves above the world with raised
z-index values in LimeZu mode. F7 debug overlay adds cyan feet/base markers to help review the
sort origin.

Player collision remains a compact feet circle. Rowan/Hazel/SimpleVillager NPCs now add a
compact metadata-driven body circle (`AssetWorldMetadata["npc"]`) so the player cannot casually
walk through them, while interaction remains larger and unchanged so talking still works.

Animation is intentionally minimal for now: `AvatarVisual` accepts `idle_down`, `idle_up`,
`idle_side`, `walk_down`, `walk_up`, and `walk_side`. Until full safe animation sheets are
integrated, walking uses a small bob/sway fallback and idle eases back to rest.

Held tools are cosmetic only. The quick tools bar emits selected hotbar state
(`selected_hotbar_index`, `selected_item_id`, `held_visual_id`), and the avatar shows a small
held visual for the selected starter tool when available. This is not RPG equipment: no
equipment slots, stats, combat, or new tool gameplay were added.

## Quickbar assignment, unequip, and icons (2026-06-18 follow-up 8)

Inventory remains the source of owned items. The bottom bar is now a player-configured
quickbar: each of the 9 slots stores an item id or an empty string, and assigning an item never
removes it from inventory. Existing saves with no quickbar data receive MVP starter defaults
(tools in the first six slots, empty trailing slots); once changed, assignments persist under
`player.quickbar`.

Controls: press `1`-`9` to select quickbar slots, press the same selected number again or `0`
to unequip/hands-empty, click an inventory item to enter "assign to quickbar" mode, then click
a quickbar slot. Right-click a quickbar slot to clear it. Selecting an empty slot also means
hands empty and hides the held-tool visual.

The held-tool visual still reads only the selected quickbar item. If a LimeZu icon exists it is
used; otherwise the runtime tries local original Hearthvale generated icon outputs, then the
committed fallback icons, then a text glyph. Missing icons should never produce a missing
texture box in clean checkout.

Manual checklist for this pass:
- Launch, press `1`, `2`, `3`, and confirm the highlight moves without consuming inventory.
- Press the selected number again, then press `0`; the held tool should disappear.
- Open inventory with `I`, click a material/tool item, then click quickbar slot `8` or `9`.
- Right-click that quickbar slot; it should clear and remain empty after reopening inventory.
- Restart and confirm customized quickbar assignments persist.

## Collision / interaction / farm alignment (2026-06-18 follow-up 4)

### Homestead collision contract
- **Solid blockers (asset-shaped):** the barn/building uses two local-space polygons traced
  against the lower body/silo silhouette, the homestead apple trees block at the **trunk base
  only** (compact radius-10 circle at the visible feet, not the canopy), and fence segments use
  thin line/strip collision.
- **Visual-only decor (never block):** edge/background trees + small trees, flowers, grass,
  path, tilled soil, crops, the apple crate, signs (interactable, not solid), and the cow/NPCs.
- **Interactables (do not block):** plot/area signs, NPCs (Rowan/Hazel), the farm patch,
  resource nodes — reached on **F** within `LiveVisualPolicy.INTERACTION_RADIUS` (78px ≈ 2.4
  tiles), nearest target wins; bottom-anchored sprites interact at their feet.

### Player collision
Compact **feet** collider — a radius-9 `CircleShape2D` at `(0,-6)` (was a tall 28px capsule),
so the player blocks solids at the feet and walks "in front of" tall sprites. Layer/mask 1.
Spawn tile `(7,11)` is open (validated not inside any blocker) and a few tiles NE of the farm.

### NPC body collision
Rowan, Hazel, and current `SimpleVillager`-based NPCs use a compact metadata circle at the
lower body/feet. It is small enough not to become a wall or trap the player; interaction reach
remains much larger than body collision.

### Farm patch
Tilled-soil bed + LimeZu crops at tiles `(2-4, 12-14)` — SW of spawn, reachable, crops render
above soil. Walking onto it shows "Press F to plant carrot". (No old diamond/iso farm visuals.)

### Build / edit / admin controls
- **B** build menu · **E** edit · **Q/RB** rotate · **Del/Y** delete (two-press safety) ·
  **Esc/B** cancel — placement ghost snaps to the LimeZu grid.
- **F7** world-builder (admin) panel → **Clear Local Test Placements** (explicit, no auto-delete)
  removes leftover local test clutter; **Show Collision** toggles the debug overlay.

### Collision debug overlay
F7 -> **Show Collision** draws the actual metadata shapes: **red solid** = asset collision,
**red hatch** = tile fallback/proxy, **blue** = spawn, **green** = farm patch, **yellow** =
interaction radius, **purple** = minimap-visible schematic feature, **cyan** = y-sort feet/base
markers. Off by default.

### Minimap
Schematic top-down map; the player marker maps world→rect linearly (`_world_to_map`) and moves
N/E/S/W correctly (verified via the walk-east/walk-south captures). It is approximate (fixed
world bounds) and intentionally small.

### Manual playtest checklist
1. Walk through open grass/path — smooth, no snagging on decor.
2. Walk into the barn / a tree trunk / the fence — blocked at the visible base.
3. Walk SW to the soil patch — "Press F to plant carrot" appears; F works.
4. Approach Rowan/Hazel/a sign — F talks/reads at sensible range.
5. B → place a piece on the grid; E → select; Del twice → removes.
6. F7 → Show Collision (verify alignment), Clear Local Test Placements (clears clutter).

7. Walk above and below a tree/building/NPC and confirm the player draws behind/in front by feet.
8. Walk into Rowan/Hazel and confirm they have a small body, not a giant invisible wall.
9. Press number keys/click the hotbar and confirm owned starter tools appear in the player's hand.

Additional minimap/overlay checklist:
1. Press M and confirm the minimap remains clipped, the player marker moves while walking,
   the barn/farm are shapes, and no fake town/forest/plot markers appear in default live mode.
2. F7 -> Show Collision and confirm the legend appears, green covers the visible farm patch,
   red covers blockers, cyan marks y-sort bases, yellow marks interaction radius, and purple
   outlines minimap-visible features.

## Sprout secondary-provider status

Sprout remains present as a secondary/comparison provider and its licensed files
remain local-only/gitignored under `licensed_assets/`. The current playtest target on
this branch is LimeZu. Sprout reporting remains useful for local review, but Sprout
is optional and must not block boot:

- With Sprout installed + activated, reports can confirm the optional mappings.
- With Sprout missing/inactive, `WorldRegionManager` logs a visual-fallback warning
  and still mounts the overworld.
- The generated/procedural Hearthvale art remains the committed safe fallback for
  clean checkouts, smoke tests, and any local machine without the licensed packs.
  Validation requires the fallback boot path to stay playable.

To confirm the fallback path locally, boot from a clean checkout with no licensed
packs installed: the overworld should load with lower-fidelity safe visuals.

## Screenshot cleanup pass (visual quality)

A screenshot-driven cleanup (no architecture changes) addressed the most visible
problems:

- **HUD readability:** the HUD/minimap/prompt cards keep a solid dark, mostly-opaque
  cozy backing (not the pale Sprout parchment panel that left cream text
  unreadable). The bare-number crop row is hidden; only essential rows remain.
- **Signs:** rendered as single small sprites with no permanent floating title plate
  (the name shows on the interaction prompt / land panel). There is no texture
  tiling/repeat — the previous "repeating signs" was many identical signs + labels.
- **Terrain:** meadow-first with a light, deterministic scatter of small flowers/
  pebbles/grass over the open core so it reads as a tended yard, not a flat slab.
- **Generated/dev art** is temporary and must not dominate; Sprout/modified-Sprout
  art leads. Validation now also checks HUD backing contrast and that the signpost
  sprite is not region/repeat.

## Curated demo slice + inventory cleanup

Because the full overworld is too ambitious for the current art state, **normal play
now opens in a curated demo slice**, not the broad procedural world:

- `LiveVisualPolicy.CURATED_SLICE` frames the opening view tighter (zoom 1.7) on a
  hand-composed homestead — cottage + a focal Sprout well + a small tilled garden bed
  + flower beds + framing trees/bushes (`OverworldMap._build_curated_slice`).
- The broad/ugly layers (the long connecting road to the far regions and the
  wilderness scatter) are **suppressed** in normal play. The dirt path was narrowed
  to a tidy 2-tile lane. **Full overworld visual polish is deferred** — the
  gameplay/data world (plots, NPCs, resources) is unchanged and still walkable.
- Default UI panels (inventory, build, admin, land) are **closed at launch**; only
  the compact HUD, small minimap, and toolbelt show.
- **Inventory redesigned:** a compact ~336x420 right-side window (was 364x520), one
  short status line (no verbose profile id), owned-items-only grouped into sections
  (empty sections are skipped, not "None yet" filler), tidy LimeZu-compatible 88x48
  slots in 94px cells with centered icons + counts and the name on a readable line
  beneath. Closes with Esc and the Close button. Validation enforces: closed by
  default, size within a viewport fraction, Esc/close wired, and CozyUITheme styling
  (no hardcoded art).
- Sprout assets are optional for live visual mode; generated/procedural fallback
  visuals keep clean checkouts playable and must remain visibly safe.

## LimeZu is now the LIVE visual direction

The live game now opens into a curated **LimeZu** Modern Farm slice
(`ArtProviderRegistry.LIVE_PROVIDER == "limezu"`, `OverworldMap._build_limezu_slice()`):
LimeZu grass/barn/trees/fence/garden/crops/cow/chicken/props over the unchanged
gameplay grid, LimeZu farmer actors, and Modern-UI-backed panels/controls. **Sprout
stays integrated as a secondary/comparison provider** (the standalone spike scene
`scenes/visual_spikes/limezu_homestead_slice.tscn` is also kept).

LimeZu local licensed assets are preferred for the live visual prototype when the
mapped core slice is present. If the local licensed pack is absent or incomplete,
the game must still boot with the committed generated/procedural fallback.
Preserved unchanged: movement, placement, farming data, delete-twice safety, inventory
data, offline boot, server boot. All LimeZu media stays local/gitignored; only
code/docs/templates are commit-safe. Validation asserts live provider = LimeZu, the
live slice resolves real LimeZu ids, the cow is not head-cropped, inventory is closed
by default + Modern-UI styled, Sprout stays present, and no LimeZu media is tracked.
A local opening screenshot is at
`licensed_assets/limezu/review_screenshots/live_limezu_opening.png` (gitignored).
Live polish update: the opening now hides old farm-plot soil/highlight polygons and
the old rest-marker doormat diamond, guards the generated homestead rabbit/turtle out
of the LimeZu opening, maps Modern UI button/close frames, hides the empty chat card,
and keeps inventory compact with LimeZu icons where mapped. Known remaining art gaps
are broader/offscreen: full Exteriors/Interiors/Office coverage, tameable-companion
creature art, and cozy dungeon art are still deferred.
See docs/limezu_live_pivot_plan.md and docs/limezu_visual_spike.md.

Source-purge update (this pass): the opening's largest non-LimeZu sources were purged
— the Sprout neighborhood plot grounds + per-plot biome grounds (~12k meadow tiles) and
the generated dirt/stone neighborhood roads (the "broken road") are suppressed in LimeZu
mode, village/forest generated decor + plot-skirt decor + wardrobe mirror are hidden, and
gather/resource nodes are re-skinned to LimeZu sprites. A boot-time audit
(`VisualSourceReport.live_opening_sources`) reports the opening is now `sprout=0,
legacy=0`, LimeZu-dominant (~949 LimeZu vs ~13 generated, all off-screen creatures /
placed objects). The HUD/minimap/toolbelt now use LimeZu-compatible UI assets:
Modern UI texture-backed panels, slots, buttons, close buttons, and tabs with dark
ink on parchment panels and cream/gold on dark button strips. Validation hard-fails
on any Sprout/legacy sprite in the LimeZu opening and asserts the live panel/HUD/
slot/button/close paths resolve to Modern UI texture styleboxes.

Old-visual cleanup update: `terrain.dirt_path` now maps to a reviewed transparent
Modern Exteriors dirt patch rather than the old uniform opaque terrain cell. Optional
opening signs that were still using old Sprout/generated/procedural boards are hidden
or routed through a neutral LimeZu sign sprite, while their interaction markers stay
registered. Quick tools now use Modern UI slot styling instead of old code-drawn
slots. The local capture helper writes
`licensed_assets/limezu/review_screenshots/live_limezu_opening_after_old_visual_cleanup.png`
for review; this screenshot remains gitignored/local-only.

UI rewrite/bottom-board cleanup update: Modern UI slices now skin the live panels and
controls through `CozyUITheme`; panel layouts stay compact so the assets remain legible.
The opening
HUD uses the compact controls line `Esc Menu | I Inv | B Build | E Edit` /
`M Map | H Help | F11 Window`; missing tool chips use the dark LimeZu blocked
slot style; inventory cells were resized around 88x48 slots in 94px cells so item
names stop letter-wrapping. Save-restored
generated board/deck visuals are hidden in the LimeZu opening while their records/collision/interactions remain intact;
the small lower-right board visible in the screenshot is an intentional LimeZu sign prop.
Capture `licensed_assets/limezu/review_screenshots/live_limezu_opening_after_ui_rewrite.png`
and `licensed_assets/limezu/review_screenshots/live_limezu_inventory_after_ui_rewrite.png`
for review; both remain gitignored/local-only.

Layering/footprint cleanup update: LimeZu terrain/path/soil now has an explicit
low-z ground-layer contract, while buildings, props, signs, crops, animals, NPCs,
and the player stay on the y-sorted gameplay layer. The curated slice skips path/soil
cells inside the barn/sign/crate/tree visual footprints, and the short path now
approaches the barn from below instead of running through object art. Capture
`licensed_assets/limezu/review_screenshots/live_limezu_opening_after_layering_cleanup.png`
for the focused review image; it remains gitignored/local-only.

Small playable-area expansion update: LimeZu coverage now extends a short distance
around the homestead using the bounded `LIMEZU_PLAYABLE_AREA_BOUNDS`, not the whole
overworld. The opening camera stays the same, while a few steps east/south remain on
LimeZu grass with sparse LimeZu tree/flower/fence/crate clusters and no generated
road slabs. Old procedural plot boundary lines/posts are also hidden in LimeZu live
mode; plot markers/interactions remain registered. Validation audits the bounded
playable area and hard-blocks Sprout, legacy, or missing sprites inside it. Review captures are:
`licensed_assets/limezu/review_screenshots/live_limezu_opening_after_area_expansion.png`,
`licensed_assets/limezu/review_screenshots/live_limezu_walk_east_after_area_expansion.png`,
`licensed_assets/limezu/review_screenshots/live_limezu_walk_south_after_area_expansion.png`,
and `licensed_assets/limezu/review_screenshots/live_limezu_inventory_after_area_expansion.png`.

Playability/UI asset alignment update: the live LimeZu pass now aligns interaction and
collision with the visible art instead of the older cottage/plot positions. The barn
uses an explicit LimeZu footprint collider, static blocked tiles match the visible
barn/tree/fence art, and the visible garden bed is wired to the existing farm plot
interactions. `InteractableSystem` uses a slightly wider LimeZu interaction radius so
F prompts are not pixel-fussy against 32px top-down art. The quick tools moved to a
bottom-center 8-slot hotbar sized around the smaller Modern UI slot language; inventory
uses 3 columns of compact 88x48 slots; nameplates have a small readable backing; and
the admin panel exposes **Clear Local Test Placements** for offline save cleanup after
visual tests. Review captures added by this pass:
`licensed_assets/limezu/review_screenshots/live_limezu_opening_after_playability_ui_alignment.png`,
`licensed_assets/limezu/review_screenshots/live_limezu_inventory_after_playability_ui_alignment.png`,
`licensed_assets/limezu/review_screenshots/live_limezu_build_menu_after_playability_ui_alignment.png`,
and `licensed_assets/limezu/review_screenshots/live_limezu_farm_prompt_after_playability_ui_alignment.png`.

## Visual/UI foundation checks

This branch now has a first reusable Hearthvale visual direction:

- `docs/visual_identity.md` defines the cozy 2D storybook target; the live view
  is now Sprout-compatible top-down / gentle 3/4, with the older 64x32 iso view
  kept as a fallback.
- `docs/ui_style_guide.md` defines shared parchment/wood/honey panel styling,
  slots, tabs, selected states, and close-path expectations.
- `docs/world_art_direction.md` defines terrain, biome, path, water, road, and
  plot-boundary readability.
- `docs/building_art_direction.md` defines the cozy survival-builder kit rules
  for modular pieces, prefabs, and interior deferrals.
- `docs/graphics_pipeline.md` defines the generated placeholder pipeline,
  registry routing, tile/object/icon sizes, fallback behavior, and replacement
  order.
- `docs/asset_credits.md` records that this pass imported no third-party art
  and explains the CC0/public-domain metadata rules for future imports.

Manual visual pass:

1. Confirm the normal HUD is a compact top-left card and does not cover the
   world; debug/account/server detail should not be visible by default.
2. Open the system menu, inventory, build menu, land panel, admin panel, edit
   toolbar, quick tools, and minimap.
3. Confirm LimeZu live UI visibly uses Modern UI texture-backed panels and controls
   (HUD, minimap, inventory, build menu, hotbar slots, buttons, close/tabs).
4. Confirm important panels have visible Close/Resume/Cancel paths.
5. Confirm inventory categories read as item slots rather than a plain text dump.
6. Confirm build-menu tabs, selected item info, costs, unavailable states, and
   controls are visible.
7. Confirm the minimap is clipped, styled like a small map object, and uses
   readable plot/player/landmark markers.
8. Walk meadow, forest, orchard, creekside, hilltop, grove, town, and farmland
   areas and confirm labels/props distinguish them without giant biome blocks.
9. Paint dirt path, stone path, water, and farmland through admin terrain tools
   and confirm the same sprite palette appears in-world.
10. Place crate, mailbox, fence/gate, wall, floor/foundation, roof, workbench,
   cottage shell, and shed and confirm mapped registry sprites appear where
   available while old procedural decor still remains readable.

## Verified automatically

The project validator and boot checks cover the following for this branch:

- project import completes
- offline boot of `scenes/main.tscn` succeeds
- dedicated server boot of `server/server_main.tscn` succeeds
- build menu scene loads and instantiates
- build menu categories match `systems/building/build_categories.gd`
- build menu has both a close button path and an `Esc` close path
- build menu item sources resolve to valid content ids
- build costs resolve to valid placeables and valid item/resource ids
- at least 4 claimable plots are `16x16` or larger (true homestead yards)
- the 6 built-in plots are spread, disjoint, and each declares a known biome
- large plot centers AND all four corners are buildable for the owner
- runtime (editor-made) plots merge into every plot query, round-trip through the
  `runtime_plots` save data, skip corrupt records, and clear back to the static
  catalog with no leakage
- the system/pause menu scene loads and exposes open/close + a quit handler
- the `toggle_system_menu` (Esc) input action exists alongside F7–F11/I/H/M
- owner / non-owner / admin-bypass land rules behave correctly
- the 5 new modular pieces are wired through ids, registry, costs, and scenes
- prefab interior metadata parses safely
- at least one prefab interior mapping exists
- the shared interior scene loads
- invalid or missing prefab interior metadata fails closed
- modular/custom pieces are not required to have interiors
- graphics docs and asset credits exist
- required `art/` folders and generated PNG placeholders exist
- terrain and object art registries load and safely resolve required ids
- invalid terrain/object ids fall back to the missing-art placeholder
- map renderer exposes terrain visual resolution helpers
- LimeZu live UI uses reviewed Modern UI texture styleboxes for panels, HUD cards,
  slots, buttons, close buttons, and tabs
- the LimeZu barn collider and static blocked tiles match the visible barn footprint
- LimeZu interaction radius and farm plot interaction nodes match the visible 32px
  top-down garden bed
- the bottom-center quick tools hotbar exposes 8 compact slots and the HUD hint lists
  `E Edit`
- offline admin cleanup can clear local test placements without changing network play
- local playability capture paths exist for opening, inventory, build menu, and farm
  prompt review screenshots
- external asset folders, if any, include license/source metadata

## Window controls & quitting

The game can now be closed without Alt+F4:

- Default launch is a normal **bordered windowed** mode at `1280x720`, and
  `DisplaySettings` clamps/centers the window inside the usable screen so a
  1080p monitor does not hide the OS title bar/close button.
- **Esc** (when no panel is open) opens the system/pause menu: Resume, Toggle
  Fullscreen/Windowed, Quit to Desktop, Close.
- The **Quit to Desktop** button calls `get_tree().quit()` and works even in a
  borderless window where OS chrome is hidden.
- **F11** still toggles fullscreen/windowed (persisted via
  `ui/display_settings.gd`); the menu's toggle does the same.
- Esc still closes any open panel *first* (build/inventory/land/etc.); only with
  nothing open does it reach the system menu. While building, Esc still exits
  placement/edit mode instead of opening the menu.

## The "grey line" fix

A grey-blue stripe used to run across the map. Root cause: it was the **border
river** in `world/overworld_map.gd::_build_natural_borders` (a desaturated
blue-grey ribbon near world_y 980). When the south movement wall was pushed down
to fit the bigger lots, the playable/neighborhood area extended *past* this
border, so the river ended up cutting through the map. Fix: the river was moved
well south of the play area (world_y ~1980, below the ~1820 south wall) and
recolored a softer water-blue, so it now reads as a distant water border rather
than a grey line. Plot boundaries remain a subtle soft-yellow outline plus
corner posts (not grey, not a debug line).

## Player-facing polish (this pass)

Now that `sprout_topdown` is the live projection, the prototype was tuned to feel
better to actually play:

- **Movement matches the view.** `AvatarController` now moves straight along
  screen axes in top-down mode (pressing up goes up) instead of applying the old
  isometric skew. The skew is kept only for the legacy `iso_64x32` projection; the
  avatar resolves its mode from the owning map. Camera keeps its gentle position
  smoothing and PgUp/PgDn/R zoom.
- **Delete is two-step.** In Edit mode, the first Delete (key or the danger
  toolbar button) *arms* a confirmation ("Press Delete again to confirm"); a
  second Delete on the same selected object within ~4s removes it. Changing
  selection or leaving edit mode disarms it, so a stray keypress never deletes a
  piece outright. Move/select/cancel/Esc behave as before.
- **Worldbuilder previews align to whole cells.** The parcel tool preview and the
  admin world-builder overlay now expand their footprints by half a tile in
  top-down mode, so the previewed rectangle covers the visible tiles instead of
  stopping a half-tile short at the tile centers. (Legacy iso keeps the centers
  diamond.)

### Controls (current)

Move WASD/arrows (or left stick) · Interact/confirm **F** / A · Build **B**
(Tab cycles piece) · Edit **E** (Move **M**; **Delete** twice to confirm) ·
Inventory **I** · Craft **K** · Skills **P** · Help **H** · Minimap **M** ·
Admin/world-builder **F7** · System menu **Esc** · Fullscreen **F11** · Zoom
PgUp/PgDn (**R** reset). Esc closes any open panel first; with nothing open it
opens the system menu (while building, Esc exits the build/edit mode).

### Manual test focus

Walk the homestead/neighborhood and confirm up/down/left/right go the way you
press (no diagonal drift); place a piece and confirm the ghost lines up with the
tile under the cursor; in Edit mode select a piece, press Delete once (it should
ask to confirm), press it again to remove; stake a parcel (F7) and confirm the
preview rectangle covers full tiles; toggle the world overlay and confirm plot
footprints sit on the tiles.

## Live visual stack (old-graphics purge)

The live `sprout_topdown` world now renders from the top-down art stack only:

- **Root cause of the lingering "old graphics":** the resolver was already
  returning top-down tiles, but the map drew an opaque colored ground polygon
  **on top of** each terrain sprite (and the backdrop/region tints sat above the
  sprites too), so the correct Sprout/Hearthvale tiles were created but hidden
  behind flat procedural color. The world looked like the old prototype.
- **Fixes:** the colored ground fill is skipped when a top-down sprite covers the
  cell; background scenery moved to a `z = −10` layer beneath the tiles; placed
  objects + world decoration (trees, bushes, rocks, flowers, mushrooms, pines, the
  cottage) now render through the object registry as top-down sprites; and a new
  original top-down OBJECT set under `art/generated/hearthvale/objects/` replaced
  the old `art/objects/` placeholders. Terrain remains licensed Sprout / modified
  Sprout / generated Hearthvale; no legacy `art/tiles/` diamonds in live mode.
- **Normal play hides debug regions:** the old broad alpha region-tint discs are
  not drawn in normal play. Admin/world-builder overlays still show explicit
  plot, parcel, and marker information when toggled through F7 or `/overlay`.
- **Top-down normal composition:** plot ground is meadow-first instead of
  pasted biome rectangles, with only small farmland/town terrain accents; broad
  procedural borders, old market/fountain slabs, and heavy wilderness dressing
  are hidden or reduced until proper sprite replacements exist.
- **Compact HUD + Modern UI:** the normal HUD is a small top-left card.
  Local Sprout UI now activates panel, button, hover, slot, selected slot, close,
  and menu/dialog panel variants from gitignored normalized derivatives; clean
  checkout uses original generated Hearthvale UI fallbacks.
- **Actor scale:** generated actor sprites are scaled down through
  `CharacterArtRegistry` to sit naturally on 32x32 Sprout terrain.
- **Tell which tier is rendering:** the overworld prints
  `[visual-source] …` on boot (terrain/object/UI tier counts + any legacy
  regressions + live sprite/polygon counts). F6 (`tools/art/asset_preview.tscn`)
  tags every id `licensed / licensed_modified / generated / missing`, flags any
  live id that resolves to old art as **`legacy!`** (red), and keeps a separate
  "Legacy iso art" reference strip.

### What a human should see now

- Square/top-down terrain tiles (no diamond ground), with no flat procedural color
  squares dominating; paths read as paths, water/creek read as water.
- Trees, bushes, rocks, flowers, mushrooms, pines, the cottage, fences, signs, and
  placed build pieces render as cozy top-down sprites (Sprout where wired locally,
  else the original Hearthvale top-down sprites).
- Floating nameplates are smaller, and role subtitles such as Villager/Mentor/
  Land Office/You are hidden by default to reduce clutter.
- UI may use normalized licensed panel/button/slot/menu art when local packs are
  present; otherwise it falls back to committed safe UI styling.
- With Sprout absent the world still loads; visual-fallback warnings are expected
  and the generated/procedural fallback remains the safe baseline.

### Still needs manual art replacement (deferred)

A few distinctive procedural props remain quarantined or deferred (plot signs,
plot-decoration flourishes, debug/admin previews, and legacy fallback branches);
the old village fountain/market and broad border scenery are hidden in normal
play until sprite replacements exist. The recolor tints and Hearthvale silhouettes are
functional-but-simple and would benefit from a hand-art pass; audio/animation
stay catalog-only.

## Known limitations

- prefab interiors are prototype-grade scene views, not full persistent indoor
  lots
- only selected prefab shells have interiors; greenhouse and well remain
  exterior-only
- modular custom buildings are exterior-only for now
- dungeons are future separate instances
- player-created dungeons or adventure plots are future work
- connected clients still depend on a simpler server-side terrain check than the
  richer offline map rules
- network-placed objects are still display-oriented on clients compared with the
  fully local edit/remove flow
- minimap and quick tools are intentionally lightweight UI, not full builder
  control surfaces
- the current PNG art is placeholder foundation art, not final production art
- terrain transitions are scaffolded assets/helpers, not full autotiling
- Sprout UI kit and animation catalog outputs are local review artifacts only.
  The live visual build is Sprout-optional: with `licensed_assets/`
  absent, the committed build should still boot using safe generated/procedural
  placeholders. Those placeholders remain lower-fidelity fallback art, not the
  preferred final look.

## Manual test checklist

Run this list with a real player session after major building/UI changes:

1. Offline boot into the overworld and confirm `B` opens placement with the
   build menu visible.
2. Check every build-menu category button and confirm the list changes.
3. Toggle `Cards`, select a piece, and confirm the active piece changes.
4. Close the build menu with both the button and `Esc`.
5. Place at least one modular piece, one terrain piece, and one prefab shell.
6. Claim a large neighborhood plot and confirm building works inside it.
7. Stand inside another claimed plot and confirm normal building is denied.
8. Toggle admin/world-builder mode and confirm the same denied tile becomes
   placeable.
9. Place a prefab with an interior, walk to its door, press `F`, and exit with
   `F`, `Esc`, and the Exit button.
10. Place a modular custom shape and confirm there is no required interior flow.
11. Connect to a server and confirm the builder HUD, pouch counts, and placement
   behavior still read correctly.
12. Walk the spread lots (hilltop north, brook/creekside west, orchard south,
   grove east) and confirm each reads with its own biome ground + decor.
13. Open F7 → Toggle World Overlay (or `/overlay`) and confirm every plot's
   bounds, name, size, corners, the training-core grid, and any markers draw.
14. `/newplot grove 16` where you stand; confirm a claimable lot appears with
   ground/posts/sign, shows on the minimap and overlay, and a teleport button
   appears in F7. Claim it, build on it, then `/resizeplot 2` and `/delplot`.
15. `/marker resource Pine` (or F7 Place Marker), confirm the gem + label draw,
   reload the game, and confirm the plot and marker persisted. `/delmarker`
   removes the nearest one.

## Readiness summary

This branch is ready for focused manual playtests of:

- the build menu
- large-plot claiming and building
- prefab-door interior entry
- the cozy 2D isometric modular/prefab building loop

It is not claiming readiness for:

- dungeon gameplay
- combat
- player-authored adventure instances
- full modular interior simulation

## Graphics / asset pass status

- Generated placeholder art was upgraded to Pillow (4x supersampled,
  anti-aliased, cozy): biome tiles, paths, water, nature/building objects,
  prefabs, and UI icons. Validation asserts every required PNG exists and that
  the terrain/object registries resolve required ids and fall back safely.
- **No external assets were imported.** Outbound HTTP reached asset homepages,
  but a direct binary download returned HTTP 403 and no license file could be
  fetched/verified, so per the hard rule nothing external was added. The import
  pipeline (`art/external/` + license/source enforcement, `from_external/active`
  derivative mirror, registry external→generated→missing order) is ready for a
  verified CC0 drop-in later.
- Inventory slots now show registry icons. Build-menu per-row icons and a
  build/edit toolbar icon strip are a deferred, low-risk next step (icons +
  registry already resolve).
- Still placeholder / deferred: final production art for every category, a
  player/character sprite, neighbor-aware terrain autotiling (only a simple
  deterministic edge-hint scaffold exists today).

## Asset review workflow

- There is now a review-before-wiring pipeline: `tools/art/` slicer +
  contact-sheet + importer, contact sheets under `art/review/`, an in-editor
  preview scene (`tools/art/asset_preview.tscn`, F6), and a manifest-driven
  activation layer (`art/active_art_manifest.json` + `ArtActivation`). The
  registries only use an external derivative when it's listed in the manifest, so
  imported packs can't blind-replace the cozy generated art.
- The Kenney CC0 RPG sheet has a review contact sheet (64x64 cells) but is **not
  activated** (medieval/RPG cells still need semantic review). No redistributable
  external art is active. Validation asserts the review docs/dir, the activation
  manifest parses, and the safe generated default works.

## Licensed assets (Sprout Lands, local-only)

- The premium **Sprout Lands** pack (Cup Nooble) is integrated **locally and
  gitignored** - never committed (non-redistributable license; credit required,
  in docs/asset_credits.md). Wired locally: 10 objects, 6 icons, 6 licensed
  terrain tiles (meadow/orchard/grove/creekside/water/creek), 3 `licensed_modified`
  tint terrains (forest/hilltop/town), and 2 UI ids (panel + close). Clean
  checkout falls back safely.
- **Original Hearthvale top-down gap-fill** (`art/generated/hearthvale/`,
  committable, from `tools/art/generate_hearthvale_gap_assets.py`) gives every
  terrain id a real 32x32 top-down tile, so a no-Sprout checkout still reads as a
  coherent top-down farming world (soil/paths/plot markers look intentional). UI
  resolves licensed Sprout → generated Hearthvale shape → cozy code-drawn theme.
- Projection compatibility lives in `systems/world/world_projection.gd`. The live
  overworld uses `sprout_topdown` on the same gameplay grid; `iso_64x32` remains a
  legacy/fallback projection. Source tiers: `licensed` / `licensed_modified` /
  `licensed_ui` / `generated` / `missing` (inspect with F6 asset preview).
- **Manual visual review still owed:** the recolor tints (forest/hilltop/town),
  the Sprout panel nine-patch margins, and which Sprout button/slot sheet cells
  to wire (catalog-only for now). Audio + animations remain cataloged, not wired.
- Sprout UI kit review is local-only. `tools/art/sprout_integrate.py` extracts
  the UI pack, writes a gitignored `sprout_ui_manifest.json`, and generates UI
  contact sheets; `UIArtRegistry` falls back to cozy code-drawn panels and
  generated icons unless a reviewed local manifest activates specific sprites.
- Sprout animation sheets are cataloged locally under
  `licensed_assets/sprout_lands/manifests/animations_inventory.json` with
  contact sheets under `contact_sheets/animations/`. They are not wired into
  runtime animation yet.
- If the local Sprout Sorry pack zip is present, it is cataloged under
  `contact_sheets/sorry/` and `manifests/audio_inventory.json` only. This does
  not add runtime audio, combat, enemies, dungeon gameplay, quests, or economy.
- Sprout terrain is deliberately limited to reviewed single-tile mappings
  (`meadow`, `water`, `creek`) and only in Sprout-compatible projection modes.
  Modular/custom building pieces still do not require interiors or Sprout art.
- Validation asserts `licensed_assets/` is gitignored, the tracked template
  manifest has no real mappings, a present pack reports useful readiness warnings,
  Sprout is optional, and the fallback boot path remains wired. A clean checkout
  with no pack must stay playable. Inspect in-engine via
  `tools/art/asset_preview.tscn` (F6) to see licensed/fallback source tags.

## Live MVP farming loop

The live farm is a **3-tile row just south of spawn (7,11)**: carrot (6,13),
turnip (7,13), berry (8,13) — clear of the tree at (5,15). It is marked on the
minimap and the F7 overlay (`LIMEZU_TILLED_SOIL_RECT = Rect2i(6,13,3,1)`).

`FarmPlot` draws the live, top-down visual from `FarmingSystem` state — empty
shows a light untilled "bed" cue, `tilled_soil` shows dark furrowed soil
(`LiveLimeZuSoil`), `planted_seed`/`crop_stage_1` add a small sprout, `crop_stage_2`
a larger one, and `crop_stage_3` the mature crop + accent + a harvest-ready ring
(`LiveLimeZuCrop`). The old iso-diamond soil/crop polygons are always hidden, and
the map does not paint static tilled soil on the row — so **hoeing visibly turns
grass into soil**. (Fixes the prior regression where `FarmPlot` matched stage
names — `planted_dry`/`planted_watered`/`grown` — that `FarmingSystem` normalizes
away, so nothing changed on screen.)

**Tool mapping** (select on the quickbar, then press `F` at the tile):

- Worn Hoe on empty → tills (grass/bed → soil).
- Seed Packet on tilled soil → plants stage 1 (consumes one seed).
- Watering Can on tilled/planted → waters (moisture tint).
- Empty hands / wrong tool → clear prompt, safe no-op.
- Mature crop + `F` → harvest (crop into inventory, tile back to tilled soil, no
  double-harvest). Advance growth via rest or the admin **Grow Crops** action
  (`HomesteadController.admin_grow_crops` → `FarmingSystem.advance_all_plots`).

**How to test:** walk a few steps south, select the Hoe and press `F` (soil
appears), select a Seed Packet and press `F` (sprout appears), Grow Crops to mature
it, then `F` to harvest. Proof screenshots are captured to the gitignored
`licensed_assets/limezu/review_screenshots/live_limezu_farm_*` set.

**Deferred:** irrigation/auto-water, soil quality, crop traits/variety, creature
farm helpers, multi-tile fields, full Stardew polish. **Recovery note:** the local
LimeZu *sliced textures* were lost with the git-metadata damage; re-run the LimeZu
integration to repopulate them (the farming loop is provider-agnostic and works
without them).
# F9 full wardrobe playtest focus (2026-06-25)

F9 is now a dev-unlocked wardrobe for the compatible adult Modern Interiors
Character Generator set: 9 skin/body layers, 7 eye layers, 29 hair styles with
real per-style color variants, 33 outfits with real per-outfit color variants,
and None plus 84 accessories. Hair Style and Hair Color are split fields in
`player.appearance`; the renderer resolves them to combined layer IDs such as
`hair_22_04`. Outfit and Outfit Color work the same way.

Manual checklist: open F9, cycle every enabled row, confirm Hair Color and
Outfit Color visibly change the avatar, switch styles and confirm color options
refresh to valid variants, set Accessory to None, Randomize, Reset Julie, then
walk left/right/up/down and confirm facing/idle still works. Kid generator sheets
are intentionally deferred as `incompatible_layout`; no kid/adult layer mixing is
enabled. Release gating is metadata-only for now, not shops/quests/economy.
