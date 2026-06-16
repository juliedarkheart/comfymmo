extends Node
class_name InteractableSystem

signal interaction_prompt_changed(prompt_text: String)
signal interaction_requested(interactable_id: String, interaction_type: String)

const MAILBOX_PROMPT: String = "Press F to check mailbox"
const DEFAULT_INTERACTION_RADIUS: float = 54.0

var _interactables: Dictionary = {}
var _player: Node2D
var _interactions_enabled: bool = true
var _nearest_interactable_id: String = ""

func configure(player: Node2D) -> void:
	_player = player
	_refresh_nearest_interactable()

func _process(_delta: float) -> void:
	if not _interactions_enabled or _player == null:
		if not _nearest_interactable_id.is_empty():
			_nearest_interactable_id = ""
			interaction_prompt_changed.emit("")
		return

	_refresh_nearest_interactable()

func _unhandled_input(event: InputEvent) -> void:
	if not _interactions_enabled or _nearest_interactable_id.is_empty():
		return
	if event is InputEventKey and event.echo:
		return

	if event.is_action_pressed("interact_primary"):
		var interaction_type: String = get_interaction_type(_nearest_interactable_id)
		if interaction_type.is_empty():
			return

		interaction_requested.emit(_nearest_interactable_id, interaction_type)
		_mark_input_handled()

func register_interactable(interactable_id: String, node: Node2D, interaction_type: String = ContentIds.INTERACTION_GENERIC, prompt_text: String = "") -> void:
	_interactables[interactable_id] = {
		"node": node,
		"interaction_type": interaction_type,
		"prompt_text": prompt_text,
	}
	_refresh_nearest_interactable()

func unregister_interactable(interactable_id: String) -> void:
	_interactables.erase(interactable_id)
	if _nearest_interactable_id == interactable_id:
		_nearest_interactable_id = ""
		interaction_prompt_changed.emit("")

func update_interactable_prompt(interactable_id: String, prompt_text: String) -> void:
	if not _interactables.has(interactable_id):
		return

	var interaction_data: Dictionary = _interactables[interactable_id] as Dictionary
	interaction_data["prompt_text"] = prompt_text
	_interactables[interactable_id] = interaction_data
	if _nearest_interactable_id == interactable_id:
		interaction_prompt_changed.emit(_get_prompt_text(interactable_id))

func has_interactable(interactable_id: String) -> bool:
	return _interactables.has(interactable_id)

func get_nearest_interactable_id() -> String:
	return _nearest_interactable_id

func get_interaction_type(interactable_id: String) -> String:
	if not _interactables.has(interactable_id):
		return ""

	var interaction_data: Dictionary = _interactables[interactable_id] as Dictionary
	return String(interaction_data.get("interaction_type", ""))

func set_interactions_enabled(is_enabled: bool) -> void:
	_interactions_enabled = is_enabled
	if not _interactions_enabled:
		_nearest_interactable_id = ""
		interaction_prompt_changed.emit("")
		return

	_refresh_nearest_interactable()

func get_available_actions(interactable_id: String) -> Array[String]:
	if not _interactables.has(interactable_id):
		return []

	var interaction_type: String = get_interaction_type(interactable_id)
	match interaction_type:
		ContentIds.INTERACTION_MAILBOX:
			return [ContentIds.ACTION_CHECK_MAIL]
		ContentIds.INTERACTION_FARM_PLOT:
			return [ContentIds.ACTION_TEND_PLOT]
		ContentIds.INTERACTION_NOTICE_BOARD:
			return [ContentIds.ACTION_READ_NOTICE]
		ContentIds.INTERACTION_REGION_TRANSITION:
			return [ContentIds.ACTION_TRAVEL]
		ContentIds.INTERACTION_TASK_BOARD:
			return [ContentIds.ACTION_REVIEW_TASKS]
		ContentIds.INTERACTION_AMBIENT_CREATURE:
			return [ContentIds.ACTION_OBSERVE]
		ContentIds.INTERACTION_VILLAGER:
			return [ContentIds.ACTION_TALK]
		ContentIds.INTERACTION_REST:
			return [ContentIds.ACTION_REST]
		_:
			return [ContentIds.ACTION_INSPECT]

func _refresh_nearest_interactable() -> void:
	var nearest_interactable_id: String = ""
	var nearest_distance_sq: float = INF
	var stale_ids: Array[String] = []

	for interactable_id_variant in _interactables.keys():
		var interactable_id: String = String(interactable_id_variant)
		var interaction_data: Dictionary = _interactables[interactable_id] as Dictionary
		var interactable_node: Node2D = interaction_data.get("node", null) as Node2D
		if interactable_node == null or not is_instance_valid(interactable_node):
			stale_ids.append(interactable_id)
			continue

		var distance_sq: float = _player.global_position.distance_squared_to(interactable_node.global_position)
		if distance_sq > DEFAULT_INTERACTION_RADIUS * DEFAULT_INTERACTION_RADIUS:
			continue

		if distance_sq < nearest_distance_sq:
			nearest_distance_sq = distance_sq
			nearest_interactable_id = interactable_id

	for stale_id in stale_ids:
		_interactables.erase(stale_id)

	if nearest_interactable_id == _nearest_interactable_id:
		return

	_nearest_interactable_id = nearest_interactable_id
	if _nearest_interactable_id.is_empty():
		interaction_prompt_changed.emit("")
		return

	interaction_prompt_changed.emit(_get_prompt_text(_nearest_interactable_id))

func _get_prompt_text(interactable_id: String) -> String:
	if not _interactables.has(interactable_id):
		return ""

	var interaction_data: Dictionary = _interactables[interactable_id] as Dictionary
	var prompt_text: String = String(interaction_data.get("prompt_text", ""))
	if not prompt_text.is_empty():
		return prompt_text

	match String(interaction_data.get("interaction_type", "")):
		ContentIds.INTERACTION_MAILBOX:
			return MAILBOX_PROMPT
		ContentIds.INTERACTION_FARM_PLOT:
			return "Press F to tend plot"
		ContentIds.INTERACTION_NOTICE_BOARD:
			return "Press F to read notice board"
		ContentIds.INTERACTION_REGION_TRANSITION:
			return "Press F to travel"
		ContentIds.INTERACTION_TASK_BOARD:
			return "Press F to review tasks"
		ContentIds.INTERACTION_AMBIENT_CREATURE:
			return "Press F to observe"
		ContentIds.INTERACTION_VILLAGER:
			return "Press F to talk"
		ContentIds.INTERACTION_REST:
			return "Press F to rest"
		ContentIds.INTERACTION_PREFAB_DOOR:
			return "Press F to enter"
		_:
			return "Press F to inspect"

func _mark_input_handled() -> void:
	var viewport: Viewport = get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()
