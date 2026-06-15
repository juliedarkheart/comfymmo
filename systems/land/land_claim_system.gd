extends RefCounted
class_name LandClaimSystem

## Pure claim + build-permission logic shared by the offline controller and
## the server (same pattern as CraftingSystem: one rulebook, two stores).
## `plots_state` is {plot_id: LandPlot state dict}; persistence wraps it.

const CLAIM_COST_ITEM := "land_token"

## Build permission for a tile. Returns {allowed: bool, reason: String}.
static func can_build_at(tile: Vector2i, profile_id: String, plots_state: Dictionary, is_admin: bool = false) -> Dictionary:
	if is_admin:
		return {"allowed": true, "reason": ""}
	var plot: Dictionary = LandRegistry.plot_at_tile(tile)
	if plot.is_empty():
		return {"allowed": true, "reason": ""}  # public commons / tutorial zone
	if bool(plot.get("tutorial_build", false)):
		return {"allowed": true, "reason": ""}  # Rowan's training land
	var plot_id: String = String(plot["plot_id"])
	var state: Dictionary = LandPlot.normalized_state(plots_state.get(plot_id, {}) as Dictionary)
	match String(state["status"]):
		LandPlot.STATUS_UNCLAIMED:
			return {"allowed": false, "reason": "Claim %s before building here" % String(plot["display_name"])}
		LandPlot.STATUS_OWNED:
			if LandPlot.profile_can_build(state, profile_id):
				return {"allowed": true, "reason": ""}
			return {"allowed": false, "reason": "This is %s's plot" % String(state["owner_username"])}
		_:
			return {"allowed": false, "reason": "You do not have build permission here"}

## Attempt a claim. `has_token`/`spend_token` are Callables over whichever
## inventory applies. Returns {ok, reason, state} (state = new plot state).
static func attempt_claim(plot_id: String, profile_id: String, username: String, plots_state: Dictionary, has_token: Callable, spend_token: Callable) -> Dictionary:
	var plot: Dictionary = LandRegistry.get_plot(plot_id)
	if plot.is_empty():
		return {"ok": false, "reason": "Unknown plot"}
	if not bool(plot.get("claimable", false)):
		return {"ok": false, "reason": "This land cannot be claimed"}
	var state: Dictionary = LandPlot.normalized_state(plots_state.get(plot_id, {}) as Dictionary)
	if String(state["status"]) == LandPlot.STATUS_OWNED:
		if String(state["owner_profile_id"]) == profile_id:
			return {"ok": false, "reason": "You already own this plot"}
		return {"ok": false, "reason": "This plot belongs to %s" % String(state["owner_username"])}
	var price: int = int(plot.get("price_tokens", 1))
	if price > 0 and not bool(has_token.call(CLAIM_COST_ITEM, price)):
		return {"ok": false, "reason": "You need a Land Token (finish Rowan's tutorial or ask an admin)"}
	if price > 0:
		spend_token.call(CLAIM_COST_ITEM, price)
	state["status"] = LandPlot.STATUS_OWNED
	state["owner_profile_id"] = profile_id
	state["owner_username"] = username
	state["claimed_at"] = Time.get_datetime_string_from_system(true)
	return {"ok": true, "reason": "", "state": state}

## Owner adds a friend as a plot member (shared building). Only the plot OWNER
## may invite; the target's profile_id must resolve (registered on the server).
## Returns {ok, reason, state} with the updated plot state.
static func attempt_invite(plot_id: String, requester_profile_id: String, target_profile_id: String, target_username: String, plots_state: Dictionary) -> Dictionary:
	var plot: Dictionary = LandRegistry.get_plot(plot_id)
	if plot.is_empty() or not bool(plot.get("claimable", false)):
		return {"ok": false, "reason": "That land has no owner to invite to"}
	var state: Dictionary = LandPlot.normalized_state(plots_state.get(plot_id, {}) as Dictionary)
	if String(state["status"]) != LandPlot.STATUS_OWNED or String(state["owner_profile_id"]) != requester_profile_id:
		return {"ok": false, "reason": "Only the plot owner can invite friends"}
	if target_profile_id.is_empty():
		return {"ok": false, "reason": "No player named @%s is registered here" % target_username}
	if target_profile_id == requester_profile_id:
		return {"ok": false, "reason": "You already own this plot"}
	var members: Array = state["member_profile_ids"]
	if members.has(target_profile_id):
		return {"ok": false, "reason": "@%s can already build here" % target_username}
	members.append(target_profile_id)
	state["member_profile_ids"] = members
	return {"ok": true, "reason": "", "state": state}

## One-line plot status for markers/boards (now includes member count).
static func describe(plot_id: String, plots_state: Dictionary) -> String:
	var plot: Dictionary = LandRegistry.get_plot(plot_id)
	if plot.is_empty():
		return "Unknown plot"
	if bool(plot.get("npc_owned", false)):
		return "%s — Farmer Rowan's land (not claimable)" % String(plot["display_name"])
	var state: Dictionary = LandPlot.normalized_state(plots_state.get(plot_id, {}) as Dictionary)
	if String(state["status"]) == LandPlot.STATUS_OWNED:
		var member_count: int = (state["member_profile_ids"] as Array).size()
		var members_suffix: String = "" if member_count == 0 else " (+%d friend%s)" % [member_count, "" if member_count == 1 else "s"]
		return "%s — owned by %s%s" % [String(plot["display_name"]), String(state["owner_username"]), members_suffix]
	return "%s — available (price: %d Land Token)" % [String(plot["display_name"]), int(plot.get("price_tokens", 1))]
