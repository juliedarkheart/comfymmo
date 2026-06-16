extends HomesteadMap
class_name OverworldMap

## The continuous outdoor overworld. It reuses HomesteadMap's grid/placement/
## collision/prop helpers (so building placement and farming keep working in the
## homestead area at the origin) and draws homestead, village, and forest as one
## connected landscape with roads, natural borders, and wilderness fill. There is
## no outdoor region paging — this is a single scene.
##
## INHERITANCE NOTE (transitional): `extends HomesteadMap` reuses the homestead grid
## (the placement/farming grid still lives at the origin) and its prop drawers. This
## is intentional and stable for now; a future cleaner split would extract a shared
## `IsoMapHelpers` for grid math + prop drawers. See docs/overworld_architecture.md.

const VILLAGE_OFFSET := Vector2(1500.0, 120.0)
const FOREST_OFFSET := Vector2(3000.0, 160.0)
const OW_SEED: int = 1337
const TERRAIN_PAINT_IDS: Array[String] = [
	"meadow", "forest", "orchard", "creekside", "hilltop", "grove",
	"town", "farmland", "dirt_path", "stone_path", "water",
]

var _terrain_override_layer: Node2D = null
var _terrain_override_nodes: Dictionary = {}

func _ready() -> void:
	_build_overworld()

func get_camera_limits() -> Rect2i:
	# Framed to whatever the world actually contains (core + every homestead lot +
	# town + forest), so the camera always reveals the full large neighborhood
	# instead of a hand-tuned box. Grows as plots are added.
	var bounds: Rect2 = _content_bounds_world().grow(260.0)
	return Rect2i(bounds)

## Bounding box (world px) of a tile rect's projected iso diamond.
func _projected_bounds(rect: Rect2i) -> Rect2:
	var corners: Array = [
		grid_to_world(rect.position),
		grid_to_world(Vector2i(rect.end.x - 1, rect.position.y)),
		grid_to_world(Vector2i(rect.position.x, rect.end.y - 1)),
		grid_to_world(Vector2i(rect.end.x - 1, rect.end.y - 1)),
	]
	var min_p: Vector2 = corners[0]
	var max_p: Vector2 = corners[0]
	for c in corners:
		min_p = min_p.min(c as Vector2)
		max_p = max_p.max(c as Vector2)
	return Rect2(min_p, max_p - min_p)

## Union (world px) of the homestead core, every static plot (grown by the path
## margin), and the fixed town/forest areas — the real extent of the world.
func _content_bounds_world() -> Rect2:
	var bounds: Rect2 = _projected_bounds(Rect2i(0, 0, MAP_WIDTH, MAP_HEIGHT))
	for rect_variant in LandRegistry.all_plot_rects():
		bounds = bounds.merge(_projected_bounds((rect_variant as Rect2i).grow(PLOT_BOUNDS_MARGIN)))
	for area in WorldAreaRegistry.areas():
		bounds = bounds.merge(area["rect"] as Rect2)
	return bounds

func get_camera_zoom() -> Vector2:
	# Slightly closer than 1.0 for readable detail on high-DPI / 4K monitors. Players
	# can adjust live with PageUp/PageDown/+/- and reset with R.
	return Vector2(1.3, 1.3)

func _build_overworld() -> void:
	_build_overworld_backdrop()
	_build_region_tints()
	_build_ground()                 # inherited: detailed homestead yard tiles at origin
	_build_neighborhood_ground()    # buildable ground for the neighborhood plots
	_build_natural_borders()
	_build_connecting_roads()
	_build_village_area()
	_build_forest_area()
	_build_overworld_wilderness()
	_ensure_terrain_override_layer()
	_build_homestead_colliders()    # inherited: cottage, trees, fence (homestead area)
	_build_overworld_bounds()

## The neighborhood is a second buildable region east and south of the core
## (the original homestead grid stays Rowan's training land). is_tile_in_bounds
## treats both the core AND these rects as placeable; tiles outside both remain
## structurally unbuildable (so town/forest can never be built on).
## Build margin around plots so there's walkable/buildable path access.
const PLOT_BOUNDS_MARGIN := 2

func is_tile_in_bounds(tile: Vector2i) -> bool:
	if tile.x >= 0 and tile.x < MAP_WIDTH and tile.y >= 0 and tile.y < MAP_HEIGHT:
		return true
	# Any plot rect (static OR runtime/editor), grown by a path margin, is
	# buildable. Querying LandRegistry means editor-created plots are placeable
	# the moment they exist.
	for rect_variant in LandRegistry.all_plot_rects():
		if (rect_variant as Rect2i).grow(PLOT_BOUNDS_MARGIN).has_point(tile):
			return true
	return false

## Draw cozy biome-tinted ground for each plot region (so the spread-out lots
## read as real yards on the green backdrop), plus dirt roads linking them to
## the core. Visual only — placement validity is governed by is_tile_in_bounds.
## Road corridors as tile waypoints. They run ONLY through the gutters between
## the homestead lots (never across a lot) — validated in tools/validate_project.
## A connector drops from the core into the neighborhood, then a + of avenues
## threads the gaps.
static func road_corridors() -> Array:
	return [
		[Vector2i(10, 12), Vector2i(15, 16)],     # core -> neighborhood
		[Vector2i(15, 16), Vector2i(15, 90)],     # avenue between centre & east cols
		[Vector2i(-22, 16), Vector2i(-22, 90)],   # avenue between west & centre cols
		[Vector2i(-58, 53), Vector2i(52, 53)],    # mid avenue between the two rows
	]

## Every integer tile a road passes through (for overlap validation).
static func road_sample_tiles() -> Array:
	var tiles: Array = []
	for corridor in road_corridors():
		for i in range((corridor as Array).size() - 1):
			var a: Vector2i = corridor[i]
			var b: Vector2i = corridor[i + 1]
			var steps: int = maxi(absi(b.x - a.x), absi(b.y - a.y))
			for s in range(steps + 1):
				var t: float = float(s) / float(maxi(steps, 1))
				tiles.append(Vector2i(roundi(lerpf(a.x, b.x, t)), roundi(lerpf(a.y, b.y, t))))
	return tiles

func _build_neighborhood_ground() -> void:
	for plot in LandRegistry.definitions().values():
		paint_plot_ground(plot as Dictionary)
	# Cozy dirt avenues through the gutters between the lots.
	for corridor in road_corridors():
		var pts: PackedVector2Array = PackedVector2Array()
		for t in corridor:
			pts.append(grid_to_world(t as Vector2i))
		TerrainShapes.add_ribbon(ground_layer, pts, 20.0, 20.0, BiomeRegistry.path_color("dirt_path"))

## Paint one plot's biome-tinted ground patch (a 1-tile skirt around the rect).
## Public so the in-game world-builder can draw a plot the moment it's created,
## not just at boot. Core homestead tiles are never repainted (they keep their
## detailed yard art). Returns the container node so callers can free it later.
func paint_plot_ground(plot: Dictionary) -> Node2D:
	var rect_variant: Variant = plot.get("rect", null)
	if not (rect_variant is Rect2i):
		return null
	var r: Rect2i = (rect_variant as Rect2i).grow(1)
	var base: Color = LandRegistry.biome_color(String(plot.get("biome", "meadow")))
	var alt: Color = base.darkened(0.06)
	var patch := Node2D.new()
	patch.name = "PlotGround_%s" % String(plot.get("plot_id", "plot"))
	patch.z_index = -8
	ground_layer.add_child(patch)
	for ty in range(r.position.y, r.end.y):
		for tx in range(r.position.x, r.end.x):
			if tx >= 0 and tx < MAP_WIDTH and ty >= 0 and ty < MAP_HEIGHT:
				continue  # don't repaint the homestead core
			var tile := Vector2i(tx, ty)
			var ground := Polygon2D.new()
			ground.position = grid_to_world(tile)
			ground.polygon = _tile_diamond()
			ground.color = base if (tx + ty) % 2 == 0 else alt
			_add_terrain_sprite(ground, String(plot.get("biome", "meadow")), tile)
			patch.add_child(ground)
	return patch

func terrain_paint_ids() -> Array:
	return TERRAIN_PAINT_IDS.duplicate()

static func supports_terrain_paint_id(terrain_id: String) -> bool:
	return TERRAIN_PAINT_IDS.has(String(terrain_id).to_lower())

func clear_terrain_overrides() -> void:
	for node_variant in _terrain_override_nodes.values():
		var node: Node = node_variant as Node
		if node != null and is_instance_valid(node):
			node.free()
	_terrain_override_nodes.clear()

func terrain_override_count() -> int:
	return _terrain_override_nodes.size()

func set_terrain_overrides(overrides: Dictionary) -> void:
	_ensure_terrain_override_layer()
	clear_terrain_overrides()
	for key_variant in overrides.keys():
		var terrain_id: String = String(overrides.get(key_variant, "")).to_lower()
		if not supports_terrain_paint_id(terrain_id):
			continue
		var tile_variant: Variant = _tile_from_key(String(key_variant))
		if not (tile_variant is Vector2i):
			continue
		_paint_terrain_override(tile_variant as Vector2i, terrain_id)

func _ensure_terrain_override_layer() -> void:
	if _terrain_override_layer != null and is_instance_valid(_terrain_override_layer):
		return
	_terrain_override_layer = Node2D.new()
	_terrain_override_layer.name = "TerrainOverrideLayer"
	_terrain_override_layer.z_index = -6
	ground_layer.add_child(_terrain_override_layer)

func _paint_terrain_override(tile: Vector2i, terrain_id: String) -> void:
	var key: String = _tile_key(tile)
	var node := Node2D.new()
	node.name = "TerrainOverride_%s" % key
	node.position = grid_to_world(tile)
	_terrain_override_layer.add_child(node)
	var base := Polygon2D.new()
	base.polygon = _tile_diamond()
	base.color = _terrain_base_color(terrain_id, tile)
	node.add_child(base)
	_add_terrain_sprite(node, terrain_id, tile)
	if terrain_id == "dirt_path" or terrain_id == "stone_path":
		var inset := Polygon2D.new()
		inset.polygon = PackedVector2Array([
			Vector2(0, -9),
			Vector2(20, 0),
			Vector2(0, 9),
			Vector2(-20, 0),
		])
		inset.color = _terrain_detail_color(terrain_id)
		node.add_child(inset)
	elif terrain_id == "water":
		var ripple := Polygon2D.new()
		ripple.polygon = TerrainShapes.ellipse(Vector2(0, 0), 18.0, 8.0, 16)
		ripple.color = Color(0.92, 0.98, 1.0, 0.38)
		node.add_child(ripple)
		var edge := Line2D.new()
		edge.closed = true
		edge.width = 1.6
		edge.default_color = Color("#d8f2ff")
		edge.points = PackedVector2Array([
			Vector2(0, -12),
			Vector2(25, 0),
			Vector2(0, 12),
			Vector2(-25, 0),
		])
		node.add_child(edge)
	_terrain_override_nodes[key] = node

func _tile_from_key(key: String) -> Variant:
	var parts: PackedStringArray = key.split(",")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return null
	return Vector2i(int(parts[0]), int(parts[1]))

func _tile_key(tile: Vector2i) -> String:
	return "%d,%d" % [tile.x, tile.y]

func _terrain_base_color(terrain_id: String, tile: Vector2i) -> Color:
	var tone: Color = BiomeRegistry.terrain_color(terrain_id, (tile.x + tile.y) % 2 != 0)
	var opaque_terrain: Array[String] = ["dirt_path", "stone_path", "water"]
	tone.a = 0.88 if opaque_terrain.has(terrain_id) else 0.72
	return tone

func _terrain_detail_color(terrain_id: String) -> Color:
	return BiomeRegistry.terrain_detail_color(terrain_id)

func _build_overworld_backdrop() -> void:
	var limits: Rect2i = get_camera_limits()
	var m: float = 240.0
	var bg: Polygon2D = Polygon2D.new()
	bg.name = "OverworldBackdrop"
	bg.polygon = PackedVector2Array([
		Vector2(limits.position.x - m, limits.position.y - m),
		Vector2(limits.end.x + m, limits.position.y - m),
		Vector2(limits.end.x + m, limits.end.y + m),
		Vector2(limits.position.x - m, limits.end.y + m),
	])
	bg.color = BiomeRegistry.terrain_color("meadow").darkened(0.08)
	ground_layer.add_child(bg)

func _build_region_tints() -> void:
	# Broad terrain color forms so the three areas read as distinct land without hard
	# seams (homestead meadow, village outskirts, forest floor).
	TerrainShapes.add_disc(ground_layer, Vector2(60, 300), 760, 16, BiomeRegistry.terrain_color("meadow"), 0.62)
	TerrainShapes.add_disc(ground_layer, VILLAGE_OFFSET + Vector2(96, 272), 720, 16, BiomeRegistry.terrain_color("town"), 0.62)
	TerrainShapes.add_disc(ground_layer, FOREST_OFFSET + Vector2(40, 260), 840, 16, BiomeRegistry.terrain_color("forest"), 0.62)

func _build_natural_borders() -> void:
	# All borders are derived from the actual world bounds and drawn JUST OUTSIDE
	# the south/north edges, so they always read as distant scenery and can never
	# become a "grey line" cutting through play (root cause of the old artifact: a
	# fixed-position desaturated ribbon ended up mid-map when the walls moved).
	var bounds: Rect2 = _content_bounds_world()
	var cx: float = bounds.position.x + bounds.size.x * 0.5
	# Distant soft mountains beyond the north edge.
	var north_y: float = bounds.position.y - 220.0
	var step: float = bounds.size.x / 9.0
	for i in range(10):
		var x: float = bounds.position.x + i * step
		TerrainShapes.add_disc(ground_layer, Vector2(x, north_y), 280, 7, Color("#84899e"), 0.5)
		TerrainShapes.add_disc(ground_layer, Vector2(x + 130, north_y + 60), 200, 7, Color("#9aa1b4"), 0.5)
	# A clear blue river hugging the south edge, well past the south wall.
	var river_y: float = bounds.end.y + 180.0
	TerrainShapes.add_ribbon(
		ground_layer,
		PackedVector2Array([
			Vector2(bounds.position.x - 200, river_y - 30), Vector2(cx - 600, river_y + 30),
			Vector2(cx, river_y - 20), Vector2(cx + 700, river_y + 30), Vector2(bounds.end.x + 200, river_y - 10),
		]),
		64.0, 70.0, BiomeRegistry.water_color()
	)
	# Forest wall east, soft cliff west.
	TerrainShapes.add_disc(ground_layer, Vector2(bounds.end.x + 60, bounds.position.y + bounds.size.y * 0.4), 460, 12, Color("#3f6a3c"), 0.7)
	TerrainShapes.add_disc(ground_layer, Vector2(bounds.position.x - 40, bounds.position.y + bounds.size.y * 0.5), 320, 8, Color("#8b8780"), 0.62)

func _build_connecting_roads() -> void:
	TerrainShapes.add_ribbon(
		ground_layer,
		PackedVector2Array([Vector2(-60, 300), Vector2(320, 420), Vector2(820, 440), Vector2(1300, 392), Vector2(1596, 392)]),
		30.0, 30.0, BiomeRegistry.path_color("dirt_path")
	)
	TerrainShapes.add_ribbon(
		ground_layer,
		PackedVector2Array([Vector2(1596, 392), Vector2(2100, 420), Vector2(2600, 360), Vector2(3060, 326)]),
		28.0, 24.0, BiomeRegistry.terrain_color("road", true)
	)

func _build_village_area() -> void:
	var c: Vector2 = VILLAGE_OFFSET
	TerrainShapes.add_disc(ground_layer, c + Vector2(96, 290), 108, 8, Color("#a08a66"), 0.5)
	TerrainShapes.add_disc(ground_layer, c + Vector2(96, 286), 100, 8, Color("#cdbb93"), 0.5)
	TerrainShapes.add_disc(ground_layer, c + Vector2(96, 282), 68, 8, Color("#ddd0ab"), 0.5)
	_add_overworld_fountain(c + Vector2(96, 272))
	_add_market_stall(c + Vector2(-70, 240))
	for off in [Vector2(-150, 110), Vector2(270, 140), Vector2(-90, 470), Vector2(310, 430)]:
		_add_decor_tree(gameplay_layer, c + off)

func _add_market_stall(world_pos: Vector2) -> void:
	# Visual-only village dressing: a little market stand with a striped awning
	# and a basket of produce. No collision, no interaction.
	var stall: Node2D = Node2D.new()
	stall.position = world_pos
	gameplay_layer.add_child(stall)
	var counter: Polygon2D = Polygon2D.new()
	counter.color = Color("#c89a64")
	counter.polygon = PackedVector2Array([
		Vector2(-28, -16), Vector2(28, -16), Vector2(30, -2), Vector2(26, 2), Vector2(-26, 2), Vector2(-30, -2),
	])
	stall.add_child(counter)
	var counter_top: Polygon2D = Polygon2D.new()
	counter_top.color = Color("#e0bf8a")
	counter_top.polygon = PackedVector2Array([
		Vector2(-30, -18), Vector2(30, -18), Vector2(30, -14), Vector2(-30, -14),
	])
	stall.add_child(counter_top)
	for px: float in [-25.0, 25.0]:
		var post: Polygon2D = Polygon2D.new()
		post.color = Color("#8a5e3c")
		post.polygon = PackedVector2Array([
			Vector2(px - 2, -18), Vector2(px + 2, -18), Vector2(px + 2, -46), Vector2(px - 2, -46),
		])
		stall.add_child(post)
	# Striped awning: alternating pink/cream panels with scalloped bumps.
	var stripe_colors: Array = [Color("#e8a0b4"), Color("#f2e4c8")]
	for s in range(6):
		var x0: float = -30.0 + s * 10.0
		var stripe: Polygon2D = Polygon2D.new()
		stripe.color = stripe_colors[s % 2]
		stripe.polygon = PackedVector2Array([
			Vector2(x0, -54), Vector2(x0 + 10, -54), Vector2(x0 + 10, -44), Vector2(x0, -44),
		])
		stall.add_child(stripe)
		var scallop: Polygon2D = Polygon2D.new()
		scallop.color = stripe_colors[s % 2]
		scallop.polygon = TerrainShapes.ellipse(Vector2(x0 + 5, -44), 5.0, 3.5, 10)
		stall.add_child(scallop)
	# Basket of produce on the counter.
	var basket: Polygon2D = Polygon2D.new()
	basket.color = Color("#a87848")
	basket.polygon = TerrainShapes.ellipse(Vector2(8, -20), 8.0, 4.5, 12)
	stall.add_child(basket)
	for produce in [
		[Vector2(4, -23), Color("#f0945a")],
		[Vector2(9, -24), Color("#cdb4dd")],
		[Vector2(13, -22), Color("#d87fa0")],
	]:
		var item: Polygon2D = Polygon2D.new()
		item.color = produce[1]
		item.polygon = TerrainShapes.ellipse(produce[0], 2.6, 2.6, 8)
		stall.add_child(item)

func _build_forest_area() -> void:
	var c: Vector2 = FOREST_OFFSET
	var shrine: Vector2 = c + Vector2(136, 166)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = OW_SEED
	for i in range(42):
		var p: Vector2 = c + Vector2(rng.randf_range(-380, 540), rng.randf_range(-140, 470))
		if p.distance_to(shrine) < 96.0:
			continue
		_add_overworld_pine(gameplay_layer, p)
	for i in range(8):
		_add_rock(gameplay_layer, c + Vector2(rng.randf_range(-320, 500), rng.randf_range(20, 440)))
	for i in range(10):
		_add_mushroom(gameplay_layer, c + Vector2(rng.randf_range(-340, 520), rng.randf_range(0, 460)))

func _build_overworld_wilderness() -> void:
	# Sparse deterministic countryside between the anchors so the land never reads as
	# empty. Drawn in the ground layer (behind props/player), visual only.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = OW_SEED + 7
	for i in range(190):
		var p: Vector2 = Vector2(rng.randf_range(-700, 3760), rng.randf_range(-180, 880))
		var roll: float = rng.randf()
		if roll < 0.40:
			_add_grass_tuft(rng, ground_layer, p)
		elif roll < 0.62:
			_add_shrub(ground_layer, p)
		elif roll < 0.72:
			_add_mushroom(ground_layer, p)
		elif roll < 0.88:
			_add_flowers(rng, ground_layer, p)
		else:
			_add_decor_tree(ground_layer, p)

func _build_overworld_bounds() -> void:
	# Walls are derived from the world's actual content bounds (+ a margin) and
	# overlap at the corners so the player can't slip out. They expand automatically
	# with the homestead lots — no hand-tuned magic numbers to drift out of sync.
	var b: Rect2 = _content_bounds_world().grow(120.0)
	var cx: float = b.position.x + b.size.x * 0.5
	var cy: float = b.position.y + b.size.y * 0.5
	_add_boundary("OW_North", Vector2(cx, b.position.y), Vector2(b.size.x + 200.0, 80))
	_add_boundary("OW_South", Vector2(cx, b.end.y), Vector2(b.size.x + 200.0, 80))
	_add_boundary("OW_West", Vector2(b.position.x, cy), Vector2(80, b.size.y + 200.0))
	_add_boundary("OW_East", Vector2(b.end.x, cy), Vector2(80, b.size.y + 200.0))

func _add_overworld_fountain(world_pos: Vector2) -> void:
	# Soft round stone fountain: ellipse basin, rim, water, sparkles, and a
	# little center column with a bubbling spout.
	var fountain: Node2D = Node2D.new()
	fountain.position = world_pos
	gameplay_layer.add_child(fountain)
	var base: Polygon2D = Polygon2D.new()
	base.color = Color("#c9c7d1")
	base.polygon = TerrainShapes.ellipse(Vector2(0, 6), 36.0, 19.0, 20)
	fountain.add_child(base)
	var rim: Polygon2D = Polygon2D.new()
	rim.color = Color("#dcdae2")
	rim.polygon = TerrainShapes.ellipse(Vector2(0, 2), 30.0, 15.0, 20)
	fountain.add_child(rim)
	var water: Polygon2D = Polygon2D.new()
	water.color = Color("#7db5cf")
	water.polygon = TerrainShapes.ellipse(Vector2(0, 1), 25.0, 12.0, 20)
	fountain.add_child(water)
	for sparkle_data in [Vector2(-9, -2), Vector2(7, 3)]:
		var sparkle: Polygon2D = Polygon2D.new()
		sparkle.color = Color(0.92, 0.97, 1.0, 0.75)
		sparkle.polygon = TerrainShapes.ellipse(sparkle_data, 3.5, 1.6, 8)
		fountain.add_child(sparkle)
	var post: Polygon2D = Polygon2D.new()
	post.color = Color("#b5aa9a")
	post.polygon = PackedVector2Array([Vector2(-5, -8), Vector2(5, -8), Vector2(4, -42), Vector2(-4, -42)])
	fountain.add_child(post)
	var post_cap: Polygon2D = Polygon2D.new()
	post_cap.color = Color("#c9bfae")
	post_cap.polygon = TerrainShapes.ellipse(Vector2(0, -43), 7.0, 3.0, 10)
	fountain.add_child(post_cap)
	var spout: Polygon2D = Polygon2D.new()
	spout.color = Color("#9fc6da")
	spout.polygon = TerrainShapes.ellipse(Vector2(0, -49), 4.5, 4.0, 10)
	fountain.add_child(spout)

func _add_overworld_pine(parent: Node2D, world_pos: Vector2) -> void:
	# Cute rounded pine: stacked soft tiers getting lighter toward the top.
	var pine: Node2D = Node2D.new()
	pine.position = world_pos
	parent.add_child(pine)
	var trunk: Polygon2D = Polygon2D.new()
	trunk.color = Color("#8a5e3c")
	trunk.polygon = PackedVector2Array([Vector2(-4.5, 0), Vector2(4.5, 0), Vector2(6, -24), Vector2(-6, -24)])
	pine.add_child(trunk)
	for tier in [
		[Vector2(0, -30), 22.0, 13.0, Color("#48763f")],
		[Vector2(0, -46), 17.0, 11.0, Color("#5f9150")],
		[Vector2(0, -60), 12.0, 9.0, Color("#79a865")],
		[Vector2(0, -71), 6.5, 6.0, Color("#8cba74")],
	]:
		var layer: Polygon2D = Polygon2D.new()
		layer.polygon = TerrainShapes.ellipse(tier[0], tier[1], tier[2])
		layer.color = tier[3]
		pine.add_child(layer)
