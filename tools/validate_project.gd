extends SceneTree

# The continuous overworld is the main outdoor scene. The legacy paged region scenes
# are kept here too so we catch it early if they ever stop parsing.
const RESOURCE_PATHS: Array[String] = [
	"res://scenes/main.tscn",
	"res://scenes/world/overworld.tscn",
	"res://world/overworld_controller.gd",
	"res://world/overworld_map.gd",
	"res://world/outdoor_area_controller.gd",
	"res://world/homestead_controller.gd",
	"res://world/homestead_map.gd",
	"res://world/terrain_shapes.gd",
	"res://world/iso_map_helpers.gd",
	"res://world/outdoor_controller_helpers.gd",
	"res://systems/content/content_ids.gd",
	"res://systems/content/content_registry.gd",
	"res://systems/world_region_manager.gd",
	"res://systems/local_save_system.gd",
	"res://systems/game_state_manager.gd",
	"res://systems/dev_tool_state.gd",
	"res://systems/overworld_editor_system.gd",
	"res://systems/dev_world_marker.gd",
	"res://systems/admin/moderation_models.gd",
	"res://systems/admin/audit_log.gd",
	"res://scenes/world/homestead.tscn",
	"res://scenes/world/regions/homestead/homestead_region.tscn",
	"res://scenes/world/regions/village_square/village_square_region.tscn",
	"res://scenes/world/regions/forest_edge/forest_edge_region.tscn",
	"res://systems/region_transition_system.gd",
	"res://world/regions/homestead/homestead_region_controller.gd",
	"res://world/regions/village_square/village_square_region_controller.gd",
	"res://world/regions/forest_edge/forest_edge_region_controller.gd",
]

func _initialize() -> void:
	for resource_path in RESOURCE_PATHS:
		var resource: Resource = load(resource_path)
		if resource == null:
			push_error("Failed to load resource: %s" % resource_path)
			quit(1)
			return

		if resource is PackedScene:
			var packed_scene: PackedScene = resource as PackedScene
			var instance: Node = packed_scene.instantiate()
			if instance == null:
				push_error("Failed to instantiate scene: %s" % resource_path)
				quit(1)
				return
			instance.free()

	# Lightweight save-helper sanity: defaults must be returned with no save file.
	var save_system: LocalSaveSystem = LocalSaveSystem.new()
	if save_system.get_current_mood().is_empty():
		push_error("Save helper get_current_mood returned empty default")
		quit(1)
		return
	if save_system.get_day_count() < 1:
		push_error("Save helper get_day_count returned invalid default")
		quit(1)
		return
	# Overworld/instance helpers must return dictionaries (defensive defaults).
	var _ow: Dictionary = save_system.get_overworld_flags()
	var _inst: Dictionary = save_system.get_instance_state("none")
	save_system.free()

	# Shared iso grid helper must match the original formula and round-trip cleanly.
	if IsoMapHelpers.grid_to_world(Vector2i(1, 0), 64, 32) != Vector2(32, 16):
		push_error("IsoMapHelpers.grid_to_world regression")
		quit(1)
		return
	for tile in [Vector2i(0, 0), Vector2i(7, 11), Vector2i(15, 10), Vector2i(21, 17)]:
		var round_trip: Vector2i = IsoMapHelpers.world_to_grid(IsoMapHelpers.grid_to_world(tile, 64, 32), 64, 32)
		if round_trip != tile:
			push_error("IsoMapHelpers grid round-trip mismatch for %s -> %s" % [tile, round_trip])
			quit(1)
			return

	# Content ids must equal the exact strings already used in saves and dict keys.
	# A mismatch here would silently break save compatibility.
	var id_pairs: Array = [
		[ContentIds.ITEM_CARROT, "carrot"],
		[ContentIds.ITEM_TURNIP, "turnip"],
		[ContentIds.ITEM_BERRY, "berry"],
		[ContentIds.PLACEABLE_MAILBOX, "mailbox"],
		[ContentIds.AREA_HOMESTEAD, "homestead"],
		[ContentIds.AREA_VILLAGE_SQUARE, "village_square"],
		[ContentIds.AREA_FOREST_EDGE, "forest_edge"],
		[ContentIds.TASK_WATER_GARDEN, "mock_water_garden"],
		[ContentIds.TASK_HARVEST_CARROT, "mock_harvest_carrot"],
		[TaskIntegrationSystem.WATER_GARDEN_TASK_ID, "mock_water_garden"],
		[TaskIntegrationSystem.HARVEST_CARROT_TASK_ID, "mock_harvest_carrot"],
		# Adopted controller constants must still resolve to their original strings.
		[HomesteadController.REGION_ID, "homestead"],
		[HomesteadController.CARROT_ITEM_ID, "carrot"],
		[HomesteadController.TURNIP_ITEM_ID, "turnip"],
		[HomesteadController.BERRY_ITEM_ID, "berry"],
		[HomesteadController.FARM_PLOT_CARROT_ID, "farm_plot_carrot"],
		[HomesteadController.FARM_PLOT_TURNIP_ID, "farm_plot_turnip"],
		[HomesteadController.FARM_PLOT_BERRY_ID, "farm_plot_berry"],
		[HomesteadController.LEGACY_FARM_PLOT_ID, "farm_plot_main"],
		[OverworldController.VILLAGE_REGION_ID, "village_square"],
		[OverworldController.FOREST_REGION_ID, "forest_edge"],
		[OverworldController.MARIBEL_INTRO_FLAG, "maribel_intro_seen"],
		[OverworldController.BRAM_INTRO_FLAG, "bram_intro_seen"],
		[OverworldController.NOTICE_SEEN_FLAG, "notice_board_seen"],
		[OverworldController.SHRINE_SEEN_FLAG, "adventure_marker_seen"],
		# Interaction type ids (now centralized through ContentIds.INTERACTION_*).
		[ContentIds.INTERACTION_MAILBOX, "mailbox"],
		[ContentIds.INTERACTION_FARM_PLOT, "farm_plot"],
		[ContentIds.INTERACTION_AMBIENT_CREATURE, "ambient_creature"],
		[ContentIds.INTERACTION_VILLAGER, "villager"],
		[ContentIds.INTERACTION_NOTICE_BOARD, "notice_board"],
		[ContentIds.INTERACTION_SHRINE_MARKER, "shrine_marker"],
		[ContentIds.INTERACTION_REST, "rest"],
		[ContentIds.INTERACTION_REGION_TRANSITION, "region_transition"],
		[ContentIds.INTERACTION_TASK_BOARD, "task_board"],
		[ContentIds.INTERACTION_GENERIC, "generic"],
		# Action ids (what the player can do; values from get_available_actions).
		[ContentIds.ACTION_CHECK_MAIL, "check_mail"],
		[ContentIds.ACTION_TEND_PLOT, "tend_plot"],
		[ContentIds.ACTION_READ_NOTICE, "read_notice"],
		[ContentIds.ACTION_TRAVEL, "travel"],
		[ContentIds.ACTION_REVIEW_TASKS, "review_tasks"],
		[ContentIds.ACTION_OBSERVE, "observe"],
		[ContentIds.ACTION_TALK, "talk"],
		[ContentIds.ACTION_REST, "rest"],
		[ContentIds.ACTION_INSPECT, "inspect"],
	]
	for pair in id_pairs:
		if String(pair[0]) != String(pair[1]):
			push_error("Content id mismatch: got '%s', expected '%s'" % [pair[0], pair[1]])
			quit(1)
			return

	# No critical id may be empty.
	for critical_id in [
		ContentIds.ITEM_CARROT, ContentIds.PLACEABLE_MAILBOX,
		ContentIds.AREA_HOMESTEAD, ContentIds.AREA_VILLAGE_SQUARE, ContentIds.AREA_FOREST_EDGE,
		ContentIds.INTERACTION_MAILBOX, ContentIds.INTERACTION_FARM_PLOT, ContentIds.INTERACTION_VILLAGER,
		ContentIds.INTERACTION_AMBIENT_CREATURE, ContentIds.INTERACTION_NOTICE_BOARD,
		ContentIds.INTERACTION_SHRINE_MARKER, ContentIds.INTERACTION_REST, ContentIds.INTERACTION_GENERIC,
		ContentIds.ACTION_CHECK_MAIL, ContentIds.ACTION_TEND_PLOT, ContentIds.ACTION_OBSERVE,
		ContentIds.ACTION_TALK, ContentIds.ACTION_REST, ContentIds.ACTION_INSPECT,
	]:
		if String(critical_id).is_empty():
			push_error("Critical content id is empty")
			quit(1)
			return

	# ContentRegistry must return the expected display names (display-only metadata).
	var name_pairs: Array = [
		[String((ContentRegistry.items().get(ContentIds.ITEM_CARROT, {}) as Dictionary).get("display_name", "")), "Carrot"],
		[String((ContentRegistry.placeables().get(ContentIds.PLACEABLE_MAILBOX, {}) as Dictionary).get("display_name", "")), "Cozy Mailbox"],
		[ContentRegistry.area_display_name(ContentIds.AREA_HOMESTEAD), "Homestead"],
		[ContentRegistry.area_display_name(ContentIds.AREA_VILLAGE_SQUARE), "Village Square"],
		[ContentRegistry.area_display_name(ContentIds.AREA_FOREST_EDGE), "Forest Edge"],
	]
	for pair in name_pairs:
		if String(pair[0]) != String(pair[1]):
			push_error("ContentRegistry display-name mismatch: got '%s', expected '%s'" % [pair[0], pair[1]])
			quit(1)
			return

	# Phase-1 inheritance chain: HomesteadController -> OutdoorAreaController, and
	# OverworldController -> HomesteadController -> OutdoorAreaController.
	var homestead_controller: HomesteadController = HomesteadController.new()
	var homestead_chain_ok: bool = homestead_controller is OutdoorAreaController
	# Generic observe/message-panel lifecycle must live on the shared base.
	var panel_api_ok: bool = (
		homestead_controller.has_method("_open_observe_panel")
		and homestead_controller.has_method("_close_observe_panel")
		and homestead_controller.has_method("is_observe_panel_open")
	)
	# Generic interactable-registration plumbing must live on the shared base too.
	var registration_api_ok: bool = (
		homestead_controller.has_method("register_world_interactable")
		and homestead_controller.has_method("unregister_world_interactable")
		and homestead_controller.has_method("get_world_interactable_data")
		and homestead_controller.has_method("_dispatch_world_interactable")
	)
	# Phase-4 setup orchestration hooks must be present (added in Chunk 10 step 1).
	var setup_hooks_ok: bool = (
		homestead_controller.has_method("_setup_area_content")
		and homestead_controller.has_method("_after_area_setup")
	)
	homestead_controller.free()
	if not homestead_chain_ok:
		push_error("HomesteadController no longer extends OutdoorAreaController")
		quit(1)
		return
	if not panel_api_ok:
		push_error("Observe panel lifecycle missing from the outdoor controller chain")
		quit(1)
		return
	if not registration_api_ok:
		push_error("World interactable registration plumbing missing from the outdoor controller chain")
		quit(1)
		return
	if not setup_hooks_ok:
		push_error("Setup orchestration hooks (_setup_area_content/_after_area_setup) missing from the outdoor controller chain")
		quit(1)
		return

	var overworld_controller: OverworldController = OverworldController.new()
	var overworld_chain_ok: bool = (overworld_controller is HomesteadController) and (overworld_controller is OutdoorAreaController)
	overworld_controller.free()
	if not overworld_chain_ok:
		push_error("OverworldController inheritance chain regressed")
		quit(1)
		return

	print("Project smoke test passed.")
	quit(0)
