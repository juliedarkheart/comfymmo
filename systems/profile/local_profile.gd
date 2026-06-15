extends RefCounted
class_name LocalProfile

## Local profile data model + normalization. A profile is local playtest
## identity only: a generated id, a display name, and appearance. No passwords,
## no secrets, no online account — see docs/profile_and_accounts.md.

static func create_default(display_name: String = "Villager") -> Dictionary:
	var now: String = Time.get_datetime_string_from_system(true)
	return {
		"profile_id": generate_profile_id(),
		"username": PlayerIdentity.username_from_display_name(display_name),
		"display_name": display_name,
		"created_at": now,
		"last_played_at": now,
		"appearance": CharacterAppearance.default_appearance(),
		"pronouns": "",
		"favorite_color": "",
		"last_server_ip": "127.0.0.1",
		"last_server_port": ServerConfig.DEFAULT_PORT,
	}

static func generate_profile_id() -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	return "profile_%08x%08x" % [rng.randi(), rng.randi()]

## Fills missing fields and normalizes appearance; never fails on old/partial
## profile files.
static func normalized(data: Dictionary) -> Dictionary:
	var result: Dictionary = create_default()
	for key in result.keys():
		if data.has(key) and typeof(data[key]) == typeof(result[key]):
			result[key] = data[key]
	if String(result.get("profile_id", "")).is_empty():
		result["profile_id"] = generate_profile_id()
	if String(result.get("display_name", "")).strip_edges().is_empty():
		result["display_name"] = "Villager"
	# Old profiles lack a username: derive one from the display name.
	var username: String = PlayerIdentity.sanitize_username(String(result.get("username", "")))
	if username.length() < PlayerIdentity.USERNAME_MIN_LENGTH:
		username = PlayerIdentity.username_from_display_name(String(result["display_name"]))
	result["username"] = username
	result["appearance"] = CharacterAppearance.normalized(result.get("appearance", {}) as Dictionary)
	result["last_server_port"] = clampi(int(result.get("last_server_port", ServerConfig.DEFAULT_PORT)), 1, 65535)
	return result
