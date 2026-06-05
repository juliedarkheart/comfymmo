# Interactions

Hearthvale does not yet have a full interaction loop, but it now has a clean
placeholder boundary for one.

## Current State

- mailboxes can be checked in Explore mode
- the nearest mailbox shows `Press F to check mailbox`
- pressing `F` opens a tiny local mailbox panel
- mailbox messages have local `New` / `Seen` state
- one mailbox task can now become `Done` from a world action
- placed mailboxes show a subtle world-space new-mail signal when unseen mail exists
- `Esc` closes the mailbox panel
- no task board yet
- no inventory UI yet
- one farm plot now uses the same local interaction seam
- the village square has a tiny local notice board interaction
- the forest edge has a tiny local shrine interaction

## Interactable System

`systems/interactable_system.gd` is a small registry for future world-facing
interactions.

Current placeholder concepts:

- `generic -> inspect`
- `mailbox -> check_mail`
- `farm_plot -> tend_plot`
- `notice_board -> read_notice`
- `shrine_marker -> inspect_shrine`
- `task_board -> review_tasks`

The registry is intentionally simple:

- register an interactable id
- point it at a node
- label its interaction type
- ask for available actions later

For small region-only props, `BaseRegionController` now also provides a tiny
helper seam:

- register a one-off interactable node
- give it a prompt
- attach a local callback
- optionally unregister it later

## Intended Next Uses

- mailbox interaction
- task or calendar board interaction
- crop plot interaction
- creature petting or bonding interaction
- dungeon entrance confirmation

## Why This Exists Now

The project already has placeable objects with identity, save/load, and local
world state. Adding a lightweight interaction seam now helps future gameplay
attach to those objects without stuffing unrelated logic into placement code.

## Mailbox Slice

The first real interaction slice now works like this:

- placed mailboxes register with `InteractableSystem`
- the system tracks the nearest interactable in Explore mode
- the HUD shows a small prompt when the player is close enough
- pressing `F` requests a mailbox interaction
- `TaskIntegrationSystem` supplies a short local mock message list
- the HUD displays that list in a small mailbox panel
- opening the mailbox marks all current messages seen and saves that state locally
- all placed mailboxes hide their new-mail signal after the seen state updates
- watering the farm plot marks the local `Water the garden` mailbox task complete
- harvesting the crop marks the local `Harvest a carrot` mailbox task complete

## Message State

Mailbox messages now use stable local ids and a tiny seen/completed-state model.

- seeded mock messages start as unseen
- the first mailbox open shows their current state
- opening the mailbox marks all current messages seen
- reopening later shows them as seen
- watering the farm plot marks `Water the garden` as done
- harvesting a grown carrot marks `Harvest a carrot` as done
- done tasks display as `[Done]` in the mailbox panel
- restarting the project preserves that seen state through the save file
- if unseen messages exist, every placed mailbox shows a small active world signal

This remains local-only and intentionally lightweight so future real task or
calendar integrations can plug into the same seam later.

## Village Notice Slice

The second non-homestead interaction proof is the village notice board:

- the notice board registers only inside `village_square`
- it now registers through `BaseRegionController.register_region_interactable(...)`
- the nearest prompt shows `Press F to read notice board`
- pressing `F` opens a tiny local panel through the existing HUD surface
- reading it can mark `world.regions.village_square.region_flags.notice_board_seen`
- this stays region-local and does not touch mailbox/task systems
- the flag read/write and message panel flow now come from `BaseRegionController`

## Forest Shrine Slice

The third region proof is a tiny forest-side adventure tease:

- the shrine registers only inside `forest_edge`
- it uses `BaseRegionController.register_region_interactable(...)`
- the nearest prompt shows `Press F to inspect shrine`
- pressing `F` opens a small local message panel
- the first inspection marks
  `world.regions.forest_edge.region_flags.adventure_marker_seen`
- later inspections can show a softer repeat message
- this stays fully local and does not activate combat, dungeon, or reward logic
