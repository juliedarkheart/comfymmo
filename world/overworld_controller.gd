extends HomesteadController
class_name OverworldController

## The continuous overworld controller. It inherits the full homestead gameplay
## stack (farming, placement, mailbox, rest, mood/day, creatures, inventory,
## comfort, save) unchanged, then adds the village and forest content — villagers,
## notice board, shrine, and their ambient creatures — into the same single scene.
## No outdoor scene swapping happens; this is one continuous world.
##
## INHERITANCE NOTE (transitional): `extends HomesteadController` was the low-risk
## way to reuse the proven gameplay stack during the pivot away from paged regions.
## It is stable and intentionally kept for now. The eventual cleaner shape is a
## shared `OutdoorAreaController` base (or component systems) that both the overworld
## and any future authored area build on; do NOT attempt that refactor casually —
## it must preserve every system here. See docs/overworld_architecture.md.

const MARIBEL_SCENE := preload("res://scenes/villagers/maribel_tock.tscn")
const BRAM_SCENE := preload("res://scenes/villagers/bram_nettle.tscn")
const DEV_CHARACTER_CREATOR_SCENE := preload("res://ui/dev_character_creator_panel.tscn")
const NETWORK_CONNECT_PANEL_SCENE := preload("res://ui/network_connect_panel.tscn")
const CHAT_PANEL_SCENE := preload("res://ui/chat_panel.tscn")
# Constant names kept; values now come from ContentIds (stable, save-compatible).
const VILLAGE_REGION_ID := ContentIds.AREA_VILLAGE_SQUARE
const FOREST_REGION_ID := ContentIds.AREA_FOREST_EDGE
const MARIBEL_INTRO_FLAG := ContentIds.FLAG_MARIBEL_INTRO_SEEN
const MARIBEL_COUNT_FLAG := ContentIds.FLAG_MARIBEL_VISIT_COUNT
const BRAM_INTRO_FLAG := ContentIds.FLAG_BRAM_INTRO_SEEN
const BRAM_COUNT_FLAG := ContentIds.FLAG_BRAM_VISIT_COUNT
const NOTICE_SEEN_FLAG := ContentIds.FLAG_NOTICE_BOARD_SEEN
const SHRINE_SEEN_FLAG := ContentIds.FLAG_ADVENTURE_MARKER_SEEN

var _villager_data: Dictionary = {}
var _profile_manager: LocalProfileManager = LocalProfileManager.new()
var _creator_panel: CanvasLayer = null
var _chat_panel: CanvasLayer = null
var _network_player: AvatarController = null
var _resource_nodes: Dictionary = {}
var _gather_rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	super._ready()
	_profile_manager.load_profiles()
	_gather_rng.randomize()
	var player: AvatarController = _find_player()
	_network_player = player
	_apply_overworld_camera(player)
	_spawn_village_content(player)
	_spawn_forest_content(player)
	_setup_resource_nodes()
	_setup_dev_overlay(player)
	_setup_wardrobe()
	_setup_cottage_sign()
	_setup_network(player)
	_show_welcome_if_first_boot.call_deferred()

func _setup_dev_overlay(player: AvatarController) -> void:
	var camera: AvatarCamera = get_camera(player)

	# A world-space layer (origin-aligned, drawn above props) that holds temporary
	# dev markers. It carries no collision and is never saved.
	var marker_layer: Node2D = Node2D.new()
	marker_layer.name = "DevMarkerLayer"
	marker_layer.z_index = 200
	map.add_child(marker_layer)

	var editor: OverworldEditorSystem = OverworldEditorSystem.new()
	editor.name = "OverworldEditorSystem"
	add_child(editor)
	editor.setup(player, camera, marker_layer)

	# Appearance precedence (docs/character_customization.md): an explicit
	# player.appearance in the save wins; otherwise the active local profile
	# seeds the look. The wardrobe/F9 panel writes both from then on.
	var avatar_visual: Node = null
	if player != null:
		avatar_visual = player.get_node_or_null("Body")
	if avatar_visual != null and avatar_visual.has_method("rebuild"):
		avatar_visual.call("rebuild", _resolve_boot_appearance())

	_creator_panel = DEV_CHARACTER_CREATOR_SCENE.instantiate() as CanvasLayer
	_creator_panel.name = "DevCharacterCreatorPanel"
	add_child(_creator_panel)
	_creator_panel.call("setup", avatar_visual, save_system, _profile_manager)

func _resolve_boot_appearance() -> Dictionary:
	var player_section: Dictionary = save_system.load_save_data().get("player", {}) as Dictionary
	if player_section.has("appearance"):
		return save_system.get_player_appearance()
	return CharacterAppearance.normalized(
		_profile_manager.get_active_profile().get("appearance", {}) as Dictionary
	)

func _find_player() -> AvatarController:
	# Player lookup is now a shared OutdoorAreaController helper (phase-1 seam).
	return get_player_avatar(gameplay_layer)

func _apply_overworld_camera(player: AvatarController) -> void:
	if player == null:
		return
	var camera: AvatarCamera = get_camera(player)
	if camera != null:
		camera.apply_region_view(map.get_camera_zoom(), map.get_camera_limits())

func _spawn_village_content(player: AvatarController) -> void:
	var c: Vector2 = OverworldMap.VILLAGE_OFFSET
	var maribel: SimpleVillager = MARIBEL_SCENE.instantiate() as SimpleVillager
	maribel.position = c + Vector2(128, 218)
	gameplay_layer.add_child(maribel)
	register_world_interactable(
		"ow_maribel", maribel, ContentIds.INTERACTION_VILLAGER, "Press F to talk to Maribel",
		_talk_villager.bind("ow_maribel")
	)
	_villager_data["ow_maribel"] = {
		"villager": maribel, "intro": MARIBEL_INTRO_FLAG, "count": MARIBEL_COUNT_FLAG,
		"passage": Callable(self, "_maribel_passage_line"),
	}

	var bram: SimpleVillager = BRAM_SCENE.instantiate() as SimpleVillager
	bram.position = c + Vector2(60, 452)
	gameplay_layer.add_child(bram)
	register_world_interactable(
		"ow_bram", bram, ContentIds.INTERACTION_VILLAGER, "Press F to talk to Bram",
		_talk_villager.bind("ow_bram")
	)
	_villager_data["ow_bram"] = {
		"villager": bram, "intro": BRAM_INTRO_FLAG, "count": BRAM_COUNT_FLAG,
		"passage": Callable(self, "_bram_passage_line"),
	}

	var notice: Node2D = _build_notice_marker(c + Vector2(176, 160))
	register_world_interactable(
		"ow_notice", notice, ContentIds.INTERACTION_NOTICE_BOARD, "Press F to read notice board",
		_open_notice_board
	)

	var rabbit: MossRabbit = MossRabbit.new()
	rabbit.position = c + Vector2(-10, 360)
	gameplay_layer.add_child(rabbit)
	rabbit.configure_creature(player)
	register_world_interactable(
		"ow_village_rabbit", rabbit, ContentIds.INTERACTION_AMBIENT_CREATURE, "Press F to observe",
		_handle_creature_observe.bind("ow_village_rabbit")
	)
	_ambient_creatures["ow_village_rabbit"] = rabbit

func _spawn_forest_content(player: AvatarController) -> void:
	var c: Vector2 = OverworldMap.FOREST_OFFSET
	var shrine: Node2D = _build_shrine_marker(c + Vector2(136, 166))
	register_world_interactable(
		"ow_shrine", shrine, ContentIds.INTERACTION_SHRINE_MARKER, "Press F to inspect shrine",
		_open_shrine
	)

	var rabbit_positions: Array[Vector2] = [Vector2(32, 304), Vector2(192, 448), Vector2(-64, 448)]
	for i in range(rabbit_positions.size()):
		var rabbit: MossRabbit = MossRabbit.new()
		rabbit.position = c + rabbit_positions[i]
		gameplay_layer.add_child(rabbit)
		rabbit.configure_creature(player)
		var rabbit_id: String = "ow_forest_rabbit_%d" % i
		register_world_interactable(
			rabbit_id, rabbit, ContentIds.INTERACTION_AMBIENT_CREATURE, "Press F to observe",
			_handle_creature_observe.bind(rabbit_id)
		)
		_ambient_creatures[rabbit_id] = rabbit

	var moth_positions: Array[Vector2] = [Vector2(224, 336), Vector2(-128, 320)]
	for i in range(moth_positions.size()):
		var moth: LanternMoth = LanternMoth.new()
		moth.position = c + moth_positions[i]
		gameplay_layer.add_child(moth)
		moth.configure_creature(player)
		var moth_id: String = "ow_forest_moth_%d" % i
		register_world_interactable(
			moth_id, moth, ContentIds.INTERACTION_AMBIENT_CREATURE, "Press F to observe",
			_handle_creature_observe.bind(moth_id)
		)
		_ambient_creatures[moth_id] = moth

# Interaction dispatch is fully inherited now: villagers, notice board, shrine, and
# creatures were registered with bound callbacks via register_world_interactable, so
# HomesteadController._on_interaction_requested's default branch dispatches them
# after the same four panel/mode guards this controller previously duplicated.

func _talk_villager(interactable_id: String) -> void:
	var data: Dictionary = _villager_data.get(interactable_id, {})
	if data.is_empty():
		return
	var villager: SimpleVillager = data["villager"]
	var flags: Dictionary = save_system.get_region_flags(VILLAGE_REGION_ID)
	if not bool(flags.get(data["intro"], false)):
		_open_observe_panel(villager.villager_name, villager.first_visit_text)
		save_system.set_region_flag(VILLAGE_REGION_ID, data["intro"], true)
		return
	var visit_count: int = int(flags.get(data["count"], 0))
	var line: String = villager.get_repeat_line(visit_count)
	var passage: Callable = data["passage"]
	if passage.is_valid() and visit_count % 2 == 1:
		line = passage.call(save_system.get_day_count(), save_system.get_current_mood())
	_open_observe_panel(villager.villager_name, line)
	save_system.set_region_flag(VILLAGE_REGION_ID, data["count"], visit_count + 1)

func _open_notice_board() -> void:
	_open_observe_panel("Village Notice Board", "Welcome to the village square. Plans, errands, and little celebrations get pinned here.")
	if not bool(save_system.get_region_flags(VILLAGE_REGION_ID).get(NOTICE_SEEN_FLAG, false)):
		save_system.set_region_flag(VILLAGE_REGION_ID, NOTICE_SEEN_FLAG, true)

func _open_shrine() -> void:
	var seen: bool = bool(save_system.get_region_flags(FOREST_REGION_ID).get(SHRINE_SEEN_FLAG, false))
	var body: String = "The marker still hums softly." if seen else "The path beyond is quiet... for now."
	_open_observe_panel("Old Shrine", body)
	if not seen:
		save_system.set_region_flag(FOREST_REGION_ID, SHRINE_SEEN_FLAG, true)

func _bram_passage_line(day_count: int, mood_id: String) -> String:
	match WorldMood.normalize(mood_id):
		WorldMood.MORNING:
			return "Day %d already. Mornings like this, the flowerbeds near tend themselves." % day_count
		WorldMood.DUSK:
			return "Quiet evenings are good for the nerves. Rest easy when the day is done."
		_:
			return "Feels like a slow sort of afternoon. No hurry in it."

func _maribel_passage_line(day_count: int, mood_id: String) -> String:
	match WorldMood.normalize(mood_id):
		WorldMood.MORNING:
			return "Day %d on the calendar. Each morning I pin up a little hope and see what stays." % day_count
		WorldMood.DUSK:
			return "Dusk again. We have kept the small things %d days now, you and I." % day_count
		_:
			return "A gentle afternoon. I tidy the notices and let the hours wander."

# --- Gathering (survival-lite materials) -------------------------------------

func _setup_resource_nodes() -> void:
	# Gather spots come from ResourceSpawnRegistry — the same catalog the
	# server validates gather requests against, so client and server can never
	# disagree about what is gatherable.
	for definition_variant in ResourceSpawnRegistry.definitions():
		var definition: Dictionary = definition_variant as Dictionary
		var node: ResourceNode = ResourceNode.new()
		node.position = _resolve_spawn_position(definition)
		gameplay_layer.add_child(node)
		node.configure(String(definition["type"]))
		var node_id: String = String(definition["node_id"])
		_resource_nodes[node_id] = node
		register_world_interactable(
			node_id, node, ContentIds.INTERACTION_GENERIC, node.get_prompt(),
			_handle_gather.bind(node_id)
		)

func _resolve_spawn_position(definition: Dictionary) -> Vector2:
	var x: float = float(definition.get("x", 0))
	var y: float = float(definition.get("y", 0))
	match String(definition.get("anchor", "homestead")):
		"village":
			return OverworldMap.VILLAGE_OFFSET + Vector2(x, y)
		"forest":
			return OverworldMap.FOREST_OFFSET + Vector2(x, y)
		_:
			return map.grid_to_world(Vector2i(int(x), int(y)))

func _handle_gather(node_id: String) -> void:
	var node: ResourceNode = _resource_nodes.get(node_id) as ResourceNode
	if node == null:
		return

	# Connected: the server owns the pouch and the cooldown; results come back
	# via gather_result/gather_denied signals (wired in _setup_network).
	var session: Node = get_node_or_null("/root/NetworkSession")
	if session != null and bool(session.call("is_client_connected")):
		session.call("request_gather", node_id)
		return

	# Offline: local cooldown + local inventory (auto-saves via the existing
	# inventory_changed handler), with a non-modal toast in the chat log.
	if not node.is_ready():
		_chat_toast("This spot is still recovering (%ds)." % node.remaining_seconds())
		return
	var result: Dictionary = node.roll_yield(_gather_rng)
	var material_id: String = String(result.get("material_id", ""))
	var amount: int = int(result.get("amount", 1))
	inventory_system.add_item(material_id, amount)
	node.start_cooldown()
	_chat_toast("+%d %s (now %d)" % [amount, ResourceIds.display_name(material_id), inventory_system.get_quantity(material_id)])

func _chat_toast(text: String) -> void:
	if _chat_panel != null and _chat_panel.has_method("add_system_line"):
		_chat_panel.call("add_system_line", text)

func _on_network_gather_result(node_id: String, material_id: String, amount: int) -> void:
	# Mirror the server cooldown on the local node visual and toast the gain.
	var node: ResourceNode = _resource_nodes.get(node_id) as ResourceNode
	if node != null:
		node.start_cooldown()
	_chat_toast("+%d %s" % [amount, ResourceIds.display_name(material_id)])

func _on_network_gather_denied(_node_id: String, reason: String) -> void:
	_chat_toast("%s." % reason)

# --- Wardrobe mirror -----------------------------------------------------------

func _setup_wardrobe() -> void:
	# A standing mirror beside the cottage that opens the same registry-driven
	# customization panel as F9, in player-facing "Wardrobe" dress.
	var mirror: Node2D = Node2D.new()
	mirror.position = map.grid_to_world(Vector2i(9, 6))
	gameplay_layer.add_child(mirror)
	var shadow: Polygon2D = Polygon2D.new()
	shadow.polygon = TerrainShapes.ellipse(Vector2(0, 1), 12.0, 5.0)
	shadow.color = Color(0.16, 0.12, 0.08, 0.2)
	mirror.add_child(shadow)
	for leg_x: float in [-6.0, 6.0]:
		var leg: Polygon2D = Polygon2D.new()
		leg.polygon = PackedVector2Array([
			Vector2(leg_x - 1.5, 0), Vector2(leg_x + 1.5, 0), Vector2(leg_x * 0.5 + 1.5, -10), Vector2(leg_x * 0.5 - 1.5, -10),
		])
		leg.color = Color("#8a5e3c")
		mirror.add_child(leg)
	var frame: Polygon2D = Polygon2D.new()
	frame.polygon = TerrainShapes.ellipse(Vector2(0, -26), 11.0, 17.0)
	frame.color = Color("#c89a64")
	mirror.add_child(frame)
	var glass: Polygon2D = Polygon2D.new()
	glass.polygon = TerrainShapes.ellipse(Vector2(0, -26), 8.0, 14.0)
	glass.color = Color("#bcd8e8")
	mirror.add_child(glass)
	var glint: Polygon2D = Polygon2D.new()
	glint.polygon = TerrainShapes.ellipse(Vector2(-3, -31), 2.5, 5.0, 10)
	glint.color = Color(1, 1, 1, 0.55)
	mirror.add_child(glint)

	register_world_interactable(
		"wardrobe_mirror", mirror, ContentIds.INTERACTION_GENERIC,
		"Press F to open wardrobe", _open_wardrobe
	)

func _open_wardrobe() -> void:
	if _creator_panel != null and _creator_panel.has_method("open_panel"):
		_creator_panel.call("open_panel", true)

# --- Cottage door sign (interiors deferred) ----------------------------------
# TODO(interiors): when interiors land (docs/interiors_plan.md), this sign is
# replaced by a real door interaction routed through WorldRegionManager as a
# server-backed interior instance. Until then the world stays one continuous
# outdoor overworld and NOTHING teleports the player inside.

func _setup_cottage_sign() -> void:
	var sign_marker: Node2D = Node2D.new()
	sign_marker.position = map.grid_to_world(Vector2i(5, 8))
	gameplay_layer.add_child(sign_marker)
	var post: Polygon2D = Polygon2D.new()
	post.polygon = PackedVector2Array([Vector2(-1.5, 0), Vector2(1.5, 0), Vector2(1.5, -16), Vector2(-1.5, -16)])
	post.color = Color("#8a5e3c")
	sign_marker.add_child(post)
	var board: Polygon2D = Polygon2D.new()
	board.polygon = PackedVector2Array([
		Vector2(-10, -25), Vector2(10, -25), Vector2(12, -21), Vector2(10, -14), Vector2(-10, -14), Vector2(-12, -21),
	])
	board.color = Color("#e0bf8a")
	sign_marker.add_child(board)
	for line_y: float in [-22.0, -18.5]:
		var scribble: Polygon2D = Polygon2D.new()
		scribble.polygon = PackedVector2Array([
			Vector2(-7, line_y), Vector2(6, line_y), Vector2(6, line_y + 1.4), Vector2(-7, line_y + 1.4),
		])
		scribble.color = Color("#8a5e3c")
		sign_marker.add_child(scribble)

	register_world_interactable(
		"cottage_door_sign", sign_marker, ContentIds.INTERACTION_GENERIC,
		"Press F to read the door sign", _read_cottage_sign
	)

func _read_cottage_sign() -> void:
	_open_observe_panel(
		"Cottage Door",
		"\"Inside coming soon!\" For now, all of Hearthvale's coziness lives outdoors — the door stays shut while the interior is being furnished (a future update)."
	)

# --- Network bridge (client side) ------------------------------------------------

func _setup_network(player: AvatarController) -> void:
	# Chat / event log first so even offline toasts have somewhere to land.
	_chat_panel = CHAT_PANEL_SCENE.instantiate() as CanvasLayer
	_chat_panel.name = "ChatPanel"
	add_child(_chat_panel)
	_chat_panel.call("setup", player, Callable(self, "_chat_can_open"))

	# Runtime autoload lookup (direct identifier breaks --script validation).
	var session: Node = get_node_or_null("/root/NetworkSession")
	if session == null:
		return
	session.call("register_world", self)
	session.connect("place_denied_received", _on_network_place_denied)
	session.connect("server_materials_changed", _on_server_materials_changed)
	session.connect("gather_result_received", _on_network_gather_result)
	session.connect("gather_denied_received", _on_network_gather_denied)
	var network_panel: CanvasLayer = NETWORK_CONNECT_PANEL_SCENE.instantiate() as CanvasLayer
	network_panel.name = "NetworkConnectPanel"
	add_child(network_panel)
	network_panel.call("setup", _profile_manager)

## Chat may open on Enter only while plain-exploring: never during placement/
## edit/move (Enter places there) and never while a panel is using the keys.
func _chat_can_open() -> bool:
	return (
		not _decorating_mode_active
		and not _is_mailbox_open()
		and not is_observe_panel_open()
		and not _rest_panel_open
	)

## NetworkSession bridge: own avatar position for the sync loop.
func get_player_position() -> Vector2:
	if _network_player != null and is_instance_valid(_network_player):
		return _network_player.global_position
	return Vector2.ZERO

## NetworkSession bridge: where remote player avatars live (y-sorted layer).
func get_network_player_layer() -> Node:
	return gameplay_layer

## NetworkSession bridge: spawn a server-committed placed object. These are
## display-only on the client — not in the local save, not edit/movable.
func spawn_network_placed_object(record: Dictionary) -> Node:
	var content_id: String = String(record.get("content_id", ""))
	if object_registry == null or not object_registry.has_placeable(content_id):
		return null
	var data: PlaceableObjectData = object_registry.get_placeable_data(content_id)
	var node: PlaceableCrate = data.scene.instantiate() as PlaceableCrate
	var tile: Vector2i = Vector2i(int(record.get("tile_x", 0)), int(record.get("tile_y", 0)))
	gameplay_layer.add_child(node)
	node.set_tile_position(tile, map.grid_to_world(tile))
	node.set_placed_visual()
	return node

func _on_network_place_denied(reason: String) -> void:
	# Non-modal: a chat-log line instead of a panel, so building flow continues.
	_chat_toast("Server: placement denied — %s." % reason.to_lower())

func _on_server_materials_changed(materials: Dictionary) -> void:
	if hud.has_method("set_materials_text"):
		var parts: Array[String] = []
		for material_id in ResourceIds.ALL_MATERIALS:
			parts.append("%s %d" % [ResourceIds.display_name(material_id), int(materials.get(material_id, 0))])
		hud.call("set_materials_text", "Server: %s" % " · ".join(parts))

# --- Onboarding -------------------------------------------------------------------

func _show_welcome_if_first_boot() -> void:
	if bool(save_system.get_overworld_flag("welcome_seen", false)):
		return
	save_system.set_overworld_flag("welcome_seen", true)
	_open_observe_panel(
		"Welcome to Hearthvale",
		"Gather wood, stone, fiber, and clay from the piles around your homestead (walk up, press F). "
		+ "Build with B — Tab switches items and shows their cost — and edit with E. "
		+ "Tend the farm plots, check the mailbox, and rest at the cottage door at dusk. "
		+ "The mirror by the cottage opens your wardrobe (F9 works too). "
		+ "F8 opens multiplayer, F10 opens dev tools."
	)

func _build_notice_marker(world_pos: Vector2) -> Node2D:
	# Cozy village notice board: warm frame, little domed roof cap, and a few
	# colorful pinned notes.
	var marker: Node2D = Node2D.new()
	marker.position = world_pos
	gameplay_layer.add_child(marker)
	for px in [-18, 18]:
		var post: Polygon2D = Polygon2D.new()
		post.position = Vector2(px, 0)
		post.color = Color("#a8754a")
		post.polygon = PackedVector2Array([Vector2(-3.5, -40), Vector2(3.5, -40), Vector2(3.5, 10), Vector2(-3.5, 10)])
		marker.add_child(post)
	var frame: Polygon2D = Polygon2D.new()
	frame.position = Vector2(0, -28)
	frame.color = Color("#a8754a")
	frame.polygon = PackedVector2Array([Vector2(-30, -20), Vector2(30, -20), Vector2(30, 20), Vector2(-30, 20)])
	marker.add_child(frame)
	var board: Polygon2D = Polygon2D.new()
	board.position = Vector2(0, -28)
	board.color = Color("#e0bf8a")
	board.polygon = PackedVector2Array([Vector2(-26, -16), Vector2(26, -16), Vector2(26, 16), Vector2(-26, 16)])
	marker.add_child(board)
	var roof: Polygon2D = Polygon2D.new()
	roof.polygon = TerrainShapes.dome(Vector2(0, -48), 34.0, 12.0, 12)
	roof.color = Color("#c97a6a")
	marker.add_child(roof)
	for note_data in [
		[Vector2(-14, -32), Color("#faeecd")],
		[Vector2(2, -26), Color("#e8a0b4")],
		[Vector2(15, -33), Color("#9fc4e8")],
	]:
		var note: Polygon2D = Polygon2D.new()
		note.position = note_data[0]
		note.color = note_data[1]
		note.polygon = PackedVector2Array([Vector2(-6, -7), Vector2(6, -7), Vector2(6, 7), Vector2(-6, 7)])
		marker.add_child(note)
		var pin: Polygon2D = Polygon2D.new()
		pin.position = note_data[0] + Vector2(0, -6)
		pin.color = Color("#c25448")
		pin.polygon = PackedVector2Array([Vector2(0, -1.5), Vector2(1.5, 0), Vector2(0, 1.5), Vector2(-1.5, 0)])
		marker.add_child(pin)
	return marker

func _build_shrine_marker(world_pos: Vector2) -> Node2D:
	# Gentle old shrine: mossy mound, rounded weathered stone, and a soft warm
	# glow with a halo — mysterious but friendly.
	var marker: Node2D = Node2D.new()
	marker.position = world_pos
	gameplay_layer.add_child(marker)
	var mound: Polygon2D = Polygon2D.new()
	mound.color = Color("#7da964")
	mound.polygon = TerrainShapes.ellipse(Vector2(0, 10), 28.0, 10.0, 16)
	marker.add_child(mound)
	var stone: Polygon2D = Polygon2D.new()
	stone.color = Color("#8b8f88")
	stone.polygon = TerrainShapes.ellipse(Vector2(0, 2), 24.0, 12.0, 16)
	marker.add_child(stone)
	var body: Polygon2D = Polygon2D.new()
	body.color = Color("#aab0a3")
	body.polygon = TerrainShapes.ellipse(Vector2(0, -20), 17.0, 21.0, 16)
	marker.add_child(body)
	var moss_cap: Polygon2D = Polygon2D.new()
	moss_cap.color = Color("#7da964")
	moss_cap.polygon = TerrainShapes.dome(Vector2(0, -36), 12.0, 6.0, 10)
	marker.add_child(moss_cap)
	var halo: Polygon2D = Polygon2D.new()
	halo.color = Color(0.95, 0.89, 0.62, 0.25)
	halo.polygon = TerrainShapes.ellipse(Vector2(0, -24), 13.0, 13.0, 16)
	marker.add_child(halo)
	var glow: Polygon2D = Polygon2D.new()
	glow.color = Color(0.95, 0.89, 0.62, 0.9)
	glow.polygon = TerrainShapes.ellipse(Vector2(0, -24), 6.5, 7.5, 12)
	marker.add_child(glow)
	return marker
