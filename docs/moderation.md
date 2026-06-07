# Moderation (Scaffolding)

This describes the **stubbed** moderation model in `systems/admin/`. It is data
shapes and helpers only — there is no live moderation UI, no enforcement, no
network, and no persistence. The intent is a safe, small family/friends server
later, with conservative defaults and a full audit trail.

## Roles

`ModerationModels.ROLES`, least to most privileged:

- `player` — default.
- `trusted` — vouched-for player; future relaxed limits.
- `moderator` — can review reports and take soft actions.
- `admin` — full moderation + build management.
- `owner` — server owner; all permissions.

`role_rank(role)` returns the rank; `can_moderate(actor, target)` is a placeholder
that requires the actor to be at least a moderator and outrank the target. Real
enforcement will live on the authoritative server.

## Reports

`ModerationModels.make_report(reporter_id, target_player_id, reason, notes,
world_area, position)` returns:

```text
reporter_id, target_player_id, reason, notes, world_area,
position {x, y}, created_at, status="open"
```

`world_area` can come from `DevToolState.area_label(position)`.

## Admin actions

`ModerationModels.make_admin_action(action_type, target_id, actor_admin_id, reason)`
returns `action_type, target_id, actor_admin_id, reason, timestamp`.

Action types (`ModerationModels.ACTION_TYPES`): `mute`, `kick`, `ban`, `warn`,
`delete_build`, `restore_build`. Build actions pair with the future persisted
placement/terraforming system so a moderator can remove and restore player builds.

## Audit log

`systems/admin/audit_log.gd` (`AuditLog`) is an in-memory, append-only session log:

- `append(kind, payload)`, plus `record_report` / `record_admin_action` helpers
- `get_entries()`, `get_entries_of_kind(kind)`, `size()`, `clear()`

Future: forward entries to a durable, server-side, tamper-evident store.

## Future hooks (not implemented)

- **Chat moderation** — message filtering/mute enforcement on the server.
- **Build/object moderation** — review queues + `delete_build`/`restore_build`.
- **Player reports** — submission from the client, triage on the dashboard.
- **Audit trail** — durable record of all reports and actions.
- **Server authority** — all decisions validated server-side; clients only propose.

## Safety stance

Family/friends, invite-only, small scale. Defaults favor safety: conservative
permissions, easy build rollback, and complete auditing. Not built for anonymous
public scale.
