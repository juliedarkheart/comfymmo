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
const BACKDROP_COLOR := Color("#709c5d")
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
				filler.color = Color("#c2a071")
			else:
				filler.color = _apron_color(tile)
			ground_layer.add_child(filler)

func _apron_is_road(tile: Vector2i) -> bool:
	# East road corridor continuing out of the playable core toward village_square.
	return tile.x >= MAP_WIDTH and tile.y in PATH_ROW_RANGE

func _apron_color(tile: Vector2i) -> Color:
	if (tile.x + tile.y) % 2 == 0:
		return Color("#74a25e")
	return Color("#6c9954")

func _build_topology() -> void:
	# Gentle world-shape cues: a road curving toward the village exit, a shallow
	# stream suggestion, distant field hedgerows, and a couple of big foreground
	# trees (beyond the walls) for depth. Flat features sit in the ground layer,
	# under props and the player; foreground occluders go in the gameplay layer.
	TerrainShapes.add_ribbon(
		ground_layer,
		PackedVector2Array([Vector2(20, 352), Vector2(180, 398), Vector2(340, 436), Vector2(540, 470)]),
		22.0, 34.0, Color("#c2a071")
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
	elif roll < 0.48:
		_add_rock(ground_layer, pos)
	elif roll < 0.56:
		_add_mushroom(ground_layer, pos)
	elif roll < 0.74:
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
	# Round toy tree: tapered trunk under three overlapping leaf blobs.
	var tree := Node2D.new()
	tree.position = world_pos
	parent.add_child(tree)
	var trunk := Polygon2D.new()
	trunk.polygon = PackedVector2Array([
		Vector2(-3.5, 0), Vector2(3.5, 0), Vector2(4.5, -20), Vector2(-4.5, -20),
	])
	trunk.color = Color("#8a5e3c")
	tree.add_child(trunk)
	for blob in [
		[Vector2(-11, -28), 10.0, 8.5],
		[Vector2(11, -28), 10.0, 8.5],
		[Vector2(0, -34), 17.0, 14.0],
	]:
		var leaf := Polygon2D.new()
		leaf.polygon = TerrainShapes.ellipse(blob[0], blob[1], blob[2])
		leaf.color = Color("#6f9c5f")
		tree.add_child(leaf)
	var canopy_hi := Polygon2D.new()
	canopy_hi.polygon = TerrainShapes.ellipse(Vector2(-4, -39), 9.0, 6.5)
	canopy_hi.color = Color("#8cba74")
	tree.add_child(canopy_hi)

func _add_shrub(parent: Node2D, world_pos: Vector2) -> void:
	var shrub := Node2D.new()
	shrub.position = world_pos
	parent.add_child(shrub)
	var blob := Polygon2D.new()
	blob.polygon = TerrainShapes.ellipse(Vector2(0, -5), 13.0, 9.5)
	blob.color = Color("#6f9c5f")
	shrub.add_child(blob)
	var hi := Polygon2D.new()
	hi.polygon = TerrainShapes.ellipse(Vector2(-3, -8), 7.0, 4.5)
	hi.color = Color("#8cba74")
	shrub.add_child(hi)
	for berry_pos in [Vector2(5, -7), Vector2(8, -2)]:
		var berry := Polygon2D.new()
		berry.polygon = TerrainShapes.ellipse(berry_pos, 1.8, 1.8, 8)
		berry.color = Color("#d87fa0")
		shrub.add_child(berry)

func _add_rock(parent: Node2D, world_pos: Vector2) -> void:
	var rock := Node2D.new()
	rock.position = world_pos
	parent.add_child(rock)
	var body := Polygon2D.new()
	body.polygon = TerrainShapes.ellipse(Vector2(0, -2), 12.0, 8.0)
	body.color = Color("#a8a49c")
	rock.add_child(body)
	var hi := Polygon2D.new()
	hi.polygon = TerrainShapes.ellipse(Vector2(-3, -5), 5.0, 3.0, 10)
	hi.color = Color("#c2beb4")
	rock.add_child(hi)
	var moss := Polygon2D.new()
	moss.polygon = TerrainShapes.ellipse(Vector2(4, -8), 5.0, 2.5, 10)
	moss.color = Color("#7da964")
	rock.add_child(moss)

func _add_mushroom(parent: Node2D, world_pos: Vector2) -> void:
	# Chunky friendly toadstool: cream stem, terracotta cap, cream speckles.
	var mushroom := Node2D.new()
	mushroom.position = world_pos
	parent.add_child(mushroom)
	var stem := Polygon2D.new()
	stem.polygon = TerrainShapes.ellipse(Vector2(0, -4), 3.5, 4.5, 10)
	stem.color = Color("#f2e4c8")
	mushroom.add_child(stem)
	var cap := Polygon2D.new()
	cap.polygon = TerrainShapes.dome(Vector2(0, -6), 8.0, 7.0, 10)
	cap.color = Color("#c87858")
	mushroom.add_child(cap)
	for dot_pos in [Vector2(-3.5, -9), Vector2(2, -11), Vector2(4.5, -8)]:
		var dot := Polygon2D.new()
		dot.polygon = TerrainShapes.ellipse(dot_pos, 1.4, 1.4, 8)
		dot.color = Color("#f2e4c8")
		mushroom.add_child(dot)

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
	return IsoMapHelpers.grid_to_world(tile, TILE_WIDTH, TILE_HEIGHT)

func world_to_grid(position: Vector2) -> Vector2i:
	return IsoMapHelpers.world_to_grid(position, TILE_WIDTH, TILE_HEIGHT)

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

func _add_building(origin: Vector2i, footprint: Vector2i, _color: Color, label: String) -> void:
	# A front-facing toy cottage: domed rosy roof with an overhang, cream walls,
	# round windows with flower boxes, an arched door, and a smoking chimney.
	# Drawn billboard-style on an iso ground pad so it reads instantly as "home"
	# at gameplay zoom. The StaticBody2D root, node name, and collision rect are
	# unchanged from the old block version.
	var building := StaticBody2D.new()
	building.name = label
	building.position = grid_to_world(origin)
	gameplay_layer.add_child(building)

	var pad := Polygon2D.new()
	pad.name = "GroundPad"
	pad.position = Vector2(0, 30)
	pad.polygon = PackedVector2Array([
		Vector2(-68, 0), Vector2(0, -26), Vector2(68, 0), Vector2(0, 26),
	])
	pad.color = Color("#d8b58a")
	building.add_child(pad)

	var wall := Polygon2D.new()
	wall.name = "Wall"
	wall.polygon = PackedVector2Array([
		Vector2(-46, -26), Vector2(46, -26), Vector2(54, -18), Vector2(54, 22),
		Vector2(46, 30), Vector2(-46, 30), Vector2(-54, 22), Vector2(-54, -18),
	])
	wall.color = Color("#f2dfb8")
	building.add_child(wall)

	var wall_base := Polygon2D.new()
	wall_base.name = "WallBase"
	wall_base.polygon = PackedVector2Array([
		Vector2(-52, 24), Vector2(52, 24), Vector2(46, 30), Vector2(-46, 30),
	])
	wall_base.color = Color("#d9c39a")
	building.add_child(wall_base)

	# Round windows with warm glass and flower boxes.
	for wx: float in [-32.0, 32.0]:
		var frame := Polygon2D.new()
		frame.polygon = TerrainShapes.ellipse(Vector2(wx, -2), 10.5, 10.5)
		frame.color = Color("#d2ab7e")
		building.add_child(frame)
		var glass := Polygon2D.new()
		glass.polygon = TerrainShapes.ellipse(Vector2(wx, -2), 7.5, 7.5)
		glass.color = Color("#f7dfa0")
		building.add_child(glass)
		var mullion := Polygon2D.new()
		mullion.polygon = PackedVector2Array([
			Vector2(wx - 7.5, -3), Vector2(wx + 7.5, -3), Vector2(wx + 7.5, -1), Vector2(wx - 7.5, -1),
		])
		mullion.color = Color("#d2ab7e")
		building.add_child(mullion)
		var box := Polygon2D.new()
		box.polygon = PackedVector2Array([
			Vector2(wx - 9, 9), Vector2(wx + 9, 9), Vector2(wx + 8, 15), Vector2(wx - 8, 15),
		])
		box.color = Color("#a87848")
		building.add_child(box)
		var bloom_colors: Array = [Color("#e8a0b4"), Color("#f2e4c8"), Color("#b49ad0")]
		for b in range(3):
			var bloom := Polygon2D.new()
			bloom.polygon = TerrainShapes.ellipse(Vector2(wx - 5 + b * 5, 7), 2.4, 2.4, 8)
			bloom.color = bloom_colors[b]
			building.add_child(bloom)

	# Arched door with a peek window and a brass knob.
	var door_frame := Polygon2D.new()
	door_frame.name = "DoorFrame"
	var door_frame_points: PackedVector2Array = TerrainShapes.dome(Vector2(0, 6), 13.0, 14.0)
	door_frame_points.append(Vector2(13, 30))
	door_frame_points.append(Vector2(-13, 30))
	door_frame.polygon = door_frame_points
	door_frame.color = Color("#d2ab7e")
	building.add_child(door_frame)

	var door := Polygon2D.new()
	door.name = "Door"
	var door_points: PackedVector2Array = TerrainShapes.dome(Vector2(0, 6), 10.0, 11.0)
	door_points.append(Vector2(10, 30))
	door_points.append(Vector2(-10, 30))
	door.polygon = door_points
	door.color = Color("#8a5a3a")
	building.add_child(door)

	var door_window := Polygon2D.new()
	door_window.polygon = TerrainShapes.ellipse(Vector2(0, 2), 3.2, 3.2, 10)
	door_window.color = Color("#f7dfa0")
	building.add_child(door_window)

	var knob := Polygon2D.new()
	knob.polygon = TerrainShapes.ellipse(Vector2(5.5, 16), 1.6, 1.6, 8)
	knob.color = Color("#d4a84a")
	building.add_child(knob)

	# Big domed roof with overhang, highlight, and a cream eave trim.
	var roof := Polygon2D.new()
	roof.name = "Roof"
	roof.polygon = TerrainShapes.dome(Vector2(0, -26), 70.0, 56.0, 16)
	roof.color = Color("#c97a6a")
	building.add_child(roof)

	var roof_highlight := Polygon2D.new()
	roof_highlight.name = "RoofHighlight"
	roof_highlight.polygon = TerrainShapes.dome(Vector2(-6, -30), 48.0, 40.0, 14)
	roof_highlight.color = Color("#d68d7c")
	building.add_child(roof_highlight)

	var eave := Polygon2D.new()
	eave.name = "EaveTrim"
	eave.polygon = PackedVector2Array([
		Vector2(-72, -28), Vector2(72, -28), Vector2(68, -21), Vector2(-68, -21),
	])
	eave.color = Color("#e8cfa8")
	building.add_child(eave)

	# Chimney with a soft smoke trail.
	var chimney := Polygon2D.new()
	chimney.name = "Chimney"
	chimney.polygon = PackedVector2Array([
		Vector2(30, -90), Vector2(44, -90), Vector2(44, -60), Vector2(30, -64),
	])
	chimney.color = Color("#c99181")
	building.add_child(chimney)

	var chimney_cap := Polygon2D.new()
	chimney_cap.name = "ChimneyCap"
	chimney_cap.polygon = TerrainShapes.ellipse(Vector2(37, -91), 9.0, 3.5, 10)
	chimney_cap.color = Color("#dfae9d")
	building.add_child(chimney_cap)

	var smoke_small := Polygon2D.new()
	smoke_small.polygon = TerrainShapes.ellipse(Vector2(41, -102), 4.5, 3.5, 10)
	smoke_small.color = Color(0.95, 0.95, 0.97, 0.5)
	building.add_child(smoke_small)

	var smoke_big := Polygon2D.new()
	smoke_big.polygon = TerrainShapes.ellipse(Vector2(47, -113), 6.5, 5.0, 10)
	smoke_big.color = Color(0.95, 0.95, 0.97, 0.32)
	building.add_child(smoke_big)

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
	trunk.color = Color("#8a5e3c")
	tree.add_child(trunk)

	# Round overlapping leaf blobs instead of faceted diamonds.
	var canopy_back := Polygon2D.new()
	canopy_back.name = "CanopyBack"
	canopy_back.polygon = TerrainShapes.ellipse(Vector2(0, -58), 32.0, 26.0, 20)
	canopy_back.color = Color("#5f8c56")
	tree.add_child(canopy_back)

	for blob in [
		[Vector2(-19, -48), 15.0, 12.0],
		[Vector2(19, -48), 15.0, 12.0],
		[Vector2(0, -62), 22.0, 17.0],
	]:
		var leaf := Polygon2D.new()
		leaf.polygon = TerrainShapes.ellipse(blob[0], blob[1], blob[2])
		leaf.color = Color("#6f9c5f")
		tree.add_child(leaf)

	var canopy_hi := Polygon2D.new()
	canopy_hi.name = "CanopyHighlight"
	canopy_hi.polygon = TerrainShapes.ellipse(Vector2(-7, -67), 12.0, 8.0)
	canopy_hi.color = Color("#8cba74")
	tree.add_child(canopy_hi)

	for berry_data in [Vector2(12, -52), Vector2(-14, -46), Vector2(4, -44)]:
		var berry := Polygon2D.new()
		berry.polygon = TerrainShapes.ellipse(berry_data, 2.4, 2.4, 8)
		berry.color = Color("#d87fa0")
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
		return Color("#c2a071")
	if tile in get_static_blocked_tiles():
		return Color("#8cab66")
	if (tile.x + tile.y) % 2 == 0:
		return Color("#80ad68")
	return Color("#78a35e")

func _tile_highlight_color(tile: Vector2i) -> Color:
	if tile.x >= 12 and tile.y in PATH_ROW_RANGE:
		return Color("#dcc193")
	if tile in get_static_blocked_tiles():
		return Color("#9fc27c")
	if (tile.x + tile.y) % 2 == 0:
		return Color("#a9cd87")
	return Color("#9cc479")

func _tile_patch_color(tile: Vector2i) -> Color:
	# Quiet straw/green variations only — saturated warm accents on every tile read
	# as clutter at overworld zoom, so accents are left to flowers and props.
	if tile.x >= 12 and tile.y in PATH_ROW_RANGE:
		return Color("#96754f")
	if (tile.x + tile.y) % 3 == 0:
		return Color("#aaa763")
	if (tile.x + tile.y) % 3 == 1:
		return Color("#8cba78")
	return Color("#94b66d")

func _tile_diamond() -> PackedVector2Array:
	return IsoMapHelpers.tile_diamond(TILE_WIDTH, TILE_HEIGHT)
