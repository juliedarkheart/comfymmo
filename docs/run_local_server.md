# Run a local Hearthvale server

## Easiest: the run scripts

```powershell
.\tools\run_server_local.ps1                      # defaults: port 8910, world default_world
.\tools\run_server_local.ps1 -Port 9000 -World my_town
.\tools\run_server_local.ps1 -Bind 127.0.0.1      # strictly this PC, invisible to LAN
.\tools\run_server_public.ps1                     # binds 0.0.0.0 for internet playtests (read its warnings)
.\tools\run_client_local.ps1                      # launches the game client
.\tools\run_client_editor.ps1                     # opens the Godot editor
```

Each script checks the Godot/project paths, prints the exact command it runs,
and explains what to fix if something is missing. `-GodotPath`/`-ProjectPath`
override the defaults (`E:\Apps\Godot`, the repo root).

## Manual command

```powershell
& 'E:\Apps\Godot\Godot_v4.6.3-stable_win64_console.exe' --headless --path E:\GitHub\comfymmo res://server/server_main.tscn -- --port=9000 --world=my_town --bind=0.0.0.0
```

Defaults: port **8910** (UDP), world **default_world**, bind **`*`** (all
interfaces), max 16 players.

## Config file

`--config=<path>` loads a JSON config; individual CLI args override it.
Template: [server/server_config.example.json](../server/server_config.example.json)
(`bind_address`, `port`, `world`, `max_players`, `save_on_change`,
`log_connections`). Copy it somewhere (e.g. `user://server_config.json`),
edit, and run:

```powershell
.\tools\run_server_local.ps1   # then add to the printed command:  --config=user://server_config.json
```

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

## LAN / internet access

See [external_server_access.md](external_server_access.md) for the full
LAN/internet guide: ENet is **UDP**, Windows firewall needs an inbound UDP rule
(`tools\open_firewall_server_port.ps1`, Administrator PowerShell), internet play
needs router port forwarding, and CGNAT ISPs may block it entirely.

## Notes

- Server and client can run on the same machine (separate processes). There is
  deliberately no same-process "Host" button — a dedicated process keeps the
  authority model honest.
- The server never reads or writes your single-player save.
- Private/trusted-friends use only: there is no authentication or encryption yet.
