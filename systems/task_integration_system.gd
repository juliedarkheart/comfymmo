extends Node
class_name TaskIntegrationSystem

# Public ids kept (controllers reference TaskIntegrationSystem.<NAME>); values now
# come from ContentIds so the strings live in one place. Unchanged at runtime.
const WATER_GARDEN_TASK_ID: String = ContentIds.TASK_WATER_GARDEN
const LEGACY_WATER_GARDEN_TASK_ID: String = ContentIds.TASK_LEGACY_WATER_GARDEN
const HARVEST_CARROT_TASK_ID: String = ContentIds.TASK_HARVEST_CARROT

var _mock_tasks: Array[Dictionary] = []
var _mailbox_message_state: Dictionary = {}

func load_from_data(data: Dictionary) -> void:
	_mock_tasks.clear()
	_mailbox_message_state.clear()
	var task_records: Variant = data.get("mock_tasks", [])
	if typeof(task_records) == TYPE_ARRAY:
		for task_record in task_records:
			if typeof(task_record) == TYPE_DICTIONARY:
				_mock_tasks.append(_normalize_message_record(task_record))

	var saved_message_state: Variant = data.get("mailbox_message_state", {})
	if typeof(saved_message_state) == TYPE_DICTIONARY:
		for message_id_variant in saved_message_state.keys():
			var message_id: String = _normalize_message_id(String(message_id_variant))
			var raw_state: Variant = saved_message_state[message_id_variant]
			if typeof(raw_state) == TYPE_DICTIONARY:
				var state_data: Dictionary = raw_state as Dictionary
				_mailbox_message_state[message_id] = {
					"seen": bool(state_data.get("seen", false)),
					"completed": bool(state_data.get("completed", false)),
				}

	if _mock_tasks.is_empty():
		_seed_default_tasks()
	else:
		_ensure_default_task_present()

func export_state() -> Dictionary:
	return {
		"mock_tasks": _mock_tasks,
		"mailbox_message_state": _mailbox_message_state,
	}

func import_mock_task(task_id: String, label: String) -> void:
	_mock_tasks.append({
		"id": task_id,
		"title": label,
		"body": "",
		"source": "mock",
		"status": "pending",
	})

func get_mock_tasks() -> Array[Dictionary]:
	var tasks: Array[Dictionary] = []
	for task_record in _mock_tasks:
		tasks.append(_apply_message_state(task_record))
	return tasks

func get_mailbox_messages() -> Array[Dictionary]:
	var mailbox_messages: Array[Dictionary] = []
	for task_record in _mock_tasks:
		mailbox_messages.append(_apply_message_state(task_record))
	return mailbox_messages

func has_unseen_mailbox_messages() -> bool:
	return get_unseen_mailbox_count() > 0

func get_unseen_mailbox_count() -> int:
	var unseen_count: int = 0
	for task_record in _mock_tasks:
		var message_id: String = String(task_record.get("id", ""))
		if message_id.is_empty():
			continue

		var message_state: Dictionary = _get_message_state(message_id)
		if not bool(message_state.get("seen", false)) and not bool(message_state.get("completed", false)):
			unseen_count += 1
	return unseen_count

func mark_all_messages_seen() -> bool:
	var state_changed: bool = false
	for task_record in _mock_tasks:
		var message_id: String = String(task_record.get("id", ""))
		if message_id.is_empty():
			continue

		var message_state: Dictionary = _get_message_state(message_id)
		if bool(message_state.get("seen", false)):
			continue

		message_state["seen"] = true
		_mailbox_message_state[message_id] = message_state
		state_changed = true
	return state_changed

func mark_message_completed(message_id: String) -> bool:
	var normalized_id: String = _normalize_message_id(message_id)
	if normalized_id.is_empty():
		return false

	var message_state: Dictionary = _get_message_state(normalized_id)
	if bool(message_state.get("completed", false)):
		return false

	message_state["completed"] = true
	_mailbox_message_state[normalized_id] = message_state
	return true

func _seed_default_tasks() -> void:
	_mock_tasks = [
		{
			"id": ContentIds.TASK_GROCERIES,
			"title": "Pick up groceries",
			"body": "Rosie left a list at the market board.",
			"source": "mock",
			"status": "pending",
		},
		{
			"id": WATER_GARDEN_TASK_ID,
			"title": "Water the garden",
			"body": "A quick drink for the farm plot — it'll thank you!",
			"source": "mock",
			"status": "pending",
		},
		{
			"id": HARVEST_CARROT_TASK_ID,
			"title": "Harvest a carrot",
			"body": "Pick a ripe carrot from the farm plot.",
			"source": "mock",
			"status": "pending",
		},
		{
			"id": ContentIds.TASK_COOKOUT,
			"title": "Community cookout Saturday",
			"body": "Bring something cozy to share at the village green.",
			"source": "mock",
			"status": "upcoming",
		},
		{
			"id": ContentIds.TASK_DELIVERY,
			"title": "Creature feed delivery arrived",
			"body": "Dani sent blueberries from the eastern meadows.",
			"source": "mock",
			"status": "new",
		},
	]

func _ensure_default_task_present() -> void:
	var has_water_garden: bool = false
	var has_harvest_carrot: bool = false
	for task_record in _mock_tasks:
		var task_id: String = String(task_record.get("id", ""))
		if task_id == WATER_GARDEN_TASK_ID:
			has_water_garden = true
		elif task_id == HARVEST_CARROT_TASK_ID:
			has_harvest_carrot = true

	if not has_water_garden:
		_mock_tasks.append({
			"id": WATER_GARDEN_TASK_ID,
			"title": "Water the garden",
			"body": "A quick drink for the farm plot — it'll thank you!",
			"source": "mock",
			"status": "pending",
		})

	if not has_harvest_carrot:
		_mock_tasks.append({
			"id": HARVEST_CARROT_TASK_ID,
			"title": "Harvest a carrot",
			"body": "Pick a ripe carrot from the farm plot.",
			"source": "mock",
			"status": "pending",
		})

func _normalize_message_record(task_record: Dictionary) -> Dictionary:
	var message_id: String = _normalize_message_id(
		String(task_record.get("id", task_record.get("task_id", "")))
	)
	var title: String = String(task_record.get("title", task_record.get("label", "")))
	var body: String = String(task_record.get("body", ""))
	var source: String = String(task_record.get("source", "mock"))
	var status: String = String(task_record.get("status", "pending"))
	return {
		"id": message_id,
		"title": title,
		"body": body,
		"source": source,
		"status": status,
	}

func _apply_message_state(task_record: Dictionary) -> Dictionary:
	var message_record: Dictionary = task_record.duplicate(true)
	var message_id: String = String(message_record.get("id", ""))
	var message_state: Dictionary = _get_message_state(message_id)
	message_record["seen"] = bool(message_state.get("seen", false))
	message_record["completed"] = bool(message_state.get("completed", false))
	return message_record

func _get_message_state(message_id: String) -> Dictionary:
	var normalized_id: String = _normalize_message_id(message_id)
	if normalized_id.is_empty() or not _mailbox_message_state.has(normalized_id):
		return {
			"seen": false,
			"completed": false,
		}

	return _mailbox_message_state[normalized_id] as Dictionary

func _normalize_message_id(message_id: String) -> String:
	if message_id == LEGACY_WATER_GARDEN_TASK_ID:
		return WATER_GARDEN_TASK_ID
	return message_id
