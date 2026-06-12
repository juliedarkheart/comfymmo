extends RefCounted
class_name TerrainShapes

## Lightweight, node-efficient terrain primitives shared by the region maps. Each
## helper builds a single large polygon (a curved ribbon for roads/streams, or a
## flattened disc for plazas/treelines/rocks) so topology cues cost very few nodes.

## Builds a filled ribbon polygon following a centerline, with a half-width that
## lerps from start to end so roads/trails/streams can taper, curve, and narrow.
static func ribbon(points: PackedVector2Array, half_width_start: float, half_width_end: float) -> PackedVector2Array:
	var n: int = points.size()
	if n < 2:
		return PackedVector2Array()

	var left: PackedVector2Array = PackedVector2Array()
	var right: PackedVector2Array = PackedVector2Array()
	for i in range(n):
		var dir: Vector2
		if i == 0:
			dir = points[1] - points[0]
		elif i == n - 1:
			dir = points[n - 1] - points[n - 2]
		else:
			dir = points[i + 1] - points[i - 1]
		if dir.length() < 0.001:
			dir = Vector2.RIGHT
		dir = dir.normalized()
		var perp: Vector2 = Vector2(-dir.y, dir.x)
		var hw: float = lerpf(half_width_start, half_width_end, float(i) / float(n - 1))
		left.append(points[i] + perp * hw)
		right.append(points[i] - perp * hw)

	var poly: PackedVector2Array = PackedVector2Array()
	for p in left:
		poly.append(p)
	for i in range(right.size() - 1, -1, -1):
		poly.append(right[i])
	return poly

## A flattened (iso-friendly) regular polygon, useful for plaza discs, distant
## treeline blobs, ponds, and rounded rock masses.
static func disc(center: Vector2, radius: float, sides: int, y_scale: float = 0.6) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(sides):
		var a: float = TAU * float(i) / float(sides)
		pts.append(center + Vector2(cos(a) * radius, sin(a) * radius * y_scale))
	return pts

static func add_polygon(parent: Node2D, polygon: PackedVector2Array, color: Color) -> Polygon2D:
	if polygon.size() < 3:
		return null
	var node: Polygon2D = Polygon2D.new()
	node.polygon = polygon
	node.color = color
	parent.add_child(node)
	return node

static func add_ribbon(parent: Node2D, points: PackedVector2Array, half_width_start: float, half_width_end: float, color: Color) -> Polygon2D:
	return add_polygon(parent, ribbon(points, half_width_start, half_width_end), color)

static func add_disc(parent: Node2D, center: Vector2, radius: float, sides: int, color: Color, y_scale: float = 0.6) -> Polygon2D:
	return add_polygon(parent, disc(center, radius, sides, y_scale), color)

## Smooth ellipse polygon for organic, toy-like prop shapes (canopies, rocks,
## mushroom caps, character parts). Higher segment count than disc() so curves
## read as round rather than faceted at gameplay zoom.
static func ellipse(center: Vector2, rx: float, ry: float, segments: int = 16) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(segments):
		var a: float = TAU * float(i) / float(segments)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

static func add_ellipse(parent: Node2D, center: Vector2, rx: float, ry: float, color: Color, segments: int = 16) -> Polygon2D:
	return add_polygon(parent, ellipse(center, rx, ry, segments), color)

## Top half of an ellipse closed along its base — cute domed roofs and caps.
static func dome(center: Vector2, rx: float, ry: float, segments: int = 12) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(segments + 1):
		var a: float = PI + PI * float(i) / float(segments)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

static func add_dome(parent: Node2D, center: Vector2, rx: float, ry: float, color: Color, segments: int = 12) -> Polygon2D:
	return add_polygon(parent, dome(center, rx, ry, segments), color)
