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
signal chat_received(display_name: String, text: String)
signal chat_system_received(text: String)
signal gather_result_received(node_id: String, material_id: String, amount: int)
signal gather_denied_received(node_id: String, reason: String)
signal craft_result_received(message: String)
signal craft_denied_received(reason: String)

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
# Per-node gather cooldowns (node_id -> ready-at msec). In-memory only: gather
# cooldowns reset on server restart — documented temporary behaviour.
var _gather_ready_at: Dictionary = {}
var _server_rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Client state.
var _remote_avatars: Dictionary = {}
var _network_objects: Dictionary = {}
var _pending_records: Array = []
var _server_materials: Dictionary = {}
var _server_progression: Dictionary = {}

var _sync_accumulator: float = 0.0

func get_mode() -> String:
	return _mode

func is_client_connected() -> bool:
	return _mode == NetworkMode.CLIENT and _client_ready

func is_server() -> bool:
	return _mode == NetworkMode.SERVER

func get_server_materials() -> Dictionary:
	return _server_materials.duplicate()

func get_server_xp() -> int:
	return int(SkillProgression.normalized(_server_progression)["total_xp"])

func get_server_progression() -> Dictionary:
	return SkillProgression.normalized(_server_progression)

## The overworld controller registers itself so snapshots/placements can spawn
## into the live world. Safe to call multiple times; cleared on scene change.
func register_world(world: Node) -> void:
	_world = world
	_flush_pending_records()

# --- Server ---------------------------------------------------------------

func start_server(port: int, world_name: String, max_clients: int = 16, bind_address: String = "*") -> bool:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var bind: String = ServerConfig.normalize_bind(bind_address)
	if bind.is_empty():
		bind = "*"
	peer.set_bind_ip(bind)
	var error: Error = peer.create_server(port, max_clients)
	if error != OK:
		push_warning("Hearthvale server failed to listen on %s:%d (error %d) — is the port already in use?" % [bind, port, error])
		return false

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_server_peer_connected)
	multiplayer.peer_disconnected.connect(_on_server_peer_disconnected)
	_mode = NetworkMode.SERVER
	_server_rng.randomize()
	var world_existed: bool = FileAccess.file_exists(ServerSaveSystem.new(world_name).world_path())
	_server_save = ServerSaveSystem.new(world_name)
	_server_world = ServerWorldState.from_world(_server_save.load_world())
	print("[server] Listening on %s:%d (UDP/ENet), max %d players" % [bind, port, max_clients])
	if not world_existed:
		print("[server] Created new world save: %s" % _server_save.world_path())
	print("[server] World '%s' loaded: %d placed objects (%s)" % [
		world_name, _server_world.placed_objects().size(), _server_save.world_path(),
	])
	if ServerConfig.is_externally_reachable(bind):
		print("[server] Reminder: external/LAN clients need UDP %d allowed through the Windows firewall" % port)
		print("[server]           (tools/open_firewall_server_port.ps1) and, for internet play, router")
		print("[server]           port forwarding of UDP %d to this PC. See docs/external_server_access.md." % port)
	return true

func _on_server_peer_connected(peer_id: int) -> void:
	print("[server] Peer %d connected, waiting for join request." % peer_id)

func _on_server_peer_disconnected(peer_id: int) -> void:
	var player: ServerPlayerState = _players.get(peer_id)
	if player != null:
		_server_world.remember_profile(player)
		_server_save.save_world(_server_world.world)
		print("[server] %s (peer %d) left." % [player.display_name, peer_id])
		_rpc_chat_system.rpc("%s left." % player.display_name)
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

	# Session registration: a profile is "registered" the first time it joins —
	# no passwords, the profile_id is the identity (prototype trust model).
	# Display names are deduplicated against currently-online players so two
	# "Villager"s stay distinguishable in chat and name tags.
	identity["display_name"] = _dedupe_display_name(String(identity.get("display_name", "Villager")))

	var materials: MaterialInventory
	var known: Dictionary = _server_world.get_known_profile(String(identity.get("profile_id", "")))
	var is_returning: bool = not known.is_empty()
	if known.has("materials") and typeof(known["materials"]) == TYPE_DICTIONARY:
		materials = MaterialInventory.from_dictionary(known["materials"] as Dictionary)
	else:
		materials = MaterialInventory.starter_pack()

	var player: ServerPlayerState = ServerPlayerState.create(peer_id, identity, materials)
	# Old world files stored a flat profile-level "xp"; SkillProgression
	# normalizes both that and the new {total_xp, skills} shape.
	player.progression = SkillProgression.normalized(
		known.get("progression", {"xp": int(known.get("xp", 0))}) as Dictionary
	)
	player.position = Vector2(224, 368)  # homestead default spawn area
	_players[peer_id] = player
	_server_world.remember_profile(player)
	_server_save.save_world(_server_world.world)
	print("[server] %s (peer %d, profile %s) joined%s." % [
		player.display_name, peer_id, player.profile_id,
		" (returning)" if is_returning else " (new registration)",
	])
	_rpc_chat_system.rpc("%s joined." % player.display_name)
	_rpc_chat_system.rpc_id(peer_id, (
		"Welcome back, %s!" % player.display_name if is_returning
		else "Registered on this server as %s (your profile is your identity — no password)." % player.display_name
	))

	var others: Array = []
	for other_peer_id in _players.keys():
		if other_peer_id != peer_id:
			others.append((_players[other_peer_id] as ServerPlayerState).to_public_dict())
	_rpc_world_snapshot.rpc_id(peer_id, {
		"world_id": String(_server_world.world.get("world_id", "")),
		"placed_objects": _server_world.placed_objects(),
		"players": others,
		"materials": player.materials.to_dictionary(),
		"progression": player.progression,
	})
	for other_peer_id in _players.keys():
		if other_peer_id != peer_id:
			_rpc_player_joined.rpc_id(other_peer_id, player.to_public_dict())

@rpc("authority", "reliable")
func _rpc_world_snapshot(snapshot: Dictionary) -> void:
	connection_state_changed.emit("Joined world '%s'" % String(snapshot.get("world_id", "?")))
	_server_materials = snapshot.get("materials", {}) as Dictionary
	_server_progression = snapshot.get("progression", {}) as Dictionary
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
		_deny_place(peer_id, player.display_name, content_id, "Unknown item")
		return
	if not _server_world.is_tile_free(tile_x, tile_y):
		_deny_place(peer_id, player.display_name, content_id, "That spot is taken")
		return
	var lock_reason: String = ProgressionRegistry.lock_reason(
		ProgressionRegistry.placeable_locks().get(content_id, {}) as Dictionary,
		SkillProgression.player_level(player.progression),
		SkillProgression.skill_levels(player.progression)
	)
	if not lock_reason.is_empty():
		_deny_place(peer_id, player.display_name, content_id, lock_reason)
		return
	var cost: Dictionary = BuildCosts.cost_of(content_id)
	if not player.materials.spend(cost):
		_deny_place(peer_id, player.display_name, content_id, "Needs %s" % BuildCosts.cost_text(content_id))
		return

	var record: Dictionary = _server_world.add_placed_object(content_id, tile_x, tile_y, player.profile_id, player.display_name)
	if record.is_empty():
		_deny_place(peer_id, player.display_name, content_id, "That spot is taken")
		return
	_grant_server_progression(
		player, ProgressionRegistry.SKILL_BUILDING,
		ProgressionRegistry.building_xp_for_cost(cost), 0
	)
	_server_world.remember_profile(player)
	_server_save.save_world(_server_world.world)
	print("[server] %s placed %s at (%d, %d)." % [player.display_name, content_id, tile_x, tile_y])
	_rpc_placement_committed.rpc(record)
	_rpc_materials_update.rpc_id(peer_id, player.materials.to_dictionary())

func _dedupe_display_name(base_name: String) -> String:
	var candidate: String = base_name
	var suffix: int = 2
	while _is_display_name_online(candidate):
		candidate = "%s#%d" % [base_name, suffix]
		suffix += 1
	return candidate

func _is_display_name_online(display_name: String) -> bool:
	for player_variant in _players.values():
		if (player_variant as ServerPlayerState).display_name == display_name:
			return true
	return false

# --- Chat (prototype: no moderation/filtering/admin commands) ----------------

func send_chat(text: String) -> void:
	if is_client_connected():
		_rpc_chat_send.rpc_id(1, text)

@rpc("any_peer", "reliable")
func _rpc_chat_send(text: String) -> void:
	if not is_server():
		return
	var player: ServerPlayerState = _players.get(multiplayer.get_remote_sender_id())
	if player == null:
		return
	var clean: String = ChatMessage.sanitize(text)
	if clean.is_empty():
		return
	# The server's identity state names the sender — never the wire payload.
	print("[server] <%s> %s" % [player.display_name, clean])
	_rpc_chat_broadcast.rpc(player.display_name, clean)

@rpc("authority", "reliable")
func _rpc_chat_broadcast(display_name: String, text: String) -> void:
	chat_received.emit(display_name, text)

@rpc("authority", "reliable")
func _rpc_chat_system(text: String) -> void:
	chat_system_received.emit(text)

# --- Gathering (server-authoritative when connected) -------------------------

func request_gather(node_id: String) -> void:
	if is_client_connected():
		_rpc_request_gather.rpc_id(1, node_id)

@rpc("any_peer", "reliable")
func _rpc_request_gather(node_id: String) -> void:
	if not is_server():
		return
	var peer_id: int = multiplayer.get_remote_sender_id()
	var player: ServerPlayerState = _players.get(peer_id)
	if player == null:
		return
	var definition: Dictionary = ResourceSpawnRegistry.find(node_id)
	if definition.is_empty():
		_rpc_gather_denied.rpc_id(peer_id, node_id, "There is nothing to gather there")
		return
	var now: int = Time.get_ticks_msec()
	if now < int(_gather_ready_at.get(node_id, 0)):
		_rpc_gather_denied.rpc_id(peer_id, node_id, "This spot is still recovering")
		return

	var yields: Dictionary = ResourceNode.definitions().get(String(definition["type"]), {}) as Dictionary
	var material_id: String = String(yields.get("material_id", ResourceIds.MATERIAL_WOOD))
	var amount: int = _server_rng.randi_range(int(yields.get("min", 1)), int(yields.get("max", 2)))
	player.materials.add(material_id, amount)
	_gather_ready_at[node_id] = now + int(ResourceSpawnRegistry.COOLDOWN_SECONDS * 1000.0)
	_grant_server_progression(player, ProgressionRegistry.skill_for_material(material_id), 2, 1)
	_server_world.remember_profile(player)
	_server_save.save_world(_server_world.world)
	print("[server] %s gathered %d %s at %s." % [player.display_name, amount, material_id, node_id])
	_rpc_materials_update.rpc_id(peer_id, player.materials.to_dictionary())
	_rpc_gather_result.rpc_id(peer_id, node_id, material_id, amount)

@rpc("authority", "reliable")
func _rpc_gather_result(node_id: String, material_id: String, amount: int) -> void:
	gather_result_received.emit(node_id, material_id, amount)

@rpc("authority", "reliable")
func _rpc_gather_denied(node_id: String, reason: String) -> void:
	gather_denied_received.emit(node_id, reason)

# --- Crafting (server-authoritative) -----------------------------------------

func request_craft(recipe_id: String) -> void:
	if is_client_connected():
		_rpc_request_craft.rpc_id(1, recipe_id)

@rpc("any_peer", "reliable")
func _rpc_request_craft(recipe_id: String) -> void:
	if not is_server():
		return
	var peer_id: int = multiplayer.get_remote_sender_id()
	var player: ServerPlayerState = _players.get(peer_id)
	if player == null:
		return
	var level: int = SkillProgression.player_level(player.progression)
	var nearby_stations: Array = []
	for station_id in CraftingRegistry.station_ids():
		if _server_world.has_station_near(String(station_id), player.position, 110.0):
			nearby_stations.append(station_id)

	var result: Dictionary = CraftingSystem.craft_with_pouch(
		recipe_id, player.materials, level, nearby_stations,
		SkillProgression.skill_levels(player.progression)
	)
	if not bool(result["ok"]):
		print("[server] Denied craft '%s' by %s: %s" % [recipe_id, player.display_name, result["reason"]])
		_rpc_craft_denied.rpc_id(peer_id, String(result["reason"]))
		return

	# Crafting trains the crafting skill by the recipe's reward; overall XP is
	# roughly half (basic +2/+1, advanced +5/+2 — docs/progression.md).
	var crafting_xp: int = int(result["xp_reward"])
	_grant_server_progression(player, ProgressionRegistry.SKILL_CRAFTING, crafting_xp, maxi(1, crafting_xp / 2))
	_server_world.remember_profile(player)
	_server_save.save_world(_server_world.world)
	var message: String = "Crafted %d %s (+%d Crafting XP)" % [
		int(result["output_amount"]), String(result["display_name"]), crafting_xp,
	]
	print("[server] %s crafted %d %s." % [player.display_name, int(result["output_amount"]), String(result["display_name"])])
	_rpc_materials_update.rpc_id(peer_id, player.materials.to_dictionary())
	_rpc_craft_result.rpc_id(peer_id, message)

@rpc("authority", "reliable")
func _rpc_craft_result(message: String) -> void:
	craft_result_received.emit(message)

@rpc("authority", "reliable")
func _rpc_craft_denied(reason: String) -> void:
	craft_denied_received.emit(reason)

@rpc("authority", "reliable")
func _rpc_progression_update(progression: Dictionary) -> void:
	_server_progression = progression

## Server-side XP grant: updates the player's progression, pushes it to the
## client, and broadcasts level-ups in chat. Persistence rides on the caller's
## save (every grant site already saves the world right after).
func _grant_server_progression(player: ServerPlayerState, skill_id: String, skill_xp: int, total_xp: int) -> void:
	var grant_result: Dictionary = SkillProgression.grant(player.progression, skill_id, skill_xp, total_xp)
	player.progression = grant_result["progression"]
	_rpc_progression_update.rpc_id(player.peer_id, player.progression)
	if bool(grant_result["player_levelled"]):
		_rpc_chat_system.rpc("%s reached Level %d!" % [player.display_name, int(grant_result["new_player_level"])])
	if bool(grant_result["skill_levelled"]) and not skill_id.is_empty():
		_rpc_chat_system.rpc_id(player.peer_id, "%s skill is now Level %d!" % [
			ProgressionRegistry.skill_display_name(skill_id), int(grant_result["new_skill_level"]),
		])

func _deny_place(peer_id: int, display_name: String, content_id: String, reason: String) -> void:
	print("[server] Denied placement of '%s' by %s (peer %d): %s" % [content_id, display_name, peer_id, reason])
	_rpc_place_denied.rpc_id(peer_id, reason)

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
