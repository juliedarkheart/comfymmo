# World-builder / admin tools

Trust-based prototype (no passwords). **Offline you are the owner of your
world**; on a server, the world-save `roles` map governs (see
docs/admin_tools.md and docs/server_identity.md). Honest limitation: anyone who
can run offline or holds an admin profile_id has full power — fine for private
playtests, not public servers.

## Admin panel (F7)

Opens a panel showing your role, current area, and admin-build state, with
buttons: Toggle Admin Build, Save World, List Plots, Where Am I, Give Land
Token, Give Starter Materials, Toggle Plot Debug Overlay, Teleport
(Landing/Neighborhood/Town), Close. Most buttons reuse the chat command router
so there is one source of truth.

## Chat commands

Player: `/skills` `/progression` `/invite <user>` `/where`
Admin (offline): `/give <id> [n]` `/xp [n]` `/skillxp <skill> [n]`
`/adminbuild` `/plots` `/plotinfo <id>` `/inspect` `/claimplot <id> [user]`
`/unclaimplot <id>` `/save` `/announce <msg>` `/help`

- `/adminbuild` toggles world-builder mode: placement ignores costs, tools,
  land permission, and level/skill locks — so admins can build in town and on
  any plot.
- `/where` reports position, tile, area, and plot under your feet.
- `/plots` lists every plot with id, name, tile bounds, and ownership.
- `/plotinfo <id>` / `/inspect` shows one plot's full record (bounds, area,
  status, owner, members). `/inspect` with no id uses the plot you stand on.
- `/claimplot <id> [user]` assigns a plot; `/unclaimplot <id>` clears it.
- Bad input prints usage; non-applicable commands while connected say
  "offline-only."

## Plot debug overlay

The minimap (M) draws plot squares tinted by ownership; admin debug adds white
outlines around each plot for boundary inspection. `/where` + `/plotinfo`
agree with what the HUD/minimap show.

## Deferred

Server-side admin command routing with role checks (`/role`, `/kick`,
server `/announce`), a full in-world plot editor (`/createplot` with custom
bounds), and admin-placed world markers beyond the existing F10 dev markers.
