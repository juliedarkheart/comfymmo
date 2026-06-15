extends RefCounted
class_name ServerPlayerState

## Server-authoritative record of one connected player: identity (sanitized),
## session position, and the player's material pouch. Materials are persisted
## per profile_id into the world save's known_profiles cache so they survive
## reconnects and server restarts.

var peer_id: int = 0
var profile_id: String = ""
var username: String = "villager"
var display_name: String = "Villager"
var appearance: Dictionary = {}
var position: Vector2 = Vector2.ZERO
var materials: MaterialInventory = MaterialInventory.new()
# Full progression dict ({total_xp, skills}); see SkillProgression.
var progression: Dictionary = SkillProgression.default_progression()

static func create(target_peer_id: int, identity: Dictionary, starting_materials: MaterialInventory) -> ServerPlayerState:
	var state: ServerPlayerState = ServerPlayerState.new()
	state.peer_id = target_peer_id
	state.profile_id = String(identity.get("profile_id", ""))
	state.username = String(identity.get("username", "villager"))
	state.display_name = String(identity.get("display_name", "Villager"))
	state.appearance = identity.get("appearance", {}) as Dictionary
	state.materials = starting_materials
	return state

## Public shape broadcast to other clients (no materials — those are private).
func to_public_dict() -> Dictionary:
	return {
		"peer_id": peer_id,
		"display_name": display_name,
		"appearance": appearance,
		"position_x": position.x,
		"position_y": position.y,
	}
