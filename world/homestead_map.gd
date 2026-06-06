extends Node2D
class_name HomesteadMap

const TILE_WIDTH := 64
const TILE_HEIGHT := 32
const MAP_WIDTH := 22
const MAP_HEIGHT := 18
const COTTAGE_ORIGIN := Vector2i(6, 6)
const COTTAGE_FOOTPRINT := Vector2i(2, 2)
const TREE_TILES := [
	Vector2i(10, 8),
	Vector2i(3, 11),
	Vector2i(15, 6),
	Vector2i(18, 10),
	Vector2i(5, 15),
]
const DEFAULT_SPAWN_TILE := Vector2i(7, 11)
const VILLAGE_RETURN_SPAWN_TILE := Vector2i(15, 10)
const FENCE_START_TILE := Vector2i(3, 5)
const FENCE_LENGTH := 8
const PATH_ROW_RANGE := [8, 9, 10]
const GROUND_APRON := 8
const BACKDROP_COLOR := Color("#6a9760")
const BACKDROP_MARGIN := 200.0
const WILDERNESS_RADIUS := 14
const WILDERNESS_SEED := 20240611
const WILDERNESS_DENSITY := 0.09

@onready var ground_layer: Node2D = $GroundLayer
@onready var gameplay_layer: Node2D = $GameplayLayer

func _ready() -> void:
	_build_backdrop()
	_build_apron()
	_build_ground()
	_build_topology()
	_build_wilderness()
	_build_homestead_colliders()
	_build_edge_dressing()
	_add_map_bounds()

func _build_backdrop() -> void:
	# A full-bleed terrain backdrop sized to cover the entire camera view, so the
	# iso ground diamond never leaves transparent void in the rectangular camera
	# corners. Drawn first, so it sits behind every ground tile.
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
	# Filler ground tiles ringing the authored core so terrain reads as continuous
	# out toward the backdrop instead of a small floating patch. Visual only: these
	# tiles carry no collision and are outside the gameplay/placement grid. The east
	# road is continued into the apron so it visibly runs off toward village_square.
	for y in range(-GROUND_APRON, MAP_HEIGHT + GROUND_APRON):
		for x in range(-GROUND_APRON, MAP_WIDTH + GROUND_APRON):
			if x >= 0 and x < MAP_WIDTH and y >= 0 and y < MAP_HEIGHT:
				continue
			var tile := Vector2i(x, y)
			var filler := Polygon2D.new()
			filler.position = grid_to_world(tile)
			filler.polygon = _tile_diamond()
			if _apron_is_road(tile):
				filler.color = Color("#b59872")
			else:
				filler.color = _apron_color(tile)
			ground_layer.add_child(filler)

func _apron_is_road(tile: Vector2i) -> bool:
	# East road corridor continuing out of the playable core toward village_square.
	return tile.x >= MAP_WIDTH and tile.y in PATH_ROW_RANGE

func _apron_color(tile: Vector2i) -> Color:
	if (tile.x + tile.y) % 2 == 0:
		return Color("#6c9962")
	return Color("#659158")

func _build_topology() -> void:
	# Gentle world-shape cues: a road curving toward the village exit, a shallow
	# stream suggestion, distant field hedgerows, and a couple of big foreground
	# trees (beyond the walls) for depth. Flat features sit in the ground layer,
	# under props and the player; foreground occluders go in the gameplay layer.
	TerrainShapes.add_ribbon(
		ground_layer,
		PackedVector2Array([Vector2(20, 352), Vector2(180, 398), Vector2(340, 436), Vector2(540, 470)]),
		22.0, 34.0, Color("#b89a72")
	)
	TerrainShapes.add_ribbon(
		ground_layer,
		PackedVector2Array([Vector2(-430, 300), Vector2(-250, 360), Vector2(-90, 432), Vector2(110, 506), Vector2(280, 566)]),
		11.0, 15.0, Color(0.44, 0.58, 0.6, 0.7)
	)
	TerrainShapes.add_ribbon(ground_layer, PackedVector2Array([Vector2(300, 150), Vector2(470, 188)]), 5.0, 5.0, Color("#557c4d"))
	TerrainShapes.add_ribbon(ground_layer, PackedVector2Array([Vector2(360, 86), Vector2(540, 120)]), 5.0, 5.0, Color("#4f7647"))
	_add_foreground_tree(Vector2(-300, 808), 1.7)
	_add_foreground_tree(Vector2(280, 824), 1.5)

func _add_foreground_tree(world_pos: Vector2, prop_scale: float) -> void:
	var holder := Node2D.new()
	holder.position = world_pos
	holder.scale = Vector2(prop_scale, prop_scale)
	gameplay_layer.add_child(holder)
	_add_decor_tree(holder, Vector2.ZERO)

func _build_edge_dressing() -> void:
	# Visible vegetated border so the map edges read as intentional instead of an
	# invisible wall. Props sit just outside the core ring, with a gap left at the
	# east road so the exit reads as an opening. Visual only, no collision.
	var ring: int = 2
	for x in range(-ring, MAP_WIDTH + ring + 1, 2):
		_add_border_prop(Vector2i(x, -ring))
		_add_border_prop(Vector2i(x, MAP_HEIGHT + ring - 1))
	for y in range(-ring, MAP_HEIGHT + ring + 1, 2):
		_add_border_prop(Vector2i(-ring, y))
		if not (y in PATH_ROW_RANGE):
			_add_border_prop(Vector2i(MAP_WIDTH + ring - 1, y))

func _add_border_prop(tile: Vector2i) -> void:
	if tile.y % 3 == 0:
		_add_decor_tree(gameplay_layer, grid_to_world(tile))
	else:
		_add_shrub(gameplay_layer, grid_to_world(tile))

func _build_wilderness() -> void:
	# Deterministic, seed-friendly decorative wilderness filling the outer shell well
	# beyond the gameplay core. Visual only; drawn into the (non-y-sorted) ground
	# layer so it always sits behind the player and core props. Reads as open
	# countryside continuing outward, with field fences hinting at neighbouring farms.
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
	# Keep a clean margin around the gameplay core and an open gap at the east road.
	if x >= -3 and x < MAP_WIDTH + 3 and y >= -3 and y < MAP_HEIGHT + 3:
		return true
	if x >= MAP_WIDTH and (y in PATH_ROW_RANGE):
		return true
	return false

func _place_wilderness_prop(rng: RandomNumberGenerator, tile: Vector2i) -> void:
	var pos := grid_to_world(tile) + Vector2(rng.randf_range(-12.0, 12.0), rng.randf_range(-7.0, 7.0))
	var roll := rng.randf()
	if roll < 0.26:
		_add_tree_cluster(rng, ground_layer, pos)
	elif roll < 0.40:
		_add_shrub(ground_layer, pos)
	elif roll < 0.52:
		_add_rock(ground_layer, pos)
	elif roll < 0.72:
		_add_flowers(rng, ground_layer, pos)
	elif roll < 0.92:
		_add_grass_tuft(rng, ground_layer, pos)
	else:
		_add_field_fence(ground_layer, pos)

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
	canopy.color = Color("#5f8c56")
	tree.add_child(canopy)
	var canopy_hi := Polygon2D.new()
	canopy_hi.position = Vector2(-3, -36)
	canopy_hi.polygon = PackedVector2Array([
		Vector2(0, -12), Vector2(11, -2), Vector2(6, 9), Vector2(-8, 6), Vector2(-11, -3),
	])
	canopy_hi.color = Color("#82b26e")
	tree.add_child(canopy_hi)

func _add_shrub(parent: Node2D, world_pos: Vector2) -> void:
	var shrub := Node2D.new()
	shrub.position = world_pos
	parent.add_child(shrub)
	var blob := Polygon2D.new()
	blob.polygon = PackedVector2Array([
		Vector2(0, -14), Vector2(13, -6), Vector2(11, 6), Vector2(0, 11), Vector2(-11, 6), Vector2(-13, -6),
	])
	blob.color = Color("#5f8c56")
	shrub.add_child(blob)
	var hi := Polygon2D.new()
	hi.position = Vector2(-2, -4)
	hi.polygon = PackedVector2Array([
		Vector2(0, -7), Vector2(7, -2), Vector2(4, 5), Vector2(-5, 4), Vector2(-7, -2),
	])
	hi.color = Color("#7aa86a")
	shrub.add_child(hi)

func _add_rock(parent: Node2D, world_pos: Vector2) -> void:
	var rock := Node2D.new()
	rock.position = world_pos
	parent.add_child(rock)
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(0, -10), Vector2(12, -2), Vector2(9, 9), Vector2(-9, 9), Vector2(-12, -2),
	])
	body.color = Color("#9a968f")
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

func _add_field_fence(parent: Node2D, world_pos: Vector2) -> void:
	var fence := Node2D.new()
	fence.position = world_pos
	parent.add_child(fence)
	for px in [-16, 0, 16]:
		var post := Polygon2D.new()
		post.position = Vector2(px, 0)
		post.polygon = PackedVector2Array([
			Vector2(-2, -14), Vector2(2, -14), Vector2(2, 4), Vector2(-2, 4),
		])
		post.color = Color("#a97749")
		fence.add_child(post)
	var rail := Polygon2D.new()
	rail.position = Vector2(0, -10)
	rail.polygon = PackedVector2Array([
		Vector2(-18, -2), Vector2(18, -2), Vector2(18, 2), Vector2(-18, 2),
	])
	rail.color = Color("#c08a57")
	fence.add_child(rail)

func grid_to_world(tile: Vector2i) -> Vector2:
	return Vector2(
		(tile.x - tile.y) * TILE_WIDTH * 0.5,
		(tile.x + tile.y) * TILE_HEIGHT * 0.5
	)

func world_to_grid(position: Vector2) -> Vector2i:
	var x := int(round((position.x / (TILE_WIDTH * 0.5) + position.y / (TILE_HEIGHT * 0.5)) * 0.5))
	var y := int(round((position.y / (TILE_HEIGHT * 0.5) - position.x / (TILE_WIDTH * 0.5)) * 0.5))
	return Vector2i(x, y)

func get_spawn_position(spawn_id: String = "default") -> Vector2:
	return grid_to_world(get_spawn_tile(spawn_id))

func get_spawn_tile(spawn_id: String = "default") -> Vector2i:
	match spawn_id:
		"from_village_square":
			return VILLAGE_RETURN_SPAWN_TILE
		_:
			return DEFAULT_SPAWN_TILE

func get_camera_limits() -> Rect2i:
	# Wide framing so the visible countryside dwarfs the gameplay core, the player
	# reads as small in the landscape, and the camera keeps centered toward exits.
	return Rect2i(-820, -260, 1640, 1220)

func get_camera_zoom() -> Vector2:
	return Vector2(1.14, 1.14)

func is_tile_in_bounds(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.x < MAP_WIDTH and tile.y >= 0 and tile.y < MAP_HEIGHT

func get_footprint_tiles(origin: Vector2i, footprint: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for y in range(footprint.y):
		for x in range(footprint.x):
			tiles.append(origin + Vector2i(x, y))
	return tiles

func get_static_blocked_tiles() -> Array[Vector2i]:
	var blocked_tiles: Array[Vector2i] = get_footprint_tiles(COTTAGE_ORIGIN, COTTAGE_FOOTPRINT)
	for tree_tile in TREE_TILES:
		blocked_tiles.append(tree_tile)
	for offset in range(FENCE_LENGTH):
		blocked_tiles.append(FENCE_START_TILE + Vector2i(offset, 0))
	return blocked_tiles

func is_tile_blocked(tile: Vector2i) -> bool:
	if not is_tile_in_bounds(tile):
		return true
	return tile in get_static_blocked_tiles() or tile == get_spawn_tile()

func can_place_footprint(origin: Vector2i, footprint: Vector2i, occupied_tiles: Array[Vector2i] = []) -> bool:
	var placement_result: Dictionary = get_place_footprint_result(origin, footprint, occupied_tiles)
	return bool(placement_result.get("valid", false))

func get_place_footprint_result(origin: Vector2i, footprint: Vector2i, occupied_tiles: Array[Vector2i] = []) -> Dictionary:
	for tile in get_footprint_tiles(origin, footprint):
		var tile_result: Dictionary = get_tile_block_result(tile, occupied_tiles)
		if not bool(tile_result.get("valid", false)):
			return tile_result
	return {
		"valid": true,
		"reason": "",
	}

func get_tile_block_result(tile: Vector2i, occupied_tiles: Array[Vector2i] = []) -> Dictionary:
	if not is_tile_in_bounds(tile):
		return {
			"valid": false,
			"reason": "Out of bounds",
		}

	if tile == get_spawn_tile():
		return {
			"valid": false,
			"reason": "Reserved spawn",
		}

	if tile in occupied_tiles:
		return {
			"valid": false,
			"reason": "Occupied",
		}

	if tile in get_footprint_tiles(COTTAGE_ORIGIN, COTTAGE_FOOTPRINT):
		return {
			"valid": false,
			"reason": "Blocked by cottage",
		}

	if tile in TREE_TILES:
		return {
			"valid": false,
			"reason": "Blocked by tree",
		}

	for offset in range(FENCE_LENGTH):
		if tile == FENCE_START_TILE + Vector2i(offset, 0):
			return {
				"valid": false,
				"reason": "Blocked by fence",
			}

	return {
		"valid": true,
		"reason": "",
	}

func _build_ground() -> void:
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var tile := Vector2i(x, y)
			var ground_tile := Node2D.new()
			ground_tile.name = "Tile_%s_%s" % [x, y]
			ground_tile.position = grid_to_world(tile)
			ground_layer.add_child(ground_tile)

			var base := Polygon2D.new()
			base.name = "Base"
			base.polygon = _tile_diamond()
			base.color = _tile_color(tile)
			ground_tile.add_child(base)

			var highlight := Polygon2D.new()
			highlight.name = "Highlight"
			highlight.position = Vector2(0, -3)
			highlight.polygon = PackedVector2Array([
				Vector2(0, -11),
				Vector2(24, 0),
				Vector2(0, 6),
				Vector2(-24, 0),
			])
			highlight.color = _tile_highlight_color(tile)
			ground_tile.add_child(highlight)

			var patch := Polygon2D.new()
			patch.name = "Patch"
			patch.position = Vector2(0, 2)
			patch.polygon = PackedVector2Array([
				Vector2(0, -6),
				Vector2(10, -1),
				Vector2(8, 6),
				Vector2(-8, 6),
				Vector2(-10, -1),
			])
			patch.color = _tile_patch_color(tile)
			ground_tile.add_child(patch)

func _build_homestead_colliders() -> void:
	_add_building(COTTAGE_ORIGIN, COTTAGE_FOOTPRINT, Color("#8f6f4f"), "Cottage")
	for tree_tile in TREE_TILES:
		_add_tree(tree_tile)
	_add_fence_line(FENCE_START_TILE, FENCE_LENGTH)

func _add_building(origin: Vector2i, footprint: Vector2i, color: Color, label: String) -> void:
	var building := StaticBody2D.new()
	building.name = label
	building.position = grid_to_world(origin)
	gameplay_layer.add_child(building)

	var porch := Polygon2D.new()
	porch.name = "Porch"
	porch.position = Vector2(0, 30)
	porch.polygon = PackedVector2Array([
		Vector2(-44, 0),
		Vector2(0, -18),
		Vector2(44, 0),
		Vector2(0, 18),
	])
	porch.color = Color("#c9a073")
	building.add_child(porch)

	var base := Polygon2D.new()
	base.name = "Base"
	base.polygon = PackedVector2Array([
		Vector2(0, -30),
		Vector2(62, 0),
		Vector2(0, 34),
		Vector2(-62, 0),
	])
	base.color = Color("#d7b184")
	building.add_child(base)

	var wall_shadow := Polygon2D.new()
	wall_shadow.name = "WallShadow"
	wall_shadow.position = Vector2(16, 6)
	wall_shadow.polygon = PackedVector2Array([
		Vector2(0, -18),
		Vector2(34, 0),
		Vector2(0, 18),
		Vector2(-34, 0),
	])
	wall_shadow.color = Color("#bb8b62")
	building.add_child(wall_shadow)

	var roof := Polygon2D.new()
	roof.name = "Roof"
	roof.position = Vector2(0, -42)
	roof.polygon = PackedVector2Array([
		Vector2(0, -38),
		Vector2(84, 0),
		Vector2(0, 38),
		Vector2(-84, 0),
	])
	roof.color = Color("#8c5142")
	building.add_child(roof)

	var roof_cap := Polygon2D.new()
	roof_cap.name = "RoofCap"
	roof_cap.position = Vector2(0, -54)
	roof_cap.polygon = PackedVector2Array([
		Vector2(0, -14),
		Vector2(36, 0),
		Vector2(0, 14),
		Vector2(-36, 0),
	])
	roof_cap.color = Color("#a76554")
	building.add_child(roof_cap)

	var door := Polygon2D.new()
	door.name = "Door"
	door.position = Vector2(0, 8)
	door.polygon = PackedVector2Array([
		Vector2(-8, -14),
		Vector2(8, -14),
		Vector2(8, 12),
		Vector2(-8, 12),
	])
	door.color = Color("#6e4b30")
	building.add_child(door)

	var window_left := Polygon2D.new()
	window_left.name = "WindowLeft"
	window_left.position = Vector2(-22, -2)
	window_left.polygon = PackedVector2Array([
		Vector2(-7, -7),
		Vector2(7, -7),
		Vector2(7, 7),
		Vector2(-7, 7),
	])
	window_left.color = Color("#f3dfa7")
	building.add_child(window_left)

	var window_right := Polygon2D.new()
	window_right.name = "WindowRight"
	window_right.position = Vector2(22, -2)
	window_right.polygon = PackedVector2Array([
		Vector2(-7, -7),
		Vector2(7, -7),
		Vector2(7, 7),
		Vector2(-7, 7),
	])
	window_right.color = Color("#f3dfa7")
	building.add_child(window_right)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(52 * footprint.x, 24 * footprint.y)
	collision.shape = shape
	building.add_child(collision)

func _add_tree(tile: Vector2i) -> void:
	var tree := StaticBody2D.new()
	tree.name = "Tree_%s_%s" % [tile.x, tile.y]
	tree.position = grid_to_world(tile)
	gameplay_layer.add_child(tree)

	var shadow := Polygon2D.new()
	shadow.name = "Shadow"
	shadow.position = Vector2(0, 2)
	shadow.polygon = PackedVector2Array([
		Vector2(-24, 0),
		Vector2(-12, -6),
		Vector2(0, -8),
		Vector2(12, -6),
		Vector2(24, 0),
		Vector2(12, 6),
		Vector2(0, 8),
		Vector2(-12, 6),
	])
	shadow.color = Color(0.12, 0.11, 0.09, 0.18)
	tree.add_child(shadow)

	var trunk := Polygon2D.new()
	trunk.name = "Trunk"
	trunk.polygon = PackedVector2Array([
		Vector2(-8, 0),
		Vector2(8, 0),
		Vector2(10, -34),
		Vector2(4, -42),
		Vector2(-4, -42),
		Vector2(-10, -34),
	])
	trunk.color = Color("#7a5536")
	tree.add_child(trunk)

	var canopy_back := Polygon2D.new()
	canopy_back.name = "CanopyBack"
	canopy_back.position = Vector2(0, -54)
	canopy_back.polygon = PackedVector2Array([
		Vector2(0, -30),
		Vector2(24, -18),
		Vector2(34, 0),
		Vector2(26, 18),
		Vector2(0, 28),
		Vector2(-26, 18),
		Vector2(-34, 0),
		Vector2(-24, -18),
	])
	canopy_back.color = Color("#5f8c56")
	tree.add_child(canopy_back)

	var canopy_front := Polygon2D.new()
	canopy_front.name = "CanopyFront"
	canopy_front.position = Vector2(0, -46)
	canopy_front.polygon = PackedVector2Array([
		Vector2(0, -24),
		Vector2(18, -16),
		Vector2(28, -2),
		Vector2(24, 14),
		Vector2(0, 24),
		Vector2(-24, 14),
		Vector2(-28, -2),
		Vector2(-18, -16),
	])
	canopy_front.color = Color("#82b26e")
	tree.add_child(canopy_front)

	var berry := Polygon2D.new()
	berry.name = "Berry"
	berry.position = Vector2(10, -42)
	berry.polygon = PackedVector2Array([
		Vector2(0, -4),
		Vector2(4, 0),
		Vector2(0, 4),
		Vector2(-4, 0),
	])
	berry.color = Color("#d28c6d")
	tree.add_child(berry)

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
		gameplay_layer.add_child(fence)

		var post_left := Polygon2D.new()
		post_left.name = "PostLeft"
		post_left.position = Vector2(-16, -2)
		post_left.polygon = PackedVector2Array([
			Vector2(-3, -18),
			Vector2(3, -18),
			Vector2(3, 8),
			Vector2(-3, 8),
		])
		post_left.color = Color("#a97749")
		fence.add_child(post_left)

		var post_right := Polygon2D.new()
		post_right.name = "PostRight"
		post_right.position = Vector2(16, -2)
		post_right.polygon = PackedVector2Array([
			Vector2(-3, -18),
			Vector2(3, -18),
			Vector2(3, 8),
			Vector2(-3, 8),
		])
		post_right.color = Color("#a97749")
		fence.add_child(post_right)

		var rail_top := Polygon2D.new()
		rail_top.name = "RailTop"
		rail_top.position = Vector2(0, -10)
		rail_top.polygon = PackedVector2Array([
			Vector2(-22, -4),
			Vector2(22, -4),
			Vector2(22, 2),
			Vector2(-22, 2),
		])
		rail_top.color = Color("#d4ab73")
		fence.add_child(rail_top)

		var rail_bottom := Polygon2D.new()
		rail_bottom.name = "RailBottom"
		rail_bottom.position = Vector2(0, 0)
		rail_bottom.polygon = PackedVector2Array([
			Vector2(-22, -4),
			Vector2(22, -4),
			Vector2(22, 2),
			Vector2(-22, 2),
		])
		rail_bottom.color = Color("#c08a57")
		fence.add_child(rail_bottom)

		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(48, 12)
		collision.shape = shape
		fence.add_child(collision)

func _add_map_bounds() -> void:
	_add_boundary("NorthBoundary", Vector2(20, -88), Vector2(1180, 64))
	_add_boundary("SouthBoundary", Vector2(20, 760), Vector2(1180, 64))
	_add_boundary("WestBoundary", Vector2(-560, 340), Vector2(64, 940))
	_add_boundary("EastBoundaryTop", Vector2(560, 112), Vector2(64, 220))
	_add_boundary("EastBoundaryBottom", Vector2(560, 626), Vector2(64, 150))

func _add_boundary(label: String, boundary_position: Vector2, size: Vector2) -> void:
	var boundary := StaticBody2D.new()
	boundary.name = label
	boundary.position = boundary_position
	gameplay_layer.add_child(boundary)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	boundary.add_child(collision)

func _tile_color(tile: Vector2i) -> Color:
	if tile.x >= 12 and tile.y in PATH_ROW_RANGE:
		return Color("#b59872")
	if tile in get_static_blocked_tiles():
		return Color("#88a56b")
	if (tile.x + tile.y) % 2 == 0:
		return Color("#79aa70")
	return Color("#739f67")

func _tile_highlight_color(tile: Vector2i) -> Color:
	if tile.x >= 12 and tile.y in PATH_ROW_RANGE:
		return Color("#d1b38a")
	if tile in get_static_blocked_tiles():
		return Color("#9abc7f")
	if (tile.x + tile.y) % 2 == 0:
		return Color("#a3c78c")
	return Color("#94be82")

func _tile_patch_color(tile: Vector2i) -> Color:
	if tile.x >= 12 and tile.y in PATH_ROW_RANGE:
		return Color("#8d6b52")
	if (tile.x + tile.y) % 3 == 0:
		return Color("#ba9c5e")
	if (tile.x + tile.y) % 3 == 1:
		return Color("#8ab57a")
	return Color("#c78868")

func _tile_diamond() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0, -TILE_HEIGHT * 0.5),
		Vector2(TILE_WIDTH * 0.5, 0),
		Vector2(0, TILE_HEIGHT * 0.5),
		Vector2(-TILE_WIDTH * 0.5, 0),
	])
