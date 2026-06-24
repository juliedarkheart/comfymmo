extends OutdoorAreaController
class_name HomesteadController

@onready var map: HomesteadMap = $Map
@onready var gameplay_layer: Node2D = $Map/GameplayLayer
@onready var farm_plot_carrot: FarmPlot = $Map/GameplayLayer/FarmPlotCarrot
@onready var farm_plot_turnip: FarmPlot = $Map/GameplayLayer/FarmPlotTurnip
@onready var farm_plot_berry: FarmPlot = $Map/GameplayLayer/FarmPlotBerry
@onready var player_spawn_system: PlayerSpawnSystem = $PlayerSpawnSystem
@onready var save_system: LocalSaveSystem = $LocalSaveSystem
@onready var object_registry: ObjectRegistry = $ObjectRegistry
@onready var game_state_manager: GameStateManager = $GameStateManager
@onready var building_placement_system: BuildingPlacementSystem = $BuildingPlacementSystem
@onready var interactable_system: InteractableSystem = $InteractableSystem
@onready var inventory_system: InventorySystem = $InventorySystem
@onready var farming_system: FarmingSystem = $FarmingSystem
@onready var creature_system: CreatureSystem = $CreatureSystem
@onready var survival_system: SurvivalSystem = $SurvivalSystem
@onready var task_integration_system: TaskIntegrationSystem = $TaskIntegrationSystem
@onready var combat_system: CombatSystem = $CombatSystem
@onready var dungeon_system: DungeonSystem = $DungeonSystem
@onready var hud: CanvasLayer = $HUD
var _decorating_mode_active: bool = false
# _observe_panel_open + the observe-panel open/close lifecycle now live in
# OutdoorAreaController; this controller only provides the placement-aware hooks.
var _rest_panel_open: bool = false
var _rest_phase: String = ""
var _rest_marker: Node2D = null
var _ambient_creatures: Dictionary = {}
# Constant names kept (referenced across this controller); values now come from
# ContentIds so the stable ids live in one place. Strings are unchanged.
const REGION_ID: String = ContentIds.AREA_HOMESTEAD
const REST_INTERACTABLE_ID: String = "homestead_rest"
const CARROT_ITEM_ID: String = ContentIds.ITEM_CARROT
const TURNIP_ITEM_ID: String = ContentIds.ITEM_TURNIP
const BERRY_ITEM_ID: String = ContentIds.ITEM_BERRY
const CARROT_COMFORT_BONUS: float = 5.0
const LEGACY_FARM_PLOT_ID: String = ContentIds.FARM_PLOT_LEGACY_MAIN
const FARM_PLOT_CARROT_ID: String = ContentIds.FARM_PLOT_CARROT
const FARM_PLOT_TURNIP_ID: String = ContentIds.FARM_PLOT_TURNIP
const FARM_PLOT_BERRY_ID: String = ContentIds.FARM_PLOT_BERRY
const STARTER_SEED_PACKET_COUNT: int = 6
const FARM_SEED_ITEM_IDS: Array[String] = [
	ContentIds.ITEM_PLACEHOLDER_SEED_PACKET,
	ResourceIds.COMPONENT_SEED_PACKET,
]
const CRAFTING_PANEL_SCENE := preload("res://ui/crafting_panel.tscn")
const INVENTORY_PANEL_SCENE := preload("res://ui/inventory_panel.tscn")
const BUILD_MENU_SCENE := preload("res://ui/build_menu_panel.tscn")
const INTERIOR_VIEW_SCENE := preload("res://ui/interior_view.tscn")
const SYSTEM_MENU_SCENE := preload("res://ui/system_menu.tscn")
const STATION_RADIUS := 110.0

var _farm_plots: Dictionary = {}
var _crafting_panel: CanvasLayer = null
var _progression_panel: CanvasLayer = null
var _inventory_panel: CanvasLayer = null
var _build_menu: CanvasLayer = null
var _interior_view: CanvasLayer = null
var _system_menu: CanvasLayer = null
var _local_player: AvatarController = null
var _local_nameplate: Node2D = null
var _selected_farming_item_id: String = ""
# Session-once XP marks (e.g. "talk_ow_maribel") so social/exploration XP
# can't be farmed by spamming one villager/creature. Resets each boot.
var _session_xp_marks: Dictionary = {}
# Network-committed station positions (content_id, world position) so the
# panel's preview matches the server's station check while connected.
var _network_stations: Array = []

func _ready() -> void:
	game_state_manager.configure(save_system, object_registry)
	inventory_system.configure(object_registry)
	inventory_system.load_from_data(game_state_manager.get_player_section("inventory"))
	_grant_starter_kit_once()
	_grant_starter_seed_packet_once()
	farming_system.load_from_data(game_state_manager.get_region_section(REGION_ID, "farming"))
	_configure_farm_plots()
	creature_system.load_from_data(game_state_manager.get_world_section("creatures"))
	survival_system.load_from_data(game_state_manager.get_player_section("survival"))
	task_integration_system.load_from_data(game_state_manager.get_task_section("integration"))
	dungeon_system.configure(combat_system)
	inventory_system.inventory_changed.connect(_on_inventory_changed)
	survival_system.survival_changed.connect(_on_survival_changed)

	var player: AvatarController = player_spawn_system.spawn_player(gameplay_layer, map.get_spawn_position())
	interactable_system.configure(player)
	_setup_area_content(player)
	building_placement_system.configure(
		map,
		gameplay_layer,
		save_system,
		object_registry,
		interactable_system,
		REGION_ID
	)
	# Survival-lite: building consumes materials from the player inventory.
	building_placement_system.set_inventory_system(inventory_system)
	building_placement_system.object_placed.connect(_on_object_placed_for_xp)
	_setup_crafting_panel()
	_setup_progression_panel()
	_setup_inventory_panel()
	_setup_build_menu()
	_local_player = player
	_local_nameplate = Nameplate.attach(player, _local_player_name(), "You", Color("#bfe0ff"))
	_refresh_mailbox_world_state()
	building_placement_system.decorating_mode_changed.connect(_on_decorating_mode_changed.bind(player))
	building_placement_system.decorating_mode_label_changed.connect(_on_decorating_mode_label_changed)
	interactable_system.interaction_prompt_changed.connect(_on_interaction_prompt_changed)
	interactable_system.interaction_requested.connect(_on_interaction_requested)
	_register_farm_plot_interactions()
	_refresh_all_farm_plot_visuals("")
	_refresh_inventory_hud()
	_refresh_survival_hud()
	_apply_saved_mood()
	_apply_saved_day()
	_after_area_setup(player)

func _unhandled_input(event: InputEvent) -> void:
	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == KEY_T
		and _can_cycle_mood()
	):
		_cycle_mood()
		_mark_input_handled()
		return

	if _rest_panel_open:
		if event is InputEventKey and event.pressed and not event.echo:
			if _rest_phase == "confirm":
				if event.keycode == KEY_F:
					_confirm_rest()
					_mark_input_handled()
				elif event.keycode == KEY_ESCAPE:
					_close_rest_panel()
					_mark_input_handled()
			elif event.keycode == KEY_ESCAPE or event.keycode == KEY_F:
				_close_rest_panel()
				_mark_input_handled()
		return

	if _observe_panel_open:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			_close_observe_panel()
			_mark_input_handled()
		return

	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == KEY_I
		and not _is_mailbox_open()
	):
		_toggle_inventory_panel()
		_mark_input_handled()
		return

	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == KEY_K
		and not _is_mailbox_open()
		and not _decorating_mode_active
	):
		_toggle_crafting_panel()
		_mark_input_handled()
		return

	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == KEY_P
		and not _is_mailbox_open()
		and not _decorating_mode_active
	):
		if _progression_panel != null:
			_progression_panel.call("toggle_panel")
		_mark_input_handled()
		return

	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == KEY_H
		and not _is_mailbox_open()
		and not _decorating_mode_active
	):
		_open_help_panel()
		_mark_input_handled()
		return

	if (
		not _is_mailbox_open()
		and event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == KEY_C
		and not _decorating_mode_active
	):
		_consume_carrot()
		_mark_input_handled()
		return

	if event is InputEventKey and event.echo:
		return

	if event.is_action_pressed("toggle_system_menu"):
		# Esc with no panel open: mailbox closes first; otherwise (when not in
		# build/edit mode, which the placement system handles) open the system
		# menu. While decorating, don't consume Esc — let placement exit its mode.
		if _is_mailbox_open():
			_close_mailbox()
			_mark_input_handled()
		elif not _decorating_mode_active:
			_toggle_system_menu()
			_mark_input_handled()
		return

func _on_decorating_mode_changed(is_active: bool, player: AvatarController) -> void:
	_decorating_mode_active = is_active
	# Build/edit own placement interactions, but walking/camera follow should stay active.
	player.set_movement_enabled(true)
	interactable_system.set_interactions_enabled(not is_active and not _is_mailbox_open())
	# Show the build menu while placing (it drives item selection); hide it when
	# leaving build/edit.
	if _build_menu != null:
		if is_active and building_placement_system.is_placement_active():
			_build_menu.call("open_panel")
		else:
			_build_menu.call("close_panel")

func _on_decorating_mode_label_changed(mode_name: String, help_text: String) -> void:
	if hud.has_method("set_mode_text"):
		hud.call("set_mode_text", mode_name, help_text)

func _on_interaction_prompt_changed(prompt_text: String) -> void:
	if hud.has_method("set_interaction_prompt"):
		hud.call("set_interaction_prompt", prompt_text)

	_refresh_all_farm_plot_visuals(interactable_system.get_nearest_interactable_id())

func _on_interaction_requested(interactable_id: String, interaction_type: String) -> void:
	if _decorating_mode_active or _is_mailbox_open() or _observe_panel_open or _rest_panel_open:
		return

	match interaction_type:
		ContentIds.INTERACTION_MAILBOX:
			# Mailboxes are registered by BuildingPlacementSystem (no callback), so
			# they stay on the explicit match, like the farming-owned plots below.
			_open_mailbox()
		ContentIds.INTERACTION_CRAFTING_STATION:
			# Stations are placed objects registered by BuildingPlacementSystem.
			_open_crafting_panel()
		ContentIds.INTERACTION_PREFAB_DOOR:
			_enter_prefab_interior(interactable_id)
		ContentIds.INTERACTION_FARM_PLOT:
			_handle_farm_plot_interaction(interactable_id)
		_:
			# Everything registered through register_world_interactable (creatures,
			# rest, and the overworld's villagers/notice/shrine) dispatches via its
			# bound callback. The guards above ran first, exactly as before.
			if _dispatch_world_interactable(interactable_id):
				return
			# Fallback: a placed contract prop (e.g. a crate) registered directly with the
			# interactable system shows its contract response — so its prompt is never silent.
			var placed_response: String = building_placement_system.placed_contract_response(interactable_id)
			if not placed_response.is_empty():
				_announce(placed_response)

func _on_inventory_changed() -> void:
	_save_inventory_state()
	_refresh_inventory_hud()
	if _crafting_panel != null and bool(_crafting_panel.call("is_open")):
		_crafting_panel.call("refresh")
	refresh_inventory_panel()

## Rebuild the inventory panel + HUD lines + quick tools. Public so the
## overworld controller can call it on a server materials/plot update too.
func refresh_inventory_panel() -> void:
	if _inventory_panel != null and bool(_inventory_panel.call("is_open")):
		_inventory_panel.call("refresh")
	_refresh_inventory_hud()
	_refresh_quick_tools()

## Quick-tools strip refresh hook. Base has no strip; overworld owns it.
func _refresh_quick_tools() -> void:
	pass

func set_selected_farming_item(item_id: String) -> void:
	_selected_farming_item_id = item_id.strip_edges()

# --- Crafting -------------------------------------------------------------------

func _setup_crafting_panel() -> void:
	_crafting_panel = CRAFTING_PANEL_SCENE.instantiate() as CanvasLayer
	_crafting_panel.name = "CraftingPanel"
	add_child(_crafting_panel)
	_crafting_panel.call(
		"setup",
		Callable(self, "_crafting_get_count"),
		Callable(self, "_crafting_get_level"),
		Callable(self, "_nearby_station_ids"),
		Callable(self, "_attempt_craft"),
		Callable(self, "_crafting_get_skills")
	)

func _toggle_crafting_panel() -> void:
	if _crafting_panel == null:
		return
	if bool(_crafting_panel.call("is_open")):
		_crafting_panel.call("close_panel")
	else:
		_open_crafting_panel()

func _open_crafting_panel() -> void:
	if _crafting_panel != null:
		_crafting_panel.call("open_panel")

func _is_crafting_connected() -> bool:
	var session: Node = get_node_or_null("/root/NetworkSession")
	return session != null and bool(session.call("is_client_connected"))

func _crafting_get_count(item_id: String) -> int:
	if _is_crafting_connected():
		var session: Node = get_node_or_null("/root/NetworkSession")
		return int((session.call("get_server_materials") as Dictionary).get(item_id, 0))
	return inventory_system.get_quantity(item_id)

func _crafting_get_level() -> int:
	if _is_crafting_connected():
		var session: Node = get_node_or_null("/root/NetworkSession")
		return PlayerProgression.level_for_xp(int(session.call("get_server_xp")))
	return PlayerProgression.level_for_xp(save_system.get_player_xp())

## Station ids within reach of the player. Offline: locally placed stations.
## Connected: server-committed station objects only, mirroring what the server
## itself will check, so the panel preview never lies about authority.
func _nearby_station_ids() -> Array:
	var player: AvatarController = get_player_avatar(gameplay_layer)
	if player == null:
		return []
	var stations: Array = []
	for station_id in CraftingRegistry.station_ids():
		if _is_crafting_connected():
			for entry_variant in _network_stations:
				var entry: Dictionary = entry_variant as Dictionary
				if String(entry.get("content_id", "")) == String(station_id) \
						and (entry.get("position", Vector2.ZERO) as Vector2).distance_to(player.global_position) <= STATION_RADIUS:
					stations.append(station_id)
					break
		elif building_placement_system.has_placed_object_near(String(station_id), player.global_position, STATION_RADIUS):
			stations.append(station_id)
	return stations

func _crafting_get_skills() -> Dictionary:
	if _is_crafting_connected():
		var session: Node = get_node_or_null("/root/NetworkSession")
		return SkillProgression.skill_levels(session.call("get_server_progression") as Dictionary)
	return SkillProgression.skill_levels(save_system.get_player_progression())

func _attempt_craft(recipe_id: String) -> void:
	if _is_crafting_connected():
		var session: Node = get_node_or_null("/root/NetworkSession")
		session.call("request_craft", recipe_id)
		_set_crafting_status("Crafting...")
		return

	var result: Dictionary = CraftingSystem.craft_with_inventory(
		recipe_id, inventory_system, _crafting_get_level(), _nearby_station_ids(), _crafting_get_skills()
	)
	if not bool(result["ok"]):
		_set_crafting_status(String(result["reason"]))
		return
	# Crafting trains the crafting skill by the recipe's reward; overall XP is
	# roughly half (basic +2/+1, advanced +5/+2 — docs/progression.md).
	var crafting_xp: int = int(result["xp_reward"])
	_grant_xp(ProgressionRegistry.SKILL_CRAFTING, crafting_xp, maxi(1, crafting_xp / 2))
	var crafted_text: String = "Crafted %d %s (+%d Crafting XP)" % [
		int(result["output_amount"]), String(result["display_name"]), crafting_xp,
	]
	_set_crafting_status(crafted_text)
	_announce(crafted_text)

# --- Progression (offline grants; the server grants its own when connected) ----

func _grant_xp(skill_id: String, skill_xp: int, total_xp: int) -> void:
	var grant_result: Dictionary = save_system.grant_player_xp(skill_id, skill_xp, total_xp)
	if bool(grant_result["player_levelled"]):
		_announce("Level %d reached! New recipes and builds unlocked." % int(grant_result["new_player_level"]))
	if bool(grant_result["skill_levelled"]) and not skill_id.is_empty():
		_announce("%s skill is now Level %d!" % [
			ProgressionRegistry.skill_display_name(skill_id), int(grant_result["new_skill_level"]),
		])
	if _progression_panel != null and bool(_progression_panel.call("is_open")):
		_progression_panel.call("refresh")

## Session-once grant (per villager/creature/landmark) so cozy interactions
## give a little XP without being spam-farmable.
func _grant_xp_once(mark: String, skill_id: String, skill_xp: int, total_xp: int) -> void:
	if _session_xp_marks.has(mark):
		return
	_session_xp_marks[mark] = true
	_grant_xp(skill_id, skill_xp, total_xp)

func _on_object_placed_for_xp(object_id: String) -> void:
	_grant_xp(
		ProgressionRegistry.SKILL_BUILDING,
		ProgressionRegistry.building_xp_for_cost(BuildCosts.cost_of(object_id)), 0
	)

func _setup_progression_panel() -> void:
	_progression_panel = preload("res://ui/progression_panel.tscn").instantiate() as CanvasLayer
	_progression_panel.name = "ProgressionPanel"
	add_child(_progression_panel)
	_progression_panel.call("setup", Callable(self, "_get_progression_snapshot"))

func _setup_inventory_panel() -> void:
	_inventory_panel = INVENTORY_PANEL_SCENE.instantiate() as CanvasLayer
	_inventory_panel.name = "InventoryPanel"
	add_child(_inventory_panel)
	# Reuse the crafting count getter (offline inventory or server pouch) so the
	# inventory panel always matches whatever store is authoritative right now.
	_inventory_panel.call("setup", Callable(self, "_crafting_get_count"), Callable(self, "_inventory_get_identity"))

func _setup_build_menu() -> void:
	_build_menu = BUILD_MENU_SCENE.instantiate() as CanvasLayer
	_build_menu.name = "BuildMenuPanel"
	add_child(_build_menu)
	_build_menu.call(
		"setup",
		Callable(object_registry, "get_placeable_ids"),
		Callable(building_placement_system, "placeable_status"),
		Callable(building_placement_system, "set_active_placeable"),
		Callable(building_placement_system, "get_active_placeable_id")
	)
	_interior_view = INTERIOR_VIEW_SCENE.instantiate() as CanvasLayer
	_interior_view.name = "InteriorView"
	add_child(_interior_view)
	_interior_view.connect("interior_closed", _on_interior_closed)

	_system_menu = SYSTEM_MENU_SCENE.instantiate() as CanvasLayer
	_system_menu.name = "SystemMenu"
	add_child(_system_menu)
	_system_menu.connect("close_requested", _on_system_menu_closed)

## Esc when nothing else is open opens the system/pause menu (Resume, fullscreen
## toggle, Quit to Desktop). Movement + interactions pause while it's open.
func _toggle_system_menu() -> void:
	if _system_menu == null:
		return
	if bool(_system_menu.call("is_open")):
		_system_menu.call("close")
		_on_system_menu_closed()
	else:
		_system_menu.call("open")
		if _local_player != null and is_instance_valid(_local_player):
			_local_player.set_movement_enabled(false)
		interactable_system.set_interactions_enabled(false)

func _on_system_menu_closed() -> void:
	if _local_player != null and is_instance_valid(_local_player):
		_local_player.set_movement_enabled(true)
	interactable_system.set_interactions_enabled(not _is_mailbox_open())

## Identity snapshot for the inventory panel + HUD. Base (offline homestead)
## has no profile/plot; OverworldController overrides this with username,
## profile id, server/offline mode, and the player's plot status.
func _inventory_get_identity() -> Dictionary:
	return {
		"display_name": "Villager",
		"username": "villager",
		"mode": "Offline",
		"plot_status": "—",
		"profile_id": "",
	}

## Local player nameplate name. Base is "You"; OverworldController overrides
## with the active profile's display name.
func _local_player_name() -> String:
	return "You"

## Whichever progression applies right now: the server's when connected
## (matching authority), else the local save's.
func _get_progression_snapshot() -> Dictionary:
	if _is_crafting_connected():
		var session: Node = get_node_or_null("/root/NetworkSession")
		return SkillProgression.normalized(session.call("get_server_progression") as Dictionary)
	return save_system.get_player_progression()

func _set_crafting_status(text: String) -> void:
	if _crafting_panel != null:
		_crafting_panel.call("set_status", text)
		_crafting_panel.call("refresh")

## Toast into the chat/event log when it exists (overworld), no-op otherwise.
func _announce(text: String) -> void:
	if has_method("_chat_toast"):
		call("_chat_toast", text)

## New (or pre-tools) saves get the starter tool loadout once. Tools are also
## hand-recraftable from raw materials, so losing them never soft-locks.
func _grant_starter_kit_once() -> void:
	if bool(save_system.get_overworld_flag("starter_kit_granted", false)):
		return
	save_system.set_overworld_flag("starter_kit_granted", true)
	var loadout: Dictionary = ItemIds.starter_loadout()
	for tool_id in loadout.keys():
		inventory_system.add_item(String(tool_id), int(loadout[tool_id]))
	_save_inventory_state()

func _grant_starter_seed_packet_once() -> void:
	if bool(save_system.get_overworld_flag("starter_seed_packet_granted", false)):
		return
	save_system.set_overworld_flag("starter_seed_packet_granted", true)
	if inventory_system.get_quantity(ContentIds.ITEM_PLACEHOLDER_SEED_PACKET) < STARTER_SEED_PACKET_COUNT:
		inventory_system.add_item(ContentIds.ITEM_PLACEHOLDER_SEED_PACKET, STARTER_SEED_PACKET_COUNT)
	_save_inventory_state()

## Reward hook for mailbox/task completions: a small material bundle + XP.
func _grant_task_reward(task_label: String) -> void:
	inventory_system.add_item(ResourceIds.MATERIAL_WOOD, 2)
	inventory_system.add_item(ResourceIds.MATERIAL_FIBER, 2)
	_grant_xp(ProgressionRegistry.SKILL_STEWARDSHIP, 10, 5)
	_announce("Task complete: %s  (+2 Wood, +2 Fiber, +10 Stewardship XP)" % task_label)

func _on_survival_changed() -> void:
	_save_survival_state()
	_refresh_survival_hud()

func _open_mailbox() -> void:
	var mailbox_messages: Array[Dictionary] = task_integration_system.get_mailbox_messages()
	if hud.has_method("show_mailbox"):
		hud.call("show_mailbox", mailbox_messages)
	if task_integration_system.mark_all_messages_seen():
		_save_task_integration_state()
		_refresh_mailbox_world_state()
	interactable_system.set_interactions_enabled(false)
	building_placement_system.set_process_unhandled_input(false)

func _close_mailbox() -> void:
	if hud.has_method("hide_mailbox"):
		hud.call("hide_mailbox")
	interactable_system.set_interactions_enabled(not _decorating_mode_active)
	building_placement_system.set_process_unhandled_input(true)

func _is_mailbox_open() -> bool:
	if hud.has_method("is_mailbox_open"):
		return bool(hud.call("is_mailbox_open"))
	return false

func _save_task_integration_state() -> void:
	var save_data: Dictionary = save_system.load_save_data()
	var tasks_data: Dictionary = {}
	var raw_tasks: Variant = save_data.get("tasks", {})
	if typeof(raw_tasks) == TYPE_DICTIONARY:
		tasks_data = raw_tasks as Dictionary

	tasks_data["integration"] = task_integration_system.export_state()
	save_data["tasks"] = tasks_data
	save_system.save_save_data(save_data)

func _refresh_mailbox_world_state() -> void:
	building_placement_system.set_mailbox_new_mail_active(
		task_integration_system.has_unseen_mailbox_messages()
	)

func _handle_farm_plot_interaction(interactable_id: String) -> void:
	if not _farm_plots.has(interactable_id):
		return

	var plot_state: Dictionary = farming_system.get_plot_state(interactable_id)
	var plot_stage: String = String(plot_state.get("stage", FarmingSystem.STAGE_EMPTY))
	var selected_item_id: String = _selected_farming_item_id
	var interaction_result: Dictionary = {"changed": false, "action": "none"}

	match plot_stage:
		FarmingSystem.STAGE_EMPTY:
			if selected_item_id != ItemIds.TOOL_WORN_HOE:
				_announce("Select Worn Hoe on the quickbar, then press F to till this plot.")
				return
			if farming_system.till_plot(interactable_id):
				interaction_result = {"changed": true, "action": "till"}
		FarmingSystem.STAGE_TILLED_SOIL:
			if selected_item_id == ItemIds.TOOL_WATERING_CAN:
				if farming_system.water_plot(interactable_id):
					interaction_result = {"changed": true, "action": "water"}
				else:
					_announce("That soil is already watered.")
					return
			elif _is_seed_item(selected_item_id):
				if inventory_system.get_quantity(selected_item_id) < 1:
					_announce("You need a Seed Packet in your inventory.")
					return
				var crop_id: String = _plot_crop_id(interactable_id)
				if not farming_system.can_plant(interactable_id, crop_id):
					_announce("Seeds need prepared tilled soil.")
					return
				if not inventory_system.remove_item(selected_item_id, 1):
					_announce("You need a Seed Packet in your inventory.")
					return
				if farming_system.plant_seed(interactable_id, crop_id):
					interaction_result = {"changed": true, "action": "plant"}
				else:
					inventory_system.add_item(selected_item_id, 1)
					_announce("This plot is not ready for seeds yet.")
					return
			else:
				_announce("Select a Seed Packet to plant, or Watering Can to water the soil.")
				return
		FarmingSystem.STAGE_PLANTED_SEED, FarmingSystem.STAGE_CROP_STAGE_1, FarmingSystem.STAGE_CROP_STAGE_2:
			if bool(plot_state.get("watered", false)):
				_announce("This crop is watered. Rest or use admin Grow Crops to advance it.")
				return
			if selected_item_id != ItemIds.TOOL_WATERING_CAN:
				_announce("Select Watering Can on the quickbar, then press F to water this crop.")
				return
			if farming_system.water_plot(interactable_id):
				interaction_result = {"changed": true, "action": "water"}
		FarmingSystem.STAGE_CROP_STAGE_3:
			var harvested_plot: Dictionary = farming_system.harvest_plot(interactable_id)
			if harvested_plot.is_empty():
				_announce("This crop is not ready to harvest.")
				return
			interaction_result = {
				"changed": true,
				"action": "harvest",
				"crop_id": String(harvested_plot.get("crop_id", CARROT_ITEM_ID)),
			}
		_:
			_announce("This plot needs attention later.")
			return

	# Clear success feedback for each action (the no-op / wrong-tool cases above
	# already toast; the player should also hear when an action lands).
	match String(interaction_result.get("action", "")):
		"till":
			_grant_xp(ProgressionRegistry.SKILL_FARMING, 1, 0)
			_announce("Tilled the soil. Select a Seed Packet to plant.")
		"plant":
			_grant_xp(ProgressionRegistry.SKILL_FARMING, 1, 0)
			_announce("Planted %s." % _crop_label(_plot_crop_id(interactable_id)))
		"water":
			_grant_xp(ProgressionRegistry.SKILL_FARMING, 1, 0)
			_announce("Watered the crop. Rest or use Grow Crops (F7) to advance it.")
		"harvest":
			_grant_xp(ProgressionRegistry.SKILL_FARMING, 5, 2)
	if not bool(interaction_result.get("changed", false)):
		return

	if String(interaction_result.get("action", "")) == "harvest":
		var harvested_crop_id: String = String(
			interaction_result.get("crop_id", CARROT_ITEM_ID)
		)
		if object_registry.get_item_definition(harvested_crop_id).is_empty():
			harvested_crop_id = CARROT_ITEM_ID
		inventory_system.add_item(harvested_crop_id, 1)
		_announce("Harvested %s! (now %d)" % [_crop_label(harvested_crop_id), inventory_system.get_quantity(harvested_crop_id)])
		if task_integration_system.mark_message_completed(
			TaskIntegrationSystem.HARVEST_CARROT_TASK_ID
		):
			_save_task_integration_state()
			_refresh_mailbox_world_state()
			_grant_task_reward("Harvest a carrot")
	elif String(interaction_result.get("action", "")) == "water":
		if task_integration_system.mark_message_completed(
			TaskIntegrationSystem.WATER_GARDEN_TASK_ID
		):
			_save_task_integration_state()
			_refresh_mailbox_world_state()
			_grant_task_reward("Water the garden")

	_save_farming_state()
	interactable_system.update_interactable_prompt(
		interactable_id,
		farming_system.get_plot_prompt(interactable_id)
	)
	_refresh_all_farm_plot_visuals(interactable_id)

func _is_seed_item(item_id: String) -> bool:
	return FARM_SEED_ITEM_IDS.has(item_id)

func _plot_crop_id(plot_id: String) -> String:
	var crop_id: String = String(farming_system.get_plot_state(plot_id).get("crop_id", CARROT_ITEM_ID))
	if ContentRegistry.crops().has(crop_id):
		return crop_id
	return CARROT_ITEM_ID

## Readable name for a crop/item id (crops registry -> items registry -> capitalize).
func _crop_label(crop_id: String) -> String:
	var crop: Variant = ContentRegistry.crops().get(crop_id, {})
	if typeof(crop) == TYPE_DICTIONARY and (crop as Dictionary).has("display_name"):
		return String((crop as Dictionary)["display_name"])
	var item: Variant = ContentRegistry.items().get(crop_id, {})
	if typeof(item) == TYPE_DICTIONARY and (item as Dictionary).has("display_name"):
		return String((item as Dictionary)["display_name"])
	return crop_id.capitalize()

func admin_grow_crops() -> void:
	var changed_count: int = farming_system.advance_all_plots(true)
	if changed_count <= 0:
		_announce("(admin) No growing crops to advance.")
		return
	_save_farming_state()
	_refresh_all_farm_plot_visuals("")
	for plot_id_variant in _farm_plots.keys():
		var plot_id: String = String(plot_id_variant)
		interactable_system.update_interactable_prompt(plot_id, farming_system.get_plot_prompt(plot_id))
	_announce("(admin) Advanced %d crop plot%s." % [changed_count, "" if changed_count == 1 else "s"])

func _refresh_farm_plot_visuals(plot_id: String, is_nearby: bool) -> void:
	if not _farm_plots.has(plot_id):
		return

	var plot: FarmPlot = _farm_plots[plot_id] as FarmPlot
	if plot == null:
		return

	var plot_state: Dictionary = farming_system.get_plot_state(plot_id)
	var visual_state: Dictionary = plot_state.duplicate(true)
	visual_state["is_nearby"] = is_nearby
	plot.set_plot_state(visual_state)

func _refresh_all_farm_plot_visuals(active_plot_id: String) -> void:
	for plot_id_variant in _farm_plots.keys():
		var plot_id: String = String(plot_id_variant)
		_refresh_farm_plot_visuals(plot_id, plot_id == active_plot_id)

func _refresh_inventory_hud() -> void:
	if hud.has_method("set_inventory_counts"):
		hud.call("set_inventory_counts", _get_inventory_counts())
	if hud.has_method("set_identity_line"):
		var identity: Dictionary = _inventory_get_identity()
		var level: int = PlayerProgression.level_for_xp(_player_xp_for_hud())
		hud.call("set_identity_line", "@%s (%s) · %s · Lv %d" % [
			String(identity.get("username", "villager")),
			String(identity.get("display_name", "Villager")),
			String(identity.get("mode", "Offline")),
			level,
		])
	if hud.has_method("set_materials_text"):
		hud.call("set_materials_text", "%s · Tokens %d" % [_format_materials_text(), _crafting_get_count(ItemIds.QUEST_LAND_TOKEN)])
	if hud.has_method("set_area_line"):
		hud.call("set_area_line", _player_area_text())

## Player XP for the HUD level readout (server value when connected).
func _player_xp_for_hud() -> int:
	if _is_crafting_connected():
		var session: Node = get_node_or_null("/root/NetworkSession")
		return int(session.call("get_server_xp"))
	return save_system.get_player_xp()

## Current area label for the HUD. Base homestead has no neighborhood; the
## overworld overrides this with full area/plot classification.
func _player_area_text() -> String:
	return "Homestead"

func _format_materials_text() -> String:
	var parts: Array[String] = []
	for material_id in ResourceIds.ALL_MATERIALS:
		parts.append("%s %d" % [ResourceIds.display_name(material_id), _crafting_get_count(material_id)])
	return " · ".join(parts)

func _refresh_survival_hud() -> void:
	if hud.has_method("set_survival_text"):
		hud.call(
			"set_survival_text",
			"Comfort: %d" % int(snappedf(survival_system.get_stat("comfort"), 1.0))
		)

func _consume_carrot() -> void:
	if not inventory_system.has_item(CARROT_ITEM_ID):
		return

	if not inventory_system.remove_item(CARROT_ITEM_ID, 1):
		return

	survival_system.add_to_stat("comfort", CARROT_COMFORT_BONUS)

func _save_inventory_state() -> void:
	var save_data: Dictionary = save_system.load_save_data()
	var player_data: Dictionary = {}
	var raw_player: Variant = save_data.get("player", {})
	if typeof(raw_player) == TYPE_DICTIONARY:
		player_data = raw_player as Dictionary

	player_data["inventory"] = inventory_system.export_state()
	save_data["player"] = player_data
	save_system.save_save_data(save_data)

func _save_survival_state() -> void:
	var save_data: Dictionary = save_system.load_save_data()
	var player_data: Dictionary = {}
	var raw_player: Variant = save_data.get("player", {})
	if typeof(raw_player) == TYPE_DICTIONARY:
		player_data = raw_player as Dictionary

	player_data["survival"] = survival_system.export_state()
	save_data["player"] = player_data
	save_system.save_save_data(save_data)

func _save_farming_state() -> void:
	save_system.set_region_farming(REGION_ID, farming_system.export_state())

func _configure_farm_plots() -> void:
	_farm_plots = {
		FARM_PLOT_CARROT_ID: farm_plot_carrot,
		FARM_PLOT_TURNIP_ID: farm_plot_turnip,
		FARM_PLOT_BERRY_ID: farm_plot_berry,
	}
	_align_limezu_farm_interaction_nodes()

	if farming_system.has_plot(LEGACY_FARM_PLOT_ID) and not farming_system.has_plot(FARM_PLOT_CARROT_ID):
		farming_system.set_plot_state(FARM_PLOT_CARROT_ID, farming_system.get_plot_state(LEGACY_FARM_PLOT_ID))
		farming_system.remove_plot(LEGACY_FARM_PLOT_ID)
		_save_farming_state()

	farming_system.ensure_plot_with_crop(FARM_PLOT_CARROT_ID, CARROT_ITEM_ID)
	farming_system.ensure_plot_with_crop(FARM_PLOT_TURNIP_ID, TURNIP_ITEM_ID)
	farming_system.ensure_plot_with_crop(FARM_PLOT_BERRY_ID, BERRY_ITEM_ID)

	farm_plot_carrot.plot_id = FARM_PLOT_CARROT_ID
	farm_plot_turnip.plot_id = FARM_PLOT_TURNIP_ID
	farm_plot_berry.plot_id = FARM_PLOT_BERRY_ID

func _align_limezu_farm_interaction_nodes() -> void:
	# Runs for the live curated top-down slice (Sprout-curated OR LimeZu) — both place
	# the farm row here. Gating on live_limezu_slice() alone would skip the move when
	# the local LimeZu pack is absent and the Sprout-curated slice is showing instead.
	if not LiveVisualPolicy.CURATED_SLICE or map == null:
		return
	# A tidy 3-tile row just south of spawn (7,11), in clear view and away from the
	# tree at (5,15), the cottage (6-7,6-7), the fence (row 5), and the path (rows
	# 8-10). The old layout scattered these and put the carrot plot behind a tree.
	var farm_tiles := {
		FARM_PLOT_CARROT_ID: Vector2i(6, 13),
		FARM_PLOT_TURNIP_ID: Vector2i(7, 13),
		FARM_PLOT_BERRY_ID: Vector2i(8, 13),
	}
	for plot_id in farm_tiles.keys():
		var plot: FarmPlot = _farm_plots.get(plot_id, null) as FarmPlot
		if plot == null:
			continue
		plot.position = map.grid_to_world(farm_tiles[plot_id] as Vector2i)
		plot.set_meta("interaction_point_offset", Vector2.ZERO)

func _register_farm_plot_interactions() -> void:
	for plot_id_variant in _farm_plots.keys():
		var plot_id: String = String(plot_id_variant)
		var plot: FarmPlot = _farm_plots[plot_id_variant] as FarmPlot
		if plot == null:
			continue

		interactable_system.register_interactable(
			plot_id,
			plot,
			ContentIds.INTERACTION_FARM_PLOT,
			farming_system.get_plot_prompt(plot_id)
		)

# OutdoorAreaController phase-4 hook: spawn homestead-specific area content.
# Called from HomesteadController._ready after the player is spawned and the
# interactable_system is configured. OverworldController inherits this and gains
# the homestead creatures + rest marker as part of the overworld scene.
func _setup_area_content(player: AvatarController) -> void:
	_spawn_ambient_creatures(player)
	_setup_rest_marker()

func _spawn_ambient_creatures(player: AvatarController) -> void:
	if LiveVisualPolicy.live_limezu_slice():
		return
	var rabbit: MossRabbit = MossRabbit.new()
	rabbit.position = Vector2(-64.0, 384.0)
	gameplay_layer.add_child(rabbit)
	rabbit.configure_creature(player)
	register_world_interactable(
		"homestead_rabbit_0", rabbit, ContentIds.INTERACTION_AMBIENT_CREATURE, "Press F to observe",
		_handle_creature_observe.bind("homestead_rabbit_0")
	)
	_ambient_creatures["homestead_rabbit_0"] = rabbit

	var turtle: StumpTurtle = StumpTurtle.new()
	turtle.position = Vector2(40.0, 256.0)
	gameplay_layer.add_child(turtle)
	turtle.configure_creature(player)
	register_world_interactable(
		"homestead_turtle_0", turtle, ContentIds.INTERACTION_AMBIENT_CREATURE, "Press F to observe",
		_handle_creature_observe.bind("homestead_turtle_0")
	)
	_ambient_creatures["homestead_turtle_0"] = turtle

func _handle_creature_observe(interactable_id: String) -> void:
	var creature: AmbientCreature = _ambient_creatures.get(interactable_id, null) as AmbientCreature
	if creature == null:
		return
	_open_observe_panel(creature.get_display_name(), creature.get_observe_text())
	_grant_xp_once("observe_%s" % interactable_id, ProgressionRegistry.SKILL_EXPLORATION, 2, 1)

# Observe-panel hooks for OutdoorAreaController's generic lifecycle: the homestead
# area also suspends building placement input and keeps interactions disabled while a
# decorating mode is active. Together these reproduce the original behaviour exactly.
func _set_area_input_suspended(suspended: bool) -> void:
	building_placement_system.set_process_unhandled_input(not suspended)

func _area_interactions_enabled() -> bool:
	return not _decorating_mode_active

func _setup_rest_marker() -> void:
	# A cozy doormat at the cottage doorway. No collision, so it never blocks the
	# player; it only carries the "Press F to rest" interaction.
	var marker: Node2D = Node2D.new()
	marker.name = "RestMarker"
	marker.position = Vector2(0.0, 224.0)
	gameplay_layer.add_child(marker)

	if not LiveVisualPolicy.live_limezu_slice():
		var mat: Polygon2D = Polygon2D.new()
		mat.polygon = PackedVector2Array([
			Vector2(0, -10), Vector2(22, 0), Vector2(0, 10), Vector2(-22, 0),
		])
		mat.color = Color("#a9763f")
		marker.add_child(mat)

		var mat_inner: Polygon2D = Polygon2D.new()
		mat_inner.polygon = PackedVector2Array([
			Vector2(0, -6), Vector2(14, 0), Vector2(0, 6), Vector2(-14, 0),
		])
		mat_inner.color = Color("#caa06a")
		marker.add_child(mat_inner)

		var stitch: Polygon2D = Polygon2D.new()
		stitch.position = Vector2(0, -1)
		stitch.polygon = PackedVector2Array([
			Vector2(-10, 0), Vector2(10, 0), Vector2(10, 1), Vector2(-10, 1),
		])
		stitch.color = Color("#80502a")
		marker.add_child(stitch)

	_rest_marker = marker
	register_world_interactable(
		REST_INTERACTABLE_ID, marker, ContentIds.INTERACTION_REST, "Press F to rest",
		_open_rest_panel
	)

func _open_rest_panel() -> void:
	_rest_panel_open = true
	_rest_phase = "confirm"
	interactable_system.set_interactions_enabled(false)
	building_placement_system.set_process_unhandled_input(false)
	if hud.has_method("show_message_panel"):
		hud.call(
			"show_message_panel",
			"Rest for a while?",
			"The cottage feels warm and quiet.",
			"F = Rest   Esc = Cancel"
		)

func _confirm_rest() -> void:
	var current_mood: String = save_system.get_current_mood()
	var result_body: String = ""
	if WorldMood.rest_increments_day(current_mood):
		var new_day_count: int = save_system.get_day_count() + 1
		save_system.set_day_count(new_day_count)
		save_system.set_current_mood(WorldMood.MORNING)
		result_body = "You sleep soundly. Day %d dawns, quiet and new." % new_day_count
	else:
		var next_mood: String = WorldMood.next_mood(current_mood)
		save_system.set_current_mood(next_mood)
		result_body = "You rest a while. The %s settles in softly." % WorldMood.display_name(next_mood).to_lower()

	# A restful day restores comfort. set_stat emits survival_changed, which saves
	# and refreshes the comfort HUD line for us.
	survival_system.set_stat("comfort", 100.0)
	_advance_watered_crops_for_day()

	if hud.has_method("set_mood"):
		hud.call("set_mood", save_system.get_current_mood())
	if hud.has_method("set_day"):
		hud.call("set_day", save_system.get_day_count())

	_rest_phase = "result"
	if hud.has_method("show_message_panel"):
		hud.call("show_message_panel", "Rested", result_body, "Esc to close")

func _close_rest_panel() -> void:
	_rest_panel_open = false
	_rest_phase = ""
	if hud.has_method("hide_message_panel"):
		hud.call("hide_message_panel")
	interactable_system.set_interactions_enabled(not _decorating_mode_active)
	building_placement_system.set_process_unhandled_input(true)

func _apply_saved_day() -> void:
	OutdoorControllerHelpers.apply_day(hud, save_system.get_day_count())

func _can_cycle_mood() -> bool:
	# Mood cycling is an Explore-mode action: suppress it while a modal panel is
	# open or while a decorating mode owns input. The inventory panel is a
	# non-blocking overlay (carrot consume also works under it), so it is allowed.
	return (
		not _observe_panel_open
		and not _rest_panel_open
		and not _is_mailbox_open()
		and not _decorating_mode_active
	)

func _apply_saved_mood() -> void:
	OutdoorControllerHelpers.apply_mood(hud, save_system.get_current_mood())

func _cycle_mood() -> void:
	OutdoorControllerHelpers.cycle_mood(save_system, hud)

func _get_inventory_counts() -> Dictionary:
	return {
		CARROT_ITEM_ID: inventory_system.get_count(CARROT_ITEM_ID),
		TURNIP_ITEM_ID: inventory_system.get_count(TURNIP_ITEM_ID),
		BERRY_ITEM_ID: inventory_system.get_count(BERRY_ITEM_ID),
		ContentIds.ITEM_PLACEHOLDER_SEED_PACKET: inventory_system.get_count(ContentIds.ITEM_PLACEHOLDER_SEED_PACKET),
		ResourceIds.COMPONENT_SEED_PACKET: inventory_system.get_count(ResourceIds.COMPONENT_SEED_PACKET),
	}

func _advance_watered_crops_for_day() -> void:
	var changed_count: int = farming_system.advance_all_plots(false)
	if changed_count <= 0:
		return
	_save_farming_state()
	_refresh_all_farm_plot_visuals("")
	for plot_id_variant in _farm_plots.keys():
		var plot_id: String = String(plot_id_variant)
		interactable_system.update_interactable_prompt(plot_id, farming_system.get_plot_prompt(plot_id))
	_announce("Watered crops grew overnight.")

func _toggle_inventory_panel() -> void:
	if _inventory_panel != null:
		_inventory_panel.call("toggle_panel")

## Enter a placed prefab structure's interior (prototype room-view overlay).
## The player keeps their world position; exiting returns them right here. Owner-
## safe by construction offline (it's your own placed object).
func _enter_prefab_interior(record_id: String) -> void:
	if _interior_view == null:
		return
	var object_id: String = building_placement_system.get_placed_object_id(record_id)
	var metadata: Dictionary = PrefabInteriors.metadata(object_id)
	if metadata.is_empty():
		_open_observe_panel("Interior", "Interior coming later.")
		return
	interactable_system.set_interactions_enabled(false)
	if _local_player != null and is_instance_valid(_local_player):
		_local_player.set_movement_enabled(false)
	_interior_view.call("open_interior", String(metadata.get("template", "")), String(metadata.get("title", "Interior")))

func _on_interior_closed() -> void:
	if _local_player != null and is_instance_valid(_local_player):
		_local_player.set_movement_enabled(true)
	interactable_system.set_interactions_enabled(true)

func _open_help_panel() -> void:
	_open_observe_panel(
		"Hearthvale Controls",
		"Move: WASD / Arrow keys\n"
		+ "Interact / talk / gather / claim: F\n"
		+ "Inventory I | Craft K | Skills P | Help H | Minimap M\n"
		+ "Build B | Edit E | Move M | Rotate Q/RB | Delete Del/Y\n"
		+ "Controller: left stick move | A confirm | B cancel | Start menu\n"
		+ "Chat Enter | Profile F8 | Wardrobe F9 | Admin F7 | Fullscreen F11\n"
		+ "System menu: Esc when no other panel is open\n\n"
		+ "Farming: select Hoe to till, Seed Packet to plant, Watering Can to water; mature crops harvest with F.\n\n"
		+ "Esc closes any open panel first; with nothing open it opens the system menu.\n\n"
		+ "Getting started: gather branches/pebbles/fiber/clay (F), craft tools (K), "
		+ "claim a plot at a plot sign, then build (B). Talk to Farmer Rowan for help."
	)

# _mark_input_handled() is inherited from OutdoorAreaController.
