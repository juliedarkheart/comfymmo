extends Node

## Placeholder boundary for sessions, authority, and replication.

enum NetworkMode {
	OFFLINE,
	HOST,
	CLIENT,
	DEDICATED_SERVER,
}

var mode: NetworkMode = NetworkMode.OFFLINE

func configure_offline() -> void:
	mode = NetworkMode.OFFLINE

func is_authoritative() -> bool:
	return mode == NetworkMode.HOST or mode == NetworkMode.DEDICATED_SERVER

