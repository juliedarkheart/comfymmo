extends RefCounted
class_name NetworkMessages

## Wire-format reference and record builders for the Hearthvale prototype
## protocol. The actual transport is Godot high-level multiplayer RPCs on the
## NetworkSession autoload; this file documents/builds the dictionary payloads
## so client, server, and persistence agree on shape.
##
## Messages (all dictionaries):
## - join_request:       {profile_id, display_name, appearance}
## - world_snapshot:     {world_id, placed_objects: [placed_object], players: [player_public], materials}
## - player_joined:      {peer_id, display_name, appearance, position_x, position_y}
## - player_left:        {peer_id}
## - sync_positions:     {peer_id(int as key string): [x, y]}
## - request_place:      {object_id, tile_x, tile_y}
## - placement_committed: placed_object (below)
## - place_denied:       {reason}
## - materials_update:   {material_id: count}
##
## placed_object (also the server save record):
## {instance_id, content_id, tile_x, tile_y, owner_profile_id,
##  owner_display_name, placed_at}

static func build_placed_object(instance_id: String, content_id: String, tile: Vector2i, owner_profile_id: String, owner_display_name: String) -> Dictionary:
	return {
		"instance_id": instance_id,
		"content_id": content_id,
		"tile_x": tile.x,
		"tile_y": tile.y,
		"owner_profile_id": owner_profile_id,
		"owner_display_name": owner_display_name,
		"placed_at": Time.get_datetime_string_from_system(true),
	}

static func is_valid_placed_object(record: Dictionary) -> bool:
	return (
		not String(record.get("instance_id", "")).is_empty()
		and not String(record.get("content_id", "")).is_empty()
		and record.has("tile_x")
		and record.has("tile_y")
	)
