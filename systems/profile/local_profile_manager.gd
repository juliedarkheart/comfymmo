extends RefCounted
class_name LocalProfileManager

## Loads/saves local profiles at user://profiles/profiles.json and tracks the
## active one. Creates a default profile on first run so every boot has a
## usable identity. Appearance precedence (documented in
## docs/character_customization.md):
##   1. The save's player.appearance (if present) wins at boot.
##   2. Otherwise the active profile's appearance seeds the avatar.
##   3. The wardrobe/F9 panel writes BOTH, keeping them in step going forward.

const PROFILES_DIR := "user://profiles"
const PROFILES_PATH := "user://profiles/profiles.json"

var _data: Dictionary = {"active_profile_id": "", "profiles": {}}

func load_profiles() -> void:
	if not FileAccess.file_exists(PROFILES_PATH):
		_ensure_default_profile()
		return
	var file: FileAccess = FileAccess.open(PROFILES_PATH, FileAccess.READ)
	if file == null:
		_ensure_default_profile()
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_ensure_default_profile()
		return
	_data = parsed as Dictionary
	if typeof(_data.get("profiles")) != TYPE_DICTIONARY:
		_data["profiles"] = {}
	_ensure_default_profile()

func save_profiles() -> void:
	DirAccess.make_dir_recursive_absolute(PROFILES_DIR)
	var file: FileAccess = FileAccess.open(PROFILES_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Unable to write profiles file: %s" % PROFILES_PATH)
		return
	file.store_string(JSON.stringify(_data, "\t"))

func get_active_profile() -> Dictionary:
	var profiles: Dictionary = _data.get("profiles", {}) as Dictionary
	var active_id: String = String(_data.get("active_profile_id", ""))
	if profiles.has(active_id) and typeof(profiles[active_id]) == TYPE_DICTIONARY:
		return LocalProfile.normalized(profiles[active_id] as Dictionary)
	_ensure_default_profile()
	return LocalProfile.normalized((_data["profiles"] as Dictionary).get(String(_data["active_profile_id"]), {}) as Dictionary)

func update_active_profile(changes: Dictionary) -> Dictionary:
	var profile: Dictionary = get_active_profile()
	for key in changes.keys():
		profile[key] = changes[key]
	profile["last_played_at"] = Time.get_datetime_string_from_system(true)
	profile = LocalProfile.normalized(profile)
	var profiles: Dictionary = _data.get("profiles", {}) as Dictionary
	profiles[String(profile["profile_id"])] = profile
	_data["profiles"] = profiles
	_data["active_profile_id"] = String(profile["profile_id"])
	save_profiles()
	return profile

func set_active_appearance(appearance: Dictionary) -> void:
	update_active_profile({"appearance": CharacterAppearance.normalized(appearance)})

func set_display_name(display_name: String) -> void:
	if not display_name.strip_edges().is_empty():
		update_active_profile({"display_name": display_name.strip_edges()})

func remember_server(ip: String, port: int) -> void:
	update_active_profile({"last_server_ip": ip, "last_server_port": port})

func _ensure_default_profile() -> void:
	var profiles: Dictionary = _data.get("profiles", {}) as Dictionary
	var active_id: String = String(_data.get("active_profile_id", ""))
	if profiles.has(active_id):
		return
	if not profiles.is_empty():
		_data["active_profile_id"] = String(profiles.keys()[0])
		return
	var profile: Dictionary = LocalProfile.create_default()
	profiles[String(profile["profile_id"])] = profile
	_data["profiles"] = profiles
	_data["active_profile_id"] = String(profile["profile_id"])
	save_profiles()
