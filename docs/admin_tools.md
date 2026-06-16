# Admin / world-builder tools (prototype)

## Trust model (honest)

Roles: owner / admin / builder / moderator / player
(`systems/admin/admin_permissions.gd`). **Offline, you are the owner of your
own world** — all admin commands work. **On a server**, the world file's
`roles` map grants profile_ids server-side bypasses (land, tools, locks on
placement). There are no passwords; roles are exactly as trustworthy as the
profile ids they key on (docs/server_identity.md).

## Commands (chat, offline-admin)

| command | effect |
|---|---|
| `/help` | list commands |
| `/give <id> [n]` | grant materials/components/tools/weapons/wearables/land tokens |
| `/xp [n]`, `/skillxp <skill> [n]` | progression testing |
| `/skills`, `/progression` | summary line |
| `/adminbuild` | toggle world-builder mode: placement ignores costs, tools, land permission, and level/skill locks |
| `/where` | position, grid tile, area, and plot under your feet |
| `/save` | force a local save write |
| `/announce <msg>` | local announcement line |

Bad input prints usage; commands while connected answer "offline-only for
now" — the server intentionally ignores chat commands, so connected players
cannot self-grant.

## World-builder panel + plot/marker commands

There is an **F7 admin panel** and a full in-game world-builder: plot commands
(`/plots`, `/plotinfo`, `/inspect`, `/claimplot`, `/unclaimplot`), live plot
authoring (`/newplot`, `/resizeplot`, `/delplot`), persistent world markers
(`/marker`, `/delmarker`), an in-world overlay (`/overlay`), and teleport
navigation (`/tp <plot_id>`). Editor-made plots and markers persist to the
offline save (`runtime_plots` / `world_markers` flags). Full reference in
docs/world_builder_tools.md. The panel reuses these so behavior is identical
whether clicked or typed.

## Deferred (documented, not built)

Server-side command routing with role checks (`/role`, `/kick`, `/players`,
server `/announce`); wiring authored world markers to live resource-node / NPC
spawners (today they record placement intent and show on the overlay);
free-form / draggable plot bounds and plot moving; audit-log surfacing
(AuditLog already records dev marker actions).
