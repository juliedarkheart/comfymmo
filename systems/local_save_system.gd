extends Node
class_name LocalSaveSystem

const HOMESTEAD_SAVE_PATH: String = "user://homestead_save.json"
const CURRENT_SAVE_VERSION: int = 3
const DEFAULT_REGION_ID: String = "homestead"
const DEFAULT_MOOD: String = "morning"
const DEFAULT_DAY_COUNT: int = 1
const QUICKBAR_SLOT_COUNT: int = 9

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

# --- Continuous overworld state (forward-looking, additive) -------------------
# The continuous overworld is the main outdoor world. Its own global flags live
# under `world.overworld.flags`. For save compatibility the homestead farming and
# the village/forest seen-flags still live in their legacy `world.regions.*` paths
# (see the region helpers below and docs/save_data_model.md); these helpers are the
# clean home for NEW overworld-wide state. No migration is forced.

func get_overworld_state() -> Dictionary:
	var save_data: Dictionary = load_save_data()
	var world_data: Dictionary = _get_dictionary_section(save_data, "world")
	return _get_dictionary_section(world_data, "overworld")

func ensure_overworld_state() -> Dictionary:
	var save_data: Dictionary = load_save_data()
	var world_data: Dictionary = _get_dictionary_section(save_data, "world")
	var overworld_data: Dictionary = _get_dictionary_section(world_data, "overworld")
	if not overworld_data.has("flags"):
		overworld_data["flags"] = {}
	world_data["overworld"] = overworld_data
	save_data["world"] = world_data
	save_save_data(save_data)
	return overworld_data

func get_overworld_flags() -> Dictionary:
	var flags: Variant = get_overworld_state().get("flags", {})
	if typeof(flags) != TYPE_DICTIONARY:
		return {}
	return flags as Dictionary

func get_overworld_flag(key: String, default_value: Variant = null) -> Variant:
	if key.is_empty():
		return default_value
	return get_overworld_flags().get(key, default_value)

func set_overworld_flag(key: String, value: Variant) -> void:
	if key.is_empty():
		return

	var save_data: Dictionary = load_save_data()
	var world_data: Dictionary = _get_dictionary_section(save_data, "world")
	var overworld_data: Dictionary = _get_dictionary_section(world_data, "overworld")
	var flags: Dictionary = {}
	var raw_flags: Variant = overworld_data.get("flags", {})
	if typeof(raw_flags) == TYPE_DICTIONARY:
		flags = raw_flags as Dictionary
	flags[key] = value
	overworld_data["flags"] = flags
	world_data["overworld"] = overworld_data
	save_data["world"] = world_data
	save_save_data(save_data)

# --- Player appearance (additive, backward-compatible) ------------------------
# Stored under `player.appearance` as a dict of stable option ids (see
# CharacterAppearanceRegistry). Old saves simply lack the key and resolve to
# CharacterAppearance.default_appearance(); unknown ids normalize per-slot to
# defaults. No save version bump: the key is optional and migration passes the
# whole player section through untouched.

func get_player_appearance() -> Dictionary:
	var save_data: Dictionary = load_save_data()
	var player_data: Dictionary = _get_dictionary_section(save_data, "player")
	var raw_appearance: Variant = player_data.get("appearance", {})
	if typeof(raw_appearance) != TYPE_DICTIONARY:
		return CharacterAppearance.default_appearance()
	return CharacterAppearance.normalized(raw_appearance as Dictionary)

func set_player_appearance(appearance: Dictionary) -> void:
	var save_data: Dictionary = load_save_data()
	var player_data: Dictionary = _get_dictionary_section(save_data, "player")
	player_data["appearance"] = CharacterAppearance.normalized(appearance)
	save_data["player"] = player_data
	save_save_data(save_data)

# --- Player quickbar shortcuts (additive, backward-compatible) ----------------
# Inventory owns item counts. The quickbar stores item ids (or "" for empty slots)
# under player.quickbar and never removes/duplicates inventory items.

static func default_quickbar_slots() -> Array[String]:
	var slots: Array[String] = []
	for item_id in [
		ItemIds.TOOL_WORN_AXE,
		ItemIds.TOOL_WORN_PICKAXE,
		ItemIds.TOOL_WORN_HOE,
		ItemIds.TOOL_WATERING_CAN,
		ItemIds.TOOL_SIMPLE_HAMMER,
		ItemIds.TOOL_BASIC_SHOVEL,
	]:
		slots.append(String(item_id))
	while slots.size() < QUICKBAR_SLOT_COUNT:
		slots.append("")
	return slots

static func normalize_quickbar_slots(raw_slots: Variant) -> Array[String]:
	var slots: Array[String] = []
	var source: Array = raw_slots as Array if typeof(raw_slots) == TYPE_ARRAY else []
	for i in range(QUICKBAR_SLOT_COUNT):
		var item_id := ""
		if i < source.size():
			item_id = String(source[i]).strip_edges()
		if not item_id.is_empty() and not _is_valid_quickbar_item(item_id):
			item_id = ""
		slots.append(item_id)
	return slots

static func _is_valid_quickbar_item(item_id: String) -> bool:
	return item_id.is_empty() or ItemIds.is_storable(item_id) or ContentRegistry.items().has(item_id)

static func normalize_quickbar_selected_index(value: Variant) -> int:
	var index := int(value)
	return clampi(index, -1, QUICKBAR_SLOT_COUNT - 1)

func get_player_quickbar() -> Dictionary:
	var save_data: Dictionary = load_save_data()
	var player_data: Dictionary = _get_dictionary_section(save_data, "player")
	var raw_quickbar: Variant = player_data.get("quickbar", {})
	if typeof(raw_quickbar) != TYPE_DICTIONARY:
		return {
			"slots": default_quickbar_slots(),
			"selected_index": 0,
		}
	var quickbar := raw_quickbar as Dictionary
	if not quickbar.has("slots"):
		return {
			"slots": default_quickbar_slots(),
			"selected_index": 0,
		}
	return {
		"slots": normalize_quickbar_slots(quickbar.get("slots", [])),
		"selected_index": normalize_quickbar_selected_index(quickbar.get("selected_index", 0)),
	}

func set_player_quickbar(slots: Array, selected_index: int = -1) -> void:
	var save_data: Dictionary = load_save_data()
	var player_data: Dictionary = _get_dictionary_section(save_data, "player")
	player_data["quickbar"] = {
		"slots": normalize_quickbar_slots(slots),
		"selected_index": normalize_quickbar_selected_index(selected_index),
	}
	save_data["player"] = player_data
	save_save_data(save_data)

# --- Player progression (additive, backward-compatible) ------------------------
# Shape at `player.progression`: {total_xp, skills: {skill_id: xp}} — see
# SkillProgression. Reads normalize any stored shape, including the earlier
# flat `{xp: N}` (migrates into total_xp) and missing keys (level 1, all
# skills 0). No version bump; migration passes `player` through untouched.

func get_player_progression() -> Dictionary:
	var save_data: Dictionary = load_save_data()
	var player_data: Dictionary = _get_dictionary_section(save_data, "player")
	return SkillProgression.normalized(_get_dictionary_section(player_data, "progression"))

func get_player_xp() -> int:
	return int(get_player_progression()["total_xp"])

## Grants skill + total XP in one write. Returns SkillProgression.grant's
## result (level-up flags included) so callers can toast level-ups.
func grant_player_xp(skill_id: String, skill_xp: int, total_xp: int) -> Dictionary:
	var save_data: Dictionary = load_save_data()
	var player_data: Dictionary = _get_dictionary_section(save_data, "player")
	var grant_result: Dictionary = SkillProgression.grant(
		_get_dictionary_section(player_data, "progression"), skill_id, skill_xp, total_xp
	)
	player_data["progression"] = grant_result["progression"]
	save_data["player"] = player_data
	save_save_data(save_data)
	return grant_result

## Legacy helper kept for compatibility: plain total XP, no skill.
func add_player_xp(amount: int) -> int:
	if amount > 0:
		grant_player_xp("", 0, amount)
	return get_player_xp()

# --- Future instanced scenes (dungeons / caves / interiors) -------------------
# Reserved for when WorldRegionManager loads non-outdoor instances. Outdoor play is
# one continuous overworld and never scene-swaps, so this stays empty for now.

func get_instance_state(instance_id: String) -> Dictionary:
	if instance_id.is_empty():
		return {}
	var save_data: Dictionary = load_save_data()
	var world_data: Dictionary = _get_dictionary_section(save_data, "world")
	var instances_data: Dictionary = _get_dictionary_section(world_data, "instances")
	var entry: Variant = instances_data.get(instance_id, {})
	if typeof(entry) != TYPE_DICTIONARY:
		return {}
	return entry as Dictionary

func set_instance_state(instance_id: String, instance_state: Dictionary) -> void:
	if instance_id.is_empty():
		return
	var save_data: Dictionary = load_save_data()
	var world_data: Dictionary = _get_dictionary_section(save_data, "world")
	var instances_data: Dictionary = _get_dictionary_section(world_data, "instances")
	instances_data[instance_id] = instance_state
	world_data["instances"] = instances_data
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
	# Ensure the forward-looking overworld/instances sections exist on migrated saves
	# (additive, preserves any existing values, no version bump).
	if not migrated_data["world"].has("overworld"):
		migrated_data["world"]["overworld"] = {"flags": {}}
	if not migrated_data["world"].has("instances"):
		migrated_data["world"]["instances"] = {}
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
			# Main continuous outdoor world's own global flags. Note: homestead farming
			# and village/forest seen-flags still live under world.regions.* for save
			# compatibility (see docs/save_data_model.md). This is the clean home for
			# new overworld-wide flags.
			"overworld": {
				"flags": {},
			},
			# Reserved for future instanced, scene-swapped spaces (dungeons, caves,
			# interiors). Outdoor traversal never scene-swaps.
			"instances": {},
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
