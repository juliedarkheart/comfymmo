extends BaseRegionController
class_name ForestEdgeRegionController

const TARGET_REGION_ID: String = "village_square"
const TARGET_SPAWN_ID: String = "from_forest_edge"
const CARROT_ITEM_ID: String = "carrot"
const TURNIP_ITEM_ID: String = "turnip"
const BERRY_ITEM_ID: String = "berry"
const CARROT_COMFORT_BONUS: float = 5.0
const ADVENTURE_MARKER_INTERACTABLE_ID: String = "forest_edge_adventure_marker"
const ADVENTURE_MARKER_SEEN_FLAG: String = "adventure_marker_seen"

var _forest_creatures: Array[AmbientCreature] = []

@onready var map: ForestEdgeMap = $Map
@onready var gameplay_layer: Node2D = $Map/GameplayLayer
@onready var player_spawn_system: PlayerSpawnSystem = $PlayerSpawnSystem
@onready var save_system: LocalSaveSystem = $LocalSaveSystem
@onready var object_registry: ObjectRegistry = $ObjectRegistry
@onready var game_state_manager: GameStateManager = $GameStateManager
@onready var interactable_system: InteractableSystem = $InteractableSystem
@onready var inventory_system: InventorySystem = $InventorySystem
@onready var survival_system: SurvivalSystem = $SurvivalSystem
@onready var region_transition_system: RegionTransitionSystem = $RegionTransitionSystem
@onready var hud: CanvasLayer = $HUD
@onready var village_transition_area: Area2D = $VillageTransitionArea
@onready var adventure_marker: Node2D = $AdventureMarker

func _ready() -> void:
	game_state_manager.configure(save_system, object_registry)
	inventory_system.configure(object_registry)
	inventory_system.load_from_data(game_state_manager.get_player_section("inventory"))
	survival_system.load_from_data(game_state_manager.get_player_section("survival"))
	inventory_system.inventory_changed.connect(_on_inventory_changed)
	survival_system.survival_changed.connect(_on_survival_changed)
	region_transition_system.transition_requested.connect(_on_transition_requested)
	village_transition_area.body_entered.connect(_on_village_transition_body_entered)

	var player: AvatarController = player_spawn_system.spawn_player(
		gameplay_layer,
		map.get_spawn_position(get_entry_spawn_id())
	)
	var camera: AvatarCamera = player.get_node_or_null("Camera2D") as AvatarCamera
	if camera != null:
		camera.apply_region_view(map.get_camera_zoom(), map.get_camera_limits())
	interactable_system.configure(player)
	_spawn_ambient_creatures(player)
	register_region_interactable(
		adventure_marker,
		ADVENTURE_MARKER_INTERACTABLE_ID,
		"Press F to inspect shrine",
		_open_adventure_marker_message,
		"shrine_marker"
	)
	interactable_system.interaction_prompt_changed.connect(_on_interaction_prompt_changed)

	_refresh_inventory_hud()
	_refresh_survival_hud()
	apply_saved_mood()
	apply_saved_day()
	if hud.has_method("set_mode_text"):
		hud.call(
			"set_mode_text",
			"Explore",
			"Move with WASD or arrow keys. Follow the forest trail. C to eat carrot."
		)

func _unhandled_input(event: InputEvent) -> void:
	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == KEY_T
		and not is_region_message_open()
	):
		cycle_mood()
		_mark_input_handled()
		return

	if is_region_message_open():
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			hide_region_message()
			_mark_input_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_I:
		_toggle_inventory_panel()
		_mark_input_handled()
		return

	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == KEY_C
	):
		_consume_carrot()
		_mark_input_handled()

func _on_interaction_prompt_changed(prompt_text: String) -> void:
	if hud.has_method("set_interaction_prompt"):
		hud.call("set_interaction_prompt", prompt_text)

func _on_village_transition_body_entered(body: Node) -> void:
	if not body is AvatarController:
		return

	region_transition_system.request_transition(TARGET_REGION_ID, TARGET_SPAWN_ID)

func _on_transition_requested(target_region_id: String, target_spawn_id: String) -> void:
	request_region_transition(target_region_id, target_spawn_id)

func _on_inventory_changed() -> void:
	_save_inventory_state()
	_refresh_inventory_hud()

func _on_survival_changed() -> void:
	_save_survival_state()
	_refresh_survival_hud()

func _refresh_inventory_hud() -> void:
	if hud.has_method("set_inventory_counts"):
		hud.call("set_inventory_counts", _get_inventory_counts())

func _refresh_survival_hud() -> void:
	if hud.has_method("set_survival_text"):
		hud.call(
			"set_survival_text",
			"Comfort %d" % int(snappedf(survival_system.get_stat("comfort"), 1.0))
		)

func _consume_carrot() -> void:
	if not inventory_system.has_item(CARROT_ITEM_ID):
		return

	if not inventory_system.remove_item(CARROT_ITEM_ID, 1):
		return

	survival_system.add_to_stat("comfort", CARROT_COMFORT_BONUS)

func _spawn_ambient_creatures(player: AvatarController) -> void:
	var rabbit_positions: Array[Vector2] = [
		Vector2(32.0, 304.0),
		Vector2(192.0, 448.0),
		Vector2(-64.0, 448.0),
	]
	for i: int in range(rabbit_positions.size()):
		var rabbit: MossRabbit = MossRabbit.new()
		rabbit.position = rabbit_positions[i]
		gameplay_layer.add_child(rabbit)
		rabbit.configure_creature(player)
		_forest_creatures.append(rabbit)
		register_region_interactable(
			rabbit,
			"forest_rabbit_%d" % i,
			"Press F to observe",
			_on_observe_creature.bind(rabbit),
			"ambient_creature"
		)

	var moth_positions: Array[Vector2] = [
		Vector2(224.0, 336.0),
		Vector2(-128.0, 320.0),
	]
	for i: int in range(moth_positions.size()):
		var moth: LanternMoth = LanternMoth.new()
		moth.position = moth_positions[i]
		gameplay_layer.add_child(moth)
		moth.configure_creature(player)
		_forest_creatures.append(moth)
		register_region_interactable(
			moth,
			"forest_moth_%d" % i,
			"Press F to observe",
			_on_observe_creature.bind(moth),
			"ambient_creature"
		)

func _on_observe_creature(creature: AmbientCreature) -> void:
	show_region_message(creature.get_display_name(), creature.get_observe_text())

func _open_adventure_marker_message() -> void:
	var marker_seen: bool = bool(get_region_flag(ADVENTURE_MARKER_SEEN_FLAG, false))
	var message_body: String = "The marker still hums softly." if marker_seen else "The path beyond is quiet... for now."
	show_region_message("Old Shrine", message_body)
	if not marker_seen:
		mark_region_flag_seen(ADVENTURE_MARKER_SEEN_FLAG)

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

func _mark_input_handled() -> void:
	var viewport: Viewport = get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()

func _get_inventory_counts() -> Dictionary:
	return {
		CARROT_ITEM_ID: inventory_system.get_count(CARROT_ITEM_ID),
		TURNIP_ITEM_ID: inventory_system.get_count(TURNIP_ITEM_ID),
		BERRY_ITEM_ID: inventory_system.get_count(BERRY_ITEM_ID),
	}

func _toggle_inventory_panel() -> void:
	if hud.has_method("toggle_inventory_panel"):
		hud.call("toggle_inventory_panel")
