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

## World-builder panel + plot commands

There is now an **F7 admin panel** and plot commands (`/plots`, `/plotinfo`,
`/inspect`, `/claimplot`, `/unclaimplot`) — full reference in
docs/world_builder_tools.md. The panel reuses these commands so behavior is
identical whether clicked or typed.

## Deferred (documented, not built)

A dedicated F7 admin panel UI; server-side command routing with role checks
(`/role`, `/kick`, `/players`, server `/announce`); admin-only world-marker
placeables (spawn/region/NPC markers — the F10 dev marker tools cover the
inspection half today); audit-log surfacing (AuditLog already records dev
marker actions).
