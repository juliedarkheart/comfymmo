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
const LAND_PANEL_SCENE := preload("res://ui/land_panel.tscn")
const MINIMAP_SCENE := preload("res://ui/minimap_panel.tscn")
const QUICK_TOOLS_SCENE := preload("res://ui/quick_tools_bar.tscn")
const ADMIN_PANEL_SCENE := preload("res://ui/admin_panel.tscn")
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
var _land_panel: CanvasLayer = null
var _minimap: CanvasLayer = null
var _quick_tools: CanvasLayer = null
var _admin_panel: CanvasLayer = null
var _hud_tick: float = 0.0

func _ready() -> void:
	# Load profiles BEFORE super._ready(): the base spawns the avatar and reads
	# _local_player_name()/_inventory_get_identity() (overridden here to use the
	# profile), so the real username must be available first. Calling
	# get_active_profile() before load would create/overwrite the profiles file.
	_profile_manager.load_profiles()
	super._ready()
	_gather_rng.randomize()
	var player: AvatarController = _find_player()
	_network_player = player
	_refresh_inventory_hud()
	_setup_land_panel()
	_setup_overworld_ui()
	_apply_overworld_camera(player)
	_spawn_village_content(player)
	_spawn_forest_content(player)
	_setup_resource_nodes()
	_setup_dev_overlay(player)
	_setup_wardrobe()
	_setup_cottage_sign()
	_setup_landing_area()
	_setup_plot_markers()
	_setup_town_services()
	_setup_network(player)
	_show_welcome_if_first_boot.call_deferred()

func _setup_land_panel() -> void:
	_land_panel = LAND_PANEL_SCENE.instantiate() as CanvasLayer
	_land_panel.name = "LandPanel"
	add_child(_land_panel)
	_land_panel.call("setup", Callable(self, "_do_claim_plot"))

func _setup_overworld_ui() -> void:
	# Quick tools strip (left), minimap (top-right), admin panel (F7).
	_quick_tools = QUICK_TOOLS_SCENE.instantiate() as CanvasLayer
	_quick_tools.name = "QuickToolsBar"
	add_child(_quick_tools)
	_quick_tools.call("setup", Callable(self, "_crafting_get_count"))

	_minimap = MINIMAP_SCENE.instantiate() as CanvasLayer
	_minimap.name = "MinimapPanel"
	add_child(_minimap)
	var landmarks: Array = [
		{"pos": map.grid_to_world(Vector2i(3, 8)), "color": Color("#bfe6a0")},   # Rowan
		{"pos": map.grid_to_world(Vector2i(29, 19)), "color": Color("#9fc4e8")},  # Clerk Hazel
		{"pos": OverworldMap.VILLAGE_OFFSET + Vector2(96, 272), "color": Color("#f2d469")}, # town fountain
		{"pos": OverworldMap.FOREST_OFFSET + Vector2(136, 166), "color": Color("#c0a0e0")}, # shrine
	]
	var plot_centers: Dictionary = {}
	for plot_id in LandRegistry.claimable_plot_ids():
		var rect: Rect2i = LandRegistry.get_plot(String(plot_id)).get("rect", Rect2i()) as Rect2i
		plot_centers[plot_id] = map.grid_to_world(Vector2i(rect.position.x + rect.size.x / 2, rect.position.y + rect.size.y / 2))
	_minimap.call("setup", landmarks, plot_centers)

	_admin_panel = ADMIN_PANEL_SCENE.instantiate() as CanvasLayer
	_admin_panel.name = "AdminPanel"
	add_child(_admin_panel)
	_admin_panel.call("setup", self)
	_refresh_quick_tools()
	_refresh_minimap_plots()

func _process(delta: float) -> void:
	# Throttled HUD area + minimap player marker updates as the player walks.
	_hud_tick += delta
	if _hud_tick < 0.25:
		return
	_hud_tick = 0.0
	if hud.has_method("set_area_line"):
		hud.call("set_area_line", _player_area_text())
	if _minimap != null:
		_minimap.call("set_player_position", get_player_position())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_minimap"):
		if _minimap != null:
			_minimap.call("toggle_panel")
		_mark_input_handled()
		return
	if event.is_action_pressed("toggle_admin_panel"):
		if _admin_panel != null:
			_admin_panel.call("toggle_panel")
		_mark_input_handled()
		return
	super._unhandled_input(event)

func _refresh_quick_tools() -> void:
	if _quick_tools != null:
		_quick_tools.call("refresh")

func _refresh_minimap_plots() -> void:
	if _minimap == null:
		return
	var profile_id: String = String(_profile_manager.get_active_profile().get("profile_id", ""))
	var plots: Dictionary = _current_land_plots()
	var states: Dictionary = {}
	for plot_id in LandRegistry.claimable_plot_ids():
		var state: Dictionary = LandPlot.normalized_state(plots.get(String(plot_id), {}) as Dictionary)
		if String(state["status"]) != LandPlot.STATUS_OWNED:
			states[plot_id] = "unclaimed"
		elif String(state["owner_profile_id"]) == profile_id:
			states[plot_id] = "owned"
		elif (state["member_profile_ids"] as Array).has(profile_id):
			states[plot_id] = "friend"
		else:
			states[plot_id] = "other"
	_minimap.call("set_plot_states", states)

## Override: real identity from the active profile + current plot status.
func _inventory_get_identity() -> Dictionary:
	var profile: Dictionary = _profile_manager.get_active_profile()
	var connected: bool = false
	var session: Node = get_node_or_null("/root/NetworkSession")
	if session != null and bool(session.call("is_client_connected")):
		connected = true
	return {
		"display_name": String(profile.get("display_name", "Villager")),
		"username": String(profile.get("username", "villager")),
		"profile_id": String(profile.get("profile_id", "")),
		"mode": "Server" if connected else "Offline",
		"plot_status": _player_plot_status_text(),
	}

func _local_player_name() -> String:
	return String(_profile_manager.get_active_profile().get("display_name", "You"))

## Short plot-status label for the HUD/inventory: where the player is standing.
func _player_plot_status_text() -> String:
	var tile: Vector2i = map.world_to_grid(get_player_position())
	var plot: Dictionary = LandRegistry.plot_at_tile(tile)
	if plot.is_empty():
		return "Town/Commons"
	if bool(plot.get("npc_owned", false)):
		return "Rowan's Farm"
	var profile_id: String = String(_profile_manager.get_active_profile().get("profile_id", ""))
	var state: Dictionary = LandPlot.normalized_state(_current_land_plots().get(String(plot["plot_id"]), {}) as Dictionary)
	if String(state["status"]) != LandPlot.STATUS_OWNED:
		return "Unclaimed: %s" % String(plot["display_name"])
	if String(state["owner_profile_id"]) == profile_id:
		return "Your plot"
	if (state["member_profile_ids"] as Array).has(profile_id):
		return "Friend's plot"
	return "%s's plot" % String(state["owner_username"])

## Rich area/plot label for the HUD area line. Classifies by plot, then by
## world region (town/forest/neighborhood/landing). Matches /where.
func _player_area_text() -> String:
	var pos: Vector2 = get_player_position()
	var tile: Vector2i = map.world_to_grid(pos)
	var plot: Dictionary = LandRegistry.plot_at_tile(tile)
	if not plot.is_empty():
		if bool(plot.get("npc_owned", false)):
			return "%s — Tutorial Land" % String(plot["display_name"])
		var profile_id: String = String(_profile_manager.get_active_profile().get("profile_id", ""))
		var state: Dictionary = LandPlot.normalized_state(_current_land_plots().get(String(plot["plot_id"]), {}) as Dictionary)
		if String(state["status"]) != LandPlot.STATUS_OWNED:
			return "%s — Unclaimed" % String(plot["display_name"])
		if String(state["owner_profile_id"]) == profile_id:
			return "%s — Your Plot" % String(plot["display_name"])
		if (state["member_profile_ids"] as Array).has(profile_id):
			return "%s — Friend's Plot" % String(plot["display_name"])
		return "%s — Owned by @%s" % [String(plot["display_name"]), String(state["owner_username"])]
	# Off-plot: classify by world region.
	if pos.x >= 1150.0 and pos.x < 2050.0:
		return "Town Square — Public, protected"
	if pos.x >= 2550.0:
		return "Forest Edge — Wilderness"
	for rect in (map as OverworldMap).neighborhood_rects():
		if (rect as Rect2i).has_point(tile):
			return "Neighborhood — Public path"
	if map.is_tile_in_bounds(tile):
		return "Rowan's Training Farm — Tutorial"
	return "Hearthvale — Wilderness"

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
	Nameplate.attach(maribel, "Maribel Tock", "Villager", Color("#e8c0d4"))
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
	Nameplate.attach(bram, "Bram Nettle", "Villager", Color("#c8d0a0"))
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
	_grant_xp_once("talk_%s" % interactable_id, ProgressionRegistry.SKILL_SOCIAL, 2, 1)

func _open_notice_board() -> void:
	_open_observe_panel("Village Notice Board", "Welcome to the village square. Plans, errands, and little celebrations get pinned here.")
	if not bool(save_system.get_region_flags(VILLAGE_REGION_ID).get(NOTICE_SEEN_FLAG, false)):
		save_system.set_region_flag(VILLAGE_REGION_ID, NOTICE_SEEN_FLAG, true)
	_grant_xp_once("visit_notice_board", ProgressionRegistry.SKILL_STEWARDSHIP, 1, 0)

func _open_shrine() -> void:
	var seen: bool = bool(save_system.get_region_flags(FOREST_REGION_ID).get(SHRINE_SEEN_FLAG, false))
	var body: String = "The marker still hums softly." if seen else "The path beyond is quiet... for now."
	_open_observe_panel("Old Shrine", body)
	if not seen:
		save_system.set_region_flag(FOREST_REGION_ID, SHRINE_SEEN_FLAG, true)
	_grant_xp_once("visit_shrine", ProgressionRegistry.SKILL_EXPLORATION, 1, 0)

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
	var required_tool: String = node.get_required_tool()
	if not required_tool.is_empty() and inventory_system.get_quantity(required_tool) < 1:
		_chat_toast("Requires %s (craft one with K)." % ItemIds.display_name(required_tool))
		return
	if not node.is_ready():
		_chat_toast("This spot is still recovering (%ds)." % node.remaining_seconds())
		return
	var result: Dictionary = node.roll_yield(_gather_rng)
	var material_id: String = String(result.get("material_id", ""))
	var amount: int = int(result.get("amount", 1))
	inventory_system.add_item(material_id, amount)
	node.start_cooldown()
	_grant_xp(ProgressionRegistry.skill_for_material(material_id), 2, 1)
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

func _on_network_craft_result(message: String) -> void:
	_set_crafting_status(message)
	_chat_toast(message)

func _on_network_craft_denied(reason: String) -> void:
	_set_crafting_status(reason)

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

# --- Landing area, Farmer Rowan, neighborhood plots, town services ------------

const ROWAN_TOKEN_FLAG := "rowan_land_token_given"

func _setup_landing_area() -> void:
	# The spawn IS the landing: Rowan's training farm. A welcome board plus
	# Farmer Rowan herself, whose staged dialogue is the tutorial chain.
	var board: Node2D = _make_sign(map.grid_to_world(Vector2i(9, 12)), Color("#e8a0b4"))
	register_world_interactable(
		"landing_welcome_board", board, ContentIds.INTERACTION_GENERIC,
		"Press F to read the welcome board", _read_welcome_board
	)

	var rowan: SimpleVillager = SimpleVillager.new()
	rowan.villager_name = "Farmer Rowan"
	rowan.position = map.grid_to_world(Vector2i(3, 8))
	gameplay_layer.add_child(rowan)
	Nameplate.attach(rowan, "Farmer Rowan", "Mentor", Color("#bfe6a0"))
	register_world_interactable(
		"farmer_rowan", rowan, ContentIds.INTERACTION_VILLAGER,
		"Press F to talk to Farmer Rowan", _talk_rowan
	)

func _read_welcome_board() -> void:
	_open_observe_panel(
		"Welcome to Hearthvale Landing",
		"You're on Farmer Rowan's training farm — learn here, then make a place of your own.\n\n"
		+ "GATHER branches/pebbles/fiber/clay: F   ·   INVENTORY: I   ·   CRAFT: K\n"
		+ "BUILD: B (needs your hammer)   ·   SKILLS: P   ·   FULL HELP: H\n"
		+ "CHAT: Enter   ·   MULTIPLAYER/PROFILE: F8   ·   WARDROBE: F9   ·   FULLSCREEN: F11\n\n"
		+ "Plot signs east and north mark claimable lots — talk to Farmer Rowan for a Land Token, "
		+ "then press F at a sign to Claim it. The village square (east) has the town stalls and notice board."
	)

## Rowan's staged tutorial: each talk reads your actual progress and gives the
## next concrete step. First talk hands over the land token. Lightweight by
## design — the mailbox tasks remain the structured task list.
func _talk_rowan() -> void:
	_grant_xp_once("talk_farmer_rowan", ProgressionRegistry.SKILL_SOCIAL, 2, 1)
	if not bool(save_system.get_overworld_flag(ROWAN_TOKEN_FLAG, false)):
		save_system.set_overworld_flag(ROWAN_TOKEN_FLAG, true)
		inventory_system.add_item(ItemIds.QUEST_LAND_TOKEN, 1)
		_chat_toast("Farmer Rowan gave you a Land Token!")
		_open_observe_panel("Farmer Rowan",
			"Welcome to Hearthvale, neighbor! This is my training farm — practice anything here. "
			+ "Start by gathering: branches, pebbles, fiber, and that soft clay by the fence, all bare-handed. "
			+ "Press K to craft your tools if you ever lose them. And take this Land Token — "
			+ "when you've found your feet, claim a lot at the plot signs east of here.")
		return
	if inventory_system.get_quantity(ItemIds.TOOL_WORN_AXE) < 1:
		_open_observe_panel("Farmer Rowan",
			"Lost your axe? No matter — gather a couple of branches and pebbles, press K, and craft a worn axe by hand. "
			+ "Every tool I know starts from what's lying on the ground.")
		return
	if not _player_owns_any_plot():
		_open_observe_panel("Farmer Rowan",
			"You're handling those tools well! Chop the marked trees for proper wood, mine the boulder out east with a pickaxe. "
			+ "When you're ready for land of your own, take your token to a plot sign — Meadow Lots east, Orchard Lots north.")
		return
	_open_observe_panel("Farmer Rowan",
		"Look at you, a landholder! Build something cozy on your lot — walls, a shed, even a cottage shell. "
		+ "Craft planks and stone blocks at the workbench. And bring friends; Hearthvale grows best together.")

func _player_owns_any_plot() -> bool:
	var profile_id: String = String(_profile_manager.get_active_profile().get("profile_id", ""))
	var plots: Dictionary = _current_land_plots()
	for plot_state in plots.values():
		if String((plot_state as Dictionary).get("owner_profile_id", "")) == profile_id:
			return true
	return false

## The plot id the active profile owns, preferring the one under the player's
## feet (so /invite targets the right lot when they own several); "" if none.
func _player_owned_plot_id() -> String:
	var profile_id: String = String(_profile_manager.get_active_profile().get("profile_id", ""))
	var plots: Dictionary = _current_land_plots()
	var standing_plot: Dictionary = LandRegistry.plot_at_tile(map.world_to_grid(get_player_position()))
	var standing_id: String = String(standing_plot.get("plot_id", ""))
	var first_owned: String = ""
	for plot_id_variant in plots.keys():
		var plot_id: String = String(plot_id_variant)
		if String((plots[plot_id] as Dictionary).get("owner_profile_id", "")) != profile_id:
			continue
		if plot_id == standing_id:
			return plot_id
		if first_owned.is_empty():
			first_owned = plot_id
	return first_owned

func _current_land_plots() -> Dictionary:
	var session: Node = get_node_or_null("/root/NetworkSession")
	if session != null and bool(session.call("is_client_connected")):
		return session.call("get_server_plots") as Dictionary
	var raw: Variant = save_system.get_overworld_flag("land_plots", {})
	return raw as Dictionary if typeof(raw) == TYPE_DICTIONARY else {}

func _setup_plot_markers() -> void:
	# Neighborhood entrance sign + notice board where the road meets the lots.
	var entrance: Node2D = _make_plot_sign(map.grid_to_world(Vector2i(28, 19)), "Hearthvale Neighborhood", Color("#e8c060"))
	register_world_interactable(
		"neighborhood_entrance", entrance, ContentIds.INTERACTION_GENERIC,
		"Press F to read the neighborhood board", _read_neighborhood_board
	)
	for plot_id_variant in LandRegistry.definitions().keys():
		var plot_id: String = String(plot_id_variant)
		if not bool(LandRegistry.get_plot(plot_id).get("claimable", false)):
			continue
		_build_plot_boundary(plot_id)
		var marker: Node2D = _make_plot_sign(
			map.grid_to_world(LandRegistry.marker_tile(plot_id)),
			String(LandRegistry.get_plot(plot_id).get("display_name", plot_id)), Color("#9fc4e8")
		)
		register_world_interactable(
			"plot_marker_%s" % plot_id, marker, ContentIds.INTERACTION_GENERIC,
			"Press F to view %s" % String(LandRegistry.get_plot(plot_id).get("display_name", "plot")), _interact_plot_marker.bind(plot_id)
		)
	# Land clerk at the neighborhood entrance.
	var clerk: BramVillager = BramVillager.new()
	clerk.villager_name = "Clerk Hazel"
	clerk.position = map.grid_to_world(Vector2i(29, 19))
	gameplay_layer.add_child(clerk)
	Nameplate.attach(clerk, "Clerk Hazel", "Land Office", Color("#9fc4e8"))
	register_world_interactable(
		"land_clerk", clerk, ContentIds.INTERACTION_VILLAGER,
		"Press F to talk to the land clerk", _talk_land_clerk
	)

func _read_neighborhood_board() -> void:
	_open_observe_panel(
		"Hearthvale Neighborhood",
		"Homestead lots for cozy folk! Each lot is a full yard — room for a cottage shell, garden, shed, "
		+ "fences, paths and decor. Walk up to a lot's sign and press F to Claim it (one Land Token; "
		+ "Farmer Rowan hands those out). Lots are marked by corner posts and a boundary. "
		+ "Own one? Build anywhere inside it (B), and /invite <username> a friend on a server. "
		+ "Open the minimap (M) to find your way around."
	)

## Draw corner posts + a soft boundary outline so a plot reads as a real yard.
func _build_plot_boundary(plot_id: String) -> void:
	var corners: Array = LandRegistry.corner_tiles(plot_id)
	var boundary: Line2D = Line2D.new()
	boundary.width = 3.0
	boundary.default_color = Color(0.94, 0.86, 0.55, 0.55)
	boundary.z_index = -5
	for corner_tile in corners:
		boundary.add_point(map.grid_to_world(corner_tile as Vector2i))
	boundary.add_point(map.grid_to_world(corners[0] as Vector2i))
	gameplay_layer.add_child(boundary)
	for corner_tile in corners:
		var post: Node2D = Node2D.new()
		post.position = map.grid_to_world(corner_tile as Vector2i)
		gameplay_layer.add_child(post)
		var stake: Polygon2D = Polygon2D.new()
		stake.polygon = PackedVector2Array([Vector2(-2.5, 0), Vector2(2.5, 0), Vector2(2.5, -22), Vector2(-2.5, -22)])
		stake.color = Color("#a8754a")
		post.add_child(stake)
		var cap: Polygon2D = Polygon2D.new()
		cap.polygon = TerrainShapes.ellipse(Vector2(0, -23), 4.5, 2.5, 8)
		cap.color = Color("#d8b572")
		post.add_child(cap)

## A large, readable plot/area sign with a title plate.
func _make_plot_sign(world_pos: Vector2, title: String, accent: Color) -> Node2D:
	var sign_marker: Node2D = Node2D.new()
	sign_marker.position = world_pos
	gameplay_layer.add_child(sign_marker)
	for px: float in [-12.0, 12.0]:
		var post: Polygon2D = Polygon2D.new()
		post.polygon = PackedVector2Array([Vector2(px - 3, 0), Vector2(px + 3, 0), Vector2(px + 3, -34), Vector2(px - 3, -34)])
		post.color = Color("#8a5e3c")
		sign_marker.add_child(post)
	var board: Polygon2D = Polygon2D.new()
	board.polygon = PackedVector2Array([Vector2(-30, -56), Vector2(30, -56), Vector2(33, -48), Vector2(30, -30), Vector2(-30, -30), Vector2(-33, -48)])
	board.color = Color("#e0bf8a")
	sign_marker.add_child(board)
	var ribbon: Polygon2D = Polygon2D.new()
	ribbon.polygon = PackedVector2Array([Vector2(-30, -52), Vector2(30, -52), Vector2(30, -47), Vector2(-30, -47)])
	ribbon.color = accent
	sign_marker.add_child(ribbon)
	var plate: Label = Label.new()
	plate.text = title
	plate.position = Vector2(-60, -48)
	plate.custom_minimum_size = Vector2(120, 0)
	plate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.add_theme_font_size_override("font_size", 11)
	plate.add_theme_color_override("font_color", Color("#4a3420"))
	sign_marker.add_child(plate)
	return sign_marker

func _talk_land_clerk() -> void:
	_grant_xp_once("talk_land_clerk", ProgressionRegistry.SKILL_SOCIAL, 2, 1)
	var tokens: int = _crafting_get_count(ItemIds.QUEST_LAND_TOKEN)
	var lines: Array[String] = [
		"Land office, at your service! You hold %d Land Token%s." % [tokens, "" if tokens == 1 else "s"],
		"",
		"Current registry:",
	]
	var plots: Dictionary = _current_land_plots()
	for plot_id in LandRegistry.definitions().keys():
		lines.append("· %s" % LandClaimSystem.describe(String(plot_id), plots))
	lines.append("")
	lines.append("To claim: walk to a plot sign (the blue-ribbon posts east and north) and press F — a panel will let you Claim it. One token each. Town and Rowan's farm stay public. Own a plot? Share it with /invite <username> on a server.")
	_open_observe_panel("Clerk Hazel — Land Office", "\n".join(lines))

## Plot sign interaction: opens the land panel with full info + a Claim button.
## (Keyboard F opens the panel; the panel's Claim button does the actual claim
## via _do_claim_plot, so the flow is visible and mouse-friendly.)
func _interact_plot_marker(plot_id: String) -> void:
	var plots: Dictionary = _current_land_plots()
	var plot: Dictionary = LandRegistry.get_plot(plot_id)
	var state: Dictionary = LandPlot.normalized_state(plots.get(plot_id, {}) as Dictionary)
	var profile_id: String = String(_profile_manager.get_active_profile().get("profile_id", ""))
	var tokens: int = _crafting_get_count(ItemIds.QUEST_LAND_TOKEN)
	var cost: int = int(plot.get("price_tokens", 1))
	var status: String = String(state["status"])
	var is_owner: bool = status == LandPlot.STATUS_OWNED and String(state["owner_profile_id"]) == profile_id

	var owner_text: String = "Unclaimed"
	var permission_text: String = ""
	var can_claim: bool = false
	if status == LandPlot.STATUS_OWNED:
		owner_text = String(state["owner_username"])
		if is_owner:
			permission_text = "You own this plot — you can build here."
		elif (state["member_profile_ids"] as Array).has(profile_id):
			permission_text = "You're a member here — you can build."
		else:
			permission_text = "You cannot build here (not the owner)."
	else:
		if tokens >= cost:
			can_claim = true
			permission_text = "Available! Claim it to build here."
		else:
			permission_text = "You need %d Land Token to claim this (talk to Farmer Rowan)." % cost

	var rect: Rect2i = plot.get("rect", Rect2i()) as Rect2i
	_land_panel.call("open_for_plot", {
		"plot_id": plot_id,
		"display_name": String(plot.get("display_name", plot_id)),
		"size_text": "Homestead Plot · %d×%d tiles · Neighborhood" % [rect.size.x, rect.size.y],
		"status_text": status.capitalize(),
		"owner": owner_text,
		"members": (state["member_profile_ids"] as Array).size(),
		"cost": cost,
		"tokens": tokens,
		"permission_text": permission_text,
		"can_claim": can_claim,
		"is_owner": is_owner,
	})

## Executes a claim (panel Claim button callback). Connected = server-
## authoritative; offline = local save. Refreshes HUD/inventory either way.
func _do_claim_plot(plot_id: String) -> void:
	var session: Node = get_node_or_null("/root/NetworkSession")
	if session != null and bool(session.call("is_client_connected")):
		session.call("request_claim_plot", plot_id)
		return
	var plots: Dictionary = _current_land_plots()
	var profile: Dictionary = _profile_manager.get_active_profile()
	var result: Dictionary = LandClaimSystem.attempt_claim(
		plot_id, String(profile.get("profile_id", "")), String(profile.get("username", "")), plots,
		func(item_id: String, amount: int) -> bool: return inventory_system.get_quantity(item_id) >= amount,
		func(item_id: String, amount: int) -> void: inventory_system.remove_item(item_id, amount)
	)
	if not bool(result["ok"]):
		_chat_toast("%s." % String(result["reason"]))
		return
	plots[plot_id] = result["state"]
	save_system.set_overworld_flag("land_plots", plots)
	_grant_xp(ProgressionRegistry.SKILL_STEWARDSHIP, 5, 3)
	refresh_inventory_panel()
	_refresh_minimap_plots()
	_chat_toast("You claimed %s! Build anywhere inside it (B)." % String(LandRegistry.get_plot(plot_id).get("display_name", plot_id)))

func _setup_town_services() -> void:
	# Outdoor service stalls around the village square: visual kiosks with
	# friendly "coming soon" panels — the town structure ahead of the economy.
	var c: Vector2 = OverworldMap.VILLAGE_OFFSET
	var services: Array = [
		["town_general_store", "General Store", c + Vector2(220, 240), "Seeds, snacks, and sundries — trading opens with the economy update."],
		["town_builder_supply", "Builder Supply", c + Vector2(-40, 160), "Planks and blocks by the bundle — for now, craft your own at a workbench (K)."],
		["town_farm_supply", "Farming Supply", c + Vector2(200, 400), "Tools and seeds someday; today, Rowan's farm west of here teaches it free."],
		["town_wardrobe_stall", "Wardrobe Stall", c + Vector2(-100, 380), "Fashion forward! Craft wearables (K) and try looks at any mirror (F9)."],
	]
	for service in services:
		var stall: Node2D = _make_sign(service[2] as Vector2, Color("#f2d469"))
		var service_id: String = String(service[0])
		var service_name: String = String(service[1])
		var blurb: String = String(service[3])
		register_world_interactable(
			service_id, stall, ContentIds.INTERACTION_GENERIC,
			"Press F to visit %s" % service_name,
			func() -> void: _open_observe_panel("%s (coming soon)" % service_name, blurb)
		)

func _make_sign(world_pos: Vector2, accent: Color) -> Node2D:
	var sign_marker: Node2D = Node2D.new()
	sign_marker.position = world_pos
	gameplay_layer.add_child(sign_marker)
	var post: Polygon2D = Polygon2D.new()
	post.polygon = PackedVector2Array([Vector2(-2, 0), Vector2(2, 0), Vector2(2, -20), Vector2(-2, -20)])
	post.color = Color("#8a5e3c")
	sign_marker.add_child(post)
	var board: Polygon2D = Polygon2D.new()
	board.polygon = PackedVector2Array([
		Vector2(-13, -32), Vector2(13, -32), Vector2(15, -27), Vector2(13, -19), Vector2(-13, -19), Vector2(-15, -27),
	])
	board.color = Color("#e0bf8a")
	sign_marker.add_child(board)
	var ribbon: Polygon2D = Polygon2D.new()
	ribbon.polygon = PackedVector2Array([Vector2(-10, -29), Vector2(10, -29), Vector2(10, -26), Vector2(-10, -26)])
	ribbon.color = accent
	sign_marker.add_child(ribbon)
	return sign_marker

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
	_chat_panel.call("setup", player, Callable(self, "_chat_can_open"), Callable(self, "_handle_chat_command"))

	# Runtime autoload lookup (direct identifier breaks --script validation).
	var session: Node = get_node_or_null("/root/NetworkSession")
	if session == null:
		return
	session.call("register_world", self)
	session.connect("place_denied_received", _on_network_place_denied)
	session.connect("server_materials_changed", _on_server_materials_changed)
	session.connect("gather_result_received", _on_network_gather_result)
	session.connect("gather_denied_received", _on_network_gather_denied)
	session.connect("craft_result_received", _on_network_craft_result)
	session.connect("craft_denied_received", _on_network_craft_denied)
	session.connect("claim_result_received", _chat_toast)
	session.connect("server_plots_changed", _on_server_plots_changed)
	building_placement_system.set_builder_profile(
		String(_profile_manager.get_active_profile().get("profile_id", ""))
	)
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
	# Track network-committed crafting stations so the crafting panel's
	# "station nearby" preview matches the server's own check.
	if CraftingRegistry.station_ids().has(content_id):
		_network_stations.append({"content_id": content_id, "position": map.grid_to_world(tile)})
	return node

## Prototype admin/world-builder command (trust-based, like F10 dev tools —
## documented in docs/crafting.md). Offline-only: the server ignores commands.
##   /give <material_or_component_id> [amount]
func _handle_chat_command(text: String) -> void:
	var parts: PackedStringArray = text.split(" ", false)
	if parts.is_empty():
		return
	match String(parts[0]).to_lower():
		"/give":
			var session: Node = get_node_or_null("/root/NetworkSession")
			if session != null and bool(session.call("is_client_connected")):
				_chat_toast("Admin commands are offline-only for now.")
				return
			if parts.size() < 2:
				_chat_toast("Usage: /give <id> [amount] — e.g. /give plank 10")
				return
			var item_id: String = String(parts[1]).to_lower()
			var amount: int = clampi(int(parts[2]) if parts.size() > 2 else 1, 1, 999)
			if not ItemIds.is_storable(item_id) and ContentRegistry.items().get(item_id, {}).is_empty():
				_chat_toast("Unknown id '%s'. Try wood, plank, worn_axe, land_token..." % item_id)
				return
			inventory_system.add_item(item_id, amount)
			_chat_toast("(admin) +%d %s" % [amount, ItemIds.display_name(item_id)])
		"/xp":
			if _admin_commands_blocked():
				return
			var xp_amount: int = clampi(int(parts[1]) if parts.size() > 1 else 10, 1, 9999)
			_grant_xp("", 0, xp_amount)
			_chat_toast("(admin) +%d player XP — %s" % [xp_amount, PlayerProgression.progress_text(save_system.get_player_xp())])
		"/skillxp":
			if _admin_commands_blocked():
				return
			if parts.size() < 2 or not ProgressionRegistry.SKILL_IDS.has(String(parts[1]).to_lower()):
				_chat_toast("Usage: /skillxp <skill> [amount] — skills: %s" % ", ".join(ProgressionRegistry.SKILL_IDS))
				return
			var skill_id: String = String(parts[1]).to_lower()
			var skill_amount: int = clampi(int(parts[2]) if parts.size() > 2 else 10, 1, 9999)
			_grant_xp(skill_id, skill_amount, 0)
			_chat_toast("(admin) +%d %s XP" % [skill_amount, ProgressionRegistry.skill_display_name(skill_id)])
		"/help":
			_chat_toast("Player: /skills /progression /invite <user> /where  ·  Admin: /give <id> [n] /xp [n] /adminbuild /plots /plotinfo <id> /inspect /claimplot <id> <user> /unclaimplot <id> /save /announce")
		"/adminbuild":
			if _admin_commands_blocked():
				return
			building_placement_system.set_admin_bypass(not building_placement_system.admin_bypass)
			_chat_toast("(admin) World-builder mode %s — costs, tools, land, and locks %s." % [
				"ON" if building_placement_system.admin_bypass else "OFF",
				"bypassed" if building_placement_system.admin_bypass else "enforced",
			])
		"/where":
			var where_pos: Vector2 = get_player_position()
			var where_tile: Vector2i = map.world_to_grid(where_pos)
			var where_plot: Dictionary = LandRegistry.plot_at_tile(where_tile)
			_chat_toast("Position (%d, %d) · tile (%d, %d) · %s · %s" % [
				int(where_pos.x), int(where_pos.y), where_tile.x, where_tile.y,
				DevToolState.area_label(where_pos),
				String(where_plot.get("display_name", "public commons")) if not where_plot.is_empty() else "public commons",
			])
		"/save":
			if _admin_commands_blocked():
				return
			save_system.save_save_data(save_system.load_save_data())
			_chat_toast("(admin) Local save written.")
			refresh_inventory_panel()
		"/plots":
			_admin_list_plots()
		"/plotinfo", "/inspect":
			_admin_plot_info(parts)
		"/claimplot":
			_admin_claimplot(parts)
		"/unclaimplot":
			_admin_unclaimplot(parts)
		"/announce":
			if _admin_commands_blocked():
				return
			_chat_toast("[Announcement] %s" % text.substr(10).strip_edges())
		"/invite":
			_handle_invite_command(parts)
		"/skills", "/progression":
			var progression: Dictionary = _get_progression_snapshot()
			var lines: Array[String] = [PlayerProgression.progress_text(int(progression["total_xp"]))]
			for listed_skill_id in ProgressionRegistry.SKILL_IDS:
				lines.append("%s %d" % [
					ProgressionRegistry.skill_display_name(listed_skill_id),
					SkillProgression.skill_level(progression, listed_skill_id),
				])
			_chat_toast(" · ".join(lines))
		_:
			_chat_toast("Commands: /give /xp /skillxp /skills /progression /invite <username> /where")

## Plot owner shares a plot with a friend by username. Multiplayer-only: the
## server resolves the username to a registered profile and updates the plot's
## member list (server-authoritative). Offline there's only your single local
## identity, so there's no one to invite.
func _handle_invite_command(parts: PackedStringArray) -> void:
	var session: Node = get_node_or_null("/root/NetworkSession")
	if session == null or not bool(session.call("is_client_connected")):
		_chat_toast("Invites need a server (connect with F8) — that's where friends register a username.")
		return
	if parts.size() < 2:
		_chat_toast("Usage: /invite <username> — shares the plot you own with that player.")
		return
	var owned_plot_id: String = _player_owned_plot_id()
	if owned_plot_id.is_empty():
		_chat_toast("Claim a plot first (at a plot sign), then invite friends to build on it.")
		return
	session.call("request_invite", owned_plot_id, String(parts[1]))

func _admin_commands_blocked() -> bool:
	var session: Node = get_node_or_null("/root/NetworkSession")
	if session != null and bool(session.call("is_client_connected")):
		_chat_toast("Admin commands are offline-only for now.")
		return true
	return false

# --- Admin plot commands (offline world-builder) -------------------------------

func _admin_list_plots() -> void:
	var plots: Dictionary = _current_land_plots()
	var lines: Array[String] = ["Plots (id — name — bounds — status):"]
	for plot_id in LandRegistry.definitions().keys():
		var plot: Dictionary = LandRegistry.get_plot(String(plot_id))
		var rect: Rect2i = plot.get("rect", Rect2i()) as Rect2i
		var state: Dictionary = LandPlot.normalized_state(plots.get(String(plot_id), {}) as Dictionary)
		var owner: String = "npc" if bool(plot.get("npc_owned", false)) else (
			"@%s" % String(state["owner_username"]) if String(state["status"]) == LandPlot.STATUS_OWNED else "unclaimed"
		)
		lines.append("· %s — %s — [%d,%d %dx%d] — %s" % [
			String(plot_id), String(plot.get("display_name", "")),
			rect.position.x, rect.position.y, rect.size.x, rect.size.y, owner,
		])
	_open_observe_panel("Plot Registry (/plots)", "\n".join(lines))

func _admin_plot_info(parts: PackedStringArray) -> void:
	var plot_id: String = String(parts[1]) if parts.size() > 1 else String(LandRegistry.plot_at_tile(map.world_to_grid(get_player_position())).get("plot_id", ""))
	if plot_id.is_empty() or not LandRegistry.has_plot(plot_id):
		_chat_toast("Stand on a plot or use /plotinfo <plot_id>. See /plots for ids.")
		return
	var plot: Dictionary = LandRegistry.get_plot(plot_id)
	var rect: Rect2i = plot.get("rect", Rect2i()) as Rect2i
	var state: Dictionary = LandPlot.normalized_state(_current_land_plots().get(plot_id, {}) as Dictionary)
	_open_observe_panel("Plot: %s" % String(plot.get("display_name", plot_id)), "\n".join([
		"id: %s" % plot_id,
		"area: %s" % String(plot.get("area_id", "")),
		"bounds (tiles): [%d, %d] size %dx%d" % [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
		"claimable: %s · npc_owned: %s" % [str(bool(plot.get("claimable", false))), str(bool(plot.get("npc_owned", false)))],
		"status: %s" % String(state["status"]),
		"owner: %s" % (String(state["owner_username"]) if String(state["status"]) == LandPlot.STATUS_OWNED else "—"),
		"members: %d" % (state["member_profile_ids"] as Array).size(),
	]))

func _admin_claimplot(parts: PackedStringArray) -> void:
	if _admin_commands_blocked():
		return
	if parts.size() < 2 or not LandRegistry.has_plot(String(parts[1])):
		_chat_toast("Usage: /claimplot <plot_id> [username]. See /plots.")
		return
	var plot_id: String = String(parts[1])
	if not bool(LandRegistry.get_plot(plot_id).get("claimable", false)):
		_chat_toast("That plot is not claimable.")
		return
	var profile: Dictionary = _profile_manager.get_active_profile()
	var username: String = String(parts[2]) if parts.size() > 2 else String(profile.get("username", "admin"))
	var plots: Dictionary = _current_land_plots()
	var state: Dictionary = LandPlot.default_state()
	state["status"] = LandPlot.STATUS_OWNED
	state["owner_profile_id"] = String(profile.get("profile_id", "")) if parts.size() <= 2 else "admin_assigned_%s" % username
	state["owner_username"] = username
	state["claimed_at"] = Time.get_datetime_string_from_system(true)
	plots[plot_id] = state
	save_system.set_overworld_flag("land_plots", plots)
	refresh_inventory_panel()
	_refresh_minimap_plots()
	_chat_toast("(admin) %s assigned to @%s." % [plot_id, username])

func _admin_unclaimplot(parts: PackedStringArray) -> void:
	if _admin_commands_blocked():
		return
	if parts.size() < 2 or not LandRegistry.has_plot(String(parts[1])):
		_chat_toast("Usage: /unclaimplot <plot_id>. See /plots.")
		return
	var plots: Dictionary = _current_land_plots()
	plots[String(parts[1])] = LandPlot.default_state()
	save_system.set_overworld_flag("land_plots", plots)
	refresh_inventory_panel()
	_refresh_minimap_plots()
	_chat_toast("(admin) %s is now unclaimed." % String(parts[1]))

# --- Admin panel hooks ---------------------------------------------------------

func admin_get_info() -> Dictionary:
	return {
		"role": "owner (offline)" if not _is_crafting_connected() else "player (server)",
		"area": _player_area_text(),
		"admin_build": building_placement_system.admin_bypass,
	}

func admin_teleport(destination: String) -> void:
	if _network_player == null or not is_instance_valid(_network_player):
		return
	var target_tile: Vector2i
	match destination:
		"neighborhood":
			target_tile = Vector2i(28, 26)
		"town":
			_network_player.global_position = OverworldMap.VILLAGE_OFFSET + Vector2(96, 320)
			return
		_:
			target_tile = map.get_spawn_tile()
	_network_player.global_position = map.grid_to_world(target_tile)

func admin_toggle_plot_debug() -> void:
	if _minimap != null:
		# Reuse the minimap's admin debug outline as the plot-debug overlay.
		_minimap.call("set_admin_debug", true)
	_chat_toast("(admin) Plot debug overlay on the minimap toggled on.")

func _on_network_place_denied(reason: String) -> void:
	# Non-modal: a chat-log line instead of a panel, so building flow continues.
	_chat_toast("Server: placement denied — %s." % reason.to_lower())

func _on_server_materials_changed(_materials: Dictionary) -> void:
	# Keep the inventory panel + HUD (materials/tokens/level via _crafting_get_count)
	# in step with the authoritative server pouch.
	refresh_inventory_panel()

func _on_server_plots_changed(_plots: Dictionary) -> void:
	refresh_inventory_panel()
	_refresh_minimap_plots()

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
