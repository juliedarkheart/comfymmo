extends RefCounted
class_name AdminPermissions

## Prototype role model (trust-based — see docs/admin_tools.md). Offline, the
## local player IS the owner of their world. On a server, roles live in the
## world save's "roles" map (profile_id -> role), edited by hand or future
## commands; the server checks registered identity (profile_id), never display
## names. No passwords exist, which is why this stays private-playtest only.

const ROLE_OWNER := "owner"
const ROLE_ADMIN := "admin"
const ROLE_BUILDER := "builder"
const ROLE_MODERATOR := "moderator"
const ROLE_PLAYER := "player"

const ROLES: Array[String] = [ROLE_OWNER, ROLE_ADMIN, ROLE_BUILDER, ROLE_MODERATOR, ROLE_PLAYER]

## Roles allowed to bypass build costs/tools/locks and shape protected land.
static func can_world_build(role: String) -> bool:
	return role == ROLE_OWNER or role == ROLE_ADMIN or role == ROLE_BUILDER

static func is_valid_role(role: String) -> bool:
	return ROLES.has(role)

## Offline single-player is always the owner of their own world.
static func offline_role() -> String:
	return ROLE_OWNER
