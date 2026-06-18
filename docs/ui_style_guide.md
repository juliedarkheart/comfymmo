# Hearthvale UI Style Guide

The UI should feel like a friendly tabletop village kit: parchment panels, warm
wood borders, honey highlights, readable slots, and simple close paths.

The reusable helper is `ui/cozy_ui_theme.gd`.

## Shared UI Pieces

- Main panels use warm parchment with a thick wood border.
- HUD/minimap frames can use darker wood, but text must stay cream and readable.
- Item/tool/resource icons should come from `systems/art/object_art_registry.gd`
  or a future UI-specific registry, not panel-local hardcoded paths.
- Buttons use parchment slots with honey hover/pressed states.
- Category tabs use the same button style, with a stronger selected state.
- Item slots use pale parchment; selected slots use honey; unavailable slots are
  muted with a clear blocked border.
- Close buttons should be visible on major panels.
- Destructive buttons, such as Delete or Quit, use the danger treatment. In Edit
  mode, Delete is **two-step** (first press arms a confirmation, second press
  within a few seconds removes), so a single stray press never deletes a piece.

## Panel Expectations

- System menu: Resume, Toggle Fullscreen / Windowed, Settings / Display, Quit
  to Desktop, and Close.
- Inventory: identity/profile line, category headings, item slot grids, counts,
  missing tool/token states, and Close.
- Build menu: compact category tabs with full category tooltips, selected item
  info, cost/tool/size/interior status, unavailable reason, Cards, Select, and
  Close.
- Land panel: plot name, owner/status/cost/tokens, claim affordance, permission
  text, and Close.
- Admin/worldbuilder panel: grouped sections for admin status, plot tools,
  terrain paint, parcel preview, markers, teleports, and Close.
- Minimap: clipped map content, cozy frame, readable player marker, landmark
  dots, plot ownership borders, and biome-tinted plot fills.

## HUD Expectations

The default HUD is compact. It should answer the playtester's first questions
without covering the world:

- Day/time and comfort.
- Key crop/resource counts.
- Current area and mode/tool.
- Main controls: Esc/Start menu, F11 fullscreen, I inventory, B build, E edit,
  H help, M minimap.

Debug/account/server detail belongs in explicit panels or debug/admin overlays,
not in the normal HUD card.

### HUD readability rules

- **Readability beats skinning.** The HUD/minimap/prompt cards keep a **solid dark,
  mostly-opaque** cozy backing (`CozyUITheme.hud_panel_style`) with a honey border —
  they do **not** swap to the pale Sprout parchment nine-patch. Cream text on pale
  parchment is unreadable; cream text on the dark card is not. Sprout panel art still
  skins the menus/dialogs (`apply_panel`), where text is dark ink on parchment.
- Keep generous content padding so text never touches the border.
- Show only essential always-on rows: day/time, comfort, current mode/tool, a compact
  resources line, and a short controls hint. The bare-number crop row is hidden in
  normal play (crop counts live in the inventory panel); identity/account lines stay
  hidden unless debug.
- Validation enforces this: the HUD `panel` stylebox must be a `StyleBoxFlat` with a
  dark (`luma < 0.45`), mostly-opaque (`alpha >= 0.85`) fill.

### Signs and world labels

- Signs render as a **single sprite**, never a tiled/repeated/region texture, and a
  sign sprite is never reused as a panel/nine-patch background. Validation asserts the
  signpost sprite is not `region_enabled`/`texture_repeat`.
- Plot/area signs do **not** float a permanent title plate — that yard-full of
  always-on labels was the main clutter source. The name is shown by the interaction
  prompt ("Press F to view <name>") when the player is near and in the land panel on
  F. Names are kept as node metadata, not always-on text.
- Keep sign sprites small/tidy so a cluster of identical signs does not read as a
  repeated graphic.

### Default panel visibility

The default screenshot must be mostly world, not UI. Inventory, build menu, admin/
worldbuilder, and land panels are **closed at launch** and open only on their key
(inventory on I, build on B, admin on F7). Only the compact HUD, small minimap, and
compact toolbelt show by default. Debug/admin overlays stay hidden unless enabled.

### Inventory window

The inventory is a **compact** right-side window (~336x420, well under a viewport
fraction - not a full-height parchment wall), closed by default, opened with I and
closed with Esc or the Close button:

- LimeZu-compatible styling via `CozyUITheme`: `apply_inventory_panel` frame,
  `apply_slot` item slots, `apply_close_button`. In LimeZu live mode these resolve
  to reviewed Modern UI texture slices, with dark panel text and light button text.
- One short status line (`@user | mode | plot`) - no verbose profile id / duplicated
  display name.
- **Owned items only**, grouped into sections; empty sections are skipped entirely
  (no "None yet" filler) and a single quiet line shows when nothing is owned.
- Tidy fixed **88x48 slots** in wider 94px cells, arranged in a compact 3-column
  grid: centered icon (LimeZu where mapped, registry fallback where safe) + count,
  with the item name on a readable
  line beneath. Icons stay aligned and labels must not letter-wrap or overlap.
- Validation enforces: closed by default, size within a viewport fraction, Esc/close
  wired, and CozyUITheme/UIArtRegistry styling rather than hardcoded art.

### LimeZu live UI: Stardew/cozy-survival layout, real Modern UI 9-patch art

The live UI direction is **Stardew Valley / Minecraft / cozy-survival INSPIRED layout**
(bottom hotbar, grid inventory, framed panels, dialogue boxes, tabs, readable tooltips) —
**layout inspiration only; no art, exact UI, or proprietary layouts are copied.** The
actual art is the LimeZu Modern UI kit.

**Real 9-patch, no distortion.** The earlier attempt stretched tiny, badly-cropped
Modern UI crops (panel `47x31` with embedded shadow, `29x11` buttons) with wrong
margins → warping. The fix: frames are re-sliced from measured Style_1 cells
(connected-component + border scan; `panel (8,8,32,31)`, `slot (58,129/169,28,29)`,
`button (51,80,42,16)`, `close (54,344,20,20)`, `text_input (1,209,45,18)`), upscaled
**x2 NEAREST** to match the world's 2x pixel scale, and used as `StyleBoxTexture`
9-patches with **per-id texture margins measured from the art** (in
`ui/limezu_ui_theme.gd` `TEX_MARGIN`). Corners stay crisp; only the flat edges/centre
stretch. The real Modern UI panels are **light tan parchment**, so all text is **dark
ink** (Stardew-style), not cream-on-dark.

`CozyUITheme` is still the single switch point; `_limezu_box()` returns the
`LimeZuUITheme.*_texture_style()` 9-patch for panel/inventory_panel/slot/slot_selected/
button/hover/pressed/close/tab when LimeZu is live. `LimeZuUITheme` is an explicit style
**contract** — `panel_texture_style`, `hotbar_slot_style`/`_selected`, `inventory_slot_style`,
`dialogue_panel_style`, `tooltip_panel_style`, `text_input_style`, `tab_selected_style`,
`button_disabled_style`, `close_texture_style`, plus `readable/title/muted/button/
disabled/warning_text_color`. Each method returns the real 9-patch art, or — only when a
texture id is missing — an **approved flat fallback in LimeZu tan** (so dark ink stays
readable). `is_textured()` reports which is live. **Flat fills are interiors/fallbacks
only, never the primary look.**

**Hotbar** (`ui/quick_tools_bar.gd`): a bottom-centre row of 9 LimeZu slot frames sitting
inside a **framed wood rail** (`LimeZuUITheme.hotbar_rail_style`) so the slots read as one
cohesive HUD element, not loose buttons. Number keys (1-9), tool icons (LimeZu icon where
mapped, else a short text glyph), a dim state for tools not yet owned, a gold **selected**
slot, and the held tool's name on a framed label above the row. Selection is presentational
only (the game checks ownership, not an active slot) — no gameplay/selection system added.

### UI polish standard (typography, spacing, composition)

The UI must feel designed, not "text dumped in a box":
- **No text touches a border** — panels/buttons carry generous content margins from the
  theme; header buttons set `clip_text = false` + a min width so labels like "Cards"/"Close"
  never truncate.
- **Hierarchy:** gold/brown title, a thin wood **divider** under a panel header, then the
  grid/body, then a framed **detail/description** area. Item names live on the hover/detail
  line, never wrapped inside every slot.
- **Default HUD stays a clean status card** — the long control list lives in Help (H) / the
  system menu, not the HUD (the HUD controls line is hidden in normal play; it still flashes
  briefly on F11).
- **Dark ink on tan**, cream/gold only on genuinely dark backings; avoid heavy black
  outlines (nameplates use a thin outline + soft shadow, no backing blob).
- Flat fills are readable interiors/fallbacks only — never the primary identity.

### Slot icon centering (inventory + hotbar)

Item/tool icons must sit centred inside the slot frame's **usable inner cavity**, not the
full texture rect (the slot border is uneven — the top is thicker). Both the inventory and
hotbar use the **shared** `LimeZuUITheme` helpers so they stay consistent:
- `slot_inner_rect(slot_size)` — the cavity, inset by the slot's measured per-side texture
  margins (`TEX_MARGIN[ui.slot] = [10,12,10,10]`).
- `apply_slot_icon_layout(icon, slot_size)` — fills the cavity, `EXPAND_IGNORE_SIZE` +
  `STRETCH_KEEP_ASPECT_CENTERED` + NEAREST, so **every** icon (16/32/48px native) renders at
  a consistent centred size instead of native-size top-left (the old off-centre bug).
- `apply_slot_count_layout(label, slot_size)` — count pinned bottom-right inside the cavity
  with a soft shadow. Empty slots show a clean frame with no icon.

### Left-side menu composition standard (admin / world-builder)

A left-side panel must read as a composed game menu, not a dev scaffold:
- A **header row** (title + framed Close), then a thin wood **divider**.
- Status in its own **framed sub-panel** (tooltip frame), not floating debug text.
- Controls grouped into **sections**, each introduced by a heading with a divider above it.
- **Row buttons** use `SIZE_EXPAND_FILL` + `clip_text = false` + short labels (details in
  tooltips) so 3-per-row controls never truncate to "Gro/Shr/Re".
The F7 world-builder panel (`ui/admin_panel.gd`) is the reference implementation.

**Inventory** (`ui/inventory_panel.gd`): grid-first — square `56x56` LimeZu slot frames
(4 per row) with a centred icon and a bottom-right count overlay, grouped under section
headers, with the item name shown on a framed **hover/detail line** at the bottom instead
of wrapping under every slot. Closed by default, opens on I, closes on Esc/Close.

Every other panel (build menu, system menu, land/admin, dialogue, prompts, network) picks
this up automatically through `CozyUITheme`, so the whole UI is one coherent asset-backed
family. Validation hard-checks the live panel/HUD/slot/button resolve to Modern UI texture
styleboxes (never a stretched whole-texture), the theme exposes the style methods, the
hotbar is bottom-centred with its slot count, and the inventory grid renders. Default
window is **1280x720**. Nothing licensed is committed; slices live under gitignored
`licensed_assets/limezu/modern_ui/normalized/spike/`.

### Leftover placed-object boards in the LimeZu opening

Save-restored build pieces (crates, decks, etc.) still resolve their sprite through
`ObjectArtRegistry`, which has no LimeZu tier, so in LimeZu live mode they render with
generated/legacy planks that clash with the LimeZu world (the "leftover boards" at the
map edge). `BuildingPlacementSystem._place_record()` therefore **hides the visual of
save-restored placed objects in LimeZu live mode** so the curated opening reads as pure
LimeZu. Record, collision, occupancy, and interaction are preserved (the object is still
placed and editable), and **in-session placements stay visible** so the place-and-see
feedback loop still works. (Not to be confused with the LimeZu plot/area signs, which
are intentional LimeZu `object.sign` sprites with a "press F" interaction.)

## Accessibility And Readability

- Target 1080p readability first.
- Avoid tiny labels inside dense panels.
- Avoid always-on floating role subtitles in the world. Nameplates should stay
  compact; secondary role lines are opt-in for hover, selection, or debug states.
- Keep button text short and concrete.
- Prefer item slots or grouped rows over long walls of text.
- Use clear denial feedback when an action is blocked.
- Use consistent selected state rather than relying on text alone.

## Icons

Inventory slots now show a cozy `ObjectArtRegistry` icon above the name/count
when one resolves (materials, crops, tools, land token); items with no icon keep
text only, and the missing-art X never appears (slots check `source_of != missing`).
Toolbar icons exist and resolve (`build_tool`, `delete`, `rotate`, `paint`) for a
later, low-risk build/edit toolbar adoption - text labels stay either way.

## Sprout UI Kit (local-only, fallback-safe)

`UIArtRegistry` (`systems/art/ui_art_registry.gd`) resolves UI art in three
tiers: **activated licensed Sprout UI → generated Hearthvale UI shape
(`art/generated/hearthvale/ui/`) → cozy code-drawn `CozyUITheme`**. Missing ids
never crash — they fall through to the code-drawn theme. The local mapping lives
in the gitignored `licensed_assets/sprout_lands/sprout_ui_manifest.json`; the
committed template `art/sprout_ui_manifest.template.json` has no active paths.

**Sprout-required live build.** The Sprout UI manifest is one of the assets the
boot-time Sprout requirement checks (`systems/visual/sprout_asset_requirement.gd`):
with it absent the live game shows the missing-assets screen, so the activated
Sprout UI — not the code-drawn fallback — is the intended live UI skin. The
code-drawn `CozyUITheme` boxes now serve diagnostics (including the missing-assets
screen itself, which must not depend on the Sprout UI it reports as missing) and
non-visual tests, rather than being a parallel shipped UI style.

### How the live wiring works

Every panel already styles itself through `CozyUITheme` (`apply_panel`,
`apply_button`, `apply_slot`, `apply_tab_button`, ...). Those helpers now ask
`UIArtRegistry.texture_stylebox(id)` first: when a licensed Sprout UI asset is
activated for that id they return a nine-patch `StyleBoxTexture` (with content
margins so labels stay off the border); otherwise they return the existing
code-drawn box. So a single switch point reskins the system menu, inventory,
build menu, land panel, admin/worldbuilder panel, edit toolbar, terrain-paint
controls, and quick tools at once. (With Sprout absent the live world does not
mount at all — see the Sprout-required note above — so this skinning is the live
UI, not an optional layer.)

What is activated locally is deliberately reviewed and normalized under the
gitignored `licensed_assets/sprout_lands/normalized/ui/`: panel, button,
button-hover, slot, slot-selected, close, and panel variants used by dialog,
inventory, system, and build menus. Blocked/disabled states still keep a clear
code-drawn fallback so "unavailable" always reads. Text readability, Esc
behavior, and visible Close buttons take priority over skinning. Inspect tiers in
`tools/art/asset_preview.tscn` (F6).
