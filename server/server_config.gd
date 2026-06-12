extends RefCounted
class_name ServerConfig

## Dedicated-server launch configuration. Sources, lowest to highest priority:
##   1. defaults()                         (private-LAN friendly)
##   2. --config=<path> JSON file          (see server/server_config.example.json)
##   3. individual CLI args                (--port=, --world=, --bind=, --max-players=)
## All user args go after a `--` separator, e.g.:
##   godot --headless res://server/server_main.tscn -- --config=user://server_config.json --port=9000

const DEFAULT_PORT := 8910
const DEFAULT_WORLD := "default_world"
const DEFAULT_BIND := "*"  # all interfaces (ENet wildcard); use 127.0.0.1 for strictly-local
const MAX_CLIENTS := 16

static func defaults() -> Dictionary:
	return {
		"bind_address": DEFAULT_BIND,
		"port": DEFAULT_PORT,
		"world": DEFAULT_WORLD,
		"max_players": MAX_CLIENTS,
		"save_on_change": true,
		"log_connections": true,
	}

static func parse_from_args() -> Dictionary:
	return resolve(OS.get_cmdline_user_args())

## Pure resolution (testable headlessly): defaults <- config file <- CLI args.
static func resolve(args: Array) -> Dictionary:
	var config: Dictionary = defaults()

	# First pass: find --config= and merge that file under the CLI args.
	for arg in args:
		var text: String = String(arg)
		if text.begins_with("--config="):
			config = merge(config, load_config_file(text.get_slice("=", 1)))

	# Second pass: individual args override everything.
	for arg in args:
		var text: String = String(arg)
		if text.begins_with("--port="):
			config = merge(config, {"port": int(text.get_slice("=", 1))})
		elif text.begins_with("--world="):
			config = merge(config, {"world": text.get_slice("=", 1)})
		elif text.begins_with("--bind="):
			config = merge(config, {"bind_address": text.get_slice("=", 1)})
		elif text.begins_with("--max-players="):
			config = merge(config, {"max_players": int(text.get_slice("=", 1))})
	return config

static func load_config_file(path: String) -> Dictionary:
	if path.is_empty():
		return {}
	if not FileAccess.file_exists(path):
		push_warning("Server config file not found, using defaults: %s" % path)
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Server config file unreadable: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Server config file is not a JSON object: %s" % path)
		return {}
	return parsed as Dictionary

## Merge overrides into base, sanitizing each known key; unknown keys ignored.
static func merge(base: Dictionary, overrides: Dictionary) -> Dictionary:
	var result: Dictionary = base.duplicate()
	if overrides.has("port"):
		var port: int = int(overrides["port"])
		if port > 0 and port < 65536:
			result["port"] = port
	if overrides.has("world"):
		var world: String = String(overrides["world"]).validate_filename()
		if not world.is_empty():
			result["world"] = world
	if overrides.has("bind_address"):
		var bind: String = normalize_bind(String(overrides["bind_address"]))
		if not bind.is_empty():
			result["bind_address"] = bind
	if overrides.has("max_players"):
		result["max_players"] = clampi(int(overrides["max_players"]), 1, 64)
	if overrides.has("save_on_change"):
		result["save_on_change"] = bool(overrides["save_on_change"])
	if overrides.has("log_connections"):
		result["log_connections"] = bool(overrides["log_connections"])
	return result

## ENet's wildcard is "*"; people will type "0.0.0.0", so accept both. Anything
## else must be a valid IP; junk falls back to empty (caller keeps previous).
static func normalize_bind(bind: String) -> String:
	var trimmed: String = bind.strip_edges()
	if trimmed == "0.0.0.0" or trimmed == "*" or trimmed.is_empty():
		return "*"
	if trimmed.is_valid_ip_address():
		return trimmed
	push_warning("Ignoring invalid bind address: %s" % trimmed)
	return ""

## True when the bind accepts non-local connections (firewall reminder).
static func is_externally_reachable(bind: String) -> bool:
	return bind != "127.0.0.1" and bind != "::1"
