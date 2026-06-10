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

var _farm_plots: Dictionary = {}

func _ready() -> void:
	game_state_manager.configure(save_system, object_registry)
	inventory_system.configure(object_registry)
	inventory_system.load_from_data(game_state_manager.get_player_section("inventory"))
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

	if not _is_mailbox_open():
		if (
			event is InputEventKey
			and event.pressed
			and not event.echo
			and event.keycode == KEY_C
			and not _decorating_mode_active
		):
			_consume_carrot()
			_mark_input_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_close_mailbox()
		_mark_input_handled()

func _on_decorating_mode_changed(is_active: bool, player: AvatarController) -> void:
	_decorating_mode_active = is_active
	player.set_movement_enabled(not is_active)
	interactable_system.set_interactions_enabled(not is_active and not _is_mailbox_open())

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
		ContentIds.INTERACTION_FARM_PLOT:
			_handle_farm_plot_interaction(interactable_id)
		_:
			# Everything registered through register_world_interactable (creatures,
			# rest, and the overworld's villagers/notice/shrine) dispatches via its
			# bound callback. The guards above ran first, exactly as before.
			_dispatch_world_interactable(interactable_id)

func _on_inventory_changed() -> void:
	_save_inventory_state()
	_refresh_inventory_hud()

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

	var interaction_result: Dictionary = farming_system.interact_with_plot(interactable_id)
	if not bool(interaction_result.get("changed", false)):
		return

	if String(interaction_result.get("action", "")) == "harvest":
		var harvested_crop_id: String = String(
			interaction_result.get("crop_id", CARROT_ITEM_ID)
		)
		if object_registry.get_item_definition(harvested_crop_id).is_empty():
			harvested_crop_id = CARROT_ITEM_ID
		inventory_system.add_item(harvested_crop_id, 1)
		if task_integration_system.mark_message_completed(
			TaskIntegrationSystem.HARVEST_CARROT_TASK_ID
		):
			_save_task_integration_state()
			_refresh_mailbox_world_state()
	elif String(interaction_result.get("action", "")) == "water":
		if task_integration_system.mark_message_completed(
			TaskIntegrationSystem.WATER_GARDEN_TASK_ID
		):
			_save_task_integration_state()
			_refresh_mailbox_world_state()

	_save_farming_state()
	interactable_system.update_interactable_prompt(
		interactable_id,
		farming_system.get_plot_prompt(interactable_id)
	)
	_refresh_all_farm_plot_visuals(interactable_id)

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
	}

func _toggle_inventory_panel() -> void:
	if hud.has_method("toggle_inventory_panel"):
		hud.call("toggle_inventory_panel")

# _mark_input_handled() is inherited from OutdoorAreaController.
