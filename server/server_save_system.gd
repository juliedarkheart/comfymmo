extends RefCounted
class_name ServerSaveSystem

## Persistent world storage for the dedicated server, fully separate from the
## single-player save (user://homestead_save.json). One JSON file per world
## under user://server_worlds/. Saved on every committed placement and on
## player join/leave (profile cache), so a server restart loses nothing.

const WORLD_DIR := "user://server_worlds"

var world_name: String = "default_world"

func _init(target_world_name: String = "default_world") -> void:
	if not target_world_name.is_empty():
		world_name = target_world_name

func world_path() -> String:
	return "%s/%s.json" % [WORLD_DIR, world_name]

func load_world() -> Dictionary:
	DirAccess.make_dir_recursive_absolute(WORLD_DIR)
	if not FileAccess.file_exists(world_path()):
		var default_world: Dictionary = create_default_world(world_name)
		save_world(default_world)
		return default_world

	var file: FileAccess = FileAccess.open(world_path(), FileAccess.READ)
	if file == null:
		return create_default_world(world_name)

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Server world file unreadable, starting fresh: %s" % world_path())
		return create_default_world(world_name)
	return normalize_world(parsed as Dictionary)

func save_world(world: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(WORLD_DIR)
	world["updated_at"] = Time.get_datetime_string_from_system(true)
	var file: FileAccess = FileAccess.open(world_path(), FileAccess.WRITE)
	if file == null:
		push_warning("Unable to write server world file: %s" % world_path())
		return
	file.store_string(JSON.stringify(world, "\t"))

static func create_default_world(target_world_name: String) -> Dictionary:
	var now: String = Time.get_datetime_string_from_system(true)
	return {
		"world_id": target_world_name,
		"created_at": now,
		"updated_at": now,
		"placed_objects": [],
		"world_flags": {},
		# Cache of previously seen players keyed by profile_id: display name and
		# materials, so materials survive reconnects/restarts. No secrets.
		"known_profiles": {},
	}

## Defensive shape repair so a hand-edited or older world file always loads.
static func normalize_world(world: Dictionary) -> Dictionary:
	var normalized: Dictionary = create_default_world(String(world.get("world_id", "default_world")))
	normalized["created_at"] = String(world.get("created_at", normalized["created_at"]))
	normalized["updated_at"] = String(world.get("updated_at", normalized["updated_at"]))
	if typeof(world.get("world_flags")) == TYPE_DICTIONARY:
		normalized["world_flags"] = world["world_flags"]
	if typeof(world.get("known_profiles")) == TYPE_DICTIONARY:
		normalized["known_profiles"] = world["known_profiles"]
	var placed: Array = []
	if typeof(world.get("placed_objects")) == TYPE_ARRAY:
		for record in (world["placed_objects"] as Array):
			if typeof(record) == TYPE_DICTIONARY and NetworkMessages.is_valid_placed_object(record as Dictionary):
				placed.append(record)
	normalized["placed_objects"] = placed
	return normalized
