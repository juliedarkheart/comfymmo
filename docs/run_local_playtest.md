# Local playtest guide

## Offline (default, zero setup)

Run `scenes/main.tscn`. Everything works with no server: gathering, material-
gated building, farming, mailbox, rest, wardrobe, villagers, creatures.

First boot shows a welcome panel with the controls. Key reference:
- WASD/arrows move · F interact · Esc close panels
- B build (Tab switches item, cost shown in the mode line) · E edit/move/remove
- I inventory · C eat carrot · T cycle time · R reset zoom
- Mirror by the cottage = wardrobe · F9 dev creator · F10 dev tools · F8 multiplayer

What to do first: walk to a gather pile (wood logs SW of the cottage, stone
to the east, fiber/clay to the north-east), press F — you get a "+2 Wood"
toast in the chat log, then the spot dims and recovers for ~20 seconds. Then
B to build something with the materials line in the HUD.

## Chat

Press **Enter** to open chat (lower-left), type, Enter to send, Esc to close.
While typing, WASD types instead of moving. Offline, the chat box is a local
event log only (gather toasts, system lines) — connect via F8 to actually
talk. Join/leave announcements and placement denials also land there.
Prototype chat: 200-char cap, no moderation/filtering/admin commands yet.

## Two-instance multiplayer playtest

1. Start the server: `.\tools\run_server_local.ps1` (docs/run_local_server.md).
2. Start client A: `.\tools\run_client_local.ps1` (or run the project), F8 → Connect.
3. Start client B: second Godot instance of the same project (the editor's
   Debug > "Run Multiple Instances" set to 2 makes this one click), F8 →
   set a different display name → Connect.
4. Expected:
   - Each client sees the other's chibi avatar with a name tag, moving live.
   - Building (B + click) sends the request to the server; the object appears
     on BOTH clients; the HUD materials line switches to "Server: ..." counts.
   - Denials (occupied tile / not enough materials) show a friendly panel.
   - Stop and restart the server: reconnect — placed objects are still there.

Honest validation status: the flow has been exercised headlessly (server boot,
world persistence, validation suite); live two-client input is exactly what
this playtest is for. See docs/playtest_readiness.md.

## Profiles

Your display name and look come from your active local profile
(user://profiles/profiles.json), editable in the F8 panel and the wardrobe.
Two clients on ONE machine share that profiles file — give the second
instance a different display name in its F8 panel before connecting.
