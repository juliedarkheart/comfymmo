extends RefCounted
class_name LandPlot

## Plot data model + normalization. A plot is a tile rectangle on the
## buildable grid with ownership/permission state. Static definitions live in
## LandRegistry; runtime ownership state is a small dict persisted offline
## (overworld flags) and server-side (world save "plots").

const STATUS_UNCLAIMED := "unclaimed"
const STATUS_RESERVED := "reserved"
const STATUS_OWNED := "owned"
const STATUS_PUBLIC := "public"
const STATUS_NPC_OWNED := "npc_owned"
const STATUS_ADMIN_LOCKED := "admin_locked"

const STATUSES: Array[String] = [
	STATUS_UNCLAIMED, STATUS_RESERVED, STATUS_OWNED,
	STATUS_PUBLIC, STATUS_NPC_OWNED, STATUS_ADMIN_LOCKED,
]

# Prototype permission roles on a plot (member arrays are scaffolded now,
# managed via future invite flow — see docs/land_ownership.md).
const ROLE_OWNER := "owner"
const ROLE_CO_OWNER := "co_owner"
const ROLE_BUILDER := "builder"
const ROLE_VISITOR := "visitor"

## Runtime ownership record (one per plot id, stored in the plots state dict).
static func default_state() -> Dictionary:
	return {
		"status": STATUS_UNCLAIMED,
		"owner_profile_id": "",
		"owner_username": "",
		"member_profile_ids": [],
		"claimed_at": "",
	}

static func normalized_state(data: Dictionary) -> Dictionary:
	var result: Dictionary = default_state()
	if data.is_empty():
		return result
	var status: String = String(data.get("status", STATUS_UNCLAIMED))
	result["status"] = status if STATUSES.has(status) else STATUS_UNCLAIMED
	result["owner_profile_id"] = String(data.get("owner_profile_id", ""))
	result["owner_username"] = String(data.get("owner_username", ""))
	result["claimed_at"] = String(data.get("claimed_at", ""))
	var members: Variant = data.get("member_profile_ids", [])
	if typeof(members) == TYPE_ARRAY:
		result["member_profile_ids"] = members
	return result

## True when this profile may build on a plot with the given state.
static func profile_can_build(state: Dictionary, profile_id: String) -> bool:
	var normalized: Dictionary = normalized_state(state)
	if String(normalized["status"]) != STATUS_OWNED:
		return false
	if String(normalized["owner_profile_id"]) == profile_id:
		return true
	return (normalized["member_profile_ids"] as Array).has(profile_id)
