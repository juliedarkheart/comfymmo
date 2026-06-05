extends Node2D
class_name VillageSquareMap

const TILE_WIDTH := 64
const TILE_HEIGHT := 32
const MAP_WIDTH := 24
const MAP_HEIGHT := 20
const DEFAULT_SPAWN_TILE := Vector2i(8, 10)
const HOMESTEAD_ENTRY_SPAWN_TILE := Vector2i(4, 10)
const FOREST_ENTRY_SPAWN_TILE := Vector2i(18, 10)

@onready var ground_layer: Node2D = $GroundLayer
@onready var gameplay_layer: Node2D = $GameplayLayer

func _ready() -> void:
	_build_ground()
	_build_square_features()
	_add_map_bounds()

func grid_to_world(tile: Vector2i) -> Vector2:
	return Vector2(
		(tile.x - tile.y) * TILE_WIDTH * 0.5,
		(tile.x + tile.y) * TILE_HEIGHT * 0.5
	)

func get_spawn_position(spawn_id: String = "default") -> Vector2:
	return grid_to_world(get_spawn_tile(spawn_id))

func get_spawn_tile(spawn_id: String = "default") -> Vector2i:
	match spawn_id:
		"from_homestead":
			return HOMESTEAD_ENTRY_SPAWN_TILE
		"from_forest_edge":
			return FOREST_ENTRY_SPAWN_TILE
		_:
			return DEFAULT_SPAWN_TILE

func get_camera_limits() -> Rect2i:
	return Rect2i(-620, -120, 1360, 940)

func get_camera_zoom() -> Vector2:
	return Vector2(1.12, 1.12)

func _build_ground() -> void:
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var tile: Vector2i = Vector2i(x, y)
			var ground_tile: Node2D = Node2D.new()
			ground_tile.name = "Tile_%s_%s" % [x, y]
			ground_tile.position = grid_to_world(tile)
			ground_layer.add_child(ground_tile)

			var base: Polygon2D = Polygon2D.new()
			base.polygon = _tile_diamond()
			base.color = _tile_color(tile)
			ground_tile.add_child(base)

			var accent: Polygon2D = Polygon2D.new()
			accent.position = Vector2(0, -2)
			accent.polygon = PackedVector2Array([
				Vector2(0, -10),
				Vector2(24, 0),
				Vector2(0, 5),
				Vector2(-24, 0),
			])
			accent.color = _tile_accent(tile)
			ground_tile.add_child(accent)

func _build_square_features() -> void:
	_add_fountain(Vector2i(10, 7))
	_add_tree(Vector2i(15, 5))
	_add_tree(Vector2i(14, 11))
	_add_tree(Vector2i(6, 4))
	_add_tree(Vector2i(18, 9))
	_add_tree(Vector2i(19, 14))
	_add_tree(Vector2i(4, 15))
	_add_flower_patch(Vector2i(8, 13))
	_add_flower_patch(Vector2i(16, 13))
	_add_flower_patch(Vector2i(20, 6))

func _add_fountain(tile: Vector2i) -> void:
	var fountain: StaticBody2D = StaticBody2D.new()
	fountain.name = "Fountain"
	fountain.position = grid_to_world(tile)
	gameplay_layer.add_child(fountain)

	var base: Polygon2D = Polygon2D.new()
	base.position = Vector2(0, 8)
	base.color = Color("#c9c7d1")
	base.polygon = PackedVector2Array([
		Vector2(0, -20),
		Vector2(34, 0),
		Vector2(0, 20),
		Vector2(-34, 0),
	])
	fountain.add_child(base)

	var basin: Polygon2D = Polygon2D.new()
	basin.position = Vector2(0, -6)
	basin.color = Color("#8db8c9")
	basin.polygon = PackedVector2Array([
		Vector2(0, -16),
		Vector2(18, 0),
		Vector2(0, 12),
		Vector2(-18, 0),
	])
	fountain.add_child(basin)

	var post: Polygon2D = Polygon2D.new()
	post.position = Vector2(0, -28)
	post.color = Color("#b5aa9a")
	post.polygon = PackedVector2Array([
		Vector2(-5, -18),
		Vector2(5, -18),
		Vector2(5, 14),
		Vector2(-5, 14),
	])
	fountain.add_child(post)

	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(44, 22)
	collision.position = Vector2(0, 8)
	collision.shape = shape
	fountain.add_child(collision)

func _add_tree(tile: Vector2i) -> void:
	var tree: StaticBody2D = StaticBody2D.new()
	tree.name = "Tree_%s_%s" % [tile.x, tile.y]
	tree.position = grid_to_world(tile)
	gameplay_layer.add_child(tree)

	var trunk: Polygon2D = Polygon2D.new()
	trunk.color = Color("#7a5536")
	trunk.polygon = PackedVector2Array([
		Vector2(-7, 0),
		Vector2(7, 0),
		Vector2(9, -30),
		Vector2(-9, -30),
	])
	tree.add_child(trunk)

	var canopy: Polygon2D = Polygon2D.new()
	canopy.position = Vector2(0, -42)
	canopy.color = Color("#7ba86f")
	canopy.polygon = PackedVector2Array([
		Vector2(0, -24),
		Vector2(20, -14),
		Vector2(30, 0),
		Vector2(20, 14),
		Vector2(0, 22),
		Vector2(-20, 14),
		Vector2(-30, 0),
		Vector2(-20, -14),
	])
	tree.add_child(canopy)

	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 15.0
	collision.position = Vector2(0, -8)
	collision.shape = shape
	tree.add_child(collision)

func _add_flower_patch(tile: Vector2i) -> void:
	var patch: Node2D = Node2D.new()
	patch.name = "Flowers_%s_%s" % [tile.x, tile.y]
	patch.position = grid_to_world(tile)
	gameplay_layer.add_child(patch)

	var petals: Array[Color] = [
		Color("#d98c82"),
		Color("#efd07a"),
		Color("#c69de2"),
	]
	var offsets: Array[Vector2] = [
		Vector2(-12, 2),
		Vector2(0, -2),
		Vector2(12, 1),
	]
	for index in range(offsets.size()):
		var bloom: Polygon2D = Polygon2D.new()
		bloom.position = offsets[index]
		bloom.color = petals[index]
		bloom.polygon = PackedVector2Array([
			Vector2(0, -5),
			Vector2(5, 0),
			Vector2(0, 5),
			Vector2(-5, 0),
		])
		patch.add_child(bloom)

func _add_map_bounds() -> void:
	_add_boundary("NorthBoundary", Vector2(80, -100), Vector2(1360, 64))
	_add_boundary("SouthBoundary", Vector2(80, 900), Vector2(1360, 64))
	_add_boundary("WestBoundaryTop", Vector2(-560, 112), Vector2(64, 224))
	_add_boundary("WestBoundaryBottom", Vector2(-560, 698), Vector2(64, 178))
	_add_boundary("EastBoundaryTop", Vector2(560, 112), Vector2(64, 224))
	_add_boundary("EastBoundaryBottom", Vector2(560, 698), Vector2(64, 178))

func _add_boundary(label: String, boundary_position: Vector2, size: Vector2) -> void:
	var boundary: StaticBody2D = StaticBody2D.new()
	boundary.name = label
	boundary.position = boundary_position
	gameplay_layer.add_child(boundary)

	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	boundary.add_child(collision)

func _tile_color(tile: Vector2i) -> Color:
	if tile.x >= 7 and tile.x <= 13 and tile.y >= 5 and tile.y <= 9:
		return Color("#b8a383")
	if tile.x <= 6 and tile.y >= 9 and tile.y <= 11:
		return Color("#b59872")
	if tile.x >= 15 and tile.y >= 8 and tile.y <= 10:
		return Color("#ad8a64")
	if tile.x >= 18 and tile.y >= 11 and tile.y <= 14:
		return Color("#8fb287")
	return Color("#78a36e")

func _tile_accent(tile: Vector2i) -> Color:
	if tile.x >= 7 and tile.x <= 13 and tile.y >= 5 and tile.y <= 9:
		return Color("#d8c4a6")
	if tile.x <= 6 and tile.y >= 9 and tile.y <= 11:
		return Color("#d1b38a")
	if tile.x >= 15 and tile.y >= 8 and tile.y <= 10:
		return Color("#cfb08a")
	if tile.x >= 18 and tile.y >= 11 and tile.y <= 14:
		return Color("#b7d1ad")
	return Color("#92bc83")

func _tile_diamond() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0, -TILE_HEIGHT * 0.5),
		Vector2(TILE_WIDTH * 0.5, 0),
		Vector2(0, TILE_HEIGHT * 0.5),
		Vector2(-TILE_WIDTH * 0.5, 0),
	])
