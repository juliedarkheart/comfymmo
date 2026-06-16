# World-builder / admin tools

Trust-based prototype (no passwords). **Offline you are the owner of your
world**; on a server, the world-save `roles` map governs (see
docs/admin_tools.md and docs/server_identity.md). Honest limitation: anyone who
can run offline or holds an admin profile_id has full power — fine for private
playtests, not public servers. All world-builder authoring below is **offline /
world-builder only**; while connected to a server these commands answer
"offline-only for now" so connected players can't reshape the world.

## Admin panel (F7)

Opens a panel showing your role, current area, and admin-build state, grouped
into sections:

- **General:** Toggle Admin Build, Save World, List Plots, Where Am I, Give Land
  Token, Give Starter Materials, Toggle World Overlay.
- **World Builder · Plots:** a biome picker + **Create Plot Here**, then
  **Grow +2 / Shrink -2 / Remove Here** for the editor plot you're standing in.
- **World Builder · Terrain:** a terrain picker + **Brush Here / Fill Area /
  Reset Here** for first-pass visual biome/path/water painting.
- **World Builder · Markers:** a marker-type picker + **Place Marker Here** /
  **Remove Marker Here**.
- **Teleport:** Landing / Neighborhood / Town, plus a button for **every plot**
  (built-in and editor-made) that jumps you to its center. The plot list
  rebuilds whenever you open the panel or change a plot.

Buttons call the controller's `admin_*` methods directly (or the chat router for
the general ones), so clicked and typed actions behave identically.

## In-game world-builder editor

You can author the world live, in the running game, and it persists to your
offline save:

- **Create a plot** where you stand: `/newplot [biome] [size]` (or the panel).
  Biome is one of `meadow orchard creekside hilltop grove brook`; size is the
  side length in tiles (clamped 8–24, default 16). The new lot is a real
  claimable plot the instant it exists — it draws its biome ground patch, corner
  posts, boundary, and a claim sign, and shows up on the minimap and overlay.
  Creation is rejected if it would overlap (or touch) another plot.
- **Resize** the editor plot under your feet: `/resizeplot <±n>` (panel:
  Grow/Shrink). Built-in lots are fixed and can't be resized.
- **Remove** the editor plot under your feet: `/delplot` (panel: Remove Here).
  This also clears any claim recorded for it. Built-in lots can't be removed.

Editor plots live in a runtime overlay on `LandRegistry` and are saved to the
`runtime_plots` flag (serialized as `{display_name, rect:[x,y,w,h], biome}`).
On boot they're reloaded **before** plot signs are drawn, so a custom lot comes
back looking exactly like a built-in one. A corrupt record is skipped, never
fatal.

## Terrain paint (first pass)

The branch now includes a lightweight, admin-only visual terrain painter. It is
still intentionally simple:

- **Brush Here** paints the tile under your feet.
- **Fill Area** fills the current plot, or the authored fixed area you stand in.
- **Reset Here** clears paint from the current plot/area, or just the current
  tile when you're not inside one.

Supported paint ids:

- `meadow`
- `forest`
- `orchard`
- `creekside`
- `hilltop`
- `grove`
- `town`
- `farmland`
- `dirt_path`
- `stone_path`
- `water`

This is a **visual ground override only** for now. It does not change plot
ownership rules, protection, pathfinding, or generation. Overrides persist to
the offline save's `terrain_overrides` flag and are replayed on boot.

## World markers (decor / resource / NPC / sign / landmark hints)

Place persistent authoring markers at your tile with `/marker <type> [label]`
(panel: Place Marker Here). Types: `spawn resource npc sign landmark decor`.
Each marker draws a colored gem-on-a-stake with its label, and is saved to the
`world_markers` flag (`{type, tile:[x,y], label}`). Remove the nearest one with
`/delmarker` (panel: Remove Marker Here). These are world-authoring hints today
(they record intent and show on the overlay); wiring them to live spawners /
NPCs is deferred.

## In-world overlay + navigation

`/overlay` (panel: Toggle World Overlay, also bound to the Toggle Plot Debug
button) toggles `WorldBuilderOverlay` — an above-the-props layer that draws,
directly in the world:

- every plot's footprint as a biome-tinted translucent diamond with an outline,
- its name and `WxH` size (tagged `· editor` for runtime plots, `· fixed` for
  non-claimable ones),
- white corner ticks,
- the original homestead "training core" grid,
- a colored cross for every authored marker.

It reads live from `LandRegistry`, so it always matches the real plots, and it's
purely visual (no collision, never saved). For fast travel, `/tp <plot_id>`
jumps to a plot center (or `/tp landing|neighborhood|town`); the F7 panel's
per-plot buttons do the same.

## Chat commands

Player: `/skills` `/progression` `/invite <user>` `/where`
Admin (offline): `/give <id> [n]` `/xp [n]` `/skillxp <skill> [n]`
`/adminbuild` `/plots` `/plotinfo <id>` `/inspect` `/claimplot <id> [user]`
`/unclaimplot <id>` `/save` `/announce <msg>` `/help`
Builder (offline): `/newplot [biome] [size]` `/delplot` `/resizeplot <±n>`
`/marker <type> [label]` `/delmarker` `/overlay` `/tp <plot_id>`

- `/adminbuild` toggles world-builder mode: placement ignores costs, tools,
  land permission, and level/skill locks — so admins can build in town and on
  any plot.
- `/where` reports position, tile, area, and plot under your feet.
- `/plots` lists every plot (built-in + editor) with id, name, tile bounds, and
  ownership; `/plotinfo <id>` / `/inspect` shows one plot's full record.
- `/claimplot <id> [user]` assigns a plot; `/unclaimplot <id>` clears it.
- Bad input prints usage; non-applicable commands while connected say
  "offline-only."

## Deferred

Server-side admin command routing with role checks (`/role`, `/kick`,
server `/announce`); wiring world markers to live resource-node / NPC spawners;
free-form (drag) plot bounds and rotation rather than centered squares;
moving an existing plot to a new location.
