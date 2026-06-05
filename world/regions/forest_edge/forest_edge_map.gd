extends Node2D
class_name ForestEdgeMap

const TILE_WIDTH := 64
const TILE_HEIGHT := 32
const MAP_WIDTH := 26
const MAP_HEIGHT := 20
const DEFAULT_SPAWN_TILE := Vector2i(8, 9)
const VILLAGE_ENTRY_SPAWN_TILE := Vector2i(5, 10)
const PINE_TILES: Array[Vector2i] = [
	Vector2i(7, 4),
	Vector2i(10, 5),
	Vector2i(15, 4),
	Vector2i(17, 8),
	Vector2i(19, 11),
	Vector2i(12, 13),
	Vector2i(6, 12),
	Vector2i(21, 6),
	Vector2i(22, 10),
	Vector2i(16, 15),
	Vector2i(9, 16),
]
const MUSHROOM_PATCHES: Array[Vector2i] = [
	Vector2i(9, 11),
	Vector2i(14, 7),
	Vector2i(18, 13),
]

@onready var ground_layer: Node2D = $GroundLayer
@onready var gameplay_layer: Node2D = $GameplayLayer

func _ready() -> void:
	_build_ground()
	_build_forest_features()
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
		"from_village_square":
			return VILLAGE_ENTRY_SPAWN_TILE
		_:
			return DEFAULT_SPAWN_TILE

func get_camera_limits() -> Rect2i:
	return Rect2i(-620, -140, 1440, 980)

func get_camera_zoom() -> Vector2:
	return Vector2(1.10, 1.10)

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

			var patch: Polygon2D = Polygon2D.new()
			patch.position = Vector2(0, 3)
			patch.polygon = PackedVector2Array([
				Vector2(0, -5),
				Vector2(9, -1),
				Vector2(7, 5),
				Vector2(-7, 5),
				Vector2(-9, -1),
			])
			patch.color = _tile_patch(tile)
			ground_tile.add_child(patch)

func _build_forest_features() -> void:
	for tree_tile in PINE_TILES:
		_add_tree(tree_tile)

	for patch_tile in MUSHROOM_PATCHES:
		_add_mushroom_patch(patch_tile)

	_add_stone(Vector2i(13, 10))
	_add_stone(Vector2i(20, 8))
	_add_stone(Vector2i(22, 14))
	_add_flower_patch(Vector2i(11, 8))
	_add_flower_patch(Vector2i(17, 13))

func _add_tree(tile: Vector2i) -> void:
	var tree: StaticBody2D = StaticBody2D.new()
	tree.name = "Pine_%s_%s" % [tile.x, tile.y]
	tree.position = grid_to_world(tile)
	gameplay_layer.add_child(tree)

	var trunk: Polygon2D = Polygon2D.new()
	trunk.color = Color("#704f35")
	trunk.polygon = PackedVector2Array([
		Vector2(-6, 0),
		Vector2(6, 0),
		Vector2(9, -34),
		Vector2(-9, -34),
	])
	tree.add_child(trunk)

	var lower_canopy: Polygon2D = Polygon2D.new()
	lower_canopy.position = Vector2(0, -30)
	lower_canopy.color = Color("#5d8e53")
	lower_canopy.polygon = PackedVector2Array([
		Vector2(0, -24),
		Vector2(26, -4),
		Vector2(0, 20),
		Vector2(-26, -4),
	])
	tree.add_child(lower_canopy)

	var mid_canopy: Polygon2D = Polygon2D.new()
	mid_canopy.position = Vector2(0, -48)
	mid_canopy.color = Color("#79ab67")
	mid_canopy.polygon = PackedVector2Array([
		Vector2(0, -26),
		Vector2(22, -2),
		Vector2(0, 18),
		Vector2(-22, -2),
	])
	tree.add_child(mid_canopy)

	var top_canopy: Polygon2D = Polygon2D.new()
	top_canopy.position = Vector2(0, -64)
	top_canopy.color = Color("#90c07c")
	top_canopy.polygon = PackedVector2Array([
		Vector2(0, -18),
		Vector2(16, -1),
		Vector2(0, 12),
		Vector2(-16, -1),
	])
	tree.add_child(top_canopy)

	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 15.0
	collision.position = Vector2(0, -10)
	collision.shape = shape
	tree.add_child(collision)

func _add_mushroom_patch(tile: Vector2i) -> void:
	var patch: Node2D = Node2D.new()
	patch.name = "Mushrooms_%s_%s" % [tile.x, tile.y]
	patch.position = grid_to_world(tile)
	gameplay_layer.add_child(patch)

	var mushroom_offsets: Array[Vector2] = [
		Vector2(-10, -2),
		Vector2(0, 3),
		Vector2(10, -4),
	]
	for offset in mushroom_offsets:
		var cap: Polygon2D = Polygon2D.new()
		cap.position = offset
		cap.color = Color("#d57d68")
		cap.polygon = PackedVector2Array([
			Vector2(0, -6),
			Vector2(7, -1),
			Vector2(0, 5),
			Vector2(-7, -1),
		])
		patch.add_child(cap)

func _add_stone(tile: Vector2i) -> void:
	var stone: StaticBody2D = StaticBody2D.new()
	stone.name = "Stone_%s_%s" % [tile.x, tile.y]
	stone.position = grid_to_world(tile)
	gameplay_layer.add_child(stone)

	var body: Polygon2D = Polygon2D.new()
	body.color = Color("#a4a09a")
	body.polygon = PackedVector2Array([
		Vector2(0, -14),
		Vector2(14, -3),
		Vector2(10, 12),
		Vector2(-10, 12),
		Vector2(-14, -3),
	])
	stone.add_child(body)

	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 11.0
	collision.position = Vector2(0, 2)
	collision.shape = shape
	stone.add_child(collision)

func _add_flower_patch(tile: Vector2i) -> void:
	var patch: Node2D = Node2D.new()
	patch.name = "ForestFlowers_%s_%s" % [tile.x, tile.y]
	patch.position = grid_to_world(tile)
	gameplay_layer.add_child(patch)

	var petal_colors: Array[Color] = [
		Color("#c688d8"),
		Color("#f0d982"),
		Color("#d99282"),
	]
	var offsets: Array[Vector2] = [
		Vector2(-9, 1),
		Vector2(1, -2),
		Vector2(10, 2),
	]
	for index in range(offsets.size()):
		var bloom: Polygon2D = Polygon2D.new()
		bloom.position = offsets[index]
		bloom.color = petal_colors[index]
		bloom.polygon = PackedVector2Array([
			Vector2(0, -4),
			Vector2(4, 0),
			Vector2(0, 4),
			Vector2(-4, 0),
		])
		patch.add_child(bloom)

func _add_map_bounds() -> void:
	_add_boundary("NorthBoundary", Vector2(100, -108), Vector2(1460, 64))
	_add_boundary("SouthBoundary", Vector2(100, 920), Vector2(1460, 64))
	_add_boundary("WestBoundaryTop", Vector2(-560, 110), Vector2(64, 220))
	_add_boundary("WestBoundaryBottom", Vector2(-560, 714), Vector2(64, 188))
	_add_boundary("EastBoundary", Vector2(620, 390), Vector2(64, 1090))

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
	if tile.x <= 6 and tile.y >= 8 and tile.y <= 10:
		return Color("#b28e63")
	if tile.x >= 16 and tile.y >= 7 and tile.y <= 9:
		return Color("#9f815c")
	if tile.x >= 20 and tile.y >= 11 and tile.y <= 15:
		return Color("#6a9a63")
	if (tile.x + tile.y) % 2 == 0:
		return Color("#6c9d61")
	return Color("#5f9157")

func _tile_accent(tile: Vector2i) -> Color:
	if tile.x <= 6 and tile.y >= 8 and tile.y <= 10:
		return Color("#d0b18c")
	if tile.x >= 16 and tile.y >= 7 and tile.y <= 9:
		return Color("#c39b71")
	if tile.x >= 20 and tile.y >= 11 and tile.y <= 15:
		return Color("#a9cb9b")
	return Color("#89b87b")

func _tile_patch(tile: Vector2i) -> Color:
	if tile.x <= 6 and tile.y >= 8 and tile.y <= 10:
		return Color("#876341")
	if tile.x >= 16 and tile.y >= 7 and tile.y <= 9:
		return Color("#745230")
	if (tile.x + tile.y) % 3 == 0:
		return Color("#7fb56f")
	return Color("#6ca164")

func _tile_diamond() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0, -TILE_HEIGHT * 0.5),
		Vector2(TILE_WIDTH * 0.5, 0),
		Vector2(0, TILE_HEIGHT * 0.5),
		Vector2(-TILE_WIDTH * 0.5, 0),
	])
