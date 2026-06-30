extends Node
class_name BuildingPlacementSystem

const PLACEABLE_CRATE_SCENE := preload("res://scenes/buildings/placeable_crate.tscn")
const WORLD_SPACE_HINT_SCENE := preload("res://ui/world_space_hint.tscn")
const EDIT_TOOLBAR_SCENE := preload("res://ui/build_edit_toolbar.tscn")

signal decorating_mode_changed(active: bool)
signal decorating_mode_label_changed(mode_name: String, help_text: String)
## Emitted after a successful LOCAL placement (offline); controllers grant
## building XP from it. Connected placements are granted XP server-side.
signal object_placed(object_id: String)

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
# Admin/world-builder bypass (/adminbuild): skips costs, tools, and locks.
var admin_bypass: bool = false
# Profile id used for land-plot permission checks ("" disables them).
var builder_profile_id: String = ""
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
var _edit_toolbar: CanvasLayer
var _edit_feedback_text: String = "Click a placed object to select it."
var _edit_feedback_is_error: bool = false
# Two-step delete safety: the first Delete (key or toolbar button) arms a
# confirmation; a second Delete on the SAME selected object within the window
# actually removes it. Prevents accidental one-press deletion.
const DELETE_CONFIRM_WINDOW_MS: int = 4000
var _delete_armed_record_id: String = ""
var _delete_armed_ms: int = 0
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
	_ensure_edit_toolbar()
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
	if _interaction_mode != InteractionMode.NONE and event.is_action_pressed("cancel_action"):
		_exit_current_mode()
		_set_edit_feedback("Cancelled.", false)
		_mark_input_handled()
		return
	if _interaction_mode == InteractionMode.PLACEMENT and event.is_action_pressed("confirm_action"):
		_try_place_active_object()
		_mark_input_handled()
		return
	if _interaction_mode == InteractionMode.EDIT and event.is_action_pressed("edit_delete"):
		_remove_selected_object()
		_mark_input_handled()
		return
	if _interaction_mode == InteractionMode.EDIT and event.is_action_pressed("edit_move"):
		_start_move_selected_object()
		_mark_input_handled()
		return
	if _interaction_mode == InteractionMode.EDIT and event.is_action_pressed("edit_rotate"):
		_attempt_rotate_selected_object()
		_mark_input_handled()
		return
	if _interaction_mode == InteractionMode.MOVE and event.is_action_pressed("confirm_action"):
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
	_set_edit_feedback("Pick a clear spot nearby, then click to place.", false)
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

## Select a placeable directly (from the build menu). Enters placement mode if
## not already in it, so the ghost preview appears immediately.
func set_active_placeable(placeable_id: String) -> void:
	_sync_placeable_ids()
	if not _placeable_ids.has(placeable_id):
		return
	_active_placeable_id = placeable_id
	if _interaction_mode == InteractionMode.PLACEMENT:
		_spawn_preview()
		_emit_mode_label_changed()
	else:
		_exit_edit_or_move_mode()
		_enter_placement_mode()

func get_active_placeable_id() -> String:
	return _active_placeable_id

func has_placed_objects() -> bool:
	return not _placed_objects.is_empty()

func is_placement_active() -> bool:
	return _interaction_mode == InteractionMode.PLACEMENT

## Build-menu affordability check (tool + materials only; land permission is
## evaluated at the target tile during placement). Returns {ok, reason}.
func placeable_status(placeable_id: String) -> Dictionary:
	if admin_bypass:
		return {"ok": true, "reason": "Admin"}
	var required_tool: String = ContentRegistry.placeable_required_tool(placeable_id)
	if not required_tool.is_empty() and _builder_item_count(required_tool) < 1:
		return {"ok": false, "reason": "Needs %s" % ItemIds.display_name(required_tool)}
	var lock_reason: String = ""
	var lock: Dictionary = ProgressionRegistry.placeable_locks().get(placeable_id, {}) as Dictionary
	if not lock.is_empty():
		var progression: Dictionary
		if _is_network_client():
			progression = SkillProgression.normalized(_network_session().call("get_server_progression") as Dictionary)
		elif save_system != null:
			progression = save_system.get_player_progression()
		else:
			progression = {}
		lock_reason = ProgressionRegistry.lock_reason(lock, SkillProgression.player_level(progression), SkillProgression.skill_levels(progression))
	if not lock_reason.is_empty():
		return {"ok": false, "reason": lock_reason}
	var cost: Dictionary = BuildCosts.cost_of(placeable_id)
	for material_id in cost.keys():
		if _builder_item_count(String(material_id)) < int(cost[material_id]):
			return {"ok": false, "reason": "Needs %s" % BuildCosts.cost_text(placeable_id)}
	return {"ok": true, "reason": ""}

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
	_set_edit_feedback("Click a placed object to select it.", false)
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

func set_builder_profile(profile_id: String) -> void:
	builder_profile_id = profile_id

func set_admin_bypass(enabled: bool) -> void:
	admin_bypass = enabled
	_emit_mode_label_changed()

func clear_local_test_placements() -> int:
	if _is_network_client():
		return -1
	var removed_count: int = _placed_objects.size()
	for record in _placed_objects:
		var record_id: String = String((record as Dictionary).get("record_id", ""))
		var object_id: String = String((record as Dictionary).get("object_id", ""))
		_unregister_interactable_for_object(record_id, object_id)
	for placed_node_variant in _placed_nodes.values():
		var placed_node: Node = placed_node_variant as Node
		if placed_node != null and is_instance_valid(placed_node):
			placed_node.queue_free()
	_placed_objects.clear()
	_occupied_tiles.clear()
	_placed_nodes.clear()
	_selected_record_id = ""
	_hovered_record_id = ""
	_moving_record_id = ""
	_disarm_delete()
	_destroy_preview()
	if save_system != null:
		save_system.set_region_placed_objects(_region_id, _placed_objects)
	_interaction_mode = InteractionMode.NONE
	_set_edit_feedback("Cleared local test placements.", false)
	_emit_decorating_mode_changed()
	_emit_mode_label_changed()
	_hide_world_space_hint()
	return removed_count

## Runtime lookup instead of the autoload identifier: scripts referencing the
## autoload name directly fail to compile under `--script` (validation) where
## autoload globals are not registered. Null means "behave offline".
func _network_session() -> Node:
	return get_node_or_null("/root/NetworkSession")

func _is_network_client() -> bool:
	var session: Node = _network_session()
	return session != null and bool(session.call("is_client_connected"))

## Player-level/skill lock check against whichever progression store applies:
## the server's (connected, so preview matches authority) or the local save.
func _progression_lock_reason(object_id: String) -> String:
	var lock: Dictionary = ProgressionRegistry.placeable_locks().get(object_id, {}) as Dictionary
	if lock.is_empty():
		return ""
	var progression: Dictionary
	if _is_network_client():
		progression = SkillProgression.normalized(
			_network_session().call("get_server_progression") as Dictionary
		)
	elif save_system != null:
		progression = save_system.get_player_progression()
	else:
		return ""
	return ProgressionRegistry.lock_reason(
		lock,
		SkillProgression.player_level(progression),
		SkillProgression.skill_levels(progression)
	)

func _get_active_place_result(tile: Vector2i) -> Dictionary:
	var placeable_data: PlaceableObjectData = _get_active_placeable_data()
	var result: Dictionary = map.get_place_footprint_result(tile, placeable_data.footprint, _get_occupied_tiles())
	if not bool(result.get("valid", false)):
		return result
	if admin_bypass:
		return result  # world-builder mode: skip locks, land, tools, costs
	# Land/plot permission (neighborhood plots need ownership; commons and
	# Rowan's training land are open; town is off-grid and unbuildable anyway).
	if inventory_system != null and not builder_profile_id.is_empty():
		var land_result: Dictionary = LandClaimSystem.can_build_at(
			tile, builder_profile_id, _current_plots_state(), false
		)
		if not bool(land_result.get("allowed", true)):
			return {"valid": false, "reason": String(land_result.get("reason", "No build permission"))}
	# Progression locks (player level / skill level) on the demonstration set.
	var lock_reason: String = _progression_lock_reason(_active_placeable_id)
	if not lock_reason.is_empty():
		return {"valid": false, "reason": lock_reason}
	# Required tool (hammer for builds, shovel for terrain).
	var required_tool: String = ContentRegistry.placeable_required_tool(_active_placeable_id)
	if inventory_system != null and not required_tool.is_empty():
		if _builder_item_count(required_tool) < 1:
			return {"valid": false, "reason": "Requires %s" % ItemIds.display_name(required_tool)}
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

## Item count from whichever store rules right now (server pouch / inventory).
func _builder_item_count(item_id: String) -> int:
	if _is_network_client():
		return int((_network_session().call("get_server_materials") as Dictionary).get(item_id, 0))
	if inventory_system != null:
		return inventory_system.get_quantity(item_id)
	return 0

## Plot ownership state from whichever store rules right now.
func _current_plots_state() -> Dictionary:
	if _is_network_client():
		return _network_session().call("get_server_plots") as Dictionary
	if save_system != null:
		var raw: Variant = save_system.get_overworld_flag("land_plots", {})
		if typeof(raw) == TYPE_DICTIONARY:
			return raw as Dictionary
	return {}

func _try_place_active_object() -> void:
	var placement_result: Dictionary = _get_active_place_result(_current_tile)
	if not bool(placement_result.get("valid", false)):
		var friendly_reason: String = _friendly_place_reason(String(placement_result.get("reason", "")))
		_update_preview_state()
		_set_edit_feedback(friendly_reason, true)
		_refresh_edit_toolbar()
		return

	# Connected to a server: placement is server-authoritative. Send a request;
	# the committed object arrives back via the world snapshot/broadcast path and
	# is spawned as a network object (not part of the local save).
	if _is_network_client():
		_network_session().call("request_place", _active_placeable_id, _current_tile)
		_update_preview_state()
		return

	# Offline: spend materials (when an inventory is wired), then place locally.
	if inventory_system != null and not admin_bypass:
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
	object_placed.emit(_active_placeable_id)
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
	# Curated LimeZu opening: build pieces (crates/decks/etc.) still resolve their art
	# through ObjectArtRegistry, which has no LimeZu tier, so save-restored objects render
	# with generated/legacy planks that clash with the LimeZu world (the "leftover boards"
	# at the map edge). Hide the visual of *save-restored* objects only in LimeZu live mode
	# so the opening reads as pure LimeZu; record/collision/interaction/occupancy are kept,
	# and in-session placements (should_append) stay visible so place-and-see still works.
	if not should_append and LiveVisualPolicy.live_limezu_slice() and not _placeable_has_limezu_art(object_id):
		placed_object.visible = false
	_apply_placed_object_collision(placed_object, object_id, tile, placeable_data.footprint)
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

## True when a placeable maps to a reviewed LimeZu asset whose sprite resolves — those placed
## objects render LimeZu art (PlaceableCrate._apply_limezu_art), so save-restore keeps them
## visible instead of hiding them to avoid clashing legacy planks.
func _placeable_has_limezu_art(object_id: String) -> bool:
	var asset_id: String = AssetWorldMetadata.asset_id_for_placeable(object_id)
	return not asset_id.is_empty() and LimeZuArtRegistry.has_asset(asset_id)

## Asset-aware collision for a placed object: prefer AssetWorldMetadata shapes, retiring the
## generic placement proxy when metadata governs the object (so curated + placed objects use
## the same collision model). Objects with no mapped asset keep the conservative proxy.
## Also tags the node with debug metadata the F7 overlay reads. Move just works (shapes are
## children of the body); delete/clear free the body and its shapes together.
func _apply_placed_object_collision(placed_object: PlaceableCrate, object_id: String, tile: Vector2i, footprint: Vector2i) -> void:
	if placed_object == null or map == null:
		return
	var asset_id: String = AssetWorldMetadata.asset_id_for_placeable(object_id)
	var tile_size := Vector2i(map.grid_to_world(Vector2i.ONE) - map.grid_to_world(Vector2i.ZERO))
	var status: String = PlacedObjectCollision.apply_to_placed(placed_object, asset_id, footprint, tile_size)
	if status != "proxy" and placed_object.collision_shape != null:
		# Metadata is authoritative -> retire the generic proxy (avoids double-collision;
		# "metadata_none" intentionally leaves decor like signs/crates non-blocking).
		placed_object.collision_shape.disabled = true
	placed_object.set_meta("debug_collision_kind", status)
	placed_object.set_meta("debug_collision_asset", asset_id)
	placed_object.set_meta("debug_footprint_tiles", map.get_footprint_tiles(tile, footprint))

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
		if not _selected_record_id.is_empty():
			_set_edit_feedback("Selection cleared.", false)
		else:
			_set_edit_feedback("Nothing to select here. Click a placed object to edit.", true)
		_clear_selection()
		_refresh_edit_toolbar()
		return

	if _selected_record_id == _hovered_record_id:
		_set_edit_feedback("Selected %s. Use Move or Delete below." % _record_summary(_selected_record_id), false)
		_refresh_edit_toolbar()
		return

	_set_record_highlight(_selected_record_id, false)
	_selected_record_id = _hovered_record_id
	_set_record_highlight(_selected_record_id, true)
	_set_edit_feedback("Selected %s." % _record_summary(_selected_record_id), false)
	_refresh_edit_toolbar()

func _start_move_selected_object() -> void:
	if _selected_record_id.is_empty():
		_set_edit_feedback("Select a placed object before moving it.", true)
		_refresh_edit_toolbar()
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
	_set_edit_feedback("Click a new spot to move %s here." % _record_summary(_moving_record_id), false)
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
			var denial_reason: String = String(move_result.get("reason", "Blocked"))
			_show_world_space_hint(false, denial_reason, moving_node.position)
			_set_edit_feedback(denial_reason, true)
			_refresh_edit_toolbar()
		return

	var moving_record: Dictionary = _find_record_by_id(_moving_record_id)
	if moving_record.is_empty():
		return
	var moved_summary: String = _record_summary(_moving_record_id)

	_update_record_tile(_moving_record_id, _current_tile)

	var moving_node: PlaceableCrate = _get_record_node(_moving_record_id)
	if moving_node != null:
		moving_node.set_tile_position(_current_tile, map.grid_to_world(_current_tile))
		moving_node.set_preview_mode(false)
		moving_node.set_placed_visual()
		moving_node.set_selected(true)
		# The metadata collision shapes are children of the body, so they moved with it.
		# set_placed_visual() re-enabled the proxy, so re-retire it for metadata objects and
		# refresh the debug footprint to the new tile.
		var moved_object_id: String = String(moving_record.get("object_id", ""))
		if object_registry != null and object_registry.has_placeable(moved_object_id):
			var moved_fp: Vector2i = object_registry.get_placeable_data(moved_object_id).footprint
			if String(moving_node.get_meta("debug_collision_kind", "proxy")) != "proxy" and moving_node.collision_shape != null:
				moving_node.collision_shape.disabled = true
			moving_node.set_meta("debug_footprint_tiles", map.get_footprint_tiles(_current_tile, moved_fp))

	_rebuild_occupied_tiles()
	save_system.set_region_placed_objects(_region_id, _placed_objects)
	_interaction_mode = InteractionMode.EDIT
	_move_origin_tile = Vector2i.ZERO
	_moving_record_id = ""
	_current_tile = map.world_to_grid(map.get_global_mouse_position())
	_update_hovered_selection()
	_set_edit_feedback("Moved %s." % moved_summary, false)
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
	_set_edit_feedback("Move cancelled.", false)
	_emit_decorating_mode_changed()
	_emit_mode_label_changed()
	_hide_world_space_hint()

func _remove_selected_object() -> void:
	if _selected_record_id.is_empty():
		_disarm_delete()
		_set_edit_feedback("Select a placed object before deleting it.", true)
		_refresh_edit_toolbar()
		return

	# First press arms; a second confirming press (same object, within the window)
	# actually deletes. So a stray Delete never removes a piece outright.
	var now_ms: int = Time.get_ticks_msec()
	var armed: bool = _delete_armed_record_id == _selected_record_id and (now_ms - _delete_armed_ms) <= DELETE_CONFIRM_WINDOW_MS
	if not armed:
		_delete_armed_record_id = _selected_record_id
		_delete_armed_ms = now_ms
		_set_edit_feedback("Press Delete again to remove %s." % _record_summary(_selected_record_id), true)
		_refresh_edit_toolbar()
		return
	_disarm_delete()

	var index_to_remove: int = -1
	for index in range(_placed_objects.size()):
		if String(_placed_objects[index].get("record_id", "")) == _selected_record_id:
			index_to_remove = index
			break

	if index_to_remove == -1:
		_set_edit_feedback("That object could not be found anymore.", true)
		_refresh_edit_toolbar()
		return

	var placed_node: PlaceableCrate = _placed_nodes.get(_selected_record_id) as PlaceableCrate
	var removed_object_id: String = String(_placed_objects[index_to_remove].get("object_id", ""))
	var removed_summary: String = _record_summary(_selected_record_id)
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
	_set_edit_feedback("Deleted %s." % removed_summary, false)
	_refresh_edit_toolbar()

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

func _disarm_delete() -> void:
	_delete_armed_record_id = ""
	_delete_armed_ms = 0

func _clear_selection() -> void:
	_disarm_delete()
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
				"Build Mode",
				"%s%s. Tab to cycle pieces. Click to place. Esc to cancel." % [placeable_data.display_name, cost_suffix]
			)
		InteractionMode.EDIT:
			decorating_mode_label_changed.emit(
				"Edit Mode",
				"Click an object to edit. M to move. Del twice to delete. Esc to cancel."
			)
		InteractionMode.MOVE:
			decorating_mode_label_changed.emit(
				"Move Mode",
				"Click a new spot to move the object here. Esc to cancel."
			)
		_:
			decorating_mode_label_changed.emit(
				"Explore",
				"WASD to move. B to build. E to edit. Esc for menu."
			)
	_refresh_edit_toolbar()

func _ensure_world_space_hint() -> void:
	if _world_space_hint != null:
		return

	_world_space_hint = WORLD_SPACE_HINT_SCENE.instantiate() as WorldSpaceHint
	gameplay_layer.add_child(_world_space_hint)

func _ensure_edit_toolbar() -> void:
	if _edit_toolbar != null:
		return
	_edit_toolbar = EDIT_TOOLBAR_SCENE.instantiate() as CanvasLayer
	add_child(_edit_toolbar)
	_edit_toolbar.connect("select_requested", _toolbar_select_mode)
	_edit_toolbar.connect("move_requested", _toolbar_move_selected_object)
	_edit_toolbar.connect("rotate_requested", _toolbar_rotate_selected_object)
	_edit_toolbar.connect("delete_requested", _toolbar_delete_selected_object)
	_edit_toolbar.connect("cancel_requested", _toolbar_cancel)
	_refresh_edit_toolbar()

func _toolbar_select_mode() -> void:
	if _interaction_mode == InteractionMode.MOVE:
		_cancel_move_selected_object()
		return
	if _interaction_mode != InteractionMode.EDIT:
		_exit_placement_mode()
		_enter_edit_mode()
		return
	_set_edit_feedback("Click a placed object to select it.", false)
	_refresh_edit_toolbar()

func _toolbar_move_selected_object() -> void:
	_start_move_selected_object()

func _toolbar_rotate_selected_object() -> void:
	_attempt_rotate_selected_object()

func _toolbar_delete_selected_object() -> void:
	_remove_selected_object()

func _toolbar_cancel() -> void:
	if _interaction_mode == InteractionMode.NONE:
		return
	_exit_current_mode()
	_set_edit_feedback("Cancelled.", false)
	_refresh_edit_toolbar()

func _attempt_rotate_selected_object() -> void:
	if _selected_record_id.is_empty():
		_set_edit_feedback("Select a placed object before trying to rotate it.", true)
		_refresh_edit_toolbar()
		return
	_set_edit_feedback("Rotation is not wired for placed pieces yet.", true)
	_refresh_edit_toolbar()

func _record_summary(record_id: String) -> String:
	var record: Dictionary = _find_record_by_id(record_id)
	if record.is_empty():
		return "object"
	var object_id: String = String(record.get("object_id", ""))
	var display_name: String = String((ContentRegistry.placeables().get(object_id, {}) as Dictionary).get("display_name", object_id))
	return "%s @ (%d,%d)" % [
		display_name,
		int(record.get("tile_x", 0)),
		int(record.get("tile_y", 0)),
	]

func _refresh_edit_toolbar() -> void:
	if _edit_toolbar == null:
		return
	var toolbar_active: bool = _interaction_mode == InteractionMode.EDIT or _interaction_mode == InteractionMode.MOVE
	_edit_toolbar.call("set_active", toolbar_active)
	if not toolbar_active:
		return
	var selected_summary: String = "No placed object selected yet."
	if not _selected_record_id.is_empty():
		selected_summary = "Selected: %s" % _record_summary(_selected_record_id)
	elif not _hovered_record_id.is_empty():
		selected_summary = "Hovering: %s" % _record_summary(_hovered_record_id)
	var controls_text: String = ""
	if _interaction_mode == InteractionMode.MOVE:
		controls_text = "Mouse: click a tile to confirm. Keyboard/controller: confirm places, cancel reverts."
	else:
		controls_text = "Mouse: click an object to select. M moves; Delete twice (or the Delete button twice) confirms removal."
	_edit_toolbar.call("set_mode_text", "Move Mode" if _interaction_mode == InteractionMode.MOVE else "Edit Mode")
	_edit_toolbar.call("set_selection_text", selected_summary)
	_edit_toolbar.call("set_feedback_text", _edit_feedback_text, _edit_feedback_is_error)
	_edit_toolbar.call("set_controls_text", controls_text)
	_edit_toolbar.call(
		"set_button_states",
		true,
		_interaction_mode == InteractionMode.EDIT and not _selected_record_id.is_empty(),
		_interaction_mode == InteractionMode.EDIT and not _selected_record_id.is_empty(),
		_interaction_mode == InteractionMode.EDIT and not _selected_record_id.is_empty(),
		_interaction_mode != InteractionMode.NONE
	)

func _set_edit_feedback(text: String, is_error: bool) -> void:
	_edit_feedback_text = text
	_edit_feedback_is_error = is_error

func _friendly_place_reason(reason_text: String) -> String:
	var reason: String = reason_text.strip_edges()
	match reason:
		"":
			return "Pick a clear spot nearby."
		"Out of bounds":
			return "Pick a clear spot inside your claimed plot."
		"Reserved spawn":
			return "Keep the arrival spot clear. Pick a nearby tile."
		"Occupied":
			return "That spot is occupied. Pick a clear spot nearby."
		"Blocked", "Blocked by cottage", "Blocked by tree", "Blocked by fence":
			return "%s. Pick a clear spot nearby." % reason
		_:
			if reason.begins_with("Needs "):
				return "%s. Gather more materials or check inventory." % reason
			if reason.begins_with("Requires "):
				return "%s. Select or craft the right tool first." % reason
			if reason.begins_with("Claim "):
				return "Claim a plot sign before building here."
			if reason.find("permission") >= 0 or reason.find("owner") >= 0 or reason.find("plot") >= 0:
				return "%s. Place this inside your claimed plot." % reason
			return reason

func _show_world_space_hint(is_valid: bool, reason_text: String, world_position: Vector2) -> void:
	if _world_space_hint == null:
		return

	var text: String = "Click to place" if is_valid else _friendly_place_reason(reason_text)
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

	if object_id == ContentIds.PLACEABLE_MAILBOX:
		interactable_system.register_interactable(
			record_id,
			placed_object,
			ContentIds.INTERACTION_MAILBOX,
			"Press F to check your mailbox"
		)
		return

	if object_id == ContentIds.PLACEABLE_WORKBENCH or object_id == ContentIds.PLACEABLE_GARDEN_TABLE:
		interactable_system.register_interactable(
			record_id,
			placed_object,
			ContentIds.INTERACTION_CRAFTING_STATION,
			"Press F to craft"
		)
		return

	# Prefab structures with interiors get a door (enter via the room view).
	if PrefabInteriors.has_interior(object_id):
		interactable_system.register_interactable(
			record_id,
			placed_object,
			ContentIds.INTERACTION_PREFAB_DOOR,
			"Press F to enter %s" % PrefabInteriors.title_of(object_id)
		)
		return

	# Contract-driven placeholder interaction (e.g. a placed crate -> "The crate is empty.").
	# Only objects whose AssetWorldMetadata contract has a self-contained toast response are
	# registered, so a placed object never shows a prompt without a backing action. The
	# response is delivered by HomesteadController._on_interaction_requested's fallback.
	if _placed_contract_response_for_object(object_id) != "":
		var contract_asset: String = AssetWorldMetadata.asset_id_for_placeable(object_id)
		placed_object.set_meta("contract_asset_id", contract_asset)
		placed_object.set_meta("interaction_point_offset", AssetWorldMetadata.interaction_point_offset(contract_asset))
		interactable_system.register_interactable(
			record_id, placed_object, ContentIds.INTERACTION_GENERIC,
			AssetWorldMetadata.interaction_prompt(contract_asset)
		)

func _unregister_interactable_for_object(record_id: String, object_id: String) -> void:
	if interactable_system == null:
		return

	if (
		object_id == ContentIds.PLACEABLE_MAILBOX
		or object_id == ContentIds.PLACEABLE_WORKBENCH
		or object_id == ContentIds.PLACEABLE_GARDEN_TABLE
		or PrefabInteriors.has_interior(object_id)
		or _placed_contract_response_for_object(object_id) != ""
	):
		interactable_system.unregister_interactable(record_id)

## Self-contained toast response for a placeable's contract, or "" when it has none (so the
## caller knows whether to register a prompt). Mailbox/workbench are handled by their own
## explicit branches above; this covers contract props like the crate.
func _placed_contract_response_for_object(object_id: String) -> String:
	if object_id == ContentIds.PLACEABLE_MAILBOX \
			or object_id == ContentIds.PLACEABLE_WORKBENCH \
			or object_id == ContentIds.PLACEABLE_GARDEN_TABLE:
		return ""
	var asset_id: String = AssetWorldMetadata.asset_id_for_placeable(object_id)
	if asset_id.is_empty() or not AssetWorldMetadata.has_toast_interaction(asset_id):
		return ""
	return AssetWorldMetadata.interaction_response(asset_id)

## Public: contract response for a currently-placed record (used by the interaction dispatch
## fallback when no bound world-interactable callback handled the press).
func placed_contract_response(record_id: String) -> String:
	var node: PlaceableCrate = _placed_nodes.get(record_id, null) as PlaceableCrate
	if node == null:
		return ""
	var asset_id: String = String(node.get_meta("contract_asset_id", ""))
	return AssetWorldMetadata.interaction_response(asset_id) if not asset_id.is_empty() else ""

## True when a placed object with this content id sits within `radius` world
## units of `world_pos`. Used for "requires a station nearby" crafting checks.
func has_placed_object_near(object_id: String, world_pos: Vector2, radius: float) -> bool:
	for record in _placed_objects:
		if String(record.get("object_id", "")) != object_id:
			continue
		var tile: Vector2i = Vector2i(int(record.get("tile_x", 0)), int(record.get("tile_y", 0)))
		if map.grid_to_world(tile).distance_to(world_pos) <= radius:
			return true
	return false

## Read-only minimap feed for currently visible player-placed objects. Save-restored
## LimeZu-hidden clutter stays hidden here too, so the minimap does not resurrect it.
func minimap_features() -> Array:
	var features: Array = []
	if map == null or not AssetWorldMetadata.minimap_visible("placed_object"):
		return features
	for record in _placed_objects:
		var record_id: String = String((record as Dictionary).get("record_id", ""))
		var object_id: String = String((record as Dictionary).get("object_id", ""))
		var placed_node: Node = _placed_nodes.get(record_id) as Node
		if placed_node == null or not is_instance_valid(placed_node) or not placed_node.visible:
			continue
		var tile := Vector2i(int((record as Dictionary).get("tile_x", 0)), int((record as Dictionary).get("tile_y", 0)))
		features.append({
			"asset_id": "placed_object",
			"content_id": object_id,
			"kind": AssetWorldMetadata.minimap_kind("placed_object"),
			"color": AssetWorldMetadata.minimap_color("placed_object"),
			"priority": AssetWorldMetadata.minimap_priority("placed_object"),
			"label": String((ContentRegistry.placeables().get(object_id, {}) as Dictionary).get("display_name", object_id)),
			"pos": map.grid_to_world(tile),
		})
	return features

## Content id of a placed record (for station interactions keyed by record id).
func get_placed_object_id(record_id: String) -> String:
	return String(_find_record_by_id(record_id).get("object_id", ""))

func _apply_mailbox_state_to_node(placed_object: PlaceableCrate) -> void:
	if placed_object == null:
		return

	if placed_object is PlaceableMailbox:
		(placed_object as PlaceableMailbox).set_has_new_mail(_mailbox_has_new_mail)

func _mark_input_handled() -> void:
	var viewport: Viewport = get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()
