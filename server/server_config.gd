extends RefCounted
class_name ServerConfig

## Dedicated-server launch configuration. Defaults are private-LAN friendly;
## override with Godot user args after `--`, e.g.:
##   godot --headless res://server/server_main.tscn -- --port=9000 --world=my_town

const DEFAULT_PORT := 8910
const DEFAULT_WORLD := "default_world"
const MAX_CLIENTS := 16

static func parse_from_args() -> Dictionary:
	var config: Dictionary = {
		"port": DEFAULT_PORT,
		"world": DEFAULT_WORLD,
		"max_clients": MAX_CLIENTS,
	}
	for arg in OS.get_cmdline_user_args():
		var text: String = String(arg)
		if text.begins_with("--port="):
			var port: int = int(text.get_slice("=", 1))
			if port > 0 and port < 65536:
				config["port"] = port
		elif text.begins_with("--world="):
			var world: String = text.get_slice("=", 1).validate_filename()
			if not world.is_empty():
				config["world"] = world
	return config
