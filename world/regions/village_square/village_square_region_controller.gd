extends BaseRegionController
class_name VillageSquareRegionController

const MARIBEL_SCENE := preload("res://scenes/villagers/maribel_tock.tscn")
const BRAM_SCENE := preload("res://scenes/villagers/bram_nettle.tscn")
const NOTICE_BOARD_INTERACTABLE_ID: String = "village_square_notice_board"
const MARIBEL_INTERACTABLE_ID: String = "village_square_maribel"
const MARIBEL_INTRO_SEEN_FLAG: String = "maribel_intro_seen"
const MARIBEL_VISIT_COUNT_FLAG: String = "maribel_visit_count"
const BRAM_INTERACTABLE_ID: String = "village_square_bram"
const BRAM_INTRO_SEEN_FLAG: String = "bram_intro_seen"
const BRAM_VISIT_COUNT_FLAG: String = "bram_visit_count"
const HOMESTEAD_REGION_ID: String = "homestead"
const HOMESTEAD_SPAWN_ID: String = "from_village_square"
const FOREST_EDGE_REGION_ID: String = "forest_edge"
const FOREST_EDGE_SPAWN_ID: String = "from_village_square"
const CARROT_ITEM_ID: String = "carrot"
const TURNIP_ITEM_ID: String = "turnip"
const BERRY_ITEM_ID: String = "berry"
const CARROT_COMFORT_BONUS: float = 5.0
const NOTICE_BOARD_SEEN_FLAG: String = "notice_board_seen"

var _village_rabbit: MossRabbit = null
var _maribel: SimpleVillager = null
var _bram: SimpleVillager = null

@onready var map: VillageSquareMap = $Map
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
@onready var homestead_transition_area: Area2D = $HomesteadTransitionArea
@onready var forest_transition_area: Area2D = $ForestTransitionArea
@onready var notice_board_marker: Node2D = $NoticeBoardMarker

func _ready() -> void:
	game_state_manager.configure(save_system, object_registry)
	inventory_system.configure(object_registry)
	inventory_system.load_from_data(game_state_manager.get_player_section("inventory"))
	survival_system.load_from_data(game_state_manager.get_player_section("survival"))
	inventory_system.inventory_changed.connect(_on_inventory_changed)
	survival_system.survival_changed.connect(_on_survival_changed)
	region_transition_system.transition_requested.connect(_on_transition_requested)
	homestead_transition_area.body_entered.connect(_on_homestead_transition_body_entered)
	forest_transition_area.body_entered.connect(_on_forest_transition_body_entered)

	var player: AvatarController = player_spawn_system.spawn_player(
		gameplay_layer,
		map.get_spawn_position(get_entry_spawn_id())
	)
	var camera: AvatarCamera = player.get_node_or_null("Camera2D") as AvatarCamera
	if camera != null:
		camera.apply_region_view(map.get_camera_zoom(), map.get_camera_limits())
	interactable_system.configure(player)
	_spawn_maribel()
	_spawn_bram()
	_spawn_ambient_creatures(player)
	register_region_interactable(
		notice_board_marker,
		NOTICE_BOARD_INTERACTABLE_ID,
		"Press F to read notice board",
		_open_notice_board,
		"notice_board"
	)
	interactable_system.interaction_prompt_changed.connect(_on_interaction_prompt_changed)
	interactable_system.interaction_requested.connect(_on_interaction_requested)

	_refresh_inventory_hud()
	_refresh_survival_hud()
	apply_saved_mood()
	apply_saved_day()
	if hud.has_method("set_mode_text"):
		hud.call(
			"set_mode_text",
			"Explore",
			"Move with WASD or arrow keys. F to read board. C to eat carrot."
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

func _on_interaction_requested(interactable_id: String, interaction_type: String) -> void:
	match interaction_type:
		_:
			return

func _on_homestead_transition_body_entered(body: Node) -> void:
	if not body is AvatarController:
		return

	region_transition_system.request_transition(HOMESTEAD_REGION_ID, HOMESTEAD_SPAWN_ID)

func _on_forest_transition_body_entered(body: Node) -> void:
	if not body is AvatarController:
		return

	region_transition_system.request_transition(FOREST_EDGE_REGION_ID, FOREST_EDGE_SPAWN_ID)

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
			"Comfort: %d" % int(snappedf(survival_system.get_stat("comfort"), 1.0))
		)

func _consume_carrot() -> void:
	if not inventory_system.has_item(CARROT_ITEM_ID):
		return

	if not inventory_system.remove_item(CARROT_ITEM_ID, 1):
		return

	survival_system.add_to_stat("comfort", CARROT_COMFORT_BONUS)

func _spawn_maribel() -> void:
	_maribel = MARIBEL_SCENE.instantiate() as SimpleVillager
	_maribel.position = Vector2(128.0, 218.0)
	gameplay_layer.add_child(_maribel)
	register_region_interactable(
		_maribel,
		MARIBEL_INTERACTABLE_ID,
		"Press F to talk to Maribel",
		_on_talk_maribel,
		"villager"
	)

func _on_talk_maribel() -> void:
	if _maribel == null:
		return
	_handle_villager_talk(_maribel, MARIBEL_INTRO_SEEN_FLAG, MARIBEL_VISIT_COUNT_FLAG, _maribel_passage_line)

func _spawn_bram() -> void:
	_bram = BRAM_SCENE.instantiate() as SimpleVillager
	_bram.position = Vector2(144.0, 452.0)
	gameplay_layer.add_child(_bram)
	register_region_interactable(
		_bram,
		BRAM_INTERACTABLE_ID,
		"Press F to talk to Bram",
		_on_talk_bram,
		"villager"
	)

func _on_talk_bram() -> void:
	if _bram == null:
		return
	_handle_villager_talk(_bram, BRAM_INTRO_SEEN_FLAG, BRAM_VISIT_COUNT_FLAG, _bram_passage_line)

func _handle_villager_talk(
	villager: SimpleVillager,
	intro_flag: String,
	count_flag: String,
	passage_line: Callable = Callable()
) -> void:
	var has_seen: bool = bool(get_region_flag(intro_flag, false))
	if not has_seen:
		show_region_message(villager.villager_name, villager.first_visit_text)
		mark_region_flag_seen(intro_flag)
		return
	var visit_count: int = int(get_region_flag(count_flag, 0))
	var line: String = villager.get_repeat_line(visit_count)
	# Every other repeat, a day/mood-aware villager remarks on the passage of time.
	if passage_line.is_valid() and visit_count % 2 == 1:
		line = passage_line.call(save_system.get_day_count(), save_system.get_current_mood())
	show_region_message(villager.villager_name, line)
	set_region_flag(count_flag, visit_count + 1)

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

func _spawn_ambient_creatures(player: AvatarController) -> void:
	_village_rabbit = MossRabbit.new()
	_village_rabbit.position = Vector2(0.0, 340.0)
	gameplay_layer.add_child(_village_rabbit)
	_village_rabbit.configure_creature(player)
	register_region_interactable(
		_village_rabbit,
		"village_rabbit_0",
		"Press F to observe",
		_on_observe_village_rabbit,
		"ambient_creature"
	)

func _on_observe_village_rabbit() -> void:
	if _village_rabbit == null:
		return
	show_region_message(_village_rabbit.get_display_name(), _village_rabbit.get_observe_text())

func _open_notice_board() -> void:
	show_region_message(
		"Village Notice Board",
		"Welcome to the village square."
	)
	if not bool(get_region_flag(NOTICE_BOARD_SEEN_FLAG, false)):
		mark_region_flag_seen(NOTICE_BOARD_SEEN_FLAG)

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
