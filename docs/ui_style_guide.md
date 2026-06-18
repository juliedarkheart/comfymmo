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

### LimeZu live UI: Modern UI assets first

LimeZu is the live UI direction, and the live UI should visibly use the reviewed
Modern UI assets. The Modern UI source frames are small and non-square (the panel is
47x31, the button 29x11), so layout must fit the asset scale: compact HUD cards,
compact inventory grids, smaller slots, concise labels, and the default 1280x720
window. Do not hide the asset set behind generic flat panels.

`CozyUITheme` is still the single switch point. `_limezu_box()` returns Modern UI
texture-backed `LimeZuUITheme` controls for panel/inventory_panel/slot/slot_selected/button/button_hover/button_pressed/
close/tab when LimeZu is the live provider (else null → Sprout nine-patch → code-drawn
cozy box). The label helpers follow the asset: panel labels use dark ink,
while buttons/tabs/close/danger get cream/gold labels on dark button strips. So in
LimeZu live mode the whole visible UI —
HUD, minimap, toolbelt, inventory, menus, tabs, close/danger — is one coherent
Modern UI family with no old Hearthvale/Sprout parchment or brown/orange fallback
buttons. Inventory stays closed by default, opens on I, closes on Esc/close.
Validation hard-checks that live panel/HUD/button/close/slot controls use Modern UI
texture styleboxes. Blocked/missing tool chips are the only flat exception so muted
denial text stays readable. Nothing licensed is committed.

The Modern UI slices (`ui.panel`/`ui.inventory_panel`/`ui.slot`/`ui.button`/...) are
produced by the slicer under gitignored `licensed_assets/limezu/modern_ui/normalized/`
and resolve as real runtime UI art. If a surface looks wrong, resize or simplify that
surface before replacing the asset with a flat fallback.

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
