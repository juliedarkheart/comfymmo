# Playtest Readiness

## Sprout secondary-provider status

Sprout remains present as a secondary/comparison provider and its licensed files
remain local-only/gitignored under `licensed_assets/`. The current playtest target on
this branch is LimeZu, but the older Sprout gate/reporting remains useful for making
sure generated/procedural art does not silently become the live look:

- With Sprout installed + activated, the overworld mounts normally.
- With Sprout missing/inactive, `WorldRegionManager` mounts a clear missing-assets
  screen (`ui/missing_assets_screen.gd`) instead of the world — verified by
  `SproutAssetRequirement.check()`. This is intentional, not a crash.
- The generated Hearthvale art still in the repo is a temporary diagnostic/dev
  fallback, never the shipped live look. Validation does **not** require the
  no-Sprout checkout to be playable; it only requires the gate to be wired and the
  pack (when present) to be fully active.

To confirm the failure path locally: move the two Sprout manifests aside, boot,
see the missing-assets screen, then restore them.

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
- **Inventory redesigned:** a compact ~340x400 right-side window (was 364x520), one
  short status line (no verbose profile id), owned-items-only grouped into sections
  (empty sections are skipped, not "None yet" filler), tidy LimeZu-compatible 66x60
  slots in wider cells with centered icons + counts and the name on a readable line
  beneath. Closes with Esc and the Close button. Validation enforces: closed by
  default, size within a viewport fraction, Esc/close wired, and CozyUITheme styling
  (no hardcoded art).
- Sprout assets are required for live visual mode (missing-assets screen otherwise);
  generated/dev art remains temporary and must not dominate the slice.

## LimeZu is now the LIVE visual direction

The live game now opens into a curated **LimeZu** Modern Farm slice
(`ArtProviderRegistry.LIVE_PROVIDER == "limezu"`, `OverworldMap._build_limezu_slice()`):
LimeZu grass/barn/trees/fence/garden/crops/cow/chicken/props over the unchanged
gameplay grid, LimeZu farmer actors, and Modern-UI-skinned panels/slots. **Sprout
stays integrated as a secondary/comparison provider** (the standalone spike scene
`scenes/visual_spikes/limezu_homestead_slice.tscn` is also kept).

LimeZu local licensed assets are **required** for the live visual prototype: a missing
pack mounts a clear missing-assets screen (no ugly generated/procedural fallback).
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
placed objects). The HUD/minimap/toolbelt now use a clean flat LimeZu-compatible UI:
dark wood panels, cream/gold text, wide readable chips, and no stretched Modern UI
nine-patches. Validation hard-fails on any Sprout/legacy sprite in the LimeZu opening
and asserts the live HUD/panel/slot/button/blocked-tool styles are `LimeZuUITheme`
`StyleBoxFlat`s rather than distorted `StyleBoxTexture`s.

Old-visual cleanup update: `terrain.dirt_path` now maps to a reviewed transparent
Modern Exteriors dirt patch rather than the old uniform opaque terrain cell. Optional
opening signs that were still using old Sprout/generated/procedural boards are hidden
or routed through a neutral LimeZu sign sprite, while their interaction markers stay
registered. Quick tools now use Modern UI slot styling instead of old code-drawn
slots. The local capture helper writes
`licensed_assets/limezu/review_screenshots/live_limezu_opening_after_old_visual_cleanup.png`
for review; this screenshot remains gitignored/local-only.

UI rewrite/bottom-board cleanup update: tiny Modern UI slices remain mapped for audits
and future native-size use, but large live panels no longer stretch them. The opening
HUD uses the compact controls line `Esc Menu | I Inv | B Build | M Map | H Help | F11`;
missing tool chips use the dark LimeZu blocked slot style; inventory cells were widened
so item names stop letter-wrapping. Save-restored generated board/deck visuals are
hidden in the LimeZu opening while their records/collision/interactions remain intact;
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
3. Confirm the panels use Sprout-normalized panel/button/slot art (the live build
   is Sprout-required; with the pack absent you get the missing-assets screen, not
   the world).
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
- external asset folders, if any, include license/source metadata

## Window controls & quitting

The game can now be closed without Alt+F4:

- Default launch is a normal **bordered windowed** mode at `1600x900`, and
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
- **Sprout-first normal composition:** plot ground is meadow-first instead of
  pasted biome rectangles, with only small farmland/town terrain accents; broad
  procedural borders, old market/fountain slabs, and heavy wilderness dressing
  are hidden or reduced until proper sprite replacements exist.
- **Compact HUD + more Sprout UI:** the normal HUD is a small top-left card.
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
- UI uses normalized Sprout panel/button/slot/menu art (Sprout-required live).
- With Sprout absent the world does not load at all — the missing-assets screen
  appears instead of the old generated/procedural fallback.

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
  The live visual build is Sprout-required: with `licensed_assets/` absent the
  committed build boots to the missing-assets screen rather than rendering the
  generated placeholders as the live game. The generated placeholders remain only
  for diagnostics/dev and for non-visual smoke tests.

## Manual test checklist

Run this list with a real player session after major building/UI changes:

1. Offline boot into the overworld and confirm `B` opens placement with the
   build menu visible.
2. Check every build-menu category button and confirm the list changes.
3. Toggle `Compact`, select a piece, and confirm the active piece changes.
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
  manifest has no real mappings, a present pack has license metadata + existing
  mapped files, the Sprout-required boot gate is wired, and a present pack is
  fully active. A clean checkout with no pack still passes validation (it does not
  demand no-Sprout playability) — the live boot would show the missing-assets
  screen. Inspect in-engine via `tools/art/asset_preview.tscn` (F6) — Sprout ids
  show a "licensed" tag.
