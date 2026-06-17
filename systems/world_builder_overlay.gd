extends Node2D
class_name WorldBuilderOverlay

## In-world admin / world-builder overlay. Hidden by default; an admin toggle
## (F7 panel, /overlay, or the plot-debug button) shows it. While on it draws —
## directly in world space, above the props — every land plot's footprint as a
## biome-tinted translucent diamond with an outline, its name + size, corner
## ticks, the original homestead "training core" grid, and any authored world
## markers. Purely visual: no collision, never saved. It reads live from
## LandRegistry, so editor-made plots appear the instant they're created.

var _map: Node = null
var _markers_provider: Callable = Callable()
var _core_size: Vector2i = Vector2i.ZERO
var _font: Font = ThemeDB.fallback_font

func setup(map: Node, markers_provider: Callable, core_size: Vector2i) -> void:
	_map = map
	_markers_provider = markers_provider
	_core_size = core_size
	z_index = 150
	visible = false
	queue_redraw()

## Toggle visibility; returns the new on/off state for the caller's toast.
func toggle() -> bool:
	visible = not visible
	queue_redraw()
	return visible

## Re-draw if currently visible (called after a plot/marker change).
func refresh() -> void:
	if visible:
		queue_redraw()

func _tile_to_world(tile: Vector2i) -> Vector2:
	return _map.call("grid_to_world", tile)

## Half a tile in world px for top-down projections (so footprints cover whole
## cells instead of stopping at tile centers); ZERO in legacy iso.
func _half_tile() -> Vector2:
	if _map != null and _map.has_method("visual_projection_mode"):
		var mode: String = String(_map.call("visual_projection_mode"))
		if WorldProjection.is_sprout_compatible(mode):
			return Vector2(WorldProjection.tile_size(mode)) * 0.5
	return Vector2.ZERO

## Expand a [TL, TR, BR, BL] corner set outward by half a tile (top-down only).
func _expand(corners: Array, half: Vector2) -> Array:
	if half == Vector2.ZERO:
		return corners
	return [
		corners[0] + Vector2(-half.x, -half.y),
		corners[1] + Vector2(half.x, -half.y),
		corners[2] + Vector2(half.x, half.y),
		corners[3] + Vector2(-half.x, half.y),
	]

func _draw() -> void:
	if _map == null or not visible:
		return
	var half: Vector2 = _half_tile()
	# Homestead training core grid (the original 0..W x 0..H buildable square).
	if _core_size.x > 0 and _core_size.y > 0:
		var w: int = _core_size.x
		var h: int = _core_size.y
		_draw_diamond(
			_expand([
				_tile_to_world(Vector2i(0, 0)), _tile_to_world(Vector2i(w - 1, 0)),
				_tile_to_world(Vector2i(w - 1, h - 1)), _tile_to_world(Vector2i(0, h - 1)),
			], half),
			Color(0.6, 0.8, 1.0, 0.08), Color(0.7, 0.85, 1.0, 0.45), 2.0
		)
		draw_string(_font, _tile_to_world(Vector2i(0, 0)) + Vector2(-36, -10),
			"Training Core", HORIZONTAL_ALIGNMENT_CENTER, 72, 12, Color(0.82, 0.9, 1.0, 0.9))
	# Every plot footprint (static + runtime), diamond-projected from its rect.
	for plot_variant in LandRegistry.definitions().values():
		var plot: Dictionary = plot_variant as Dictionary
		var rect_variant: Variant = plot.get("rect", null)
		if not (rect_variant is Rect2i):
			continue
		var rect: Rect2i = rect_variant as Rect2i
		var top: Vector2 = _tile_to_world(rect.position)
		var right: Vector2 = _tile_to_world(Vector2i(rect.end.x - 1, rect.position.y))
		var bottom: Vector2 = _tile_to_world(Vector2i(rect.end.x - 1, rect.end.y - 1))
		var left: Vector2 = _tile_to_world(Vector2i(rect.position.x, rect.end.y - 1))
		var base: Color = LandRegistry.biome_color(String(plot.get("biome", "meadow")))
		var fill := Color(base.r, base.g, base.b, 0.22)
		var line: Color = Color(base.r, base.g, base.b, 0.95).lightened(0.2)
		var plot_corners: Array = _expand([top, right, bottom, left], half)
		_draw_diamond(plot_corners, fill, line, 2.5)
		for corner in plot_corners:
			draw_circle(corner as Vector2, 3.0, Color(1, 1, 1, 0.85))
		var center: Vector2 = (top + bottom) * 0.5
		draw_string(_font, center + Vector2(-48, -2), String(plot.get("display_name", "plot")),
			HORIZONTAL_ALIGNMENT_CENTER, 96, 12, Color(1, 1, 0.95, 0.95))
		var tag: String = "%dx%d" % [rect.size.x, rect.size.y]
		if LandRegistry.is_runtime_plot(String(plot.get("plot_id", ""))):
			tag += " · editor"
		elif not bool(plot.get("claimable", false)):
			tag += " · fixed"
		draw_string(_font, center + Vector2(-48, 14), tag,
			HORIZONTAL_ALIGNMENT_CENTER, 96, 10, Color(0.95, 0.95, 0.8, 0.85))
	# Authored markers (small crosses, colored by type).
	if _markers_provider.is_valid():
		for marker_variant in _markers_provider.call():
			var marker: Dictionary = marker_variant as Dictionary
			var pos: Vector2 = _tile_to_world(marker.get("tile", Vector2i.ZERO) as Vector2i)
			var col: Color = marker.get("color", Color.WHITE)
			draw_line(pos + Vector2(-6, 0), pos + Vector2(6, 0), col, 2.0)
			draw_line(pos + Vector2(0, -6), pos + Vector2(0, 6), col, 2.0)

func _draw_diamond(points: Array, fill: Color, line: Color, width: float) -> void:
	var poly := PackedVector2Array(points)
	draw_colored_polygon(poly, fill)
	var loop := PackedVector2Array(points)
	loop.append(points[0])
	draw_polyline(loop, line, width)
