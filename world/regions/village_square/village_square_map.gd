extends Node2D
class_name VillageSquareMap

const TILE_WIDTH := 64
const TILE_HEIGHT := 32
const MAP_WIDTH := 24
const MAP_HEIGHT := 20
const DEFAULT_SPAWN_TILE := Vector2i(8, 10)
const HOMESTEAD_ENTRY_SPAWN_TILE := Vector2i(4, 10)
const FOREST_ENTRY_SPAWN_TILE := Vector2i(18, 10)
const GROUND_APRON := 8
const BACKDROP_COLOR := Color("#6e9a64")
const BACKDROP_MARGIN := 200.0
const WILDERNESS_RADIUS := 14
const WILDERNESS_SEED := 521977
const WILDERNESS_DENSITY := 0.09

@onready var ground_layer: Node2D = $GroundLayer
@onready var gameplay_layer: Node2D = $GameplayLayer

func _ready() -> void:
	_build_backdrop()
	_build_apron()
	_build_ground()
	_build_topology()
	_build_wilderness()
	_build_square_features()
	_build_edge_dressing()
	_add_map_bounds()

func _build_backdrop() -> void:
	# Full-bleed terrain backdrop covering the camera view so the iso ground never
	# leaves transparent void in the rectangular camera corners.
	var limits: Rect2i = get_camera_limits()
	var backdrop: Polygon2D = Polygon2D.new()
	backdrop.name = "Backdrop"
	backdrop.polygon = PackedVector2Array([
		Vector2(limits.position.x - BACKDROP_MARGIN, limits.position.y - BACKDROP_MARGIN),
		Vector2(limits.end.x + BACKDROP_MARGIN, limits.position.y - BACKDROP_MARGIN),
		Vector2(limits.end.x + BACKDROP_MARGIN, limits.end.y + BACKDROP_MARGIN),
		Vector2(limits.position.x - BACKDROP_MARGIN, limits.end.y + BACKDROP_MARGIN),
	])
	backdrop.color = BACKDROP_COLOR
	ground_layer.add_child(backdrop)

func _build_apron() -> void:
	# Visual-only filler tiles ringing the authored core so the plaza reads as part
	# of a larger outdoor space. No collision, outside the gameplay grid.
	for y in range(-GROUND_APRON, MAP_HEIGHT + GROUND_APRON):
		for x in range(-GROUND_APRON, MAP_WIDTH + GROUND_APRON):
			if x >= 0 and x < MAP_WIDTH and y >= 0 and y < MAP_HEIGHT:
				continue
			var tile := Vector2i(x, y)
			var filler := Polygon2D.new()
			filler.position = grid_to_world(tile)
			filler.polygon = _tile_diamond()
			if _apron_is_west_road(tile):
				filler.color = Color("#b59872")
			elif _apron_is_east_road(tile):
				filler.color = Color("#ad8a64")
			else:
				filler.color = _apron_color(tile)
			ground_layer.add_child(filler)

func _apron_is_west_road(tile: Vector2i) -> bool:
	return tile.x < 0 and tile.y >= 9 and tile.y <= 11

func _apron_is_east_road(tile: Vector2i) -> bool:
	return tile.x >= MAP_WIDTH and tile.y >= 8 and tile.y <= 10

func _apron_color(tile: Vector2i) -> Color:
	if (tile.x + tile.y) % 2 == 0:
		return Color("#71a067")
	return Color("#699760")

func _build_topology() -> void:
	# Plaza geography: a flagstone disc that makes the fountain read as a landmark,
	# roads branching out to the west and east exits, two tapering side streets that
	# imply the village continues (then peters out), and a couple of flower beds.
	# Flat features live in the ground layer beneath the fountain and props.
	TerrainShapes.add_disc(ground_layer, Vector2(96, 284), 84, 8, Color("#c4b79a"), 0.5)
	TerrainShapes.add_disc(ground_layer, Vector2(96, 282), 60, 8, Color("#d2c6ab"), 0.5)
	TerrainShapes.add_ribbon(
		ground_layer,
		PackedVector2Array([Vector2(72, 278), Vector2(-120, 250), Vector2(-330, 234), Vector2(-540, 224)]),
		26.0, 30.0, Color("#b59872")
	)
	TerrainShapes.add_ribbon(
		ground_layer,
		PackedVector2Array([Vector2(124, 290), Vector2(300, 358), Vector2(450, 408), Vector2(560, 440)]),
		26.0, 30.0, Color("#ad8a64")
	)
	TerrainShapes.add_ribbon(ground_layer, PackedVector2Array([Vector2(96, 254), Vector2(74, 150), Vector2(64, 70)]), 22.0, 3.0, Color("#b8a383"))
	TerrainShapes.add_ribbon(ground_layer, PackedVector2Array([Vector2(112, 300), Vector2(150, 418), Vector2(168, 512)]), 20.0, 3.0, Color("#b3a07f"))
	_add_flower_bed(Vector2(20, 332))
	_add_flower_bed(Vector2(176, 336))

func _add_flower_bed(world_pos: Vector2) -> void:
	var soil := Polygon2D.new()
	soil.position = world_pos
	soil.polygon = PackedVector2Array([
		Vector2(-18, 0), Vector2(0, -9), Vector2(18, 0), Vector2(0, 9),
	])
	soil.color = Color("#7c5a3a")
	ground_layer.add_child(soil)
	var blooms := Polygon2D.new()
	blooms.position = world_pos
	blooms.polygon = PackedVector2Array([
		Vector2(-11, 0), Vector2(0, -5), Vector2(11, 0), Vector2(0, 5),
	])
	blooms.color = Color("#d98c82")
	ground_layer.add_child(blooms)

func _build_edge_dressing() -> void:
	# Visible border hedge/tree line so the plaza edges feel like the rim of a
	# larger settlement, with openings left at the west and east road exits.
	var ring: int = 2
	for x in range(-ring, MAP_WIDTH + ring + 1, 2):
		_add_border_prop(Vector2i(x, -ring))
		_add_border_prop(Vector2i(x, MAP_HEIGHT + ring - 1))
	for y in range(-ring, MAP_HEIGHT + ring + 1, 2):
		if not (y >= 9 and y <= 11):
			_add_border_prop(Vector2i(-ring, y))
		if not (y >= 8 and y <= 14):
			_add_border_prop(Vector2i(MAP_WIDTH + ring - 1, y))

func _add_border_prop(tile: Vector2i) -> void:
	if tile.y % 3 == 0:
		_add_decor_tree(gameplay_layer, grid_to_world(tile))
	else:
		_add_shrub(gameplay_layer, grid_to_world(tile))

func _build_wilderness() -> void:
	# Deterministic decorative outskirts implying the settlement continues off-screen:
	# scattered trees and hedges, distant cottage silhouettes, and short road
	# fragments. Visual only, drawn behind gameplay in the ground layer.
	var rng := RandomNumberGenerator.new()
	rng.seed = WILDERNESS_SEED
	for y in range(-WILDERNESS_RADIUS, MAP_HEIGHT + WILDERNESS_RADIUS):
		for x in range(-WILDERNESS_RADIUS, MAP_WIDTH + WILDERNESS_RADIUS):
			if _wilderness_skip(x, y):
				continue
			if rng.randf() > WILDERNESS_DENSITY:
				continue
			_place_wilderness_prop(rng, Vector2i(x, y))

func _wilderness_skip(x: int, y: int) -> bool:
	if x >= -3 and x < MAP_WIDTH + 3 and y >= -3 and y < MAP_HEIGHT + 3:
		return true
	if x < 0 and y >= 9 and y <= 11:
		return true
	if x >= MAP_WIDTH and y >= 8 and y <= 10:
		return true
	return false

func _place_wilderness_prop(rng: RandomNumberGenerator, tile: Vector2i) -> void:
	var pos := grid_to_world(tile) + Vector2(rng.randf_range(-12.0, 12.0), rng.randf_range(-7.0, 7.0))
	var roll := rng.randf()
	if roll < 0.22:
		_add_tree_cluster(rng, ground_layer, pos)
	elif roll < 0.40:
		_add_shrub(ground_layer, pos)
	elif roll < 0.52:
		_add_rock(ground_layer, pos)
	elif roll < 0.66:
		_add_flowers(rng, ground_layer, pos)
	elif roll < 0.82:
		_add_grass_tuft(rng, ground_layer, pos)
	elif roll < 0.92:
		_add_distant_house(rng, ground_layer, pos)
	else:
		_add_path_fragment(rng, ground_layer, pos)

func _add_tree_cluster(rng: RandomNumberGenerator, parent: Node2D, world_pos: Vector2) -> void:
	var count := rng.randi_range(1, 3)
	for i in range(count):
		var offset := Vector2(rng.randf_range(-15.0, 15.0), rng.randf_range(-9.0, 9.0))
		_add_decor_tree(parent, world_pos + offset)

func _add_decor_tree(parent: Node2D, world_pos: Vector2) -> void:
	var tree := Node2D.new()
	tree.position = world_pos
	parent.add_child(tree)
	var trunk := Polygon2D.new()
	trunk.polygon = PackedVector2Array([
		Vector2(-4, 0), Vector2(4, 0), Vector2(5, -22), Vector2(-5, -22),
	])
	trunk.color = Color("#7a5536")
	tree.add_child(trunk)
	var canopy := Polygon2D.new()
	canopy.position = Vector2(0, -32)
	canopy.polygon = PackedVector2Array([
		Vector2(0, -22), Vector2(20, -6), Vector2(14, 14), Vector2(0, 20), Vector2(-14, 14), Vector2(-20, -6),
	])
	canopy.color = Color("#7ba86f")
	tree.add_child(canopy)

func _add_shrub(parent: Node2D, world_pos: Vector2) -> void:
	var shrub := Node2D.new()
	shrub.position = world_pos
	parent.add_child(shrub)
	var blob := Polygon2D.new()
	blob.polygon = PackedVector2Array([
		Vector2(0, -13), Vector2(12, -5), Vector2(10, 6), Vector2(0, 10), Vector2(-10, 6), Vector2(-12, -5),
	])
	blob.color = Color("#5f8c56")
	shrub.add_child(blob)
	var hi := Polygon2D.new()
	hi.position = Vector2(-2, -3)
	hi.polygon = PackedVector2Array([
		Vector2(0, -6), Vector2(6, -2), Vector2(4, 4), Vector2(-4, 4), Vector2(-6, -2),
	])
	hi.color = Color("#7ba86f")
	shrub.add_child(hi)

func _add_rock(parent: Node2D, world_pos: Vector2) -> void:
	var rock := Node2D.new()
	rock.position = world_pos
	parent.add_child(rock)
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(0, -10), Vector2(12, -2), Vector2(9, 9), Vector2(-9, 9), Vector2(-12, -2),
	])
	body.color = Color("#a4a09a")
	rock.add_child(body)

func _add_flowers(rng: RandomNumberGenerator, parent: Node2D, world_pos: Vector2) -> void:
	var patch := Node2D.new()
	patch.position = world_pos
	parent.add_child(patch)
	var palette := [Color("#d98c82"), Color("#efd07a"), Color("#c69de2"), Color("#e7a9c4")]
	for i in range(3):
		var bloom := Polygon2D.new()
		bloom.position = Vector2(rng.randf_range(-9.0, 9.0), rng.randf_range(-4.0, 4.0))
		bloom.polygon = PackedVector2Array([
			Vector2(0, -4), Vector2(4, 0), Vector2(0, 4), Vector2(-4, 0),
		])
		bloom.color = palette[rng.randi_range(0, palette.size() - 1)]
		patch.add_child(bloom)

func _add_grass_tuft(rng: RandomNumberGenerator, parent: Node2D, world_pos: Vector2) -> void:
	var tuft := Node2D.new()
	tuft.position = world_pos
	parent.add_child(tuft)
	for i in range(rng.randi_range(3, 5)):
		var blade := Polygon2D.new()
		blade.position = Vector2(rng.randf_range(-7.0, 7.0), 0.0)
		blade.polygon = PackedVector2Array([
			Vector2(-1, 0), Vector2(1, 0), Vector2(0, -rng.randf_range(5.0, 9.0)),
		])
		blade.color = Color("#6f9d5a") if (i % 2 == 0) else Color("#5d8c4c")
		tuft.add_child(blade)

func _add_distant_house(rng: RandomNumberGenerator, parent: Node2D, world_pos: Vector2) -> void:
	var house := Node2D.new()
	house.position = world_pos
	parent.add_child(house)
	var wall := Polygon2D.new()
	wall.polygon = PackedVector2Array([
		Vector2(-18, 0), Vector2(18, 0), Vector2(18, -20), Vector2(-18, -20),
	])
	wall.color = Color("#cdb189") if (rng.randf() < 0.5) else Color("#c2a273")
	house.add_child(wall)
	var roof := Polygon2D.new()
	roof.position = Vector2(0, -20)
	roof.polygon = PackedVector2Array([
		Vector2(-22, 0), Vector2(0, -16), Vector2(22, 0),
	])
	roof.color = Color("#8c5142")
	house.add_child(roof)

func _add_path_fragment(rng: RandomNumberGenerator, parent: Node2D, world_pos: Vector2) -> void:
	var frag := Node2D.new()
	frag.position = world_pos
	frag.rotation = rng.randf_range(-0.5, 0.5)
	parent.add_child(frag)
	var road := Polygon2D.new()
	road.polygon = PackedVector2Array([
		Vector2(-26, 6), Vector2(26, 2), Vector2(24, -3), Vector2(-24, 1),
	])
	road.color = Color("#b59872")
	frag.add_child(road)

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
	# Wide framing so the plaza reads as the centre of a larger settlement that
	# continues off-screen in every direction, with the player small in the scene.
	return Rect2i(-900, -300, 1880, 1340)

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
