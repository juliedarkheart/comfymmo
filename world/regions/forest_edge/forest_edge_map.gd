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
const GROUND_APRON := 8
const BACKDROP_COLOR := Color("#4f7d4a")
const BACKDROP_MARGIN := 200.0
const WILDERNESS_RADIUS := 14
const WILDERNESS_SEED := 770413
const WILDERNESS_DENSITY := 0.15

@onready var ground_layer: Node2D = $GroundLayer
@onready var gameplay_layer: Node2D = $GameplayLayer

func _ready() -> void:
	_build_backdrop()
	_build_apron()
	_build_ground()
	_build_topology()
	_build_wilderness()
	_build_forest_features()
	_build_edge_dressing()
	_add_map_bounds()

func _build_backdrop() -> void:
	# Full-bleed forest-floor backdrop covering the camera view so the region never
	# looks like a floating patch with transparent void around it.
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
	# Visual-only filler tiles ringing the authored core so the forest reads as a
	# deeper continuous woodland. No collision, outside the gameplay grid.
	for y in range(-GROUND_APRON, MAP_HEIGHT + GROUND_APRON):
		for x in range(-GROUND_APRON, MAP_WIDTH + GROUND_APRON):
			if x >= 0 and x < MAP_WIDTH and y >= 0 and y < MAP_HEIGHT:
				continue
			var tile := Vector2i(x, y)
			var filler := Polygon2D.new()
			filler.position = grid_to_world(tile)
			filler.polygon = _tile_diamond()
			if _apron_is_road(tile):
				filler.color = Color("#b28e63")
			else:
				filler.color = _apron_color(tile)
			ground_layer.add_child(filler)

func _apron_is_road(tile: Vector2i) -> bool:
	# West trail continuing out of the core back toward village_square.
	return tile.x < 0 and tile.y >= 8 and tile.y <= 10

func _apron_color(tile: Vector2i) -> Color:
	if (tile.x + tile.y) % 2 == 0:
		return Color("#558552")
	return Color("#4c7a48")

func _build_topology() -> void:
	# Nature depth: layered distant treeline masses, a rocky ridge hint, a creek
	# with a decorative crossing bridge, and a trail that curves in from the west
	# and forks up to the tucked-away shrine. Flat features go in the ground layer
	# (behind the scattered pines); the bridge is a gameplay-layer occluder.
	TerrainShapes.add_disc(ground_layer, Vector2(200, -130), 130, 9, Color("#375f36"), 0.55)
	TerrainShapes.add_disc(ground_layer, Vector2(-180, -170), 150, 9, Color("#335a33"), 0.55)
	TerrainShapes.add_disc(ground_layer, Vector2(640, 170), 140, 9, Color("#375f36"), 0.55)
	TerrainShapes.add_disc(ground_layer, Vector2(600, 70), 100, 7, Color("#7a766f"), 0.6)
	TerrainShapes.add_disc(ground_layer, Vector2(590, 52), 70, 7, Color("#928d84"), 0.6)
	TerrainShapes.add_ribbon(
		ground_layer,
		PackedVector2Array([Vector2(80, 20), Vector2(20, 150), Vector2(-20, 250), Vector2(-60, 370), Vector2(-120, 470)]),
		12.0, 16.0, Color(0.4, 0.55, 0.6, 0.72)
	)
	TerrainShapes.add_ribbon(
		ground_layer,
		PackedVector2Array([Vector2(-340, 238), Vector2(-180, 250), Vector2(-30, 258), Vector2(120, 250), Vector2(220, 262)]),
		22.0, 16.0, Color("#b28e63")
	)
	TerrainShapes.add_ribbon(ground_layer, PackedVector2Array([Vector2(120, 250), Vector2(132, 208), Vector2(136, 172)]), 12.0, 7.0, Color("#a9855c"))
	_add_bridge(Vector2(-20, 254))

func _add_bridge(world_pos: Vector2) -> void:
	var bridge := Node2D.new()
	bridge.position = world_pos
	gameplay_layer.add_child(bridge)
	var deck := Polygon2D.new()
	deck.polygon = PackedVector2Array([Vector2(-34, 8), Vector2(34, 8), Vector2(30, -8), Vector2(-30, -8)])
	deck.color = Color("#9a6f44")
	bridge.add_child(deck)
	var plank := Polygon2D.new()
	plank.polygon = PackedVector2Array([Vector2(-30, 2), Vector2(30, 2), Vector2(28, -2), Vector2(-28, -2)])
	plank.color = Color("#b08552")
	bridge.add_child(plank)
	var rail_far := Polygon2D.new()
	rail_far.position = Vector2(0, -8)
	rail_far.polygon = PackedVector2Array([Vector2(-30, 0), Vector2(30, 0), Vector2(30, -5), Vector2(-30, -5)])
	rail_far.color = Color("#7c5536")
	bridge.add_child(rail_far)
	var rail_near := Polygon2D.new()
	rail_near.position = Vector2(0, 8)
	rail_near.polygon = PackedVector2Array([Vector2(-30, 0), Vector2(30, 0), Vector2(30, -4), Vector2(-30, -4)])
	rail_near.color = Color("#8a6240")
	bridge.add_child(rail_near)

func _build_edge_dressing() -> void:
	# A dense pine/rock treeline ringing the forest so the edges imply deeper
	# unexplored woodland rather than a hard border, with a gap at the west trail.
	var ring: int = 2
	for x in range(-ring, MAP_WIDTH + ring + 1, 2):
		_add_pine(gameplay_layer, grid_to_world(Vector2i(x, -ring)))
		_add_pine(gameplay_layer, grid_to_world(Vector2i(x, MAP_HEIGHT + ring - 1)))
	for y in range(-ring, MAP_HEIGHT + ring + 1, 2):
		if not (y >= 8 and y <= 10):
			_add_pine(gameplay_layer, grid_to_world(Vector2i(-ring, y)))
		if (y % 4) == 0:
			_add_rock(gameplay_layer, grid_to_world(Vector2i(MAP_WIDTH + ring - 1, y)))
		else:
			_add_pine(gameplay_layer, grid_to_world(Vector2i(MAP_WIDTH + ring - 1, y)))

func _build_wilderness() -> void:
	# Deterministic deep-forest fill: dense, layered pine clusters with rocks, ferns
	# and the occasional clearing, thinning only toward the west trail back to the
	# village. Visual only, drawn behind gameplay in the ground layer so the woods
	# read as endless depth without ever occluding the play core.
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
	if x < 0 and y >= 8 and y <= 10:
		return true
	return false

func _place_wilderness_prop(rng: RandomNumberGenerator, tile: Vector2i) -> void:
	var pos := grid_to_world(tile) + Vector2(rng.randf_range(-12.0, 12.0), rng.randf_range(-7.0, 7.0))
	var roll := rng.randf()
	if roll < 0.62:
		_add_pine_cluster(rng, ground_layer, pos)
	elif roll < 0.78:
		_add_rock(ground_layer, pos)
	elif roll < 0.90:
		_add_grass_tuft(rng, ground_layer, pos)
	else:
		_add_flowers(rng, ground_layer, pos)

func _add_pine_cluster(rng: RandomNumberGenerator, parent: Node2D, world_pos: Vector2) -> void:
	var count := rng.randi_range(1, 3)
	for i in range(count):
		var offset := Vector2(rng.randf_range(-16.0, 16.0), rng.randf_range(-10.0, 10.0))
		_add_pine(parent, world_pos + offset)

func _add_pine(parent: Node2D, world_pos: Vector2) -> void:
	var pine := Node2D.new()
	pine.position = world_pos
	parent.add_child(pine)
	var trunk := Polygon2D.new()
	trunk.polygon = PackedVector2Array([
		Vector2(-4, 0), Vector2(4, 0), Vector2(6, -24), Vector2(-6, -24),
	])
	trunk.color = Color("#704f35")
	pine.add_child(trunk)
	var lower := Polygon2D.new()
	lower.position = Vector2(0, -22)
	lower.polygon = PackedVector2Array([
		Vector2(0, -20), Vector2(20, -2), Vector2(0, 16), Vector2(-20, -2),
	])
	lower.color = Color("#5d8e53")
	pine.add_child(lower)
	var upper := Polygon2D.new()
	upper.position = Vector2(0, -40)
	upper.polygon = PackedVector2Array([
		Vector2(0, -18), Vector2(15, -1), Vector2(0, 12), Vector2(-15, -1),
	])
	upper.color = Color("#79ab67")
	pine.add_child(upper)

func _add_rock(parent: Node2D, world_pos: Vector2) -> void:
	var rock := Node2D.new()
	rock.position = world_pos
	parent.add_child(rock)
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(0, -14), Vector2(15, -3), Vector2(11, 12), Vector2(-11, 12), Vector2(-15, -3),
	])
	body.color = Color("#9a968f")
	rock.add_child(body)
	var shade := Polygon2D.new()
	shade.position = Vector2(4, 2)
	shade.polygon = PackedVector2Array([
		Vector2(0, -7), Vector2(8, 0), Vector2(4, 8), Vector2(-6, 6),
	])
	shade.color = Color("#827e77")
	rock.add_child(shade)

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
		blade.color = Color("#4f7d44") if (i % 2 == 0) else Color("#436c3b")
		tuft.add_child(blade)

func _add_flowers(rng: RandomNumberGenerator, parent: Node2D, world_pos: Vector2) -> void:
	var patch := Node2D.new()
	patch.position = world_pos
	parent.add_child(patch)
	var palette := [Color("#c688d8"), Color("#f0d982"), Color("#d99282"), Color("#a9c6e8")]
	for i in range(3):
		var bloom := Polygon2D.new()
		bloom.position = Vector2(rng.randf_range(-9.0, 9.0), rng.randf_range(-4.0, 4.0))
		bloom.polygon = PackedVector2Array([
			Vector2(0, -4), Vector2(4, 0), Vector2(0, 4), Vector2(-4, 0),
		])
		bloom.color = palette[rng.randi_range(0, palette.size() - 1)]
		patch.add_child(bloom)

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
	# Wide framing so the woodland reads as deep and endless in every direction but
	# the west trail, with the player small beneath layered treelines.
	return Rect2i(-920, -300, 1960, 1380)

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
