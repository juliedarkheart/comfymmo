extends StaticBody2D
class_name PlaceableCrate

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var tile: Vector2i = Vector2i.ZERO
var record_id: String = ""
var _is_preview: bool = false
var _is_preview_valid: bool = true
var _is_selected: bool = false

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

func _apply_visual_state() -> void:
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
