extends Node

## NetworkSession — autoload owning the multiplayer session for both roles.
## OFFLINE by default; becomes CLIENT via the F8 connect panel or SERVER via
## server/server_main.tscn. Being an autoload gives client and server the same
## RPC node path, which Godot high-level multiplayer requires.
##
## Server-authoritative: the server owns connected players, identity/appearance
## for the session, placed network objects, per-player materials, placement
## validation + costs, and world persistence. Clients send requests and render
## results. This is prototype-grade (no auth, no encryption) — see
## docs/networking_plan.md for the honest limitation list.

signal connection_state_changed(state_text: String)
signal place_denied_received(reason: String)
signal server_materials_changed(materials: Dictionary)

const POSITION_SYNC_INTERVAL := 0.12
const REMOTE_PLAYER_SCRIPT := preload("res://systems/network/remote_player.gd")

var _mode: String = NetworkMode.OFFLINE
var _client_ready: bool = false
var _identity: Dictionary = {}
var _world: Node = null

# Server state.
var _server_save: ServerSaveSystem = null
var _server_world: ServerWorldState = null
var _players: Dictionary = {}

# Client state.
var _remote_avatars: Dictionary = {}
var _network_objects: Dictionary = {}
var _pending_records: Array = []
var _server_materials: Dictionary = {}

var _sync_accumulator: float = 0.0

func get_mode() -> String:
	return _mode

func is_client_connected() -> bool:
	return _mode == NetworkMode.CLIENT and _client_ready

func is_server() -> bool:
	return _mode == NetworkMode.SERVER

func get_server_materials() -> Dictionary:
	return _server_materials.duplicate()

## The overworld controller registers itself so snapshots/placements can spawn
## into the live world. Safe to call multiple times; cleared on scene change.
func register_world(world: Node) -> void:
	_world = world
	_flush_pending_records()

# --- Server ---------------------------------------------------------------

func start_server(port: int, world_name: String, max_clients: int = 16) -> bool:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(port, max_clients)
	if error != OK:
		push_warning("Hearthvale server failed to listen on port %d (error %d)" % [port, error])
		return false

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_server_peer_connected)
	multiplayer.peer_disconnected.connect(_on_server_peer_disconnected)
	_mode = NetworkMode.SERVER
	_server_save = ServerSaveSystem.new(world_name)
	_server_world = ServerWorldState.from_world(_server_save.load_world())
	print("[server] Hearthvale server listening on port %d" % port)
	print("[server] World '%s' loaded: %d placed objects (%s)" % [
		world_name, _server_world.placed_objects().size(), _server_save.world_path(),
	])
	return true

func _on_server_peer_connected(peer_id: int) -> void:
	print("[server] Peer %d connected, waiting for join request." % peer_id)

func _on_server_peer_disconnected(peer_id: int) -> void:
	var player: ServerPlayerState = _players.get(peer_id)
	if player != null:
		_server_world.remember_profile(player)
		_server_save.save_world(_server_world.world)
		print("[server] %s (peer %d) left." % [player.display_name, peer_id])
	_players.erase(peer_id)
	_rpc_player_left.rpc(peer_id)

# --- Client ---------------------------------------------------------------

func connect_to_server(ip: String, port: int, identity: Dictionary) -> bool:
	if _mode != NetworkMode.OFFLINE:
		return false
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	if peer.create_client(ip, port) != OK:
		connection_state_changed.emit("Could not start connection to %s:%d" % [ip, port])
		return false

	_identity = identity
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_client_connected)
	multiplayer.connection_failed.connect(_on_client_connection_failed)
	multiplayer.server_disconnected.connect(_on_client_server_disconnected)
	_mode = NetworkMode.CLIENT
	connection_state_changed.emit("Connecting to %s:%d..." % [ip, port])
	return true

func disconnect_session() -> void:
	if _mode == NetworkMode.OFFLINE:
		return
	_clear_network_visuals()
	_disconnect_multiplayer_signals()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_mode = NetworkMode.OFFLINE
	_client_ready = false
	_server_materials = {}
	connection_state_changed.emit("Offline")

func _on_client_connected() -> void:
	_client_ready = true
	connection_state_changed.emit("Connected. Joining world...")
	_rpc_join_request.rpc_id(1, _identity)

func _on_client_connection_failed() -> void:
	disconnect_session()
	connection_state_changed.emit("Connection failed")

func _on_client_server_disconnected() -> void:
	disconnect_session()
	connection_state_changed.emit("Server disconnected")

func _disconnect_multiplayer_signals() -> void:
	for connection_data in [
		["connected_to_server", _on_client_connected],
		["connection_failed", _on_client_connection_failed],
		["server_disconnected", _on_client_server_disconnected],
		["peer_connected", _on_server_peer_connected],
		["peer_disconnected", _on_server_peer_disconnected],
	]:
		var signal_name: String = connection_data[0]
		var callable: Callable = connection_data[1]
		if multiplayer.has_signal(signal_name) and multiplayer.is_connected(signal_name, callable):
			multiplayer.disconnect(signal_name, callable)

# --- Sync loop -------------------------------------------------------------

func _process(delta: float) -> void:
	_sync_accumulator += delta
	if _sync_accumulator < POSITION_SYNC_INTERVAL:
		return
	_sync_accumulator = 0.0

	if is_client_connected() and _world != null and is_instance_valid(_world) and _world.has_method("get_player_position"):
		_rpc_submit_position.rpc_id(1, _world.call("get_player_position"))
	elif is_server() and not _players.is_empty():
		var positions: Dictionary = {}
		for peer_id in _players.keys():
			var player: ServerPlayerState = _players[peer_id]
			positions[peer_id] = [player.position.x, player.position.y]
		_rpc_sync_positions.rpc(positions)

func request_place(content_id: String, tile: Vector2i) -> void:
	if is_client_connected():
		_rpc_request_place.rpc_id(1, content_id, tile.x, tile.y)

# --- RPCs ------------------------------------------------------------------

@rpc("any_peer", "reliable")
func _rpc_join_request(payload: Dictionary) -> void:
	if not is_server():
		return
	var peer_id: int = multiplayer.get_remote_sender_id()
	var identity: Dictionary = PlayerIdentity.normalized(payload)

	var materials: MaterialInventory
	var known: Dictionary = _server_world.get_known_profile(String(identity.get("profile_id", "")))
	if known.has("materials") and typeof(known["materials"]) == TYPE_DICTIONARY:
		materials = MaterialInventory.from_dictionary(known["materials"] as Dictionary)
	else:
		materials = MaterialInventory.starter_pack()

	var player: ServerPlayerState = ServerPlayerState.create(peer_id, identity, materials)
	player.position = Vector2(224, 368)  # homestead default spawn area
	_players[peer_id] = player
	_server_world.remember_profile(player)
	_server_save.save_world(_server_world.world)
	print("[server] %s (peer %d, profile %s) joined." % [player.display_name, peer_id, player.profile_id])

	var others: Array = []
	for other_peer_id in _players.keys():
		if other_peer_id != peer_id:
			others.append((_players[other_peer_id] as ServerPlayerState).to_public_dict())
	_rpc_world_snapshot.rpc_id(peer_id, {
		"world_id": String(_server_world.world.get("world_id", "")),
		"placed_objects": _server_world.placed_objects(),
		"players": others,
		"materials": player.materials.to_dictionary(),
	})
	for other_peer_id in _players.keys():
		if other_peer_id != peer_id:
			_rpc_player_joined.rpc_id(other_peer_id, player.to_public_dict())

@rpc("authority", "reliable")
func _rpc_world_snapshot(snapshot: Dictionary) -> void:
	connection_state_changed.emit("Joined world '%s'" % String(snapshot.get("world_id", "?")))
	_server_materials = snapshot.get("materials", {}) as Dictionary
	server_materials_changed.emit(get_server_materials())
	for record in (snapshot.get("placed_objects", []) as Array):
		if typeof(record) == TYPE_DICTIONARY:
			_spawn_network_object(record as Dictionary)
	for player_data in (snapshot.get("players", []) as Array):
		if typeof(player_data) == TYPE_DICTIONARY:
			_spawn_remote_player(player_data as Dictionary)

@rpc("authority", "reliable")
func _rpc_player_joined(player_data: Dictionary) -> void:
	_spawn_remote_player(player_data)

@rpc("authority", "reliable")
func _rpc_player_left(peer_id: int) -> void:
	var avatar: Node = _remote_avatars.get(peer_id)
	if avatar != null and is_instance_valid(avatar):
		avatar.queue_free()
	_remote_avatars.erase(peer_id)

@rpc("any_peer", "unreliable_ordered")
func _rpc_submit_position(player_position: Vector2) -> void:
	if not is_server():
		return
	var player: ServerPlayerState = _players.get(multiplayer.get_remote_sender_id())
	if player != null:
		player.position = player_position

@rpc("authority", "unreliable_ordered")
func _rpc_sync_positions(positions: Dictionary) -> void:
	for peer_id in positions.keys():
		if int(peer_id) == multiplayer.get_unique_id():
			continue
		var avatar: RemotePlayer = _remote_avatars.get(int(peer_id)) as RemotePlayer
		var coords: Array = positions[peer_id] as Array
		if avatar != null and is_instance_valid(avatar) and coords.size() == 2:
			avatar.apply_position(Vector2(float(coords[0]), float(coords[1])))

@rpc("any_peer", "reliable")
func _rpc_request_place(content_id: String, tile_x: int, tile_y: int) -> void:
	if not is_server():
		return
	var peer_id: int = multiplayer.get_remote_sender_id()
	var player: ServerPlayerState = _players.get(peer_id)
	if player == null:
		return
	if not ContentRegistry.placeables().has(content_id):
		_rpc_place_denied.rpc_id(peer_id, "Unknown item")
		return
	if not _server_world.is_tile_free(tile_x, tile_y):
		_rpc_place_denied.rpc_id(peer_id, "That spot is taken")
		return
	var cost: Dictionary = BuildCosts.cost_of(content_id)
	if not player.materials.spend(cost):
		_rpc_place_denied.rpc_id(peer_id, "Needs %s" % BuildCosts.cost_text(content_id))
		return

	var record: Dictionary = _server_world.add_placed_object(content_id, tile_x, tile_y, player.profile_id, player.display_name)
	if record.is_empty():
		_rpc_place_denied.rpc_id(peer_id, "That spot is taken")
		return
	_server_world.remember_profile(player)
	_server_save.save_world(_server_world.world)
	print("[server] %s placed %s at (%d, %d)." % [player.display_name, content_id, tile_x, tile_y])
	_rpc_placement_committed.rpc(record)
	_rpc_materials_update.rpc_id(peer_id, player.materials.to_dictionary())

@rpc("authority", "reliable")
func _rpc_place_denied(reason: String) -> void:
	place_denied_received.emit(reason)

@rpc("authority", "reliable")
func _rpc_placement_committed(record: Dictionary) -> void:
	_spawn_network_object(record)

@rpc("authority", "reliable")
func _rpc_materials_update(materials: Dictionary) -> void:
	_server_materials = materials
	server_materials_changed.emit(get_server_materials())

# --- Client-side world spawning ---------------------------------------------

func _spawn_network_object(record: Dictionary) -> void:
	if _world == null or not is_instance_valid(_world) or not _world.has_method("spawn_network_placed_object"):
		_pending_records.append(record)
		return
	var instance_id: String = String(record.get("instance_id", ""))
	if instance_id.is_empty() or _network_objects.has(instance_id):
		return
	var node: Node = _world.call("spawn_network_placed_object", record)
	if node != null:
		_network_objects[instance_id] = node

func _spawn_remote_player(player_data: Dictionary) -> void:
	if _world == null or not is_instance_valid(_world) or not _world.has_method("get_network_player_layer"):
		return
	var peer_id: int = int(player_data.get("peer_id", 0))
	if peer_id == 0 or _remote_avatars.has(peer_id):
		return
	var layer: Node = _world.call("get_network_player_layer")
	if layer == null:
		return
	var avatar: RemotePlayer = RemotePlayer.new()
	layer.add_child(avatar)
	avatar.setup(
		String(player_data.get("display_name", "Villager")),
		player_data.get("appearance", {}) as Dictionary,
		Vector2(float(player_data.get("position_x", 224)), float(player_data.get("position_y", 368)))
	)
	_remote_avatars[peer_id] = avatar

func _flush_pending_records() -> void:
	var pending: Array = _pending_records
	_pending_records = []
	for record in pending:
		_spawn_network_object(record as Dictionary)

func _clear_network_visuals() -> void:
	for avatar in _remote_avatars.values():
		if avatar != null and is_instance_valid(avatar):
			(avatar as Node).queue_free()
	_remote_avatars.clear()
	for node in _network_objects.values():
		if node != null and is_instance_valid(node):
			(node as Node).queue_free()
	_network_objects.clear()
	_pending_records.clear()
