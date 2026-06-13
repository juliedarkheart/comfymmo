extends RefCounted
class_name CraftingSystem

## Shared craft validation/execution, used by BOTH sides:
## - Offline: against the player's InventorySystem (items auto-save on change).
## - Server:  against a player's MaterialInventory pouch (NetworkSession).
## The check/spend/grant rules are identical so client preview ("can I craft
## this?") and server authority can never disagree about a recipe.

## Pure check. `get_count` is a Callable(item_id) -> int over whichever store
## applies; `skill_levels` is {skill_id: level} (empty = no skill gating).
## Returns {ok: bool, reason: String}.
static func check(recipe_id: String, get_count: Callable, level: int, nearby_station_ids: Array, skill_levels: Dictionary = {}) -> Dictionary:
	var recipe: Dictionary = CraftingRegistry.get_recipe(recipe_id)
	if recipe.is_empty():
		return {"ok": false, "reason": "Unknown recipe"}
	if level < int(recipe.get("required_level", 1)):
		return {"ok": false, "reason": "Requires Player Level %d" % int(recipe.get("required_level", 1))}
	var skill_lock_reason: String = ProgressionRegistry.lock_reason(
		{
			"required_skill": recipe.get("required_skill", ""),
			"required_skill_level": recipe.get("required_skill_level", 1),
		},
		level, skill_levels
	)
	if not skill_lock_reason.is_empty():
		return {"ok": false, "reason": skill_lock_reason}
	var station: String = String(recipe.get("required_station", ""))
	if not station.is_empty() and not nearby_station_ids.has(station):
		return {"ok": false, "reason": "Requires %s nearby" % _station_label(station)}
	var inputs: Dictionary = recipe.get("inputs", {}) as Dictionary
	for input_id in inputs.keys():
		var needed: int = int(inputs[input_id])
		if int(get_count.call(String(input_id))) < needed:
			return {"ok": false, "reason": "Need %s" % CraftingRegistry.inputs_text(recipe)}
	return {"ok": true, "reason": ""}

## Offline craft against an InventorySystem. Returns
## {ok, reason, output_id, output_amount, xp_reward, display_name}.
static func craft_with_inventory(recipe_id: String, inventory: InventorySystem, level: int, nearby_station_ids: Array, skill_levels: Dictionary = {}) -> Dictionary:
	var result: Dictionary = check(recipe_id, inventory.get_quantity, level, nearby_station_ids, skill_levels)
	if not bool(result["ok"]):
		return result
	var recipe: Dictionary = CraftingRegistry.get_recipe(recipe_id)
	var inputs: Dictionary = recipe.get("inputs", {}) as Dictionary
	for input_id in inputs.keys():
		if not inventory.remove_item(String(input_id), int(inputs[input_id])):
			return {"ok": false, "reason": "Need %s" % CraftingRegistry.inputs_text(recipe)}
	inventory.add_item(String(recipe["output_id"]), int(recipe["output_amount"]))
	return _success_result(recipe)

## Server craft against a MaterialInventory pouch. Crop-item inputs are also
## held in the pouch server-side? No — the server pouch only stores storables,
## so server recipes with crop inputs check the pouch and will report "Need…"
## until crop sync exists. Documented limitation in docs/crafting.md.
static func craft_with_pouch(recipe_id: String, pouch: MaterialInventory, level: int, nearby_station_ids: Array, skill_levels: Dictionary = {}) -> Dictionary:
	var result: Dictionary = check(recipe_id, pouch.get_count, level, nearby_station_ids, skill_levels)
	if not bool(result["ok"]):
		return result
	var recipe: Dictionary = CraftingRegistry.get_recipe(recipe_id)
	if not pouch.spend(recipe.get("inputs", {}) as Dictionary):
		return {"ok": false, "reason": "Need %s" % CraftingRegistry.inputs_text(recipe)}
	pouch.add(String(recipe["output_id"]), int(recipe["output_amount"]))
	return _success_result(recipe)

static func _success_result(recipe: Dictionary) -> Dictionary:
	return {
		"ok": true,
		"reason": "",
		"output_id": String(recipe["output_id"]),
		"output_amount": int(recipe["output_amount"]),
		"xp_reward": int(recipe.get("xp_reward", 0)),
		"display_name": String(recipe.get("display_name", "")),
	}

static func _station_label(station_id: String) -> String:
	var entry: Dictionary = ContentRegistry.placeables().get(station_id, {}) as Dictionary
	return String(entry.get("display_name", station_id.capitalize()))
