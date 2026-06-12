# External server access (LAN & internet playtests)

How friends reach a Hearthvale server that runs on your PC. Three tiers, each
building on the previous. **The transport is ENet over UDP, default port 8910.**

> Honesty first: this is prototype networking — no authentication, no
> encryption, no rate limiting. Anyone who can reach the port can join and
> build. Share the address with trusted friends only, and stop the server when
> you're done. Do not expose it to strangers.

## Tier 1 — same PC (zero setup)

1. `tools\run_server_local.ps1`
2. Run the game, F8 → `127.0.0.1` : `8910` → Connect.

Nothing else needed; loopback bypasses the firewall.

## Tier 2 — LAN (same house/network)

1. Host: `tools\run_server_local.ps1` (the default bind `*` accepts LAN).
2. Host: allow UDP 8910 inbound through the Windows firewall — run
   `tools\open_firewall_server_port.ps1` **in an Administrator PowerShell**
   (remove later with `remove_firewall_server_port.ps1`).
3. Host: find your LAN IP — `ipconfig` → "IPv4 Address" (usually `192.168.x.x`).
4. Friend on the same network: F8 → that LAN IP : 8910 → Connect.

If it fails: confirm the firewall rule exists, confirm both PCs are on the
same network (guest Wi-Fi networks often isolate clients), and confirm the
server console shows "Listening on *:8910".

## Tier 3 — internet (router port forwarding)

1. Host: `tools\run_server_public.ps1` (binds `0.0.0.0`, prints warnings).
2. Host: firewall rule as in Tier 2.
3. Host: in your router's admin page, forward **UDP 8910** to this PC's LAN IP.
   (Routers name this "Port Forwarding" / "Virtual Server"; consider a DHCP
   reservation so your LAN IP doesn't change.)
4. Host: find your public IP (e.g. search "what is my IP").
5. Friend anywhere: F8 → your public IP : 8910 → Connect.

### Why Tier 3 sometimes cannot work: CGNAT

Some ISPs put customers behind Carrier-Grade NAT — your router never gets a
real public IP, and port forwarding does nothing. Telltale sign: the WAN IP in
your router admin (often `100.64.x.x` or `10.x.x.x`) differs from what "what
is my IP" reports. Options: ask the ISP for a public IP, or use a private
overlay network.

### Safer private alternative

VPN/tunnel software that puts you and your friends on a shared private network
(a mesh VPN, or any UDP tunnel you already trust) avoids port forwarding and
public exposure entirely: friends connect to your VPN address : 8910 as if on
LAN. We don't bundle or endorse a specific tool; any of them beats opening a
port to the internet for a prototype with no auth.

## Server-side knobs

- `--bind=127.0.0.1` strictly local · `--bind=0.0.0.0` (or `*`, the default)
  all interfaces
- `--port=N`, `--world=name`, `--max-players=N`
- `--config=<path>` JSON file (see `server/server_config.example.json`);
  CLI args override config values

## Toward real hosting (future)

A rented VPS running the headless server removes all router/CGNAT problems and
is the honest next step before any public playtest — together with session
auth, which does not exist yet.
