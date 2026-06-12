# Profiles & accounts (prototype)

## What this is

Local playtest identity: a JSON file of profiles at
`user://profiles/profiles.json`. **Not** online accounts — no passwords, no
secrets, no server-side auth. A profile is "who I am on this machine" for
saves, the wardrobe, and joining a local server.

## Profile shape (`systems/profile/local_profile.gd`)

```json
{
  "profile_id": "profile_a1b2c3d4e5f60718",
  "display_name": "Villager",
  "created_at": "2026-06-12T10:00:00",
  "last_played_at": "2026-06-12T10:00:00",
  "appearance": { "...": "CharacterAppearance ids" },
  "pronouns": "",
  "favorite_color": "",
  "last_server_ip": "127.0.0.1",
  "last_server_port": 8910
}
```

`profile_id` is generated once (random hex) and stable thereafter — it is the
key the server uses to remember your materials between sessions.

## Lifecycle

- First boot: `LocalProfileManager` creates a default profile automatically.
- The F8 panel edits the display name and remembers the last server address.
- The wardrobe/F9 panel writes appearance changes to the profile.
- `LocalProfile.normalized()` repairs missing/typo'd fields on load, so old or
  hand-edited profile files never crash the game.

## Appearance precedence (so profile and save never fight)

1. At boot, if the single-player save has an explicit `player.appearance`,
   it wins.
2. Otherwise the active profile's appearance seeds the avatar.
3. Every wardrobe/F9 change writes BOTH, so they converge permanently after
   the first edit.

## Old saves

Untouched. A pre-profile save loads exactly as before; the default profile is
created beside it and only seeds appearance when the save has none.

## Registering on a server (how "accounts" work today)

There is no signup form: joining a server **is** registration. On your first
join the server stores your profile_id in its world file (`known_profiles`)
with your display name and material pouch, and tells you in chat —
"Registered on this server as Julie". Returning with the same profile gets
"Welcome back" and your saved materials. Your display name is set in the F8
panel (it also shows your profile id); if someone online already uses your
name, the server renames you "Name#2" for the session. **No passwords exist**,
so anyone who copies or fabricates a profile_id can impersonate it — fine for
trusted friends, the documented reason this is not public-ready.

## Toward real accounts

When a persistent backend arrives: profile_id becomes a server-issued id,
display names get server-side uniqueness, and a session token replaces the
trust-the-LAN join. The local file stays as offline identity.
