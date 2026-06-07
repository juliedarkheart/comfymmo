# Prototype Playtest

## Setup

1. Install Godot 4.x.
2. Open the repository folder as a Godot project.
3. Run `scenes/main.tscn`.

Helpful preflight checks:

- `.\tools\run-godot.ps1 -Headless -TimeoutSeconds 15 -GodotArgs "--version"`
- `.\tools\run-godot.ps1 -Headless -TimeoutSeconds 15 -GodotArgs "--help"`
- `.\tools\run-godot.ps1 -SmokeTest -TimeoutSeconds 30`

The smoke test is only a safe project-load check. Use the editor for actual gameplay acceptance.

## Acceptance Checks

- The game launches into the homestead map.
- The homestead feels like a broader yard and path-connected outdoor region rather than a one-screen block.
- The homestead reads as a cozy stylized placeholder scene rather than flat debug geometry.
- The character moves smoothly with `WASD` or arrow keys.
- Confirm the HUD shows `Comfort` and the expanded crop inventory summary.
- Confirm the game boots into the `homestead` region first.
- The camera follows the character, shows a broader useful area, and respects map limits.
- The cottage, trees, and fence block movement.
- Press `B` to enter placement mode and move the preview across the grid.
- Press `Tab` in placement mode and confirm the preview cycles through the crate, mailbox, stool, lantern, and planter.
- Confirm that valid tiles are placeable and blocked tiles are rejected.
- Confirm the HUD changes to `Placement Mode` with placement controls.
- Confirm a visible `Valid` or blocked-reason hint appears near the placement preview.
- Confirm avatar movement is paused while placement mode is active.
- Place several objects, including the crate, mailbox, stool, lantern, and planter, and confirm their silhouettes read differently.
- Press `E` to enter edit mode and hover an existing crate.
- Confirm the hovered or selected crate or mailbox highlights and can be removed.
- Confirm the HUD changes to `Edit Mode` with edit controls.
- Confirm avatar movement is paused while edit mode is active.
- Press `M` on a selected placed object and confirm its old tile becomes available during move preview.
- Confirm the move preview rejects blocked tiles and other placed objects.
- Confirm the HUD changes to `Move Mode` with move controls.
- Confirm the world-space hint appears again during move preview and updates live.
- Confirm hovering another crate shows `Occupied`.
- Confirm hovering the spawn tile shows `Reserved spawn`.
- Confirm hovering outside the map shows `Out of bounds`.
- Confirm avatar movement stays paused during move preview and returns after confirm or cancel.
- Confirm `Enter` or left click moves the crate to a new valid tile and that reload keeps the new location.
- Place a mailbox, exit decorating mode, walk near it, and confirm `Press F to check mailbox` appears.
- Confirm the mailbox shows a subtle new-mail world signal while unseen messages exist.
- Press `F` and confirm the mailbox panel opens with local mock tasks/messages.
- Confirm the mailbox entries display `New` or `Seen` state.
- Confirm `Water the garden` appears in the mailbox list.
- Confirm `Harvest a carrot` appears in the mailbox list.
- Press `Esc` and confirm the mailbox panel closes cleanly.
- Confirm the mailbox world signal disappears after the mailbox marks messages seen.
- Move or reload the mailbox and confirm the interaction still works afterward.
- Reopen the mailbox and confirm previously opened messages now show `Seen`.
- Find the three farm plots and confirm their prompts update in Explore mode.
- Press `F` on the carrot plot and confirm it plants a carrot.
- Press `F` again and confirm the carrot crop advances to watered.
- Open the mailbox again and confirm `Water the garden` now shows `[Done]`.
- Press `F` a third time and confirm the carrot crop becomes grown.
- Press `F` again and confirm the carrot harvests back to an empty plot.
- Open the mailbox again and confirm `Harvest a carrot` now shows `[Done]`.
- Plant, water, tend, and harvest the turnip and berry plots too.
- Confirm the HUD inventory summary updates for carrots, turnips, and berries.
- Press `I` and confirm a tiny inventory panel opens with carrot, turnip, and berry counts.
- Press `I` again and confirm the inventory panel closes.
- Press `C` and confirm one carrot is consumed and `Comfort` increases by 5.
- Press `C` with zero carrots and confirm nothing breaks.
- Walk down the homestead road toward the village edge and confirm the `village_square` region loads automatically.
- Walk near the notice board and confirm `Press F to read notice board` appears.
- Press `F` and confirm a notice panel opens with `Village Notice Board` and `Welcome to the village square.`
- Press `Esc` and confirm the notice panel closes cleanly.
- Confirm the notice board still works after the shared region-interactable helper refactor.
- Reopen the notice board after travel/restart if needed and confirm the seen flag behavior still works.
- Confirm the village square feels larger and leaves room for future social and shop features.
- Walk to the east side of `village_square` and confirm the `forest_edge` region loads automatically.
- Confirm `forest_edge` feels like a larger outdoor nature border with trail space and forest props.
- Walk around `forest_edge` and confirm the camera still follows cleanly and shows a useful amount of map.
- Walk near the shrine marker and confirm `Press F to inspect shrine` appears.
- Press `F` and confirm a message panel opens that teases future adventure.
- Press `Esc` and confirm the panel closes cleanly.
- Restart after reading it and confirm `adventure_marker_seen` persists.
- Walk back through the forest trail edge and confirm `village_square` loads again without a bounce loop.
- Walk along the village road back toward the homestead edge and confirm the `homestead` region loads automatically.
- Confirm the outdoor transition does not bounce or immediately send the player back.
- Confirm placed objects, mailbox state, farm state, carrot inventory, and comfort are preserved after returning home.
- Restart after each stage if needed and confirm all three farm plot states persist.
- Restart after harvesting and confirm carrot, turnip, and berry counts persist.
- Restart after consuming a carrot and confirm both carrot count and comfort persist.
- Restart after traveling and confirm the current region loads safely from save.
- If `notice_board_seen` is implemented, confirm it persists after restart.
- Press `T` in the homestead and confirm the mood cycles morning -> afternoon -> dusk -> morning.
- Confirm the full-screen tint changes subtly with each phase and afternoon reads as clear/neutral.
- Confirm the HUD `Time:` line updates to the current mood name.
- Confirm the tint never makes the HUD panels or interaction prompt unreadable.
- Confirm pressing `T` does not interfere with placement, edit, or move clicks.
- Open the mailbox, press `T`, and confirm the mood does NOT change while the panel is open.
- Enter placement/edit/move mode, press `T`, and confirm the mood does NOT change while decorating.
- Open a villager, notice board, or shrine panel, press `T`, and confirm the mood does NOT change.
- Confirm `T` still cycles the mood normally during free Explore movement (including with the inventory panel open).
- Set the mood to dusk, travel to `village_square` then `forest_edge`, and confirm dusk persists in both.
- Restart the project and confirm the last chosen mood is restored from save.
- Talk to Bram across several repeats and confirm he occasionally remarks on the current time of day.
- Travel to `village_square` and confirm Maribel Tock appears near the south plaza.
- Walk near Maribel and confirm `Press F to talk to Maribel` appears.
- Press `F` and confirm her first-visit welcome message appears.
- Press `Esc` and confirm the panel closes cleanly.
- Talk to Maribel again and confirm a repeat line appears.
- Talk a third time and confirm a different repeat line appears (rotating).
- Restart and confirm Maribel's repeat state persists (no first-visit message again).
- Walk east to find Bram Nettle near the garden and path area.
- Walk near Bram and confirm `Press F to talk to Bram` appears.
- Press `F` and confirm his first-visit message about keeping paths trimmed.
- Talk to Bram again and confirm a repeat line appears.
- Talk a third time and confirm a different repeat line.
- Restart and confirm Bram's repeat state persists.
- Confirm the notice board still works independently of both villagers.
- Confirm Maribel and Bram prompts do not appear simultaneously when player is equidistant.
- Confirm neither villager blocks player movement.
- Confirm the HUD shows `Day: 1` and `Time: Morning` on a fresh save.
- Walk to the cottage doorway and confirm `Press F to rest` appears on the doormat.
- Press `F` and confirm a `Rest for a while?` panel opens with `F = Rest   Esc = Cancel`.
- Press `Esc` and confirm the rest panel cancels cleanly with no day/mood change.
- Rest once from Day 1 Morning and confirm it advances to Day 1 Afternoon.
- Rest again and confirm Day 1 Dusk.
- Rest again and confirm it rolls over to Day 2 Morning.
- Confirm Comfort restores to 100 after a rest.
- Confirm the mood tint shifts and a short "morning/evening arrives" line shows on rest.
- Press `Esc` to close the result panel and confirm play resumes normally.
- Restart and confirm the current day and mood persist from save.
- Travel to village_square and forest_edge and confirm the same `Day:` number shows there.
- Talk to Maribel or Bram across repeats and confirm occasional day/mood-aware flavor lines.
- Confirm a moss rabbit appears in the homestead and wanders slowly in the south garden area.
- Walk near the rabbit and confirm `Press F to observe` appears.
- Press `F` and confirm a small flavor panel opens with one line of text such as "The moss rabbit twitches its ears."
- Press `Esc` and confirm the observe panel closes cleanly.
- Confirm the rabbit still wanders after the panel closes.
- Walk into the rabbit and confirm it gently moves away without blocking the player.
- Confirm one stump turtle appears near the farm plots and wanders very slowly with long idle pauses.
- Confirm the stump turtle's shell wobbles gently and its head bobs.
- Walk near the turtle and confirm `Press F to observe` appears.
- Press `F` and confirm a flavor line such as "The stump turtle blinks very slowly." appears.
- Walk into the turtle and confirm it drifts away softly without blocking or shoving the player.
- Confirm the turtle retreats much more calmly than the moss rabbit.
- Travel to `village_square` and confirm one moss rabbit wanders near the south plaza.
- Travel to `forest_edge` and confirm multiple moss rabbits wander in the forest.
- Confirm two lantern moths float gently in `forest_edge` with a subtle glow.
- Confirm moth wings flutter and the creature bobs smoothly up and down.
- Observe a lantern moth and confirm flavor text such as "Tiny wings shimmer in the light."
- Confirm no creature spams the interaction prompt when the player stands still.
- Confirm no creature blocks or slows player movement.
- Confirm no Godot debugger errors appear during creature spawning or wandering.
- Press `F10` and confirm the dev overlay appears with player position, area, and zoom.
- Press `1`/`2`/`3`/`4` and confirm the overlay `Tool:` line changes (Inspect/Marker/Blocked Note/Spawn Note).
- Press `M` (or left-click in Marker tool) and confirm a pin + label marker appears at the mouse world position.
- Place markers across the homestead, village, and forest areas and confirm the overlay marker count updates.
- Press `C` and confirm all markers disappear.
- Press `E` and confirm the overlay reports an export to `user://dev_marker_export.json`.
- Press `F10` again and confirm the overlay hides and normal gameplay input resumes (e.g. `C` eats a carrot again, not clears markers).
- Confirm dev markers never block movement and never persist after a scene reload.
- Confirm placement, edit, and move modes suppress the mailbox prompt.
- Confirm `Esc` exits the current placement or edit mode cleanly.
- Confirm the HUD returns to `Explore` after canceling or leaving decorating modes.
- Confirm the world-space hint disappears after placement, confirm, cancel, or mode exit.
- Confirm that placed crates and mailboxes load back after restarting the scene or project.
- The scene remains organized around map, player spawning, avatar, camera, and UI modules.

## Current Scope

Included:

- Small 2D isometric homestead map
- Controllable placeholder character
- Camera follow
- Basic obstacle collision
- Five local placeable object types with save/load
- One local edit/removal mode for placed objects
- One local move/reposition flow for placed objects
- One local mailbox interaction slice with mock task/messages
- One tiny mailbox-to-farming bridge through `Water the garden`
- One second mailbox-to-farming bridge through `Harvest a carrot`
- Three local farm plot interactions with simple crop stages
- One tiny inventory panel for carrots, turnips, and berries
- One local carrot consume action that boosts comfort
- One formal multi-region structure with `homestead` and `village_square`
- One third outdoor region, `forest_edge`, connected through seamless edge travel
- One tiny `forest_edge` shrine interaction that hints at future adventure
- Seamless outdoor edge travel between `homestead` and `village_square`
- One tiny village-square-only notice board interaction
- Cozy stylized in-engine placeholder visuals

- Lightweight manual world mood: morning/afternoon/dusk tint cycled with T, shown in HUD, persisted globally
- Gentle passage: global day counter, cottage rest interaction that advances mood/day and restores comfort, day/mood-aware villager flavor
- Two named villager placeholders: Maribel Tock and Bram Nettle in village_square
- Rotating repeat dialogue lines via persisted visit counter per villager
- Ambient life pass: moss rabbit (ground) and lantern moth (flying) in all three regions
- One slow homestead stump turtle (ground) near the farm/garden with observe flavor text
- Press `F` near any creature to observe it and read a short flavor line
- Creatures wander, idle, and gently flee the player when approached

Not included:

- combat
- crafting
- networking
- MMO-scale systems
- creature persistence across region loads
- creature taming or bonding
