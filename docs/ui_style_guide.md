# Hearthvale UI Style Guide

The UI should feel like a friendly tabletop village kit: parchment panels, warm
wood borders, honey highlights, readable slots, and simple close paths.

The reusable helper is `ui/cozy_ui_theme.gd`.

## Shared UI Pieces

- Main panels use warm parchment with a thick wood border.
- HUD/minimap frames can use darker wood, but text must stay cream and readable.
- Buttons use parchment slots with honey hover/pressed states.
- Category tabs use the same button style, with a stronger selected state.
- Item slots use pale parchment; selected slots use honey; unavailable slots are
  muted with a clear blocked border.
- Close buttons should be visible on major panels.
- Destructive buttons, such as Delete or Quit, use the danger treatment.

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
- Keep button text short and concrete.
- Prefer item slots or grouped rows over long walls of text.
- Use clear denial feedback when an action is blocked.
- Use consistent selected state rather than relying on text alone.
