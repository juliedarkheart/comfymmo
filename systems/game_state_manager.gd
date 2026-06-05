extends Node
class_name GameStateManager

signal state_bootstrapped()

var save_system: LocalSaveSystem
var object_registry: ObjectRegistry
var current_region_id: String = "homestead"
var world_state: Dictionary = {}
var player_state: Dictionary = {}
var task_state: Dictionary = {}

func configure(target_save_system: LocalSaveSystem, target_object_registry: ObjectRegistry) -> void:
	save_system = target_save_system
	object_registry = target_object_registry
	_load_state_from_save()
	state_bootstrapped.emit()

func get_world_section(section_name: String) -> Dictionary:
	return _get_dictionary_from_container(world_state, section_name)

func get_region_section(region_id: String, section_name: String) -> Dictionary:
	var regions_data: Dictionary = _get_dictionary_from_container(world_state, "regions")
	if not regions_data.has(region_id):
		return {}

	var region_value: Variant = regions_data.get(region_id, {})
	if typeof(region_value) != TYPE_DICTIONARY:
		return {}

	var region_data: Dictionary = region_value as Dictionary
	return _get_dictionary_from_container(region_data, section_name)

func get_player_section(section_name: String) -> Dictionary:
	return _get_dictionary_from_container(player_state, section_name)

func get_task_section(section_name: String) -> Dictionary:
	return _get_dictionary_from_container(task_state, section_name)

func set_current_region(region_id: String) -> void:
	current_region_id = region_id
	world_state["current_region_id"] = region_id

func set_world_value(key: String, value: Variant) -> void:
	world_state[key] = value

func get_world_value(key: String, default_value: Variant = null) -> Variant:
	return world_state.get(key, default_value)

func export_runtime_state() -> Dictionary:
	var export_data: Dictionary = {
		"world": world_state,
		"player": player_state,
		"tasks": task_state,
	}
	return export_data

func _load_state_from_save() -> void:
	if save_system == null:
		world_state = {"current_region_id": current_region_id}
		player_state = {}
		task_state = {}
		return

	var save_data: Dictionary = save_system.load_save_data()
	world_state = save_data.get("world", {}) as Dictionary
	player_state = save_data.get("player", {}) as Dictionary
	task_state = save_data.get("tasks", {}) as Dictionary
	current_region_id = String(world_state.get("current_region_id", world_state.get("current_world_id", "homestead")))
	world_state["current_region_id"] = current_region_id

func _get_dictionary_from_container(container: Dictionary, section_name: String) -> Dictionary:
	if not container.has(section_name):
		return {}

	return container[section_name] as Dictionary
