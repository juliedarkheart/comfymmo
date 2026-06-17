extends Node2D
class_name ParcelPreview

## Live preview for the visual parcel tool. While the admin is staking out a new
## plot (two corners), this draws the pending rectangle as a biome-tinted iso
## diamond with an outline + corner ticks, so they can SEE the size before
## confirming — no memorizing coordinates. Purely visual; the controller owns the
## actual create. Drawn above props in the world layer.

var _map: Node = null
var _rect: Rect2i = Rect2i()
var _biome: String = "meadow"
var _active: bool = false
var _font: Font = ThemeDB.fallback_font

func setup(map: Node) -> void:
	_map = map
	z_index = 160
	visible = false

## Show the rectangle spanning two (inclusive) corner tiles.
func set_corners(corner_a: Vector2i, corner_b: Vector2i, biome: String) -> void:
	var min_x: int = mini(corner_a.x, corner_b.x)
	var min_y: int = mini(corner_a.y, corner_b.y)
	var w: int = absi(corner_b.x - corner_a.x) + 1
	var h: int = absi(corner_b.y - corner_a.y) + 1
	_rect = Rect2i(min_x, min_y, w, h)
	_biome = biome
	_active = true
	visible = true
	queue_redraw()

func clear() -> void:
	_active = false
	visible = false
	queue_redraw()

## Half a tile in world px when the map is in a top-down projection (so previews
## cover whole cells); Vector2.ZERO in legacy iso (keep the centers diamond).
func _half_tile() -> Vector2:
	if _map != null and _map.has_method("visual_projection_mode"):
		var mode: String = String(_map.call("visual_projection_mode"))
		if WorldProjection.is_sprout_compatible(mode):
			return Vector2(WorldProjection.tile_size(mode)) * 0.5
	return Vector2.ZERO

func pending_rect() -> Rect2i:
	return _rect

func _draw() -> void:
	if not _active or _map == null:
		return
	var top: Vector2 = _map.call("grid_to_world", _rect.position)
	var right: Vector2 = _map.call("grid_to_world", Vector2i(_rect.end.x - 1, _rect.position.y))
	var bottom: Vector2 = _map.call("grid_to_world", Vector2i(_rect.end.x - 1, _rect.end.y - 1))
	var left: Vector2 = _map.call("grid_to_world", Vector2i(_rect.position.x, _rect.end.y - 1))
	# grid_to_world returns tile CENTERS. In top-down mode push the corners out by
	# half a tile so the preview covers the full visible cells instead of stopping
	# a half-tile short on every side. (Legacy iso keeps the centers-diamond look.)
	var half: Vector2 = _half_tile()
	top += Vector2(-half.x, -half.y)
	right += Vector2(half.x, -half.y)
	bottom += Vector2(half.x, half.y)
	left += Vector2(-half.x, half.y)
	var base: Color = BiomeRegistry.ground_color(_biome)
	var points := PackedVector2Array([top, right, bottom, left])
	draw_colored_polygon(points, Color(base.r, base.g, base.b, 0.30))
	var loop := PackedVector2Array([top, right, bottom, left, top])
	draw_polyline(loop, Color(1, 1, 1, 0.9), 3.0)
	for corner in [top, right, bottom, left]:
		draw_circle(corner, 4.0, Color(1, 0.95, 0.6, 0.95))
	var center: Vector2 = (top + bottom) * 0.5
	draw_string(_font, center + Vector2(-50, -2), "%dx%d %s" % [_rect.size.x, _rect.size.y, _biome],
		HORIZONTAL_ALIGNMENT_CENTER, 100, 13, Color(1, 1, 0.95, 0.98))
