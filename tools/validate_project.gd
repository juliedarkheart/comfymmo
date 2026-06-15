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
	"res://systems/character/character_appearance.gd",
	"res://systems/character/character_appearance_registry.gd",
	"res://systems/character/character_visual_builder.gd",
	"res://avatar/avatar_visual.gd",
	"res://ui/dev_character_creator_panel.tscn",
	# Persistent-world pass: resources, building, profiles, network, server.
	"res://systems/resources/resource_ids.gd",
	"res://systems/resources/material_inventory.gd",
	"res://systems/resources/resource_node.gd",
	"res://systems/building/build_costs.gd",
	"res://buildings/decor_visuals.gd",
	"res://buildings/placeable_decor.gd",
	"res://systems/profile/local_profile.gd",
	"res://systems/profile/local_profile_manager.gd",
	"res://systems/network/network_mode.gd",
	"res://systems/network/network_messages.gd",
	"res://systems/network/player_identity.gd",
	"res://systems/network/remote_player.gd",
	"res://systems/network/network_session.gd",
	"res://server/server_config.gd",
	"res://server/server_save_system.gd",
	"res://server/server_world_state.gd",
	"res://server/server_player_state.gd",
	"res://server/hearthvale_server.gd",
	"res://server/server_main.tscn",
	"res://ui/network_connect_panel.tscn",
	"res://systems/network/chat_message.gd",
	"res://systems/resources/resource_spawn_registry.gd",
	"res://ui/chat_panel.tscn",
	"res://systems/crafting/crafting_recipe.gd",
	"res://systems/crafting/crafting_registry.gd",
	"res://systems/crafting/crafting_system.gd",
	"res://systems/progression/player_progression.gd",
	"res://systems/progression/skill_progression.gd",
	"res://systems/progression/progression_registry.gd",
	"res://ui/crafting_panel.tscn",
	"res://ui/progression_panel.tscn",
	"res://systems/items/item_ids.gd",
	"res://systems/land/land_plot.gd",
	"res://systems/land/land_registry.gd",
	"res://systems/land/land_claim_system.gd",
	"res://systems/admin/admin_permissions.gd",
	# Usability repair pass: display, inventory, nameplate, land panels.
	"res://ui/display_settings.gd",
	"res://ui/nameplate.gd",
	"res://ui/inventory_panel.tscn",
	"res://ui/land_panel.tscn",
	# Land/HUD/admin repair pass.
	"res://ui/minimap_panel.tscn",
	"res://ui/quick_tools_bar.tscn",
	"res://ui/admin_panel.tscn",
	# Build-UI / interiors / map pass.
	"res://systems/building/build_categories.gd",
	"res://systems/building/prefab_interiors.gd",
	"res://ui/build_menu_panel.tscn",
	"res://ui/interior_view.tscn",
	"res://scenes/world/homestead.tscn",
	"res://scenes/world/regions/homestead/homestead_region.tscn",
	"res://scenes/world/regions/village_square/village_square_region.tscn",
	"res://scenes/world/regions/forest_edge/forest_edge_region.tscn",
	"res://systems/region_transition_system.gd",
	"res://world/regions/homestead/homestead_region_controller.gd",
	"res://world/regions/village_square/village_square_region_controller.gd",
	"res://world/regions/forest_edge/forest_edge_region_controller.gd",
]

var _validation_placeable_ids: Array[String] = []
var _validation_active_placeable_id: String = ""

func _validation_get_placeable_ids() -> Array:
	return _validation_placeable_ids

func _validation_get_placeable_status(_placeable_id: String) -> Dictionary:
	return {"ok": true, "reason": ""}

func _validation_select_placeable(placeable_id: String) -> void:
	_validation_active_placeable_id = placeable_id

func _validation_get_active_placeable_id() -> String:
	return _validation_active_placeable_id

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

	# Build-menu / interiors pass: the menu must build its runtime controls when
	# mounted in-tree, the close affordances must work, every menu item source id
	# must resolve to registered content, and prefab interior metadata must fail
	# closed when missing/invalid.
	var object_registry: ObjectRegistry = ObjectRegistry.new()
	get_root().add_child(object_registry)
	var build_menu_scene: PackedScene = load("res://ui/build_menu_panel.tscn") as PackedScene
	if build_menu_scene == null:
		push_error("Build menu scene failed explicit load")
		quit(1)
		return
	var build_menu: CanvasLayer = build_menu_scene.instantiate() as CanvasLayer
	if build_menu == null:
		push_error("Build menu scene failed explicit instantiate")
		quit(1)
		return
	get_root().add_child(build_menu)
	await process_frame
	_validation_placeable_ids.clear()
	_validation_placeable_ids.append_array(object_registry.get_placeable_ids())
	if _validation_placeable_ids.is_empty():
		push_error("ObjectRegistry returned no placeables for the build menu")
		quit(1)
		return
	_validation_active_placeable_id = String(_validation_placeable_ids[0])
	build_menu.call(
		"setup",
		Callable(self, "_validation_get_placeable_ids"),
		Callable(self, "_validation_get_placeable_status"),
		Callable(self, "_validation_select_placeable"),
		Callable(self, "_validation_get_active_placeable_id")
	)
	build_menu.call("open_panel")
	await process_frame
	var categories_node: HFlowContainer = build_menu.get_node_or_null("Panel/Rows/Categories") as HFlowContainer
	if categories_node == null:
		push_error("Build menu is missing Panel/Rows/Categories")
		quit(1)
		return
	var category_texts: Array[String] = []
	for child in categories_node.get_children():
		if child is Button:
			category_texts.append(String((child as Button).text))
	if category_texts.size() != BuildCategories.ORDER.size():
		push_error("Build menu built %d categories, expected %d" % [category_texts.size(), BuildCategories.ORDER.size()])
		quit(1)
		return
	for category_index in range(BuildCategories.ORDER.size()):
		if category_texts[category_index] != BuildCategories.ORDER[category_index]:
			push_error("Build menu category mismatch at index %d: got '%s', expected '%s'" % [
				category_index, category_texts[category_index], BuildCategories.ORDER[category_index],
			])
			quit(1)
			return
	var close_button: Button = null
	for button_variant in build_menu.find_children("*", "Button", true, false):
		var candidate: Button = button_variant as Button
		if candidate != null and String(candidate.text).begins_with("Close"):
			close_button = candidate
			break
	if close_button == null:
		push_error("Build menu has no Close button")
		quit(1)
		return
	close_button.emit_signal("pressed")
	if build_menu.visible:
		push_error("Build menu close button did not hide the panel")
		quit(1)
		return
	build_menu.call("open_panel")
	var escape_event: InputEventKey = InputEventKey.new()
	escape_event.pressed = true
	escape_event.keycode = KEY_ESCAPE
	build_menu.call("_input", escape_event)
	if build_menu.visible:
		push_error("Build menu Esc close path did not hide the panel")
		quit(1)
		return
	build_menu.call("open_panel")
	await process_frame
	var menu_registry: Dictionary = ContentRegistry.placeables()
	var item_list: VBoxContainer = build_menu.get_node_or_null("Panel/Rows/Scroll/Items") as VBoxContainer
	if item_list == null:
		push_error("Build menu is missing Panel/Rows/Scroll/Items")
		quit(1)
		return
	for placeable_id_variant in _validation_placeable_ids:
		var placeable_id: String = String(placeable_id_variant)
		if not menu_registry.has(placeable_id):
			push_error("Build menu references unknown content id '%s'" % placeable_id)
			quit(1)
			return
	for menu_category in BuildCategories.ORDER:
		build_menu.set("_active_category", menu_category)
		build_menu.call("refresh")
		await process_frame
		var expected_ids: Array = BuildCategories.ids_in(menu_category, _validation_placeable_ids)
		for expected_id_variant in expected_ids:
			if not menu_registry.has(String(expected_id_variant)):
				push_error("Build menu category '%s' includes unknown content id '%s'" % [menu_category, expected_id_variant])
				quit(1)
				return
		var rendered_rows: int = 0
		for child in item_list.get_children():
			if child is HBoxContainer:
				rendered_rows += 1
		if rendered_rows != expected_ids.size():
			push_error("Build menu category '%s' rendered %d rows, expected %d" % [
				menu_category, rendered_rows, expected_ids.size(),
			])
			quit(1)
			return
	var new_modular_piece_ids: Array[String] = [
		ContentIds.PLACEABLE_WOOD_WINDOW_WALL,
		ContentIds.PLACEABLE_ROOF_CAP,
		ContentIds.PLACEABLE_FENCE_CORNER,
		ContentIds.PLACEABLE_FENCE_GATE,
		ContentIds.PLACEABLE_STEPS,
	]
	for modular_id in new_modular_piece_ids:
		if not ContentIds.DECOR_PLACEABLE_IDS.has(modular_id):
			push_error("New modular piece '%s' missing from ContentIds.DECOR_PLACEABLE_IDS" % modular_id)
			quit(1)
			return
		if not menu_registry.has(modular_id):
			push_error("New modular piece '%s' missing from ContentRegistry.placeables()" % modular_id)
			quit(1)
			return
		if not BuildCosts.costs().has(modular_id):
			push_error("New modular piece '%s' missing from BuildCosts" % modular_id)
			quit(1)
			return
		if not _validation_placeable_ids.has(modular_id):
			push_error("New modular piece '%s' missing from ObjectRegistry/build menu" % modular_id)
			quit(1)
			return
		var modular_scene_path: String = String((menu_registry[modular_id] as Dictionary).get("scene_path", ""))
		var modular_scene: PackedScene = load(modular_scene_path) as PackedScene
		if modular_scene == null:
			push_error("New modular piece '%s' scene failed to load: %s" % [modular_id, modular_scene_path])
			quit(1)
			return
	var prefab_metadata: Dictionary = PrefabInteriors.all_metadata()
	if PrefabInteriors.parse_metadata_dict({
		"has_interior": true,
		"template": "bogus",
		"interior_scene_id": "",
		"title": "",
	}).size() != 0:
		push_error("PrefabInteriors.parse_metadata_dict accepted invalid metadata")
		quit(1)
		return
	if not PrefabInteriors.metadata(ContentIds.PLACEABLE_GREENHOUSE_SHELL).is_empty():
		push_error("Structure without implemented interior metadata returned non-empty PrefabInteriors metadata")
		quit(1)
		return
	if PrefabInteriors.has_interior(ContentIds.PLACEABLE_GREENHOUSE_SHELL):
		push_error("Structure without implemented interior metadata reported has_interior")
		quit(1)
		return
	if not PrefabInteriors.template_of(ContentIds.PLACEABLE_GREENHOUSE_SHELL).is_empty() \
			or not PrefabInteriors.title_of(ContentIds.PLACEABLE_GREENHOUSE_SHELL).is_empty():
		push_error("PrefabInteriors missing-metadata fallback did not fail closed")
		quit(1)
		return
	if prefab_metadata.is_empty():
		push_error("No prefab structures have valid interior metadata")
		quit(1)
		return
	for prefab_id_variant in prefab_metadata.keys():
		var prefab_id: String = String(prefab_id_variant)
		var parsed: Dictionary = prefab_metadata[prefab_id] as Dictionary
		for required_field in ["has_interior", "template", "interior_scene_id", "title"]:
			if not parsed.has(required_field):
				push_error("PrefabInteriors metadata for '%s' missing field '%s'" % [prefab_id, required_field])
				quit(1)
				return
		if not menu_registry.has(prefab_id):
			push_error("PrefabInteriors metadata references unknown placeable '%s'" % prefab_id)
			quit(1)
			return
	var interior_view_scene: PackedScene = load("res://ui/interior_view.tscn") as PackedScene
	if interior_view_scene == null:
		push_error("Interior view scene failed explicit load")
		quit(1)
		return
	for modular_id in new_modular_piece_ids:
		if PrefabInteriors.has_interior(modular_id) or not PrefabInteriors.metadata(modular_id).is_empty():
			push_error("Modular/custom piece '%s' should not require an interior" % modular_id)
			quit(1)
			return
	build_menu.queue_free()
	object_registry.queue_free()
	await process_frame

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

	# Character appearance foundation: defaults must be complete and stable,
	# unknown ids must normalize to defaults, and the save helper must always
	# return a valid (already-normalized) appearance dict.
	var default_appearance: Dictionary = CharacterAppearance.default_appearance()
	if CharacterAppearance.normalized({}) != default_appearance:
		push_error("Empty appearance did not normalize to the default appearance")
		quit(1)
		return
	if CharacterAppearance.normalized(default_appearance) != default_appearance:
		push_error("Default appearance contains an id missing from the registry")
		quit(1)
		return
	var junk_appearance: Dictionary = CharacterAppearance.normalized({
		"hair_style": "not_a_style",
		"outfit_color": "not_a_color",
		"accessory": "tiny_hat",
	})
	if String(junk_appearance.get("hair_style", "")) != String(default_appearance["hair_style"]):
		push_error("Unknown hair_style id did not fall back to the default")
		quit(1)
		return
	if String(junk_appearance.get("accessory", "")) != "tiny_hat":
		push_error("Valid accessory id was not preserved through normalization")
		quit(1)
		return

	# The dev character creator toggle must stay a real InputMap action (bound
	# to F9 logical + physical) â€” an exact-keycode check broke on Fn-layer
	# keyboards once already.
	if not InputMap.has_action("toggle_character_creator"):
		push_error("InputMap action 'toggle_character_creator' is missing from project.godot")
		quit(1)
		return

	var appearance_save_system: LocalSaveSystem = LocalSaveSystem.new()
	var saved_appearance: Dictionary = appearance_save_system.get_player_appearance()
	if CharacterAppearance.normalized(saved_appearance) != saved_appearance:
		push_error("get_player_appearance returned a non-normalized appearance")
		quit(1)
		return
	appearance_save_system.free()

	# --- Persistent-world pass: materials, costs, placeables -------------------
	var material_inventory: MaterialInventory = MaterialInventory.from_dictionary({"wood": 3, "bogus": 5})
	material_inventory.add(ResourceIds.MATERIAL_STONE, 2)
	if material_inventory.get_count("wood") != 3 or material_inventory.get_count("bogus") != 0:
		push_error("MaterialInventory failed to filter/load material counts")
		quit(1)
		return
	if material_inventory.spend({"wood": 5}):
		push_error("MaterialInventory allowed overspending")
		quit(1)
		return
	if not material_inventory.spend({"wood": 2, "stone": 1}) or material_inventory.get_count("wood") != 1:
		push_error("MaterialInventory spend math is wrong")
		quit(1)
		return

	var all_placeables: Dictionary = ContentRegistry.placeables()
	var cost_table: Dictionary = BuildCosts.costs()
	for placeable_id in all_placeables.keys():
		var entry: Dictionary = all_placeables[placeable_id] as Dictionary
		for required_field in ["id", "display_name", "scene_path", "footprint", "category"]:
			if not entry.has(required_field):
				push_error("Placeable '%s' registry entry missing field '%s'" % [placeable_id, required_field])
				quit(1)
				return
		if not cost_table.has(placeable_id):
			push_error("Placeable '%s' has no BuildCosts entry" % placeable_id)
			quit(1)
			return
		for material_id in (cost_table[placeable_id] as Dictionary).keys():
			if not ResourceIds.is_storable(String(material_id)):
				push_error("Placeable '%s' cost uses unknown material/component '%s'" % [placeable_id, material_id])
				quit(1)
				return
		var placeable_scene: PackedScene = load(String(entry["scene_path"])) as PackedScene
		if placeable_scene == null:
			push_error("Placeable '%s' scene failed to load" % placeable_id)
			quit(1)
			return
		var placeable_instance: Node = placeable_scene.instantiate()
		if not (placeable_instance is PlaceableCrate):
			push_error("Placeable '%s' root does not extend PlaceableCrate" % placeable_id)
			placeable_instance.free()
			quit(1)
			return
		placeable_instance.free()
	for decor_id in ContentIds.DECOR_PLACEABLE_IDS:
		if not all_placeables.has(decor_id):
			push_error("Decor id '%s' missing from ContentRegistry.placeables()" % decor_id)
			quit(1)
			return

	# --- Persistent-world pass: profiles ---------------------------------------
	var default_profile: Dictionary = LocalProfile.create_default()
	var renormalized_profile: Dictionary = LocalProfile.normalized(default_profile)
	if String(renormalized_profile.get("profile_id", "")).is_empty():
		push_error("Default profile lost its profile_id through normalization")
		quit(1)
		return
	if CharacterAppearance.normalized(renormalized_profile["appearance"] as Dictionary) != renormalized_profile["appearance"]:
		push_error("Default profile appearance is not normalized")
		quit(1)
		return

	# New customization ids must all survive normalization (registry + builder).
	var expanded_appearance: Dictionary = CharacterAppearance.normalized({
		"hair_style": "leafy_pigtails", "hair_color": "berry_red", "skin_tone": "umber",
		"outfit_style": "mushroom_sweater", "outfit_color": "pond_blue", "accessory": "acorn_cap",
	})
	if String(expanded_appearance["hair_style"]) != "leafy_pigtails" or String(expanded_appearance["accessory"]) != "acorn_cap":
		push_error("Expanded customization ids did not survive normalization")
		quit(1)
		return

	# --- Persistent-world pass: server + network --------------------------------
	var default_world: Dictionary = ServerSaveSystem.create_default_world("validation_world")
	for world_field in ["world_id", "created_at", "updated_at", "placed_objects", "world_flags", "known_profiles"]:
		if not default_world.has(world_field):
			push_error("Server world default missing field '%s'" % world_field)
			quit(1)
			return
	var world_state: ServerWorldState = ServerWorldState.from_world(default_world)
	var committed: Dictionary = world_state.add_placed_object("crate", 4, 4, "profile_test", "Tester")
	if committed.is_empty() or not NetworkMessages.is_valid_placed_object(committed):
		push_error("ServerWorldState failed to commit a valid placed object")
		quit(1)
		return
	if not world_state.add_placed_object("crate", 4, 4, "profile_test", "Tester").is_empty():
		push_error("ServerWorldState allowed double placement on one tile")
		quit(1)
		return
	var roundtrip_world: Dictionary = ServerSaveSystem.normalize_world(default_world)
	if (roundtrip_world["placed_objects"] as Array).size() != 1:
		push_error("Server world normalize dropped a valid placed object")
		quit(1)
		return

	var identity: Dictionary = PlayerIdentity.normalized({"display_name": "  ", "appearance": {"hair_style": "junk"}})
	if String(identity["display_name"]).is_empty():
		push_error("PlayerIdentity allowed an empty display name")
		quit(1)
		return

	if NetworkMode.OFFLINE != "offline":
		push_error("NetworkMode.OFFLINE changed; offline-default contract broken")
		quit(1)
		return

	if not InputMap.has_action("toggle_network_panel"):
		push_error("InputMap action 'toggle_network_panel' is missing from project.godot")
		quit(1)
		return

	# Usability pass: the fullscreen toggle action must exist so the player is
	# never trapped in fullscreen, plus the inventory/help action ids.
	for required_action in ["toggle_fullscreen", "toggle_inventory", "toggle_help", "toggle_minimap", "toggle_admin_panel"]:
		if not InputMap.has_action(required_action):
			push_error("InputMap action '%s' is missing from project.godot" % required_action)
			quit(1)
			return

	# --- Server run/external-access pass ----------------------------------------
	for required_file in [
		"res://tools/run_server_local.ps1",
		"res://tools/run_server_public.ps1",
		"res://tools/run_client_local.ps1",
		"res://tools/run_client_editor.ps1",
		"res://tools/open_firewall_server_port.ps1",
		"res://tools/remove_firewall_server_port.ps1",
		"res://server/server_config.example.json",
		"res://docs/external_server_access.md",
		"res://docs/run_local_server.md",
		"res://docs/run_local_playtest.md",
		"res://docs/playtest_readiness.md",
		"res://docs/interiors_plan.md",
	]:
		if not FileAccess.file_exists(required_file):
			push_error("Required playtest file missing: %s" % required_file)
			quit(1)
			return

	# Server config resolution: defaults < config file values < CLI args.
	var config_defaults: Dictionary = ServerConfig.defaults()
	for config_key in ["bind_address", "port", "world", "max_players", "save_on_change", "log_connections"]:
		if not config_defaults.has(config_key):
			push_error("ServerConfig.defaults() missing key '%s'" % config_key)
			quit(1)
			return
	var resolved_config: Dictionary = ServerConfig.resolve(["--port=9001", "--bind=0.0.0.0", "--max-players=4"])
	if int(resolved_config["port"]) != 9001 or String(resolved_config["bind_address"]) != "*" or int(resolved_config["max_players"]) != 4:
		push_error("ServerConfig.resolve() did not apply CLI overrides correctly")
		quit(1)
		return
	if not ServerConfig.resolve(["--port=999999"]).get("port", 0) == ServerConfig.DEFAULT_PORT:
		push_error("ServerConfig accepted an out-of-range port")
		quit(1)
		return
	var example_config: Dictionary = ServerConfig.load_config_file("res://server/server_config.example.json")
	var merged_example: Dictionary = ServerConfig.merge(config_defaults, example_config)
	if int(merged_example["max_players"]) != 8 or String(merged_example["bind_address"]) != "*":
		push_error("server_config.example.json did not merge as expected")
		quit(1)
		return
	if ServerConfig.normalize_bind("not_an_ip") != "" or ServerConfig.normalize_bind("192.168.1.10") != "192.168.1.10":
		push_error("ServerConfig.normalize_bind() validation regressed")
		quit(1)
		return
	if ServerConfig.is_externally_reachable("127.0.0.1") or not ServerConfig.is_externally_reachable("*"):
		push_error("ServerConfig.is_externally_reachable() logic regressed")
		quit(1)
		return

	# --- Gathering + chat pass ----------------------------------------------------
	var seen_node_ids: Dictionary = {}
	var yield_definitions: Dictionary = ResourceNode.definitions()
	for spawn_variant in ResourceSpawnRegistry.definitions():
		var spawn: Dictionary = spawn_variant as Dictionary
		var spawn_node_id: String = String(spawn.get("node_id", ""))
		if spawn_node_id.is_empty() or seen_node_ids.has(spawn_node_id):
			push_error("ResourceSpawnRegistry has a missing/duplicate node_id: '%s'" % spawn_node_id)
			quit(1)
			return
		seen_node_ids[spawn_node_id] = true
		var spawn_type: String = String(spawn.get("type", ""))
		if not yield_definitions.has(spawn_type):
			push_error("ResourceSpawnRegistry node '%s' has unknown type '%s'" % [spawn_node_id, spawn_type])
			quit(1)
			return
		var yield_material: String = String((yield_definitions[spawn_type] as Dictionary).get("material_id", ""))
		if not ResourceIds.is_material(yield_material):
			push_error("Resource type '%s' yields unknown material '%s'" % [spawn_type, yield_material])
			quit(1)
			return
		if not ["homestead", "village", "forest"].has(String(spawn.get("anchor", ""))):
			push_error("ResourceSpawnRegistry node '%s' has unknown anchor" % spawn_node_id)
			quit(1)
			return
	if seen_node_ids.size() < 8:
		push_error("Expected at least 8 gatherable nodes, found %d" % seen_node_ids.size())
		quit(1)
		return
	if ResourceSpawnRegistry.has_node_id("not_a_real_node"):
		push_error("ResourceSpawnRegistry.has_node_id() matched a bogus id")
		quit(1)
		return

	if ChatMessage.sanitize("   ") != "" or ChatMessage.is_sendable("  \n "):
		push_error("ChatMessage failed to reject empty/whitespace messages")
		quit(1)
		return
	var long_message: String = "a".repeat(ChatMessage.MAX_LENGTH + 50)
	if ChatMessage.sanitize(long_message).length() != ChatMessage.MAX_LENGTH:
		push_error("ChatMessage failed to cap message length")
		quit(1)
		return
	if ChatMessage.sanitize("hi\nthere\t friend") != "hi there friend":
		push_error("ChatMessage failed to collapse whitespace/newlines")
		quit(1)
		return

	# --- Crafting pass --------------------------------------------------------------
	var recipe_table: Dictionary = CraftingRegistry.recipes()
	if recipe_table.is_empty():
		push_error("CraftingRegistry has no recipes")
		quit(1)
		return
	for recipe_key in recipe_table.keys():
		var recipe: Dictionary = recipe_table[recipe_key] as Dictionary
		if String(recipe.get("recipe_id", "")) != String(recipe_key):
			push_error("Recipe key '%s' does not match its recipe_id" % recipe_key)
			quit(1)
			return
		var problem: String = CraftingRecipe.validate(recipe)
		if not problem.is_empty():
			push_error("Recipe '%s' invalid: %s" % [recipe_key, problem])
			quit(1)
			return

	# Build costs may use raw materials, components, or crop items â€” nothing else.
	for cost_placeable_id in BuildCosts.costs().keys():
		if not ContentRegistry.placeables().has(String(cost_placeable_id)):
			push_error("BuildCosts references unknown placeable '%s'" % cost_placeable_id)
			quit(1)
			return
		for cost_item_id in (BuildCosts.costs()[cost_placeable_id] as Dictionary).keys():
			if not CraftingRecipe.is_valid_craft_item(String(cost_item_id)):
				push_error("Build cost for '%s' uses unknown id '%s'" % [cost_placeable_id, cost_item_id])
				quit(1)
				return

	# Starter loop sanity: planks must be hand-craftable at level 1 from the
	# multiplayer starter pack, and the offline check/spend math must work.
	var starter_pouch: MaterialInventory = MaterialInventory.starter_pack()
	var plank_check: Dictionary = CraftingSystem.check("craft_plank", starter_pouch.get_count, 1, [])
	if not bool(plank_check["ok"]):
		push_error("Starter materials cannot hand-craft planks: %s" % plank_check["reason"])
		quit(1)
		return
	var plank_result: Dictionary = CraftingSystem.craft_with_pouch("craft_plank", starter_pouch, 1, [])
	if not bool(plank_result["ok"]) or starter_pouch.get_count(ResourceIds.COMPONENT_PLANK) != 2:
		push_error("Pouch plank craft did not grant 2 planks")
		quit(1)
		return
	var blocked_check: Dictionary = CraftingSystem.check("craft_stone_block", starter_pouch.get_count, 1, [])
	if bool(blocked_check["ok"]):
		push_error("Level-2 station recipe was craftable at level 1 with no station")
		quit(1)
		return
	var station_check: Dictionary = CraftingSystem.check(
		"craft_stone_block", starter_pouch.get_count, 2, [ContentIds.PLACEABLE_WORKBENCH]
	)
	if not bool(station_check["ok"]):
		push_error("Workbench recipe denied despite level + station: %s" % station_check["reason"])
		quit(1)
		return

	# Progression model sanity: curve monotonic, levels derive correctly.
	if PlayerProgression.level_for_xp(0) != 1 or PlayerProgression.level_for_xp(25) != 2 or PlayerProgression.level_for_xp(99999) != PlayerProgression.MAX_LEVEL:
		push_error("PlayerProgression level thresholds regressed")
		quit(1)
		return
	for threshold_index in range(1, PlayerProgression.LEVEL_THRESHOLDS.size()):
		if PlayerProgression.LEVEL_THRESHOLDS[threshold_index] <= PlayerProgression.LEVEL_THRESHOLDS[threshold_index - 1]:
			push_error("PlayerProgression XP curve is not strictly increasing")
			quit(1)
			return

	# Skills: unique ids, all defined, normalization (incl. legacy flat shape),
	# grants, level derivation, and unlock checks.
	var seen_skill_ids: Dictionary = {}
	for skill_id in ProgressionRegistry.SKILL_IDS:
		if seen_skill_ids.has(skill_id) or not ProgressionRegistry.skills().has(skill_id):
			push_error("Skill id '%s' duplicated or missing a definition" % skill_id)
			quit(1)
			return
		seen_skill_ids[skill_id] = true
	var default_prog: Dictionary = SkillProgression.default_progression()
	if SkillProgression.normalized({}) != default_prog:
		push_error("Empty progression did not normalize to default")
		quit(1)
		return
	var legacy_prog: Dictionary = SkillProgression.normalized({"xp": 30})
	if int(legacy_prog["total_xp"]) != 30 or SkillProgression.player_level(legacy_prog) != 2:
		push_error("Legacy flat-xp progression shape did not migrate")
		quit(1)
		return
	var grant_check: Dictionary = SkillProgression.grant({}, ProgressionRegistry.SKILL_GATHERING, 25, 25)
	if not bool(grant_check["skill_levelled"]) or not bool(grant_check["player_levelled"]):
		push_error("SkillProgression.grant did not report level-ups at threshold")
		quit(1)
		return
	if SkillProgression.skill_level(grant_check["progression"] as Dictionary, ProgressionRegistry.SKILL_GATHERING) != 2:
		push_error("Skill level did not derive correctly after grant")
		quit(1)
		return
	if ProgressionRegistry.skill_for_material(ResourceIds.MATERIAL_STONE) != ProgressionRegistry.SKILL_MINING \
			or ProgressionRegistry.skill_for_material(ResourceIds.MATERIAL_WOOD) != ProgressionRegistry.SKILL_GATHERING:
		push_error("skill_for_material mapping regressed")
		quit(1)
		return

	# Unlock checks: locked then unlocked, and lock tables reference real ids.
	var arch_lock: Dictionary = ProgressionRegistry.placeable_locks()[ContentIds.PLACEABLE_GARDEN_ARCH] as Dictionary
	if ProgressionRegistry.lock_reason(arch_lock, 1, {"building": 1}).is_empty():
		push_error("Garden arch lock did not deny at Building 1")
		quit(1)
		return
	if not ProgressionRegistry.lock_reason(arch_lock, 1, {"building": 2}).is_empty():
		push_error("Garden arch lock denied despite Building 2")
		quit(1)
		return
	for locked_placeable_id in ProgressionRegistry.placeable_locks().keys():
		if not ContentRegistry.placeables().has(String(locked_placeable_id)):
			push_error("Placeable lock references unknown placeable '%s'" % locked_placeable_id)
			quit(1)
			return
		var placeable_lock: Dictionary = ProgressionRegistry.placeable_locks()[locked_placeable_id] as Dictionary
		var lock_skill: String = String(placeable_lock.get("required_skill", ""))
		if not lock_skill.is_empty() and not ProgressionRegistry.SKILL_IDS.has(lock_skill):
			push_error("Placeable lock for '%s' references unknown skill" % locked_placeable_id)
			quit(1)
			return
	var skill_locked_recipe: Dictionary = CraftingSystem.check(
		"craft_cloth_roll",
		func(_id: String) -> int: return 99,
		PlayerProgression.MAX_LEVEL,
		[ContentIds.PLACEABLE_GARDEN_TABLE],
		{"crafting": 1}
	)
	if bool(skill_locked_recipe["ok"]):
		push_error("Cloth roll craftable despite Crafting 1 (skill lock missing)")
		quit(1)
		return

	# Station placeables exist end-to-end and components are storable.
	for station_id_variant in CraftingRegistry.station_ids():
		if not ContentRegistry.placeables().has(String(station_id_variant)):
			push_error("Recipe station '%s' is not a registered placeable" % station_id_variant)
			quit(1)
			return
	for component_id in ResourceIds.ALL_COMPONENTS:
		if not ResourceIds.is_storable(component_id):
			push_error("Component '%s' is not storable" % component_id)
			quit(1)
			return

	# --- Worldbuilding pass: items, tools, soft-lock, land, identity -----------
	# Item taxonomy: unique ids across every category, wearables map to real
	# appearance accessories.
	var all_item_ids: Dictionary = {}
	for taxonomy_id in ResourceIds.ALL_MATERIALS + ResourceIds.ALL_COMPONENTS + ItemIds.ALL_TOOLS + ItemIds.ALL_WEAPONS + ItemIds.ALL_WEARABLES + ItemIds.ALL_QUEST_ITEMS:
		if all_item_ids.has(taxonomy_id):
			push_error("Duplicate item id across taxonomy: '%s'" % taxonomy_id)
			quit(1)
			return
		all_item_ids[taxonomy_id] = true
	for wearable_id in ItemIds.ALL_WEARABLES:
		var accessory: String = ItemIds.wearable_accessory(wearable_id)
		if not CharacterAppearanceRegistry.accessories().has(accessory):
			push_error("Wearable '%s' maps to unknown accessory '%s'" % [wearable_id, accessory])
			quit(1)
			return

	# Starter soft-lock prevention: every material has a HAND source in the
	# spawn registry, every starter tool recipe is hand-craftable (no station,
	# level 1, no tool-tier inputs), and tool-tier nodes reference real tools.
	var hand_materials: Dictionary = {}
	for spawn_def_variant in ResourceSpawnRegistry.definitions():
		var spawn_def: Dictionary = spawn_def_variant as Dictionary
		var node_yield: Dictionary = ResourceNode.definitions()[String(spawn_def["type"])] as Dictionary
		var node_tool: String = String(node_yield.get("required_tool", ""))
		if node_tool.is_empty():
			hand_materials[String(node_yield["material_id"])] = true
		elif not ItemIds.is_tool_item(node_tool):
			push_error("Resource type '%s' requires unknown tool '%s'" % [spawn_def["type"], node_tool])
			quit(1)
			return
	for base_material in ResourceIds.ALL_MATERIALS:
		if not hand_materials.has(base_material):
			push_error("SOFT-LOCK: material '%s' has no hand-gatherable source" % base_material)
			quit(1)
			return
	for tool_id in ItemIds.ALL_TOOLS:
		var tool_recipe: Dictionary = CraftingRegistry.get_recipe("craft_%s" % tool_id)
		if tool_recipe.is_empty():
			push_error("SOFT-LOCK: starter tool '%s' has no recipe" % tool_id)
			quit(1)
			return
		if not String(tool_recipe.get("required_station", "")).is_empty() or int(tool_recipe.get("required_level", 1)) > 1:
			push_error("SOFT-LOCK: starter tool recipe '%s' is gated behind a station/level" % tool_id)
			quit(1)
			return
		for tool_input in (tool_recipe["inputs"] as Dictionary).keys():
			if not ResourceIds.is_material(String(tool_input)):
				push_error("SOFT-LOCK: starter tool '%s' needs non-raw input '%s'" % [tool_id, tool_input])
				quit(1)
				return
	if not ItemIds.starter_loadout().has(ItemIds.TOOL_SIMPLE_HAMMER):
		push_error("Starter loadout is missing the hammer")
		quit(1)
		return
	# A tree must require the axe (chopping is tool-gated).
	if String((ResourceNode.definitions()[ResourceNode.TYPE_TREE] as Dictionary)["required_tool"]) != ItemIds.TOOL_WORN_AXE:
		push_error("Tree chopping does not require the axe")
		quit(1)
		return

	# Required build tools resolve, terrain takes the shovel.
	for tool_check_id in ContentRegistry.placeables().keys():
		var build_tool: String = ContentRegistry.placeable_required_tool(String(tool_check_id))
		if not ItemIds.is_tool_item(build_tool):
			push_error("Placeable '%s' requires unknown tool '%s'" % [tool_check_id, build_tool])
			quit(1)
			return
	if ContentRegistry.placeable_required_tool(ContentIds.PLACEABLE_DIRT_PATH) != ItemIds.TOOL_BASIC_SHOVEL:
		push_error("Terrain overlays do not require the shovel")
		quit(1)
		return

	# Land: plot ids unique with valid rects, >= 2 claimable, and the claim +
	# build permission state machine behaves.
	var plot_ids_seen: Dictionary = {}
	for plot_def_variant in LandRegistry.definitions().values():
		var plot_def: Dictionary = plot_def_variant as Dictionary
		var def_plot_id: String = String(plot_def.get("plot_id", ""))
		if def_plot_id.is_empty() or plot_ids_seen.has(def_plot_id):
			push_error("Land plot id missing/duplicate: '%s'" % def_plot_id)
			quit(1)
			return
		plot_ids_seen[def_plot_id] = true
	if LandRegistry.claimable_plot_ids().size() < 4:
		push_error("Fewer than 4 claimable homestead plots defined")
		quit(1)
		return
	# At least 4 plots must be true homestead-sized (12x12 = 144 tiles or more).
	var large_plot_ids: Array[String] = []
	for claim_id in LandRegistry.claimable_plot_ids():
		var claim_rect: Rect2i = LandRegistry.get_plot(String(claim_id)).get("rect", Rect2i()) as Rect2i
		if claim_rect.size.x >= 12 and claim_rect.size.y >= 12:
			large_plot_ids.append(String(claim_id))
	if large_plot_ids.size() < 4:
		push_error("Fewer than 4 plots are 12x12 or larger (found %d)" % large_plot_ids.size())
		quit(1)
		return
	var overworld_map: OverworldMap = OverworldMap.new()
	for large_plot_id in large_plot_ids:
		var large_rect: Rect2i = LandRegistry.get_plot(large_plot_id).get("rect", Rect2i()) as Rect2i
		var center_tile: Vector2i = Vector2i(
			large_rect.position.x + large_rect.size.x / 2,
			large_rect.position.y + large_rect.size.y / 2
		)
		if not large_rect.has_point(center_tile):
			push_error("Computed center tile is not inside plot '%s'" % large_plot_id)
			quit(1)
			return
		if String(LandRegistry.plot_at_tile(center_tile).get("plot_id", "")) != large_plot_id:
			push_error("Large plot center resolved to the wrong plot for '%s'" % large_plot_id)
			quit(1)
			return
		var center_result: Dictionary = overworld_map.get_place_footprint_result(center_tile, Vector2i.ONE, [])
		if not bool(center_result.get("valid", false)):
			push_error("Large plot center is not buildable for '%s': %s" % [large_plot_id, center_result.get("reason", "")])
			quit(1)
			return
	overworld_map.free()
	var test_plots: Dictionary = {}
	# Use an interior tile (plot center), not the sign tile (which now sits in
	# FRONT of the plot), so build-permission tests check the real bounds.
	var test_plot_id: String = large_plot_ids[0]
	var test_rect: Rect2i = LandRegistry.get_plot(test_plot_id).get("rect", Rect2i()) as Rect2i
	var test_tile: Vector2i = Vector2i(test_rect.position.x + test_rect.size.x / 2, test_rect.position.y + test_rect.size.y / 2)
	if not test_rect.has_point(test_tile):
		push_error("Computed test tile is not inside %s" % test_plot_id)
		quit(1)
		return
	if bool(LandClaimSystem.can_build_at(test_tile, "profile_a", test_plots)["allowed"]):
		push_error("Unclaimed plot allowed building without a claim")
		quit(1)
		return
	var claim_no_token: Dictionary = LandClaimSystem.attempt_claim(
		test_plot_id, "profile_a", "julie", test_plots,
		func(_id: String, _n: int) -> bool: return false,
		func(_id: String, _n: int) -> void: pass
	)
	if bool(claim_no_token["ok"]):
		push_error("Plot claim succeeded without a land token")
		quit(1)
		return
	var claim_ok: Dictionary = LandClaimSystem.attempt_claim(
		test_plot_id, "profile_a", "julie", test_plots,
		func(_id: String, _n: int) -> bool: return true,
		func(_id: String, _n: int) -> void: pass
	)
	if not bool(claim_ok["ok"]):
		push_error("Valid plot claim failed: %s" % claim_ok["reason"])
		quit(1)
		return
	test_plots[test_plot_id] = claim_ok["state"]
	if not bool(LandClaimSystem.can_build_at(test_tile, "profile_a", test_plots)["allowed"]):
		push_error("Plot owner denied building on own plot")
		quit(1)
		return
	if bool(LandClaimSystem.can_build_at(test_tile, "profile_b", test_plots)["allowed"]):
		push_error("Non-owner allowed building on someone's plot")
		quit(1)
		return
	if not bool(LandClaimSystem.can_build_at(test_tile, "profile_b", test_plots, true)["allowed"]):
		push_error("Admin bypass denied")
		quit(1)
		return
	# Shared-plot invites: only the owner may invite, and the invited member can
	# then build; a non-owner invite is rejected.
	if bool(LandClaimSystem.attempt_invite(test_plot_id, "profile_b", "profile_c", "carol", test_plots)["ok"]):
		push_error("Non-owner was allowed to invite to a plot")
		quit(1)
		return
	var invite_result: Dictionary = LandClaimSystem.attempt_invite(test_plot_id, "profile_a", "profile_b", "bob", test_plots)
	if not bool(invite_result["ok"]):
		push_error("Owner invite failed: %s" % invite_result["reason"])
		quit(1)
		return
	test_plots[test_plot_id] = invite_result["state"]
	if not bool(LandClaimSystem.can_build_at(test_tile, "profile_b", test_plots)["allowed"]):
		push_error("Invited member denied building on shared plot")
		quit(1)
		return
	if not bool(LandClaimSystem.can_build_at(Vector2i(7, 16), "profile_b", test_plots)["allowed"]):
		push_error("Public commons denied building")
		quit(1)
		return
	if bool(LandClaimSystem.attempt_claim("rowan_training_plot", "profile_a", "julie", test_plots, func(_i: String, _n: int) -> bool: return true, func(_i: String, _n: int) -> void: pass)["ok"]):
		push_error("NPC training land was claimable")
		quit(1)
		return

	# Identity: username sanitizer + admin roles.
	if PlayerIdentity.sanitize_username("  JuLie!! 99 ") != "julie99":
		push_error("Username sanitizer regressed: '%s'" % PlayerIdentity.sanitize_username("  JuLie!! 99 "))
		quit(1)
		return
	if PlayerIdentity.is_valid_username("ab") or not PlayerIdentity.is_valid_username("julie_99"):
		push_error("Username validity rules regressed")
		quit(1)
		return
	if String(LocalProfile.normalized({"display_name": "Old Save"}).get("username", "")).is_empty():
		push_error("Old profile without username did not get a default")
		quit(1)
		return
	if not AdminPermissions.can_world_build(AdminPermissions.offline_role()) or AdminPermissions.can_world_build(AdminPermissions.ROLE_PLAYER):
		push_error("Admin role permissions regressed")
		quit(1)
		return

	# Land repair pass: claimable plot rects must not overlap each other (each
	# is a distinct yard), and the quick-tools strip ids must all be real tools.
	var claimable: Array = LandRegistry.claimable_plot_ids()
	for i in range(claimable.size()):
		for j in range(i + 1, claimable.size()):
			var rect_a: Rect2i = LandRegistry.get_plot(String(claimable[i])).get("rect", Rect2i()) as Rect2i
			var rect_b: Rect2i = LandRegistry.get_plot(String(claimable[j])).get("rect", Rect2i()) as Rect2i
			if rect_a.intersects(rect_b):
				push_error("Plots '%s' and '%s' overlap" % [claimable[i], claimable[j]])
				quit(1)
				return
	for quick_tool_id in [ItemIds.TOOL_WORN_AXE, ItemIds.TOOL_WORN_PICKAXE, ItemIds.TOOL_WORN_HOE, ItemIds.TOOL_WATERING_CAN, ItemIds.TOOL_SIMPLE_HAMMER, ItemIds.TOOL_BASIC_SHOVEL]:
		if not ItemIds.is_tool_item(quick_tool_id):
			push_error("Quick-tools strip references non-tool id '%s'" % quick_tool_id)
			quit(1)
			return

	# Usability pass: nameplate helper builds labels; inventory categories all
	# reference ids that resolve to a display name (no crash on lookup).
	var nameplate_host: Node2D = Node2D.new()
	var nameplate_holder: Node2D = Nameplate.attach(nameplate_host, "Tester", "Player")
	if nameplate_holder == null or nameplate_holder.get_child_count() < 1:
		push_error("Nameplate.attach did not build a label")
		nameplate_host.free()
		quit(1)
		return
	nameplate_host.free()

	var inventory_ids: Array = ResourceIds.ALL_MATERIALS + ResourceIds.ALL_COMPONENTS + ItemIds.ALL_TOOLS \
		+ ItemIds.ALL_QUEST_ITEMS + ItemIds.ALL_WEAPONS + ItemIds.ALL_WEARABLES \
		+ [ContentIds.ITEM_CARROT, ContentIds.ITEM_TURNIP, ContentIds.ITEM_BERRY]
	for inv_id in inventory_ids:
		if ItemIds.display_name(String(inv_id)).is_empty():
			push_error("Inventory item id '%s' has no display name" % inv_id)
			quit(1)
			return
	if not ItemIds.ALL_QUEST_ITEMS.has(ItemIds.QUEST_LAND_TOKEN):
		push_error("Land token missing from quest items (inventory tokens category)")
		quit(1)
		return

	print("Project smoke test passed.")
	quit(0)
