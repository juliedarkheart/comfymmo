extends Node

## Legacy placeholder boundary for sessions, authority, and replication.
## Superseded by the NetworkSession autoload (systems/network/network_session.gd)
## but kept so game_bootstrap's service wiring is unchanged. The enum is named
## ServiceMode to avoid clashing with the global NetworkMode class.

enum ServiceMode {
	OFFLINE,
	HOST,
	CLIENT,
	DEDICATED_SERVER,
}

var mode: ServiceMode = ServiceMode.OFFLINE

func configure_offline() -> void:
	mode = ServiceMode.OFFLINE

func is_authoritative() -> bool:
	return mode == ServiceMode.HOST or mode == ServiceMode.DEDICATED_SERVER
