extends Node
class_name BuildingPlacementSystem

const PLACEABLE_CRATE_SCENE := preload("res://scenes/buildings/placeable_crate.tscn")
const WORLD_SPACE_HINT_SCENE := preload("res://ui/world_space_hint.tscn")

signal decorating_mode_changed(active: bool)
signal decorating_mode_label_changed(mode_name: String, help_text: String)

enum InteractionMode {
	NONE,
	PLACEMENT,
	EDIT,
	MOVE,
}

var map: HomesteadMap
var gameplay_layer: Node2D
var save_system: LocalSaveSystem
var object_registry: ObjectRegistry
var interactable_system: InteractableSystem
# Optional: when wired (homestead/overworld), building consumes materials via
# BuildCosts. Legacy region controllers never wire it, so they stay free.
var inventory_system: InventorySystem = null
var _placeable_ids: Array[String] = []
var _preview_object: PlaceableCrate
var _active_placeable_id: String = "crate"
var _interaction_mode: InteractionMode = InteractionMode.NONE
var _current_tile: Vector2i = Vector2i.ZERO
var _placed_objects: Array[Dictionary] = []
var _occupied_tiles: Dictionary = {}
var _placed_nodes: Dictionary = {}
var _selected_record_id: String = ""
var _hovered_record_id: String = ""
var _next_record_id: int = 1
var _moving_record_id: String = ""
var _move_origin_tile: Vector2i = Vector2i.ZERO
var _world_space_hint: WorldSpaceHint
var _mailbox_has_new_mail: bool = false
var _region_id: String = "homestead"

func configure(target_map: HomesteadMap, target_gameplay_layer: Node2D, target_save_system: LocalSaveSystem, target_object_registry: ObjectRegistry, target_interactable_system: InteractableSystem, region_id: String = "homestead") -> void:
	map = target_map
	gameplay_layer = target_gameplay_layer
	save_system = target_save_system
	object_registry = target_object_registry
	interactable_system = target_interactable_system
	_region_id = region_id
	_sync_placeable_ids()
	_ensure_world_space_hint()
	_load_placed_objects()
	_emit_mode_label_changed()

func _process(_delta: float) -> void:
	if map == null:
		return

	match _interaction_mode:
		InteractionMode.PLACEMENT:
			if _preview_object == null:
				return

			var hovered_tile: Vector2i = map.world_to_grid(map.get_global_mouse_position())
			if hovered_tile == _current_tile:
				return

			_current_tile = hovered_tile
			_update_preview_state()
		InteractionMode.EDIT:
			_update_hovered_selection()
		InteractionMode.MOVE:
			_update_move_preview()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			_toggle_placement_mode()
			_mark_input_handled()
			return

		if event.keycode == KEY_E:
			_toggle_edit_mode()
			_mark_input_handled()
			return

		if _interaction_mode == InteractionMode.MOVE and event.keycode == KEY_M:
			_mark_input_handled()
			return

		if _interaction_mode == InteractionMode.PLACEMENT and event.keycode == KEY_TAB:
			_cycle_active_placeable()
			_mark_input_handled()
			return

		if event.keycode == KEY_ESCAPE:
			_exit_current_mode()
			_mark_input_handled()
			return

		if _interaction_mode == InteractionMode.PLACEMENT and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
			_try_place_active_object()
			_mark_input_handled()
			return

		if _interaction_mode == InteractionMode.EDIT and (event.keycode == KEY_DELETE or event.keycode == KEY_BACKSPACE):
			_remove_selected_object()
			_mark_input_handled()
			return

		if _interaction_mode == InteractionMode.EDIT and event.keycode == KEY_M:
			_start_move_selected_object()
			_mark_input_handled()
			return

		if _interaction_mode == InteractionMode.MOVE and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
			_confirm_move_selected_object()
			_mark_input_handled()
			return

	if _interaction_mode == InteractionMode.NONE:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _interaction_mode == InteractionMode.PLACEMENT:
			_try_place_active_object()
		elif _interaction_mode == InteractionMode.EDIT:
			_select_hovered_object()
		elif _interaction_mode == InteractionMode.MOVE:
			_confirm_move_selected_object()
		_mark_input_handled()

func _toggle_placement_mode() -> void:
	if _interaction_mode == InteractionMode.PLACEMENT:
		_exit_placement_mode()
		return

	_exit_edit_or_move_mode()
	_enter_placement_mode()

func _enter_placement_mode() -> void:
	_interaction_mode = InteractionMode.PLACEMENT
	_current_tile = map.world_to_grid(map.get_global_mouse_position())
	_spawn_preview()
	_emit_decorating_mode_changed()
	_emit_mode_label_changed()

func _cycle_active_placeable() -> void:
	_sync_placeable_ids()
	if _placeable_ids.is_empty():
		return

	var current_index: int = _placeable_ids.find(_active_placeable_id)
	if current_index == -1:
		current_index = 0

	_active_placeable_id = _placeable_ids[(current_index + 1) % _placeable_ids.size()]
	_spawn_preview()
	_emit_mode_label_changed()

func _exit_placement_mode() -> void:
	if _interaction_mode == InteractionMode.PLACEMENT:
		_interaction_mode = InteractionMode.NONE
	_destroy_preview()
	_emit_decorating_mode_changed()
	_emit_mode_label_changed()

func _toggle_edit_mode() -> void:
	if _interaction_mode == InteractionMode.EDIT:
		_exit_edit_mode()
		return

	if _interaction_mode == InteractionMode.MOVE:
		_cancel_move_selected_object()
		_exit_edit_mode()
		return

	_exit_placement_mode()
	_enter_edit_mode()

func _enter_edit_mode() -> void:
	_interaction_mode = InteractionMode.EDIT
	_clear_selection()
	_current_tile = map.world_to_grid(map.get_global_mouse_position())
	_update_hovered_selection()
	_emit_decorating_mode_changed()
	_emit_mode_label_changed()

func _exit_edit_mode() -> void:
	if _interaction_mode == InteractionMode.MOVE:
		_cancel_move_selected_object()

	if _interaction_mode == InteractionMode.EDIT:
		_interaction_mode = InteractionMode.NONE
	_clear_selection()
	_hovered_record_id = ""
	_emit_decorating_mode_changed()
	_emit_mode_label_changed()

func _exit_current_mode() -> void:
	if _interaction_mode == InteractionMode.PLACEMENT:
		_exit_placement_mode()
	elif _interaction_mode == InteractionMode.EDIT or _interaction_mode == InteractionMode.MOVE:
		_exit_edit_mode()

func _spawn_preview() -> void:
	_destroy_preview()
	var placeable_data: PlaceableObjectData = _get_active_placeable_data()
	_preview_object = placeable_data.scene.instantiate() as PlaceableCrate
	gameplay_layer.add_child(_preview_object)
	if _preview_object is PlaceableMailbox:
		(_preview_object as PlaceableMailbox).set_has_new_mail(_mailbox_has_new_mail)
	_preview_object.set_preview_mode(true)
	_update_preview_state()

func _destroy_preview() -> void:
	if _preview_object == null:
		return

	_preview_object.queue_free()
	_preview_object = null
	_hide_world_space_hint()

func _update_preview_state() -> void:
	if _preview_object == null:
		return

	var placement_result: Dictionary = _get_active_place_result(_current_tile)
	var is_valid: bool = bool(placement_result.get("valid", false))
	var world_position: Vector2 = map.grid_to_world(_current_tile)
	_preview_object.set_tile_position(_current_tile, world_position)
	_preview_object.set_preview_valid(is_valid)
	_show_world_space_hint(is_valid, String(placement_result.get("reason", "")), world_position)

func _is_valid_placement(tile: Vector2i) -> bool:
	var placement_result: Dictionary = _get_active_place_result(tile)
	return bool(placement_result.get("valid", false))

func set_inventory_system(target_inventory_system: InventorySystem) -> void:
	inventory_system = target_inventory_system

## Runtime lookup instead of the autoload identifier: scripts referencing the
## autoload name directly fail to compile under `--script` (validation) where
## autoload globals are not registered. Null means "behave offline".
func _network_session() -> Node:
	return get_node_or_null("/root/NetworkSession")

func _is_network_client() -> bool:
	var session: Node = _network_session()
	return session != null and bool(session.call("is_client_connected"))

func _get_active_place_result(tile: Vector2i) -> Dictionary:
	var placeable_data: PlaceableObjectData = _get_active_placeable_data()
	var result: Dictionary = map.get_place_footprint_result(tile, placeable_data.footprint, _get_occupied_tiles())
	if not bool(result.get("valid", false)):
		return result
	# Survival-lite material gate. Connected clients skip the local check — the
	# server owns their materials and validates the request authoritatively.
	if inventory_system != null and not _is_network_client():
		var cost: Dictionary = BuildCosts.cost_of(_active_placeable_id)
		for material_id in cost.keys():
			if inventory_system.get_quantity(String(material_id)) < int(cost[material_id]):
				return {
					"valid": false,
					"reason": "Needs %s" % BuildCosts.cost_text(_active_placeable_id),
				}
	return result

func _try_place_active_object() -> void:
	if not _is_valid_placement(_current_tile):
		_update_preview_state()
		return

	# Connected to a server: placement is server-authoritative. Send a request;
	# the committed object arrives back via the world snapshot/broadcast path and
	# is spawned as a network object (not part of the local save).
	if _is_network_client():
		_network_session().call("request_place", _active_placeable_id, _current_tile)
		_update_preview_state()
		return

	# Offline: spend materials (when an inventory is wired), then place locally.
	if inventory_system != null:
		var cost: Dictionary = BuildCosts.cost_of(_active_placeable_id)
		for material_id in cost.keys():
			if not inventory_system.remove_item(String(material_id), int(cost[material_id])):
				_update_preview_state()
				return

	var record: Dictionary = {
		"record_id": _generate_record_id(),
		"object_id": _active_placeable_id,
		"tile_x": _current_tile.x,
		"tile_y": _current_tile.y,
	}
	_place_record(record, true)
	save_system.set_region_placed_objects(_region_id, _placed_objects)
	_update_preview_state()
	_hide_world_space_hint()

func _load_placed_objects() -> void:
	_placed_objects.clear()
	_occupied_tiles.clear()
	_placed_nodes.clear()
	var normalized_records: bool = false

	for record in save_system.get_region_placed_objects(_region_id):
		if not record.has("record_id"):
			record["record_id"] = _generate_record_id()
			normalized_records = true
		else:
			_track_record_id(String(record.get("record_id", "")))
		_place_record(record, false)

	if normalized_records:
		save_system.set_region_placed_objects(_region_id, _placed_objects)

func _place_record(record: Dictionary, should_append: bool) -> void:
	var record_id: String = String(record.get("record_id", ""))
	if record_id.is_empty():
		return

	var object_id: String = String(record.get("object_id", ""))
	if object_registry == null or not object_registry.has_placeable(object_id):
		return

	var tile: Vector2i = Vector2i(int(record.get("tile_x", 0)), int(record.get("tile_y", 0)))
	var placeable_data: PlaceableObjectData = object_registry.get_placeable_data(object_id)
	if not map.can_place_footprint(tile, placeable_data.footprint, _get_occupied_tiles()):
		return

	var placed_object: PlaceableCrate = placeable_data.scene.instantiate() as PlaceableCrate
	placed_object.set_record_id(record_id)
	placed_object.set_tile_position(tile, map.grid_to_world(tile))
	gameplay_layer.add_child(placed_object)
	placed_object.set_placed_visual()
	_placed_nodes[record_id] = placed_object
	_apply_mailbox_state_to_node(placed_object)
	_register_interactable_for_object(record_id, object_id, placed_object)
	_mark_occupied_tiles(tile, placeable_data.footprint)

	if should_append:
		_placed_objects.append(record)
	else:
		_placed_objects.append({
			"record_id": record_id,
			"object_id": object_id,
			"tile_x": tile.x,
			"tile_y": tile.y,
		})

func _mark_occupied_tiles(origin: Vector2i, footprint: Vector2i) -> void:
	for tile in map.get_footprint_tiles(origin, footprint):
		_occupied_tiles[_tile_key(tile)] = tile

func _get_occupied_tiles() -> Array[Vector2i]:
	var results: Array[Vector2i] = []
	for occupied_tile in _occupied_tiles.values():
		results.append(occupied_tile as Vector2i)
	return results

func _tile_key(tile: Vector2i) -> String:
	return "%s,%s" % [tile.x, tile.y]

func _get_active_placeable_data() -> PlaceableObjectData:
	if object_registry == null:
		return null

	return object_registry.get_placeable_data(_active_placeable_id)

func _generate_record_id() -> String:
	var record_id: String = "%s_%04d" % [_active_placeable_id, _next_record_id]
	_next_record_id += 1
	return record_id

func _update_hovered_selection() -> void:
	var hovered_tile: Vector2i = map.world_to_grid(map.get_global_mouse_position())
	if hovered_tile == _current_tile and _hovered_record_id == _find_record_id_at_tile(hovered_tile):
		return

	_current_tile = hovered_tile
	var new_hovered_record_id: String = _find_record_id_at_tile(hovered_tile)
	if new_hovered_record_id == _hovered_record_id:
		return

	if _hovered_record_id != _selected_record_id:
		_set_record_highlight(_hovered_record_id, false)
	_hovered_record_id = new_hovered_record_id
	if _hovered_record_id != _selected_record_id:
		_set_record_highlight(_hovered_record_id, true)

func _select_hovered_object() -> void:
	if _hovered_record_id.is_empty():
		_clear_selection()
		return

	if _selected_record_id == _hovered_record_id:
		_remove_selected_object()
		return

	_set_record_highlight(_selected_record_id, false)
	_selected_record_id = _hovered_record_id
	_set_record_highlight(_selected_record_id, true)

func _start_move_selected_object() -> void:
	if _selected_record_id.is_empty():
		return

	var moving_record: Dictionary = _find_record_by_id(_selected_record_id)
	var moving_node: PlaceableCrate = _get_record_node(_selected_record_id)
	if moving_record.is_empty() or moving_node == null:
		return

	_moving_record_id = _selected_record_id
	_move_origin_tile = Vector2i(int(moving_record.get("tile_x", 0)), int(moving_record.get("tile_y", 0)))
	_interaction_mode = InteractionMode.MOVE
	_hovered_record_id = ""
	_current_tile = map.world_to_grid(map.get_global_mouse_position())
	_rebuild_occupied_tiles_excluding(_moving_record_id)
	moving_node.set_selected(false)
	moving_node.set_preview_mode(true)
	_update_move_preview()
	_emit_decorating_mode_changed()
	_emit_mode_label_changed()

func _update_move_preview() -> void:
	var moving_node: PlaceableCrate = _get_record_node(_moving_record_id)
	if moving_node == null:
		return

	var hovered_tile: Vector2i = map.world_to_grid(map.get_global_mouse_position())
	_current_tile = hovered_tile
	var world_position: Vector2 = map.grid_to_world(_current_tile)
	var move_result: Dictionary = _get_move_result(_current_tile)
	var is_valid: bool = bool(move_result.get("valid", false))
	moving_node.set_tile_position(_current_tile, world_position)
	moving_node.set_preview_valid(is_valid)
	_show_world_space_hint(is_valid, String(move_result.get("reason", "")), world_position)

func _is_valid_move_tile(tile: Vector2i) -> bool:
	var move_result: Dictionary = _get_move_result(tile)
	return bool(move_result.get("valid", false))

func _get_move_result(tile: Vector2i) -> Dictionary:
	if _moving_record_id.is_empty():
		return {
			"valid": false,
			"reason": "Blocked",
		}

	var moving_record: Dictionary = _find_record_by_id(_moving_record_id)
	if moving_record.is_empty():
		return {
			"valid": false,
			"reason": "Blocked",
		}

	var object_id: String = String(moving_record.get("object_id", ""))
	if object_registry == null or not object_registry.has_placeable(object_id):
		return {
			"valid": false,
			"reason": "Blocked",
		}

	var placeable_data: PlaceableObjectData = object_registry.get_placeable_data(object_id)
	return map.get_place_footprint_result(tile, placeable_data.footprint, _get_occupied_tiles())

func _confirm_move_selected_object() -> void:
	if _moving_record_id.is_empty() or not _is_valid_move_tile(_current_tile):
		var moving_node: PlaceableCrate = _get_record_node(_moving_record_id)
		if moving_node != null:
			var move_result: Dictionary = _get_move_result(_current_tile)
			moving_node.set_preview_valid(false)
			_show_world_space_hint(false, String(move_result.get("reason", "Blocked")), moving_node.position)
		return

	var moving_record: Dictionary = _find_record_by_id(_moving_record_id)
	if moving_record.is_empty():
		return

	_update_record_tile(_moving_record_id, _current_tile)

	var moving_node: PlaceableCrate = _get_record_node(_moving_record_id)
	if moving_node != null:
		moving_node.set_tile_position(_current_tile, map.grid_to_world(_current_tile))
		moving_node.set_preview_mode(false)
		moving_node.set_placed_visual()
		moving_node.set_selected(true)

	_rebuild_occupied_tiles()
	save_system.set_region_placed_objects(_region_id, _placed_objects)
	_interaction_mode = InteractionMode.EDIT
	_move_origin_tile = Vector2i.ZERO
	_moving_record_id = ""
	_current_tile = map.world_to_grid(map.get_global_mouse_position())
	_update_hovered_selection()
	_emit_decorating_mode_changed()
	_emit_mode_label_changed()
	_hide_world_space_hint()

func _cancel_move_selected_object() -> void:
	if _moving_record_id.is_empty():
		return

	var moving_record: Dictionary = _find_record_by_id(_moving_record_id)
	var moving_node: PlaceableCrate = _get_record_node(_moving_record_id)
	if moving_record.is_empty() or moving_node == null:
		_moving_record_id = ""
		_move_origin_tile = Vector2i.ZERO
		_interaction_mode = InteractionMode.EDIT
		_rebuild_occupied_tiles()
		return

	moving_node.set_tile_position(_move_origin_tile, map.grid_to_world(_move_origin_tile))
	moving_node.set_preview_mode(false)
	moving_node.set_placed_visual()
	moving_node.set_selected(true)
	_update_record_tile(_moving_record_id, _move_origin_tile)
	_rebuild_occupied_tiles()
	_interaction_mode = InteractionMode.EDIT
	_moving_record_id = ""
	_move_origin_tile = Vector2i.ZERO
	_current_tile = map.world_to_grid(map.get_global_mouse_position())
	_update_hovered_selection()
	_emit_decorating_mode_changed()
	_emit_mode_label_changed()
	_hide_world_space_hint()

func _remove_selected_object() -> void:
	if _selected_record_id.is_empty():
		return

	var index_to_remove: int = -1
	for index in range(_placed_objects.size()):
		if String(_placed_objects[index].get("record_id", "")) == _selected_record_id:
			index_to_remove = index
			break

	if index_to_remove == -1:
		return

	var placed_node: PlaceableCrate = _placed_nodes.get(_selected_record_id) as PlaceableCrate
	var removed_object_id: String = String(_placed_objects[index_to_remove].get("object_id", ""))
	if placed_node != null:
		placed_node.queue_free()

	_unregister_interactable_for_object(_selected_record_id, removed_object_id)
	_placed_nodes.erase(_selected_record_id)
	_placed_objects.remove_at(index_to_remove)
	_rebuild_occupied_tiles()
	save_system.set_region_placed_objects(_region_id, _placed_objects)

	var removed_record_id: String = _selected_record_id
	_selected_record_id = ""
	if _hovered_record_id == removed_record_id:
		_hovered_record_id = ""
	_update_hovered_selection()

func _rebuild_occupied_tiles() -> void:
	_occupied_tiles.clear()
	for record in _placed_objects:
		var object_id: String = String(record.get("object_id", ""))
		if object_registry == null or not object_registry.has_placeable(object_id):
			continue

		var placeable_data: PlaceableObjectData = object_registry.get_placeable_data(object_id)
		var tile: Vector2i = Vector2i(int(record.get("tile_x", 0)), int(record.get("tile_y", 0)))
		_mark_occupied_tiles(tile, placeable_data.footprint)

func _rebuild_occupied_tiles_excluding(record_id: String) -> void:
	_occupied_tiles.clear()
	for record in _placed_objects:
		if String(record.get("record_id", "")) == record_id:
			continue

		var object_id: String = String(record.get("object_id", ""))
		if object_registry == null or not object_registry.has_placeable(object_id):
			continue

		var placeable_data: PlaceableObjectData = object_registry.get_placeable_data(object_id)
		var tile: Vector2i = Vector2i(int(record.get("tile_x", 0)), int(record.get("tile_y", 0)))
		_mark_occupied_tiles(tile, placeable_data.footprint)

func _find_record_id_at_tile(tile: Vector2i) -> String:
	for record in _placed_objects:
		var object_id: String = String(record.get("object_id", ""))
		if object_registry == null or not object_registry.has_placeable(object_id):
			continue

		var placeable_data: PlaceableObjectData = object_registry.get_placeable_data(object_id)
		var origin: Vector2i = Vector2i(int(record.get("tile_x", 0)), int(record.get("tile_y", 0)))
		if tile in map.get_footprint_tiles(origin, placeable_data.footprint):
			return String(record.get("record_id", ""))
	return ""

func _clear_selection() -> void:
	_set_record_highlight(_selected_record_id, false)
	_set_record_highlight(_hovered_record_id, false)
	_selected_record_id = ""
	_hovered_record_id = ""

func _set_record_highlight(record_id: String, is_highlighted: bool) -> void:
	if record_id.is_empty():
		return

	var placed_node: PlaceableCrate = _placed_nodes.get(record_id) as PlaceableCrate
	if placed_node == null:
		return

	placed_node.set_selected(is_highlighted)

func _track_record_id(record_id: String) -> void:
	var separator_index: int = record_id.rfind("_")
	if separator_index == -1:
		return

	var suffix: String = record_id.substr(separator_index + 1)
	if not suffix.is_valid_int():
		return

	_next_record_id = max(_next_record_id, int(suffix) + 1)

func _find_record_by_id(record_id: String) -> Dictionary:
	for record in _placed_objects:
		if String(record.get("record_id", "")) == record_id:
			return record
	return {}

func _get_record_node(record_id: String) -> PlaceableCrate:
	return _placed_nodes.get(record_id) as PlaceableCrate

func _exit_edit_or_move_mode() -> void:
	if _interaction_mode == InteractionMode.EDIT or _interaction_mode == InteractionMode.MOVE:
		_exit_edit_mode()

func _update_record_tile(record_id: String, tile: Vector2i) -> void:
	for index in range(_placed_objects.size()):
		if String(_placed_objects[index].get("record_id", "")) != record_id:
			continue

		_placed_objects[index]["tile_x"] = tile.x
		_placed_objects[index]["tile_y"] = tile.y
		return

func _emit_decorating_mode_changed() -> void:
	decorating_mode_changed.emit(_interaction_mode != InteractionMode.NONE)

func _emit_mode_label_changed() -> void:
	match _interaction_mode:
		InteractionMode.PLACEMENT:
			var placeable_data: PlaceableObjectData = _get_active_placeable_data()
			var cost_text: String = BuildCosts.cost_text(_active_placeable_id)
			var cost_suffix: String = "" if cost_text.is_empty() else " (Cost: %s)" % cost_text
			decorating_mode_label_changed.emit(
				"Placement Mode",
				"%s selected%s. Tab to switch. Click or Enter to place. Esc to cancel." % [placeable_data.display_name, cost_suffix]
			)
		InteractionMode.EDIT:
			decorating_mode_label_changed.emit(
				"Edit Mode",
				"Click object to select. M to move. Delete to remove. Esc to cancel."
			)
		InteractionMode.MOVE:
			decorating_mode_label_changed.emit(
				"Move Mode",
				"Click or Enter to confirm. Esc to cancel."
			)
		_:
			decorating_mode_label_changed.emit(
				"Explore",
				"Move with WASD or arrow keys. B to place. E to edit."
			)

func _ensure_world_space_hint() -> void:
	if _world_space_hint != null:
		return

	_world_space_hint = WORLD_SPACE_HINT_SCENE.instantiate() as WorldSpaceHint
	gameplay_layer.add_child(_world_space_hint)

func _show_world_space_hint(is_valid: bool, reason_text: String, world_position: Vector2) -> void:
	if _world_space_hint == null:
		return

	var text: String = "Valid" if is_valid else reason_text if not reason_text.is_empty() else "Blocked"
	_world_space_hint.show_hint(text, is_valid, world_position)

func _hide_world_space_hint() -> void:
	if _world_space_hint == null:
		return

	_world_space_hint.hide_hint()

func _sync_placeable_ids() -> void:
	if object_registry == null:
		_placeable_ids.clear()
		return

	_placeable_ids = object_registry.get_placeable_ids()
	if _placeable_ids.is_empty():
		_active_placeable_id = ""
		return

	if not _placeable_ids.has(_active_placeable_id):
		_active_placeable_id = _placeable_ids[0]

func set_mailbox_new_mail_active(is_active: bool) -> void:
	_mailbox_has_new_mail = is_active
	for placed_node_variant in _placed_nodes.values():
		var placed_node: PlaceableCrate = placed_node_variant as PlaceableCrate
		_apply_mailbox_state_to_node(placed_node)

	if _preview_object != null:
		_apply_mailbox_state_to_node(_preview_object)

func _register_interactable_for_object(record_id: String, object_id: String, placed_object: PlaceableCrate) -> void:
	if interactable_system == null:
		return

	if object_id != ContentIds.PLACEABLE_MAILBOX:
		return

	interactable_system.register_interactable(
		record_id,
		placed_object,
		ContentIds.INTERACTION_MAILBOX,
		"Press F to check mailbox"
	)

func _unregister_interactable_for_object(record_id: String, object_id: String) -> void:
	if interactable_system == null:
		return

	if object_id != ContentIds.PLACEABLE_MAILBOX:
		return

	interactable_system.unregister_interactable(record_id)

func _apply_mailbox_state_to_node(placed_object: PlaceableCrate) -> void:
	if placed_object == null:
		return

	if placed_object is PlaceableMailbox:
		(placed_object as PlaceableMailbox).set_has_new_mail(_mailbox_has_new_mail)

func _mark_input_handled() -> void:
	var viewport: Viewport = get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()
