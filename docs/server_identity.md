# Server identity & username registration (prototype)

## How registration works

Your **username** is your persistent handle: lowercase `a-z 0-9 _ -`, 3–20
characters, set in the F8 panel (sanitized on entry; old profiles derive one
from their display name automatically). On your first join the server binds
the username to your `profile_id` in the world file's `registered_users` map
— that IS registration; there is no signup form and **no password**.

- Returning with the same profile: "Welcome back, @julie!"
- A different profile trying a taken username: the join is **rejected** with
  "Username 'julie' is taken on this server — pick another in the F8 panel."
- Uniqueness is case-insensitive (everything stores lowercase).
- Display names remain free-form and per-session deduplicated for chat;
  the username is what the land registry and roles key on (alongside
  profile_id).

The F8 panel shows username, display name, and profile id; server logs note
"NEW username registration" vs "returning".

## The honest trust model

The profile_id is a locally generated, non-secret string. Anyone who copies
or fabricates it can impersonate that user — and with it their username,
plots, materials, and role. That is acceptable for private friend playtests
and **disqualifying for public servers**. The path to real identity:
server-issued ids + session tokens at join, then optional accounts. Nothing
in the current code pretends otherwise.

## Admin roles

The world file's `roles` map (`profile_id -> owner/admin/builder/moderator`)
drives server-side bypasses (build permission, tools, locks). It is edited by
hand for now; offline, the local player is always the owner of their own
world. See docs/admin_tools.md.
