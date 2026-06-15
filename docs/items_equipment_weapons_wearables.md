# Item taxonomy: tools, weapons, wearables

`systems/items/item_ids.gd` is the single taxonomy (the suggested
tools/items/registry trio folded into one file). Categories: material,
component, tool, weapon, wearable, quest_item, placeable. Everything is an
inventory/pouch item — persistence inherited, `/give` works for all of it,
ids validated unique across every category.

## Tools (gameplay NOW)

worn_axe, worn_pickaxe, worn_hoe, watering_can, simple_hammer, basic_shovel —
see docs/tools_and_equipment.md.

## Weapons (future-combat placeholders)

wooden_staff (2 planks + rope), practice_sword (2 planks) — craftable at the
workbench, held in inventory, zero combat behavior. They exist so the
dungeon/combat milestone has item plumbing waiting.

## Wearables (cosmetic unlock tokens)

wearable_leaf_clip (1 fiber, hand), wearable_acorn_cap (garden table) — each
maps to an existing appearance accessory id. **Current honest behavior:** the
wardrobe does not yet gate accessories on owning the wearable; crafting one
is a collectible token. Gating the wardrobe option list on owned wearables is
the documented next step (the mapping `ItemIds.wearable_accessory()` is
already validated against the appearance registry).

## Quest items

land_token — spent to claim a neighborhood plot (docs/land_ownership.md).
