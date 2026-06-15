# UI / HUD reference

## Top-left status panel (always on)

- Title "Hearthvale", day/time, comfort, crop counts (icon rows).
- **Identity line**: `@username (Display) · Offline/Server · Lv N`.
- **Area line**: `📍 <area/plot>` — updates live as you walk (throttled ~4/s).
  Examples: "Landing", "Town Square — Public, protected", "Meadow Lot 1 —
  Unclaimed", "Meadow Lot 1 — Your Plot", "Orchard Lot 2 — Owned by @friend",
  "Neighborhood — Public path", "Forest Edge — Wilderness".
- **Materials line**: `Wood N · Stone N · Fiber N · Clay N · Tokens N` (uses
  the authoritative count — local inventory offline, server pouch connected).
- Mode line (build/edit state) + controls hint.

## Quick tools strip (left edge)

One chip per starter tool (Axe, Pick, Hoe, Can, Hammer, Shovel), bright when
owned and dimmed when missing. Updates on gather/craft/give and server pouch
changes. Ownership-only for now (the game checks owning a tool, not an active
selection); number-key hotkeys are documented future work to avoid clashes.

## Minimap (top-right, M toggles)

Schematic world view scaled from world coordinates: region bands (town, forest),
plot squares tinted by ownership (gold = unclaimed, green = yours, blue =
friend, red = other's), landmark dots (Rowan, Clerk Hazel, town, shrine), and a
yellow player marker that tracks your position. Updates after any plot claim.
Admin debug adds plot outlines.

## Panels

- **I** — full inventory (identity header + Materials/Components/Tools/Tokens/
  Weapons/Wearables; offline inventory or server pouch).
- **Land panel** — opens from a plot sign: name, size, status, owner, members,
  cost, your tokens, build permission, and a Claim button.
- **K** crafting · **P** progression · **F8** multiplayer/profile · **F9**
  wardrobe/creator · **F7** admin panel · **H** full help · **Enter** chat.
- **F11** toggles fullscreen/windowed (never traps you).

## Keys (no conflicts)

WASD move · F interact · I inventory · K craft · P skills · H help · M minimap ·
B build · E edit · T time · C eat · F7 admin · F8 net · F9 wardrobe · F10 dev ·
F11 fullscreen · Enter chat.
