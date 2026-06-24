# Hearthvale Graphics Pipeline

This branch establishes a Godot-ready graphics foundation without changing
gameplay scope. The current art is generated local placeholder PNG art, routed
through registries so final ComfyUI/manual sprites or verified CC0 assets can
replace it later without rewriting placement, land, building, or map systems.

## LimeZu-only live mode (2026-06-24 quarantine pass)

Live local dev mode renders **only** LimeZu-family sources. The generated local
placeholder/legacy art described below is now an **emergency fallback only** (clean checkout
with no licensed packs / generator outputs) or an explicit debug mode — it must not appear in
the normal LimeZu opening view. Allowed live tiers: `limezu_reviewed`, `limezu_raw`,
`limezu_derivative`, `limezu_inspired`, `limezu_generated_local`. Disallowed live: legacy
generated, procedural world art, Sprout, blank/missing/unknown, and unreviewed random raw
sheet cells. Sprout is optional/manual/reference-only. Raw LimeZu cells must be semantically
reviewed before live use; inspired/derivative outputs are the preferred gap-fillers. See
[docs/limezu_asset_mapping.md](limezu_asset_mapping.md) for the full policy, the resolution
order (reviewed raw beats unreviewed generator slices — the fence-post-scatter fix), HUD-icon
and actor requirements, and the documented ground/farm-plot deferrals. Enforced by
`tools/validate_project.gd`; audited by `tools/audit_live_visuals.gd`.

Visible props also carry a behavior contract (collision + interaction) in
`systems/world/asset_world_metadata.gd`, and placed build objects render LimeZu art rather than
legacy planks — see [docs/limezu_asset_mapping.md](limezu_asset_mapping.md) and
[docs/playtest_readiness.md](playtest_readiness.md).

Actors get distinct LimeZu-family looks (different base character sheet + palette tint per
profile) from `systems/character/character_profile_registry.gd`, so the player and NPCs are not
the same farmer clone — see [docs/character_customization.md](character_customization.md).

Character facing/animation (down/up + mirrored side, light down-walk + bob) and held-tool hand
sockets come from `systems/character/character_animation_registry.gd`; LimeZu animation sheets are
cataloged read-only by `tools/audit_limezu_animations.gd` into a gitignored manifest. `terrain.grass`
resolves to a reviewed LimeZu grass tile (no derivative path-tile ground). Cows/signs now block at a
small base collider. Full per-direction walk cycles + animal animation remain cataloged deferrals.

## Visual Target

Hearthvale should read as a cozy Sprout-compatible top-down / gentle 3/4 village
toybox: warm colors, chunky silhouettes, clear tile meanings, soft shadows, and
friendly UI. The older 64x32 diamond isometric view is a legacy fallback, not
the primary live visual direction. Reference games are direction only. Do not
copy, trace, rip, or use fan assets from existing IP.

Building logic can borrow the idea of gather, craft, place, move, rotate, and
delete from survival builders, but the visual style stays cute, readable, and
storybook-like.

## Folders

Game-facing art lives under `art/`:

```text
art/tiles/terrain/     transition and edge scaffold tiles
art/tiles/biomes/      meadow, forest, orchard, town, farmland, etc.
art/tiles/paths/       dirt, stone, tilled soil, plot markers
art/tiles/water/       water, creek, water edge
art/objects/building/  modular pieces, prefabs, workbench, storage
art/objects/nature/    trees, rocks, bushes, flowers, crops
art/objects/decor/     fence, gate, sign, mailbox
art/generated/hearthvale/characters/  original live actor sprites
art/generated/hearthvale/creatures/    original live ambient creature sprites
art/ui/icons/          resource, tool, build/edit icons
art/placeholders/      safe missing-art fallback
art/generated/         notes for locally generated placeholders
art/generated/from_external/  normalized derivatives of imported assets
art/generated/from_external/active/  resized/cropped derivatives the registries prefer
art/external/          third-party CC0/public-domain imports only (with license + source)
```

The generator script is `tools/art/generate_placeholder_art.py`. It now renders
with **Pillow at 4x supersampling** and downsamples with LANCZOS, so the
placeholders are soft, anti-aliased, and cozy (storybook toybox) instead of
hard-edged polygons — tiles get a subtle 3D lip and per-biome texture, objects
get soft shading + contact shadows, icons sit on a parchment chip. Output paths,
canvas sizes, and pivots are unchanged, so the registries and map/placeable
rendering keep working with no code changes. Run it with
`python tools/art/generate_placeholder_art.py` (needs `pip install Pillow`).

## Sizes And Anchors

Current targets:

- Primary Sprout terrain tile PNG: `32x32`, centered on the square tile.
- Generated fallback terrain PNG: `64x48`, kept for legacy iso/fallback review;
  in the live Sprout/top-down projection the map draws square color tiles
  instead of forcing those legacy diamonds into the grid.
- Object sprite PNG: `96x96`, bottom/center-friendly, contact shadow near the
  parent tile origin.
- Character/creature sprite PNG: `96x96`, pixel-canvas upscaled, centered with
  a contact shadow baked into the sprite. Live rendering scales these down via
  `CharacterArtRegistry` so actors fit the 32x32 Sprout terrain grid.
- UI icon PNG: `64x64`, centered.

Anchor rules:

- Terrain sprites are centered on the tile origin.
- Floor/foundation sprites sit close to the terrain plane.
- Upright objects use a negative Y offset so their contact shadow lands on the
  tile origin.
- Final art should preserve the same visible contact point even if resolution
  changes.

## Logical Grid Vs Visual Projection

Gameplay keeps using the logical tile grid for placement, land ownership,
terrain paint, minimap records, and interactions. Visual projection is a
separate helper in `systems/world/world_projection.gd`.

Supported modes:

- `sprout_topdown`: the primary live visual mode, using reviewed 32x32
  Sprout-compatible top-down tiles on the unchanged gameplay grid.
- `iso_64x32`: the legacy Hearthvale fallback, matching the older 64x32
  isometric grid.
- `topdown_16`: 16x16 top-down mode for non-Sprout packs.
- `topdown_32`: 32x32 top-down mode for larger square tiles.

The live overworld renders through `sprout_topdown`. This changes drawing and
pick-projection only; it does not rewrite placement, land ownership, minimap,
terrain paint, or save data. `iso_64x32` stays available as a legacy/fallback
mode, and licensed Sprout terrain is not allowed to leak into that mode.

## Godot Import Settings

Let Godot import PNGs normally, then keep settings consistent by category:

- Sprites/UI: lossless PNG, no mipmaps, nearest or carefully chosen filter.
- Terrain tiles: no mipmaps for the current small tiles; revisit if large
  terrain sheets arrive.
- Transparent assets: RGBA PNG with clean alpha edges and no matte halo.
- Do not wire raw generation outputs directly into scenes. Promote cleaned art
  into `art/` or documented asset bundles first.

## Registries

`systems/art/terrain_art_registry.gd` maps terrain and biome ids to tile PNGs.
It provides:

- required terrain ids
- safe path lookup
- texture lookup
- invalid-id fallback to `art/placeholders/missing.png`
- stable tile variation index
- first-pass transition helper for grass/path/water/farmland/biome edges

`systems/art/object_art_registry.gd` maps content ids, nature ids, resources,
tools, and UI action ids to sprites/icons. It provides:

- required object/icon ids
- safe path lookup
- texture lookup
- invalid-id fallback to `art/placeholders/missing.png`
- sprite creation with simple anchor/z-index rules

Map code and placeable visuals should ask these registries for art paths. Avoid
scattering raw `res://art/...` paths through gameplay systems.

`systems/art/character_art_registry.gd` maps live player, remote player,
villager, and ambient creature ids to actor sprites under
`art/generated/hearthvale/{characters,creatures}/`. The old
`CharacterVisualBuilder` polygon body remains only as a dev fallback if a sprite
cannot load; normal gameplay actors should route through `CharacterArtRegistry`
first so characters do not visually drift away from the terrain/object style.

### Actor depth, animation, and held-tool visuals

Live LimeZu actors and foreground objects should share the same y-sorted gameplay layer and
sort by feet/base point. Actor sprites must not use fixed high z-index values to float above
trees/buildings; UI, prompts, nameplates, and debug overlays are the surfaces that belong
above the world.

`AvatarVisual` currently exposes the minimal state names `idle_down`, `idle_up`, `idle_side`,
`walk_down`, `walk_up`, and `walk_side`. Until reviewed full animation sheets are integrated,
walking uses a small bob/sway fallback and idle eases back to rest. This keeps the player from
feeling like a sliding token without committing licensed animation frames.

Held tools are selected-hotbar visuals only. `ui/quick_tools_bar.gd` emits
`selected_hotbar_index`, `selected_item_id`, and `held_visual_id`; `AvatarVisual` attaches a
small icon/sprite near the hands and hides it for empty selection. This is not a full equipment
system: true RPG equipment slots, multiplayer equipment replication policy, and full
generator/animation-sheet integration remain deferred.

### Quickbar and generated item icons

The bottom bar is a saved shortcut bar, not the inventory itself. `player.quickbar.slots`
stores 9 item ids or empty strings; inventory counts remain authoritative. Hotkeys `1`-`9`
select slots, `0` or re-pressing the selected slot unequips, inventory item click begins
assignment mode, and right-clicking a quickbar slot clears it.

Icon resolution for quickbar, inventory, and held-tool fallbacks is centralized in
`ObjectArtRegistry.icon_texture_for_item()`:

1. mapped LimeZu icon, when present locally;
2. original Hearthvale generated local preview icon from
   `licensed_assets/limezu/generator_outputs/hearthvale_generated/item_icons/`;
3. committed Hearthvale fallback icon under `art/ui/icons/`;
4. UI text glyph when no texture is available.

`tools/art/hearthvale_icon_generator.py --preview` now includes original recipes for axe,
pickaxe, hoe, shovel, watering can, empty hands, generic seed, and generic tool, plus the
older log/stone/leaf/berry/acorn/coin set. The generated PNGs and review sheet stay
gitignored until an explicit commit policy changes.

## Fallback Strategy

Both registries resolve every id through one preference order
(`TerrainArtRegistry.resolve_path` / `ObjectArtRegistry.resolve_path`):

1. **External derivative** — an imported/normalized CC0 file mirrored at the same
   relative path under `art/generated/from_external/active/` (e.g.
   `.../active/tiles/biomes/meadow.png`). If present, it wins. No id-table edits
   are needed to adopt a verified asset — just drop the normalized PNG there.
2. **Generated placeholder** — the local Pillow output under `art/...`.
3. **Missing fallback** — `art/placeholders/missing.png`, intentionally obvious
   but always safe to load.

`source_of(path)` reports which tier won (`external` / `generated` / `missing`),
which the inventory icons and validation use. Every lookup fails safe:

- Unknown terrain/object ids return the missing-art placeholder.
- Existing map polygons remain as fallback *under* terrain sprites.
- Decor with no mapped sprite keeps its existing procedural drawing.
- Missing external metadata fails validation before those assets can become
  trusted project inputs.

### Importing a verified CC0/public-domain asset later

1. Put originals under `art/external/<source>/<asset>/` with a `LICENSE` (CC0 /
   public-domain text) and a source file (`README.md`/`SOURCE.txt`/`asset.json`
   with URL, author, license, files, modified?). Validation **fails** if either
   is missing.
2. Normalize (resize/crop/pad to the tile/object/icon size, clean alpha, correct
   pivot) into `art/generated/from_external/active/<mirrored path>` and record
   source→derived in `art/generated/from_external/manifest.json`.
3. No registry/gameplay code changes — the resolver prefers it automatically.

## Terrain Transitions

This pass adds transition assets and a helper, not a full autotiling system.
Current transition scaffold ids are:

- `grass_to_path`
- `grass_to_water`
- `grass_to_farmland`
- `biome_soft_edge`
- `path_edge`
- `water_edge`

Future work can replace the simple helper with neighbor-aware autotiling after
the final terrain set exists.

## Replacement Order

Recommended final-art pass order:

1. Terrain tiles
2. Paths and water
3. Trees, rocks, bushes, crops
4. Building pieces
5. Prefab cottages and sheds
6. UI icons

Keep replacement changes data-only where possible: swap PNGs and registry paths
before touching gameplay code.

## Review + activation workflow

External packs are never wired on download. They go through a review path —
contact sheets in `art/review/`, an in-editor preview (`tools/art/asset_preview.tscn`,
F6), then manual normalize + activation. The registries resolve **activated
external derivative → generated placeholder → missing fallback**, where
"activated" means listed in `art/active_art_manifest.json` (via `ArtActivation`),
not merely present on disk. Empty manifest = all generated. Full details and the
`tools/art/` helpers (`import_asset_pack.py`, `make_asset_contact_sheet.py`,
`slice_spritesheet.py`) are in `docs/asset_review_workflow.md`.

## Licensed (premium, local-only) layer

There is a highest-priority resolution tier for **paid / non-redistributable**
packs (e.g. Sprout Lands by Cup Nooble): full order is **local licensed → local
licensed_modified → redistributable external → generated → missing**. The
licensed manifest + assets live under the gitignored `licensed_assets/` and are
never committed (including the `modified/` recolors/tints that resolve as the
`licensed_modified` tier). Tooling is `tools/art/sprout_integrate.py`. Full rules:
docs/licensed_asset_policy.md.

### LimeZu collision-mask review tooling

`tools/art/limezu_collision_mask_builder.py` analyzes local LimeZu PNG alpha masks and writes
review-only collision candidates under the gitignored paths
`licensed_assets/limezu/collision_masks/` and `licensed_assets/limezu/collision_review/`.
It supports alpha threshold, simplification tolerance, lower-body-only/full-body candidates,
and anchor modes (`bottom`, `center`, `tile_origin`). The outputs are for human review; they
must not include copied image pixels in committed files. Runtime collision should be committed
only as simplified metadata/code such as polygons, multi-polygons, circles, thin lines, or
multi-rects in `systems/world/asset_world_metadata.gd`.

For the live LimeZu opening, the minimap is schematic while the F7 collision overlay is the
collision source of truth: red solid shapes are asset collision, red hatching is tile/grid
fallback or placement proxy, and major props/buildings should not rely on tile rectangles as
their final runtime collision. Player-PLACED objects draw **orange** in the overlay (distinct
from curated red).

`systems/world/placed_object_collision.gd` (`PlacedObjectCollision`) is the single runtime
shape builder for BOTH curated world objects and player-placed/build objects: it reads
`AssetWorldMetadata.collision_shapes` and instantiates Godot collision nodes. `HomesteadMap`
and `BuildingPlacementSystem` both delegate to it, so placed objects use the same asset-metadata
collision as curated ones (metadata preferred; a conservative placement proxy is kept only for
buildables with no mapped asset). This is commit-safe code; no licensed pixels are committed.

**Optional licensed-pack fallback boot.** The resolver may use LimeZu or Sprout
assets when local licensed manifests are installed, but missing licensed packs must
not block gameplay. `WorldRegionManager` logs visual-fallback warnings and still
loads the overworld, using generated/procedural fallback visuals where needed.
Policy flag: `LiveVisualPolicy.SPROUT_REQUIRED_FOR_LIVE` remains `false`.

## Original Hearthvale top-down gap-fill (`art/generated/hearthvale/`)

`tools/art/generate_hearthvale_gap_assets.py` renders **original, committable**
top-down 32x32 terrain tiles (every terrain id) plus UI panels/buttons/slots,
cursor/check fallbacks, object sprites, and actor sprites under
`art/generated/hearthvale/`. In the live `sprout_topdown` mode the terrain
registry prefers these over the legacy 64x48 isometric diamonds. They resolve as
the `generated` source tier and are **not** derived from Sprout (or any
third-party) media - the script draws them procedurally. Licensed Sprout art, when
installed locally, wins over them per the order above. These generated tiles are
the committed safe fallback for clean checkouts, validation/smoke tests, fallback
boot, and for inspecting source tiers.

The same script also renders **original top-down OBJECT sprites** (96x96,
bottom-anchored) under `art/generated/hearthvale/objects/{nature,building,decor}/`
for every placeable + decoration id. `ObjectArtRegistry` prefers these over the
old `art/objects/` 96px placeholders (order: **licensed Sprout → Hearthvale
top-down → legacy placeholder → missing**), and terrain-placeable objects route to
the Hearthvale terrain tiles. So placed buildings, props, and the world's
trees/bushes/rocks/flowers/mushrooms/pines render as cozy top-down sprites instead
of the old procedural polygons.

It also renders **original top-down ACTOR sprites** under
`art/generated/hearthvale/characters/` and `art/generated/hearthvale/creatures/`.
`AvatarVisual`, `RemotePlayer`, `SimpleVillager`, and the ambient creature nodes
resolve these through `CharacterArtRegistry` before falling back to polygon
builders. This is a containment layer, not final animation-sheet support: final
commissioned/licensed character sheets can replace the registry outputs later
without changing movement, dialogue, networking, or creature behavior.

### The "old graphics still showing" fix (live render path)

Manual playtest showed the old prototype look even though the resolver returned
top-down tiles. Root cause: the live map drew an **opaque colored ground polygon
(z 0) on top of each terrain sprite (z −1)**, and the overworld backdrop/region
tints (z 0) also sat above the sprites — so the correct top-down tiles were
created but hidden behind flat procedural color. Fixes: `_add_terrain_sprite`
now reports success and the maps **skip the colored fill when a sprite covers the
cell**; the overworld backdrop/region-tint/border/road scenery moved to a
`z = −10` background layer; and the heavy procedural decoration routes through the
object registry. Net result at boot dropped procedural polygons from ~13.6k to
~0.7k with ~13k terrain sprites now visible. `systems/visual_source_report.gd`
prints the live tier counts on overworld boot (`[visual-source] …`) and is asserted
by validation (`VisualSourceReport.is_clean`).

Normal play keeps broad biome/region debug overlays off. Admin/world-builder
overlays remain explicit tools (F7 or `/overlay`) and may show plot/parcel/marker
information, but they are separate from the calm default render path.

The current top-down live pass tightens that further through
`systems/visual/live_visual_policy.gd`: broad procedural border scenery,
market/fountain slabs, and biome rectangle carpets stay out of normal play.
Connecting roads/plazas render as tile sprites; plot ground is meadow-first with
only small special-case accents; actor sprites are scaled to the 32x32 terrain
grid.

Reviewed Sprout terrain currently activates only obvious single-tile mappings:
meadow grass, water, and creek. Other terrain sheets remain catalog/review
material until a human picks safe cells. Sprout UI kit assets follow the same
local-only rule. The local manifest is
`licensed_assets/sprout_lands/sprout_ui_manifest.json`; the tracked template is
`art/sprout_ui_manifest.template.json`. `UIArtRegistry` resolves local activated
Sprout UI first, then generated Hearthvale UI fallback, then code-drawn/missing
fallback. Current local-only activated UI includes panel, button, hover, slot,
selected slot, close, and menu/dialog panel variants; none of those Sprout
derivatives are committed.

### Single-sprite objects / signs (no tiling)

Object and sign art renders as a **single** `Sprite2D` via `ObjectArtRegistry`
(`make_sprite`) — never a tiled/region texture and never reused as a UI nine-patch
background. The Sprout signpost is a small source, so world signs are drawn at a
reduced scale and without a permanent floating title plate to avoid a "repeated
sign" look. The HUD keeps a solid dark code-drawn backing for contrast rather than a
stretched Sprout panel (see docs/ui_style_guide.md). Generated/dev art remains a
temporary fallback and must not visually dominate over Sprout/modified-Sprout art.

### Curated demo slice

Normal play opens in a curated demo slice (`LiveVisualPolicy.CURATED_SLICE`,
`OverworldMap._build_curated_slice`): the opening camera frames a small composed
homestead and the broad procedural layers (far connecting roads, wilderness scatter)
are suppressed in normal play. The full overworld renderer is unchanged and returns
when the flag is off; the gameplay/data world is intact underneath. This is a
presentation gate, not a gameplay change — see docs/world_art_direction.md.

### LimeZu provider (now the LIVE provider)

LimeZu ("Modern" ecosystem) is now the PRIMARY live visual provider
(`ArtProviderRegistry.LIVE_PROVIDER == "limezu"`). It is a licensed provider —
`systems/art/limezu_art_registry.gd` (logical-id resolver over a gitignored local
manifest) selected via `systems/art/art_provider_registry.gd`. When LimeZu is live and
its assets resolve (`LiveVisualPolicy.live_limezu_slice()`):

- `OverworldMap._build_limezu_slice()` composes the curated opening homestead from
  LimeZu art (16px drawn at x2 = 32px cells) over the unchanged gameplay grid; the
  Sprout core ground/cottage/tree/fence VISUALS are suppressed (colliders kept).
- `CozyUITheme._ui_box()` uses reviewed LimeZu Modern UI texture styleboxes for
  panels, HUD cards, slots, buttons, close buttons, and tabs. Layouts stay compact
  so the small source slices read as intentional UI instead of custom flat boxes.
- `CharacterArtRegistry.make_sprite()` returns the LimeZu farmer for live human actors.
- Source purity is enforced: `_build_neighborhood_ground`/`paint_plot_ground` (Sprout
  meadow + generated roads), village/forest decor, plot-skirt decor, and the wardrobe
  mirror are suppressed in LimeZu mode; resource nodes re-skin to LimeZu. The road uses
  the LimeZu `terrain.dirt_path` tile or is hidden. `VisualSourceReport.live_opening_sources()`
  audits the live opening and validation hard-fails on any Sprout/legacy sprite.

- The small playable-area expansion remains bounded by
  `OverworldMap.LIMEZU_PLAYABLE_AREA_BOUNDS`. It extends LimeZu ground/props only
  around the homestead, keeps terrain/path on the ground layer, keeps props/actors on
  the gameplay layer, and uses `VisualSourceReport.live_area_sources()` to audit the
  immediate walkable area. This is a source-purity guard for the homestead perimeter,
  not permission to render the whole unfinished overworld.
- Playability alignment keeps collision/interactions anchored to the visible art:
  the LimeZu barn has its own footprint collider and blocked-tile rect, visible crop
  beds align to farm plot interactables, and LimeZu prompts use the live visual
  interaction radius.

**Sprout stays fully integrated as a secondary/comparison provider** (registries, the
optional Sprout readiness helper, the Sprout spike, and docs are NOT removed). Extraction is
`tools/art/limezu_integrate.py`; spike/live slicing is
`tools/art/limezu_slice_spike_assets.py` (both write `.gdignore` into raw `extracted/`
trees so Godot never imports the ~120k licensed PNGs — only reviewed `normalized/`
derivatives import). All LimeZu media stays local/gitignored; only code, the manifest
*template*, and docs are commit-safe. See docs/limezu_live_pivot_plan.md,
docs/limezu_visual_spike.md, and docs/limezu_asset_mapping.md.
