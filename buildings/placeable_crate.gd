extends StaticBody2D
class_name PlaceableCrate

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var tile: Vector2i = Vector2i.ZERO
var record_id: String = ""
var _is_preview: bool = false
var _is_preview_valid: bool = true
var _is_selected: bool = false
var _selection_fill: Polygon2D = null
var _selection_outline: Line2D = null

func _ready() -> void:
	_ensure_selection_highlight()
	_apply_registry_art()
	_apply_visual_state()

func set_tile_position(grid_tile: Vector2i, world_position: Vector2) -> void:
	tile = grid_tile
	position = world_position

func set_record_id(value: String) -> void:
	record_id = value

func set_preview_mode(is_preview: bool) -> void:
	_is_preview = is_preview
	collision_shape.disabled = is_preview
	_apply_visual_state()

func set_preview_valid(is_valid: bool) -> void:
	_is_preview_valid = is_valid
	_apply_visual_state()

func set_selected(is_selected: bool) -> void:
	_is_selected = is_selected
	_apply_visual_state()

func set_placed_visual() -> void:
	_is_preview = false
	_is_selected = false
	collision_shape.disabled = false
	_apply_visual_state()

func _ensure_selection_highlight() -> void:
	if _selection_fill != null and _selection_outline != null:
		return
	_selection_fill = Polygon2D.new()
	_selection_fill.name = "SelectionFill"
	_selection_fill.polygon = WorldProjection.tile_polygon(WorldProjection.DEFAULT_MODE, 2.0)
	_selection_fill.color = Color(1.0, 0.9, 0.45, 0.24)
	_selection_fill.visible = false
	_selection_fill.z_index = -1
	add_child(_selection_fill)
	_selection_outline = Line2D.new()
	_selection_outline.name = "SelectionOutline"
	_selection_outline.width = 2.0
	_selection_outline.default_color = Color(1.0, 0.95, 0.62, 0.95)
	_selection_outline.closed = true
	_selection_outline.visible = false
	_selection_outline.z_index = -1
	_selection_outline.points = WorldProjection.tile_polygon(WorldProjection.DEFAULT_MODE, 2.0)
	add_child(_selection_outline)

func _art_object_id() -> String:
	return ContentIds.PLACEABLE_CRATE

func _apply_registry_art() -> void:
	var art_id: String = _art_object_id()
	if art_id.is_empty() or get_node_or_null("RegistryArtSprite") != null:
		return
	if not ObjectArtRegistry.has_art_id(art_id):
		return
	var visual: Dictionary = ObjectArtRegistry.visual_for(art_id)
	set_meta("debug_visual_asset_id", art_id)
	set_meta("debug_visual_fallback", bool(visual.get("fallback", false)))
	if ObjectArtRegistry.apply_sprite(self, art_id):
		_hide_prototype_polygons()

func _hide_prototype_polygons() -> void:
	for child in get_children():
		var child_node: Node = child as Node
		if child_node == null:
			continue
		if child_node.name == "RegistryArtSprite" or String(child_node.name).begins_with("Selection"):
			continue
		if _keeps_polygon_with_registry_art(String(child_node.name)):
			continue
		if child_node is Polygon2D:
			(child_node as Polygon2D).visible = false

func _keeps_polygon_with_registry_art(_node_name: String) -> bool:
	return false

func _apply_visual_state() -> void:
	_ensure_selection_highlight()
	if _selection_fill != null:
		_selection_fill.visible = _is_selected and not _is_preview
	if _selection_outline != null:
		_selection_outline.visible = _is_selected and not _is_preview
	if _is_preview:
		if _is_preview_valid:
			modulate = Color(0.6, 1.0, 0.7, 0.8)
			return

		modulate = Color(1.0, 0.45, 0.45, 0.8)
		return

	if _is_selected:
		modulate = Color(1.0, 0.95, 0.55, 1.0)
		return

	modulate = Color(1.0, 1.0, 1.0, 1.0)
