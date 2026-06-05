extends Node2D
class_name BaseRegionController

signal region_transition_requested(target_region_id: String, target_spawn_id: String)

@export var region_id: String = ""

var _entry_spawn_id: String = "default"
var _region_message_open: bool = false
var _region_interactable_callbacks: Dictionary = {}
var _region_interactable_connection_ready: bool = false

func set_region_id(value: String) -> void:
	region_id = value

func get_region_id() -> String:
	return region_id

func set_entry_spawn_id(spawn_id: String) -> void:
	if spawn_id.is_empty():
		return

	_entry_spawn_id = spawn_id

func get_entry_spawn_id() -> String:
	return _entry_spawn_id

func request_region_transition(target_region_id: String, target_spawn_id: String = "default") -> void:
	region_transition_requested.emit(target_region_id, target_spawn_id)

func apply_saved_mood() -> void:
	var resolved_save_system: LocalSaveSystem = _get_region_save_system()
	var resolved_hud: CanvasLayer = _get_region_hud()
	if resolved_save_system == null or resolved_hud == null or not resolved_hud.has_method("set_mood"):
		return

	resolved_hud.call("set_mood", resolved_save_system.get_current_mood())

func apply_saved_day() -> void:
	var resolved_save_system: LocalSaveSystem = _get_region_save_system()
	var resolved_hud: CanvasLayer = _get_region_hud()
	if resolved_save_system == null or resolved_hud == null or not resolved_hud.has_method("set_day"):
		return

	resolved_hud.call("set_day", resolved_save_system.get_day_count())

func cycle_mood() -> void:
	var resolved_save_system: LocalSaveSystem = _get_region_save_system()
	if resolved_save_system == null:
		return

	var next_mood: String = WorldMood.next_mood(resolved_save_system.get_current_mood())
	resolved_save_system.set_current_mood(next_mood)

	var resolved_hud: CanvasLayer = _get_region_hud()
	if resolved_hud != null and resolved_hud.has_method("set_mood"):
		resolved_hud.call("set_mood", next_mood)

func get_region_state() -> Dictionary:
	var resolved_save_system: LocalSaveSystem = _get_region_save_system()
	if resolved_save_system == null:
		return {}

	return resolved_save_system.get_region_state(region_id)

func get_region_flags() -> Dictionary:
	var resolved_save_system: LocalSaveSystem = _get_region_save_system()
	if resolved_save_system == null:
		return {}

	return resolved_save_system.get_region_flags(region_id)

func get_region_flag(key: String, default_value: Variant = null) -> Variant:
	if key.is_empty():
		return default_value

	var region_flags: Dictionary = get_region_flags()
	return region_flags.get(key, default_value)

func set_region_flag(key: String, value: Variant) -> void:
	if key.is_empty():
		return

	var resolved_save_system: LocalSaveSystem = _get_region_save_system()
	if resolved_save_system == null:
		return

	resolved_save_system.set_region_flag(region_id, key, value)

func mark_region_flag_seen(key: String) -> void:
	set_region_flag(key, true)

func show_region_message(title: String, body: String, footer: String = "Esc to close") -> void:
	var resolved_hud: CanvasLayer = _get_region_hud()
	if resolved_hud == null or not resolved_hud.has_method("show_message_panel"):
		return

	_region_message_open = true
	var resolved_interactable_system: InteractableSystem = _get_region_interactable_system()
	if resolved_interactable_system != null:
		resolved_interactable_system.set_interactions_enabled(false)

	resolved_hud.call("show_message_panel", title, body, footer)

func hide_region_message() -> void:
	var resolved_hud: CanvasLayer = _get_region_hud()
	if resolved_hud != null and resolved_hud.has_method("hide_message_panel"):
		resolved_hud.call("hide_message_panel")

	_region_message_open = false
	var resolved_interactable_system: InteractableSystem = _get_region_interactable_system()
	if resolved_interactable_system != null:
		resolved_interactable_system.set_interactions_enabled(true)

func is_region_message_open() -> bool:
	return _region_message_open

func register_region_interactable(node: Node2D, interactable_id: String, prompt: String, callback: Callable, interaction_type: String = "region_simple") -> void:
	if node == null or interactable_id.is_empty() or not callback.is_valid():
		return

	var resolved_interactable_system: InteractableSystem = _get_region_interactable_system()
	if resolved_interactable_system == null:
		return

	_ensure_region_interactable_connection()
	_region_interactable_callbacks[interactable_id] = {
		"callback": callback,
		"interaction_type": interaction_type,
	}
	resolved_interactable_system.register_interactable(
		interactable_id,
		node,
		interaction_type,
		prompt
	)

func unregister_region_interactable(interactable_id: String) -> void:
	if interactable_id.is_empty():
		return

	var resolved_interactable_system: InteractableSystem = _get_region_interactable_system()
	if resolved_interactable_system != null:
		resolved_interactable_system.unregister_interactable(interactable_id)

	_region_interactable_callbacks.erase(interactable_id)

func _get_region_save_system() -> LocalSaveSystem:
	return get_node_or_null("LocalSaveSystem") as LocalSaveSystem

func _get_region_hud() -> CanvasLayer:
	return get_node_or_null("HUD") as CanvasLayer

func _get_region_interactable_system() -> InteractableSystem:
	return get_node_or_null("InteractableSystem") as InteractableSystem

func _ensure_region_interactable_connection() -> void:
	if _region_interactable_connection_ready:
		return

	var resolved_interactable_system: InteractableSystem = _get_region_interactable_system()
	if resolved_interactable_system == null:
		return

	resolved_interactable_system.interaction_requested.connect(_on_region_interaction_requested)
	_region_interactable_connection_ready = true

func _on_region_interaction_requested(interactable_id: String, interaction_type: String) -> void:
	if not _region_interactable_callbacks.has(interactable_id):
		return

	var callback_data: Dictionary = _region_interactable_callbacks[interactable_id] as Dictionary
	var expected_type: String = String(callback_data.get("interaction_type", ""))
	if not expected_type.is_empty() and interaction_type != expected_type:
		return

	var callback: Callable = callback_data.get("callback", Callable()) as Callable
	if callback.is_valid():
		callback.call()
