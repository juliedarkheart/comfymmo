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
- Build menu: category tabs, selected item info, cost/tool/size/interior status,
  unavailable reason, Compact, Select, and Close.
- Land panel: plot name, owner/status/cost/tokens, claim affordance, permission
  text, and Close.
- Admin/worldbuilder panel: grouped sections for admin status, plot tools,
  terrain paint, parcel preview, markers, teleports, and Close.
- Minimap: clipped map content, cozy frame, readable player marker, landmark
  dots, plot ownership borders, and biome-tinted plot fills.

## HUD Expectations

The HUD should answer the playtester's first questions quickly:

- Who am I playing as?
- Am I offline or on a server?
- Where am I: town, plot, protected area, biome, or wilderness?
- What time or day/night phase is active if implemented?
- What mode is active: explore, build, edit, move, or terrain/admin tool?
- What are the main controls: Esc/Start menu, F11 fullscreen, I inventory,
  B build, E edit, H help, M minimap?

Keep the HUD compact. It should orient the player without covering the world.

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

### How the live wiring works

Every panel already styles itself through `CozyUITheme` (`apply_panel`,
`apply_button`, `apply_slot`, `apply_tab_button`, ...). Those helpers now ask
`UIArtRegistry.texture_stylebox(id)` first: when a licensed Sprout UI asset is
activated for that id they return a nine-patch `StyleBoxTexture` (with content
margins so labels stay off the border); otherwise they return the existing
code-drawn box. So a single switch point reskins the system menu, inventory,
build menu, land panel, admin/worldbuilder panel, edit toolbar, terrain-paint
controls, and quick tools at once — and a clean checkout (no Sprout) is
unchanged.

What is activated locally is deliberately conservative: the Sprout **panel**
nine-slice (`dialog box`) and the **close** X — both confidently identifiable
single assets. Button/slot SHEETS that don't divide cleanly headlessly stay
**catalog-only** (manifest `candidates`) and keep the cozy code-drawn style;
blocked/disabled states also stay code-drawn so "unavailable" always reads
clearly. Text readability, Esc behavior, and visible Close buttons always take
priority over a skin. Inspect tiers in `tools/art/asset_preview.tscn` (F6).
