# Alpha 0.1 — First Art Target List

The first concrete batch of art to replace the procedural placeholders, region by
region. Each target maps to existing in-engine content so swaps are drop-in. Status
legend: ☐ not started · ◐ generating/cleanup · ☑ in-engine.

Priorities: **P0** = visible everywhere / highest readability impact (tiles, key
landmarks), **P1** = frequently seen, **P2** = nice-to-have polish.

## Homestead

| Target | Prompt source | Format / size | In-engine ref | Pri | Status |
|---|---|---|---|---|---|
| Grass tile (2–3 variants) | terrain_tiles.md | tile PNG 128×64 | `homestead_map` ground | P0 | ☐ |
| Dirt path tile | terrain_tiles.md | tile PNG 128×64 | path rows / connecting roads | P0 | ☐ |
| Cottage exterior | buildings.md | RGBA, 2× (2×2 footprint) | `_add_building` cottage | P0 | ☐ |
| Mailbox | props.md (homestead) | RGBA prop ~96px | placeable `mailbox` | P1 | ☐ |
| Farm plot (soil + watered overlay) | crops.md | RGBA ~96px + overlay | `FarmPlot` soil states | P1 | ☐ |
| Carrot stages ×4 | crops.md | RGBA ~48–64px | `farming_system` carrot | P1 | ☐ |
| Turnip stages ×4 | crops.md | RGBA ~48–64px | turnip | P1 | ☐ |
| Berry stages ×4 | crops.md | RGBA ~48–64px | berry | P1 | ☐ |
| Stump turtle (sheet) | creatures.md | RGBA poses ~36px | `StumpTurtle` | P2 | ☐ |

## Village Square

| Target | Prompt source | Format / size | In-engine ref | Pri | Status |
|---|---|---|---|---|---|
| Plaza stone tile | terrain_tiles.md | tile PNG 128×64 | plaza disc area | P0 | ☐ |
| Fountain | props.md (village) | RGBA prop landmark | `_add_overworld_fountain` | P1 | ☐ |
| Notice board | props.md (village) | RGBA prop | notice marker | P1 | ☐ |
| Maribel (sheet) | villagers.md | RGBA views ~66px | `maribel_tock.tscn` | P1 | ☐ |
| Bram (sheet) | villagers.md | RGBA views ~66px | `bram_nettle.tscn` | P1 | ☐ |
| Flower beds | props.md (village) | RGBA prop | `_add_flower_bed` | P2 | ☐ |
| Market stall (placeholder) | buildings.md | RGBA prop/structure | future | P2 | ☐ |

## Forest Edge

| Target | Prompt source | Format / size | In-engine ref | Pri | Status |
|---|---|---|---|---|---|
| Forest grass tile | terrain_tiles.md | tile PNG 128×64 | forest ground | P0 | ☐ |
| Pine / leaf trees (2–3) | props.md (forest) | RGBA props, tall | `_add_overworld_pine` / decor trees | P0 | ☐ |
| Rocks (2 sizes) | props.md (forest) | RGBA props | `_add_rock` | P1 | ☐ |
| Mushrooms | props.md (forest) | RGBA prop | mushroom patches | P2 | ☐ |
| Shrine | buildings.md / props.md | RGBA landmark | shrine marker | P1 | ☐ |
| Creek + bridge | props.md (forest) + overworld_backgrounds.md | RGBA/strip | creek + `_add_bridge` | P2 | ☐ |
| Moss rabbit (sheet) | creatures.md | RGBA poses ~32px | `MossRabbit` | P1 | ☐ |
| Lantern moth (sheet) | creatures.md | RGBA poses ~28px | `LanternMoth` | P1 | ☐ |

## UI

| Target | Prompt source | Format / size | In-engine ref | Pri | Status |
|---|---|---|---|---|---|
| Mailbox icon | ui_icons.md | PNG 32 + 64 | new-mail signal | P1 | ☐ |
| Inventory icon | ui_icons.md | PNG 32 + 64 | inventory panel | P1 | ☐ |
| Comfort icon | ui_icons.md | PNG 32 + 64 | comfort stat | P1 | ☐ |
| Day / time icon | ui_icons.md | PNG 32 + 64 | mood/day HUD line | P1 | ☐ |
| Crop icons (carrot/turnip/berry) | ui_icons.md | PNG 32 + 64 | inventory counts | P1 | ☐ |

## Batch ordering (recommended)

1. **Terrain batch (P0):** grass, dirt path, plaza stone, forest grass — biggest
   readability win, validates the tile workflow end-to-end.
2. **Landmark batch (P0/P1):** cottage, fountain, shrine, pine trees — anchors each area.
3. **Character batch (P1):** Maribel, Bram, moss rabbit, lantern moth — life and warmth.
4. **Crop + UI batch (P1):** crop stages and the icon set — the interactive HUD layer.
5. **Polish batch (P2):** turtle, mushrooms, flower beds, creek/bridge, market stall.

Each batch: generate → clean → stage in `assets/import_staging/` → wire one item,
verify in-engine at game scale → roll the rest. Keep procedural placeholders as
fallback until a category is fully swapped.
