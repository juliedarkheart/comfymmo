extends Node
class_name LocalSaveSystem

const HOMESTEAD_SAVE_PATH: String = "user://homestead_save.json"
const CURRENT_SAVE_VERSION: int = 3
const DEFAULT_REGION_ID: String = "homestead"
const DEFAULT_MOOD: String = "morning"
const DEFAULT_DAY_COUNT: int = 1

func get_current_region_id() -> String:
	var save_data: Dictionary = load_save_data()
	var world_data: Dictionary = _get_dictionary_section(save_data, "world")
	return String(world_data.get("current_region_id", DEFAULT_REGION_ID))

func set_current_region_id(region_id: String) -> void:
	if region_id.is_empty():
		return

	var save_data: Dictionary = load_save_data()
	var world_data: Dictionary = _get_dictionary_section(save_data, "world")
	world_data["current_region_id"] = region_id
	save_data["world"] = world_data
	save_save_data(save_data)

func get_current_mood() -> String:
	var save_data: Dictionary = load_save_data()
	var world_data: Dictionary = _get_dictionary_section(save_data, "world")
	var global_flags: Dictionary = _get_dictionary_section(world_data, "global_flags")
	return String(global_flags.get("current_mood", DEFAULT_MOOD))

func set_current_mood(mood_id: String) -> void:
	if mood_id.is_empty():
		return

	var save_data: Dictionary = load_save_data()
	var world_data: Dictionary = _get_dictionary_section(save_data, "world")
	var global_flags: Dictionary = _get_dictionary_section(world_data, "global_flags")
	global_flags["current_mood"] = mood_id
	world_data["global_flags"] = global_flags
	save_data["world"] = world_data
	save_save_data(save_data)

func get_day_count() -> int:
	var save_data: Dictionary = load_save_data()
	var world_data: Dictionary = _get_dictionary_section(save_data, "world")
	var global_flags: Dictionary = _get_dictionary_section(world_data, "global_flags")
	return int(global_flags.get("day_count", DEFAULT_DAY_COUNT))

func set_day_count(day_count: int) -> void:
	var clamped_day_count: int = maxi(1, day_count)
	var save_data: Dictionary = load_save_data()
	var world_data: Dictionary = _get_dictionary_section(save_data, "world")
	var global_flags: Dictionary = _get_dictionary_section(world_data, "global_flags")
	global_flags["day_count"] = clamped_day_count
	world_data["global_flags"] = global_flags
	save_data["world"] = world_data
	save_save_data(save_data)

func load_save_data() -> Dictionary:
	if not FileAccess.file_exists(HOMESTEAD_SAVE_PATH):
		return _create_default_save_data()

	var save_file: FileAccess = FileAccess.open(HOMESTEAD_SAVE_PATH, FileAccess.READ)
	if save_file == null:
		return _create_default_save_data()

	var parsed: Variant = JSON.parse_string(save_file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return _create_default_save_data()

	var save_data: Dictionary = parsed
	return _migrate_save_data(save_data)

func load_homestead_objects() -> Array[Dictionary]:
	return load_region_objects(DEFAULT_REGION_ID)

func load_region_objects(region_id: String) -> Array[Dictionary]:
	var save_data: Dictionary = load_save_data()
	var region_data: Dictionary = load_region_data(region_id, save_data)
	var placed_objects: Variant = region_data.get("placed_objects", [])
	if typeof(placed_objects) != TYPE_ARRAY:
		return []

	var results: Array[Dictionary] = []
	for placed_object in placed_objects:
		if typeof(placed_object) == TYPE_DICTIONARY:
			results.append(placed_object)
	return results

func save_homestead_objects(placed_objects: Array[Dictionary]) -> void:
	save_region_objects(DEFAULT_REGION_ID, placed_objects)

func save_region_objects(region_id: String, placed_objects: Array[Dictionary]) -> void:
	var save_data: Dictionary = load_save_data()
	var region_data: Dictionary = load_region_data(region_id, save_data)
	region_data["placed_objects"] = placed_objects
	_set_region_data(region_id, region_data, save_data)
	save_save_data(save_data)

func load_region_data(region_id: String, save_data: Dictionary = {}) -> Dictionary:
	var resolved_save_data: Dictionary = save_data if not save_data.is_empty() else load_save_data()
	var world_data: Dictionary = _get_dictionary_section(resolved_save_data, "world")
	var regions_data: Dictionary = _get_dictionary_section(world_data, "regions")
	if not regions_data.has(region_id):
		return _create_default_region_data()

	var region_value: Variant = regions_data.get(region_id, {})
	if typeof(region_value) != TYPE_DICTIONARY:
		return _create_default_region_data()

	return _merge_region_data(region_value as Dictionary)

func get_region_state(region_id: String) -> Dictionary:
	return load_region_data(region_id)

func ensure_region_state(region_id: String) -> Dictionary:
	if region_id.is_empty():
		return _create_default_region_data()

	var save_data: Dictionary = load_save_data()
	var region_data: Dictionary = load_region_data(region_id, save_data)
	_set_region_data(region_id, region_data, save_data)
	save_save_data(save_data)
	return region_data

func get_region_placed_objects(region_id: String) -> Array[Dictionary]:
	return load_region_objects(region_id)

func set_region_placed_objects(region_id: String, placed_objects: Array[Dictionary]) -> void:
	save_region_objects(region_id, placed_objects)

func get_region_farming(region_id: String) -> Dictionary:
	var region_data: Dictionary = load_region_data(region_id)
	var farming_data: Variant = region_data.get("farming", {})
	if typeof(farming_data) != TYPE_DICTIONARY:
		return {}

	return farming_data as Dictionary

func set_region_farming(region_id: String, farming_state: Dictionary) -> void:
	var save_data: Dictionary = load_save_data()
	var region_data: Dictionary = load_region_data(region_id, save_data)
	region_data["farming"] = farming_state
	_set_region_data(region_id, region_data, save_data)
	save_save_data(save_data)

func get_region_flags(region_id: String) -> Dictionary:
	var region_data: Dictionary = load_region_data(region_id)
	var region_flags: Variant = region_data.get("region_flags", {})
	if typeof(region_flags) != TYPE_DICTIONARY:
		return {}

	return region_flags as Dictionary

func set_region_flag(region_id: String, key: String, value: Variant) -> void:
	if region_id.is_empty() or key.is_empty():
		return

	var save_data: Dictionary = load_save_data()
	var region_data: Dictionary = load_region_data(region_id, save_data)
	var region_flags: Dictionary = {}
	var raw_flags: Variant = region_data.get("region_flags", {})
	if typeof(raw_flags) == TYPE_DICTIONARY:
		region_flags = raw_flags as Dictionary

	region_flags[key] = value
	region_data["region_flags"] = region_flags
	_set_region_data(region_id, region_data, save_data)
	save_save_data(save_data)

func save_save_data(save_data: Dictionary) -> void:
	var payload: Dictionary = _migrate_save_data(save_data)
	var save_file: FileAccess = FileAccess.open(HOMESTEAD_SAVE_PATH, FileAccess.WRITE)
	if save_file == null:
		push_warning("Unable to open save file: %s" % HOMESTEAD_SAVE_PATH)
		return

	save_file.store_string(JSON.stringify(payload, "\t"))

func _migrate_save_data(save_data: Dictionary) -> Dictionary:
	var migrated_data: Dictionary = _create_default_save_data()

	var legacy_world_data: Dictionary = _get_dictionary_section(save_data, "world")
	var legacy_region_data: Dictionary = _create_default_region_data()
	var legacy_homestead_data: Dictionary = _get_dictionary_section(save_data, "homestead")

	if save_data.has("placed_objects"):
		legacy_region_data["placed_objects"] = _sanitize_placed_objects(save_data.get("placed_objects", []))
		var migrated_world_data: Dictionary = _get_dictionary_section(migrated_data, "world")
		var migrated_regions_data: Dictionary = _get_dictionary_section(migrated_world_data, "regions")
		migrated_regions_data[DEFAULT_REGION_ID] = legacy_region_data
		migrated_world_data["regions"] = migrated_regions_data
		migrated_data["world"] = migrated_world_data
		return migrated_data

	if not legacy_homestead_data.is_empty():
		legacy_region_data["placed_objects"] = _sanitize_placed_objects(
			legacy_homestead_data.get("placed_objects", [])
		)

	if legacy_world_data.has("farming"):
		var legacy_farming: Variant = legacy_world_data.get("farming", {})
		if typeof(legacy_farming) == TYPE_DICTIONARY:
			legacy_region_data["farming"] = legacy_farming as Dictionary

	if legacy_world_data.has("interactables"):
		var legacy_interactables: Variant = legacy_world_data.get("interactables", {})
		if typeof(legacy_interactables) == TYPE_DICTIONARY:
			legacy_region_data["interactables"] = legacy_interactables as Dictionary

	if legacy_world_data.has("region_flags"):
		var legacy_region_flags: Variant = legacy_world_data.get("region_flags", {})
		if typeof(legacy_region_flags) == TYPE_DICTIONARY:
			legacy_region_data["region_flags"] = legacy_region_flags as Dictionary

	var world_data: Dictionary = legacy_world_data
	var player_data: Dictionary = _get_dictionary_section(save_data, "player")
	var tasks_data: Dictionary = _get_dictionary_section(save_data, "tasks")

	var regions_data: Dictionary = _get_dictionary_section(world_data, "regions")
	var normalized_regions_data: Dictionary = {}
	for region_id_variant in regions_data.keys():
		var region_id: String = String(region_id_variant)
		var region_value: Variant = regions_data.get(region_id_variant, {})
		if typeof(region_value) == TYPE_DICTIONARY:
			normalized_regions_data[region_id] = _merge_region_data(region_value as Dictionary)

	normalized_regions_data[DEFAULT_REGION_ID] = _merge_region_data(
		normalized_regions_data.get(DEFAULT_REGION_ID, legacy_region_data) as Dictionary
	)

	var current_region_id: String = String(
		world_data.get("current_region_id", world_data.get("current_world_id", DEFAULT_REGION_ID))
	)
	migrated_data["world"] = world_data
	migrated_data["world"]["current_region_id"] = current_region_id
	migrated_data["world"]["regions"] = normalized_regions_data
	migrated_data["player"] = player_data
	migrated_data["tasks"] = tasks_data
	migrated_data["save_version"] = CURRENT_SAVE_VERSION
	return migrated_data

func _create_default_save_data() -> Dictionary:
	return {
		"save_version": CURRENT_SAVE_VERSION,
		"world": {
			"current_region_id": DEFAULT_REGION_ID,
			"regions": {
				"homestead": _create_default_region_data(),
				"village_square": _create_default_region_data(),
				"forest_edge": _create_default_region_data(),
			},
			"creatures": {
				"creatures": [],
			},
			"dungeons": {
				"active_dungeon_id": "",
			},
			"global_flags": {
				"current_mood": DEFAULT_MOOD,
				"day_count": DEFAULT_DAY_COUNT,
			},
		},
		"player": {
			"inventory": {
				"items": {},
			},
			"survival": {
				"energy": 100.0,
				"hunger": 100.0,
				"comfort": 50.0,
			},
		},
		"tasks": {
			"integration": {
				"mock_tasks": [],
				"mailbox_message_state": {},
			},
		},
	}

func _sanitize_placed_objects(placed_objects: Variant) -> Array[Dictionary]:
	var sanitized_objects: Array[Dictionary] = []
	if typeof(placed_objects) != TYPE_ARRAY:
		return sanitized_objects

	for placed_object in placed_objects:
		if typeof(placed_object) == TYPE_DICTIONARY:
			sanitized_objects.append(placed_object)
	return sanitized_objects

func _get_dictionary_section(container: Dictionary, section_name: String) -> Dictionary:
	if not container.has(section_name):
		return {}

	var section_value: Variant = container.get(section_name, {})
	if typeof(section_value) != TYPE_DICTIONARY:
		return {}

	return section_value as Dictionary

func _set_region_data(region_id: String, region_data: Dictionary, save_data: Dictionary) -> void:
	var world_data: Dictionary = _get_dictionary_section(save_data, "world")
	var regions_data: Dictionary = _get_dictionary_section(world_data, "regions")
	regions_data[region_id] = _merge_region_data(region_data)
	world_data["regions"] = regions_data
	save_data["world"] = world_data

func _create_default_region_data() -> Dictionary:
	return {
		"placed_objects": [],
		"farming": {
			"plots": {},
		},
		"interactables": {},
		"region_flags": {},
	}

func _merge_region_data(region_data: Dictionary) -> Dictionary:
	var merged_region_data: Dictionary = _create_default_region_data()
	merged_region_data["placed_objects"] = _sanitize_placed_objects(region_data.get("placed_objects", []))

	var farming_data: Variant = region_data.get("farming", {})
	if typeof(farming_data) == TYPE_DICTIONARY:
		merged_region_data["farming"] = farming_data as Dictionary

	var interactables_data: Variant = region_data.get("interactables", {})
	if typeof(interactables_data) == TYPE_DICTIONARY:
		merged_region_data["interactables"] = interactables_data as Dictionary

	var region_flags_data: Variant = region_data.get("region_flags", {})
	if typeof(region_flags_data) == TYPE_DICTIONARY:
		merged_region_data["region_flags"] = region_flags_data as Dictionary

	return merged_region_data
