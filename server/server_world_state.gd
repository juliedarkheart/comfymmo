extends RefCounted
class_name ServerWorldState

## In-memory authoritative world state for the server: placed objects plus a
## tile occupancy index. Placement validation here is intentionally simpler
## than the offline map rules (occupancy + known content id + materials); the
## full terrain/footprint rules move server-side in a later milestone and are
## documented as a known limitation.

var world: Dictionary = {}
var _occupied: Dictionary = {}
var _next_instance: int = 1

static func from_world(world_data: Dictionary) -> ServerWorldState:
	var state: ServerWorldState = ServerWorldState.new()
	state.world = world_data
	for record in state.placed_objects():
		state._occupied[state._tile_key(int(record.get("tile_x", 0)), int(record.get("tile_y", 0)))] = true
		var instance_id: String = String(record.get("instance_id", ""))
		var suffix: String = instance_id.get_slice("_", instance_id.get_slice_count("_") - 1)
		if suffix.is_valid_int():
			state._next_instance = maxi(state._next_instance, int(suffix) + 1)
	return state

func placed_objects() -> Array:
	var raw: Variant = world.get("placed_objects", [])
	if typeof(raw) != TYPE_ARRAY:
		return []
	return raw as Array

func is_tile_free(tile_x: int, tile_y: int) -> bool:
	return not _occupied.has(_tile_key(tile_x, tile_y))

func add_placed_object(content_id: String, tile_x: int, tile_y: int, owner_profile_id: String, owner_display_name: String) -> Dictionary:
	if not is_tile_free(tile_x, tile_y):
		return {}
	var record: Dictionary = NetworkMessages.build_placed_object(
		"srv_%06d" % _next_instance, content_id, Vector2i(tile_x, tile_y), owner_profile_id, owner_display_name
	)
	_next_instance += 1
	placed_objects().append(record)
	_occupied[_tile_key(tile_x, tile_y)] = true
	return record

func get_known_profile(profile_id: String) -> Dictionary:
	var profiles: Variant = world.get("known_profiles", {})
	if typeof(profiles) != TYPE_DICTIONARY or profile_id.is_empty():
		return {}
	var entry: Variant = (profiles as Dictionary).get(profile_id, {})
	if typeof(entry) != TYPE_DICTIONARY:
		return {}
	return entry as Dictionary

func remember_profile(player: ServerPlayerState) -> void:
	if player.profile_id.is_empty():
		return
	var profiles: Dictionary = world.get("known_profiles", {}) as Dictionary
	profiles[player.profile_id] = {
		"display_name": player.display_name,
		"materials": player.materials.to_dictionary(),
		"last_seen_at": Time.get_datetime_string_from_system(true),
	}
	world["known_profiles"] = profiles

func _tile_key(tile_x: int, tile_y: int) -> String:
	return "%d,%d" % [tile_x, tile_y]
