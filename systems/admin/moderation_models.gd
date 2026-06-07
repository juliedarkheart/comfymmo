extends RefCounted
class_name ModerationModels

## Local, stubbed data models for a future family/friends MMO moderation layer.
## These are plain Dictionary builders + constants — no networking, no accounts, no
## persistence, no live UI. They exist so future admin tools have a stable shape to
## target. Nothing in gameplay calls these yet.

# --- Permission / role placeholders (least to most privileged is player..owner) ---
const ROLE_OWNER := "owner"
const ROLE_ADMIN := "admin"
const ROLE_MODERATOR := "moderator"
const ROLE_TRUSTED := "trusted"
const ROLE_PLAYER := "player"
const ROLES: Array[String] = [ROLE_PLAYER, ROLE_TRUSTED, ROLE_MODERATOR, ROLE_ADMIN, ROLE_OWNER]

# --- Admin action types ---
const ACTION_MUTE := "mute"
const ACTION_KICK := "kick"
const ACTION_BAN := "ban"
const ACTION_WARN := "warn"
const ACTION_DELETE_BUILD := "delete_build"
const ACTION_RESTORE_BUILD := "restore_build"
const ACTION_TYPES: Array[String] = [
	ACTION_MUTE, ACTION_KICK, ACTION_BAN, ACTION_WARN, ACTION_DELETE_BUILD, ACTION_RESTORE_BUILD,
]

static func make_report(
	reporter_id: String,
	target_player_id: String,
	reason: String,
	notes: String = "",
	world_area: String = "",
	position: Vector2 = Vector2.ZERO
) -> Dictionary:
	return {
		"reporter_id": reporter_id,
		"target_player_id": target_player_id,
		"reason": reason,
		"notes": notes,
		"world_area": world_area,
		"position": {"x": position.x, "y": position.y},
		"created_at": Time.get_unix_time_from_system(),
		"status": "open",
	}

static func make_admin_action(
	action_type: String,
	target_id: String,
	actor_admin_id: String,
	reason: String = ""
) -> Dictionary:
	return {
		"action_type": action_type,
		"target_id": target_id,
		"actor_admin_id": actor_admin_id,
		"reason": reason,
		"timestamp": Time.get_unix_time_from_system(),
	}

static func is_valid_role(role: String) -> bool:
	return role in ROLES

static func is_valid_action(action_type: String) -> bool:
	return action_type in ACTION_TYPES

## Placeholder authority check for future server-side enforcement. Locally it just
## compares role rank; a real implementation would run on an authoritative server.
static func role_rank(role: String) -> int:
	return ROLES.find(role)

static func can_moderate(actor_role: String, target_role: String) -> bool:
	if not is_valid_role(actor_role) or not is_valid_role(target_role):
		return false
	if role_rank(actor_role) < role_rank(ROLE_MODERATOR):
		return false
	return role_rank(actor_role) > role_rank(target_role)
