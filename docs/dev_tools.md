# Dev Tools (local-only)

A small, local-only developer overlay for authoring the overworld. It adds no
gameplay, no networking, no backend calls, and no permanent world editing. Markers
are temporary and session-only unless exported.

## Toggle

- **F10** — toggle dev mode. When off, the overlay is hidden and idle and the editor
  watches no other input, so normal gameplay is untouched.

## Tools (while dev mode is on)

- **1** — Inspect (read-only)
- **2** — Marker
- **3** — Blocked Note (a marker tagged `blocked_note`)
- **4** — Spawn Note (a marker tagged `spawn_note`)

The selected tool decides the *type* tag of placed markers.

## Markers

- **M** — drop a temporary marker at the mouse world position (any tool).
- **Left-click** — drop a marker, only while the **Marker** tool is selected (so
  other tools leave clicks alone).
- **C** — clear all markers.
- **E** — export markers to a local file.

Markers are visual-only (a colored pin + a readable label showing `#id type`, world
position, and area). They have **no collision**, never block movement, and are
**never saved with the game** — they vanish on scene reload unless exported.

Marker colors by type: marker = red, blocked note = orange, spawn note = blue,
inspect = yellow.

## Overlay

While dev mode is on, the overlay shows the current tool, area label, player and
mouse world positions, camera zoom, marker count + last marker position, the key
help line, and the most recent export status.

## Export

**E** writes the current markers to `user://dev_marker_export.json` (the Godot user
data folder — safe and writable, never the project tree). Each entry includes
`id`, `position {x,y}`, `area`, `type`, and an empty `note` field for hand-editing.
There is no database and no network.

## Audit hook

Placing or clearing markers appends a local, in-memory `AuditLog` event
(`dev_marker_added` / `dev_markers_cleared`). This is session-only and exercises the
moderation/audit scaffolding (`systems/admin/audit_log.gd`) without any backend.

## Input safety

Dev keys are handled in `_input` (which runs before all `_unhandled_input`
handlers) and are only consumed while dev mode is on. So dev actions can never
collide with gameplay or building placement — e.g. `C` clears markers in dev mode
but still eats a carrot in normal play — and nothing leaks to gameplay while dev
mode is off.

## Future use

This is the seam for future world-building and moderation-review tools: terrain
painting, landmark placement, blocked-area definition, wilderness inspection,
spawned-content debugging, and player-build moderation review. See
`docs/backend_tools.md` and `docs/moderation.md`.
