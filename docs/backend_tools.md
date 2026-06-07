# Backend Tools & Staged Architecture

Hearthvale is a local, single-player cozy prototype today. This document records the
**staged direction** toward a small family/friends MMO so the current local
scaffolding (dev overlay, moderation models, audit log) lines up with a future
authoritative backend. Nothing here is implemented as a live service yet — there are
no servers, databases, accounts, or network calls in the project.

## Guiding principles

- **Local-first.** Every system runs offline today. Backend pieces are added behind
  stable interfaces so the local prototype keeps working without them.
- **Authoritative later.** When multiplayer arrives, the server owns world state,
  identity, and moderation decisions. Clients propose; the server decides.
- **Optional real-life integrations.** Any real-world connectors (calendars, etc.)
  stay opt-in and isolated from core gameplay and from the safety/moderation layer.

## Stages

1. **Local prototype (now).** One continuous overworld, local JSON save, all systems
   in-process. Dev overlay (`F10`) for inspection. Moderation/audit are stubbed data
   models only.
2. **Authoritative server (later).** A small headless authority validates movement,
   placement, farming, and inventory; clients send intents. Reuses the existing
   system boundaries (`InteractableSystem`, `BuildingPlacementSystem`, etc.).
3. **Player identity / accounts.** Lightweight identity (id + display name + role).
   Family/friends scale: invite-based, no public sign-up. Roles map to
   `ModerationModels.ROLES` (owner/admin/moderator/trusted/player).
4. **World persistence.** Server-side world state replaces local JSON as the source
   of truth; the local save becomes a cache. Save *shape* (regions, global flags,
   player) is preserved so migration is mechanical.
5. **Player builds & terraforming persistence.** Placement/edit/move/remove and
   future terraforming become server-persisted, per-player-owned, and moderatable
   (see `delete_build` / `restore_build` actions).
6. **Report queues.** Players submit reports (`ModerationModels.make_report`). The
   server queues them for moderators; `AuditLog` records submissions.
7. **Admin dashboard.** A separate tool (not in the game client) to review reports,
   take actions (`make_admin_action`), and inspect the audit trail.
8. **Audit logs.** Every report and admin action is appended to a durable,
   append-only trail. `AuditLog` is the local stand-in for that trail.
9. **Family/friends safe-server assumptions.** Small, trusted, invite-only servers.
   Defaults favor safety (conservative permissions, easy rollback of builds, full
   audit). Not designed for anonymous public scale.
10. **Real-life integrations stay optional and separate.** Any external connector is
    a sidecar that can be disabled without affecting gameplay, persistence, or
    moderation.

## Current local scaffolding

| Concern | Local stub | Future |
|---|---|---|
| Dev inspection + markers | `systems/overworld_editor_system.gd` (`F10` overlay, temporary markers, export) | World-building + moderation review tools |
| Tool state | `systems/dev_tool_state.gd` | Shared editor/tool state |
| Temporary markers | `systems/dev_world_marker.gd` + `user://dev_marker_export.json` | Authored/persisted landmarks & spawn points |
| Roles | `ModerationModels.ROLES` | Server-enforced permissions |
| Reports | `ModerationModels.make_report` | Server report queue |
| Admin actions | `ModerationModels.make_admin_action` | Server-validated actions |
| Audit trail | `systems/admin/audit_log.gd` (in-memory) | Durable append-only store |

See `docs/moderation.md` for the moderation model details.
