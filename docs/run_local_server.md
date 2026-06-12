# Run a local Hearthvale server

## Start the server (PowerShell)

```powershell
& 'E:\Apps\Godot\Godot_v4.6.3-stable_win64_console.exe' --headless --path E:\GitHub\comfymmo res://server/server_main.tscn
```

Options go after a `--` separator:

```powershell
& 'E:\Apps\Godot\Godot_v4.6.3-stable_win64_console.exe' --headless --path E:\GitHub\comfymmo res://server/server_main.tscn -- --port=9000 --world=my_town
```

Defaults: port **8910**, world **default_world**, max 16 clients.

You should see:

```
=== Hearthvale Server (prototype) ===
[server] Hearthvale server listening on port 8910
[server] World 'default_world' loaded: 0 placed objects (user://server_worlds/default_world.json)
[server] Ready. Press Ctrl+C to stop; the world saves on every change.
```

## Where the world lives

`user://server_worlds/<world>.json` — on Windows:
`%APPDATA%\Godot\app_userdata\Hearthvale\server_worlds\`.

Created automatically on first start; saved on every committed placement and
on every player join/leave; survives restarts. Contains `world_id`,
timestamps, `placed_objects`, `world_flags`, and `known_profiles` (display
name + materials per profile id — no secrets).

## Connect a client

1. Run the game normally (`scenes/main.tscn`).
2. Press **F8** → check IP `127.0.0.1` and the port → **Connect**.
3. The status line walks through Connecting → Connected → "Joined world".

See docs/run_local_playtest.md for the full two-player walkthrough.

## Notes

- Server and client can run on the same machine (separate processes). There is
  deliberately no same-process "Host" button — a dedicated process keeps the
  authority model honest.
- The server never reads or writes your single-player save.
- Private/LAN use only: there is no authentication or encryption yet.
