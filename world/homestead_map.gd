extends Node2D
class_name HomesteadMap

const TILE_WIDTH := 64
const TILE_HEIGHT := 32
const MAP_WIDTH := 12
const MAP_HEIGHT := 10

const BLOCKED_TILES := [
	Vector2i(4, 3),
	Vector2i(5, 3),
	Vector2i(4, 4),
	Vector2i(8, 6),
	Vector2i(2, 7),
]

func _ready() -> void:
	_build_ground()
	_build_homestead_colliders()
	_add_map_bounds()

func grid_to_world(tile: Vector2i) -> Vector2:
	return Vector2(
		(tile.x - tile.y) * TILE_WIDTH * 0.5,
		(tile.x + tile.y) * TILE_HEIGHT * 0.5
	)

func get_spawn_position() -> Vector2:
	return grid_to_world(Vector2i(5, 6))

func _build_ground() -> void:
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var tile := Vector2i(x, y)
			var ground_tile := Polygon2D.new()
			ground_tile.name = "Tile_%s_%s" % [x, y]
			ground_tile.polygon = _tile_diamond()
			ground_tile.position = grid_to_world(tile)
			ground_tile.color = _tile_color(tile)
			ground_tile.z_index = x + y
			add_child(ground_tile)

func _build_homestead_colliders() -> void:
	_add_building(Vector2i(4, 3), Vector2i(2, 2), Color("#8f6f4f"), "Cottage")
	_add_tree(Vector2i(8, 6))
	_add_tree(Vector2i(2, 7))
	_add_fence_line(Vector2i(1, 2), 7)

func _add_building(origin: Vector2i, footprint: Vector2i, color: Color, label: String) -> void:
	var building := StaticBody2D.new()
	building.name = label
	building.position = grid_to_world(origin)
	building.z_index = origin.x + origin.y + 20
	add_child(building)

	var base := Polygon2D.new()
	base.name = "Base"
	base.polygon = PackedVector2Array([
		Vector2(0, -32),
		Vector2(64, 0),
		Vector2(0, 32),
		Vector2(-64, 0),
	])
	base.color = color
	building.add_child(base)

	var roof := Polygon2D.new()
	roof.name = "Roof"
	roof.position = Vector2(0, -36)
	roof.polygon = PackedVector2Array([
		Vector2(0, -34),
		Vector2(74, 0),
		Vector2(0, 34),
		Vector2(-74, 0),
	])
	roof.color = Color("#6f3d35")
	building.add_child(roof)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(52 * footprint.x, 24 * footprint.y)
	collision.shape = shape
	building.add_child(collision)

func _add_tree(tile: Vector2i) -> void:
	var tree := StaticBody2D.new()
	tree.name = "Tree_%s_%s" % [tile.x, tile.y]
	tree.position = grid_to_world(tile)
	tree.z_index = tile.x + tile.y + 20
	add_child(tree)

	var trunk := Polygon2D.new()
	trunk.name = "Trunk"
	trunk.polygon = PackedVector2Array([
		Vector2(-7, 0),
		Vector2(7, 0),
		Vector2(7, -30),
		Vector2(-7, -30),
	])
	trunk.color = Color("#76533c")
	tree.add_child(trunk)

	var leaves := Polygon2D.new()
	leaves.name = "Leaves"
	leaves.position = Vector2(0, -42)
	leaves.polygon = PackedVector2Array([
		Vector2(0, -34),
		Vector2(30, -6),
		Vector2(18, 24),
		Vector2(-18, 24),
		Vector2(-30, -6),
	])
	leaves.color = Color("#4d8f55")
	tree.add_child(leaves)

	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 17.0
	collision.position = Vector2(0, -8)
	collision.shape = shape
	tree.add_child(collision)

func _add_fence_line(start_tile: Vector2i, length: int) -> void:
	for offset in range(length):
		var tile := start_tile + Vector2i(offset, 0)
		var fence := StaticBody2D.new()
		fence.name = "Fence_%s_%s" % [tile.x, tile.y]
		fence.position = grid_to_world(tile) + Vector2(0, 6)
		fence.z_index = tile.x + tile.y + 15
		add_child(fence)

		var rail := Polygon2D.new()
		rail.name = "Rail"
		rail.polygon = PackedVector2Array([
			Vector2(-24, -8),
			Vector2(24, -8),
			Vector2(24, 4),
			Vector2(-24, 4),
		])
		rail.color = Color("#b28a5c")
		fence.add_child(rail)

		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(48, 12)
		collision.shape = shape
		fence.add_child(collision)

func _add_map_bounds() -> void:
	_add_boundary("NorthBoundary", Vector2(32, -56), Vector2(900, 64))
	_add_boundary("SouthBoundary", Vector2(32, 440), Vector2(900, 64))
	_add_boundary("WestBoundary", Vector2(-460, 190), Vector2(64, 640))
	_add_boundary("EastBoundary", Vector2(520, 190), Vector2(64, 640))

func _add_boundary(label: String, boundary_position: Vector2, size: Vector2) -> void:
	var boundary := StaticBody2D.new()
	boundary.name = label
	boundary.position = boundary_position
	add_child(boundary)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	boundary.add_child(collision)

func _tile_color(tile: Vector2i) -> Color:
	if tile in BLOCKED_TILES:
		return Color("#8dae65")
	if (tile.x + tile.y) % 2 == 0:
		return Color("#76a96a")
	return Color("#6f9f63")

func _tile_diamond() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0, -TILE_HEIGHT * 0.5),
		Vector2(TILE_WIDTH * 0.5, 0),
		Vector2(0, TILE_HEIGHT * 0.5),
		Vector2(-TILE_WIDTH * 0.5, 0),
	])
