extends Node

## Dedicated Hearthvale server entry point (root of server/server_main.tscn).
## Runs headless without loading the game world or UI — the server is data-
## authoritative only and never instantiates the overworld scene. Run with:
##   & $godot --headless --path E:\GitHub\comfymmo res://server/server_main.tscn
## Optional args after `--`: --port=8910 --world=default_world

func _ready() -> void:
	var config: Dictionary = ServerConfig.parse_from_args()
	print("=== Hearthvale Server (prototype) ===")
	print("[server] Config: bind=%s port=%d world=%s max_players=%d" % [
		String(config["bind_address"]), int(config["port"]),
		String(config["world"]), int(config["max_players"]),
	])
	print("[server] (defaults < --config=<file> < CLI args; see server/server_config.example.json)")
	# Runtime autoload lookup (direct identifier breaks --script validation).
	var session: Node = get_node_or_null("/root/NetworkSession")
	if session == null:
		push_error("NetworkSession autoload missing; exiting.")
		get_tree().quit(1)
		return
	var started: bool = bool(session.call(
		"start_server",
		int(config["port"]), String(config["world"]),
		int(config["max_players"]), String(config["bind_address"])
	))
	if not started:
		push_error("Server failed to start; exiting.")
		get_tree().quit(1)
		return
	print("[server] Ready. Press Ctrl+C to stop; the world saves on every change.")
