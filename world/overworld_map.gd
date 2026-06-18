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
# Distant background scenery (backdrop, region tints, borders, connecting roads)
# lives below the terrain tiles so the top-down tile sprites are never hidden by
# the broad procedural color fills.
var _background_layer: Node2D = null

const LIMEZU_GROUND_LAYER_Z := -100
const LIMEZU_GAMEPLAY_LAYER_Z := 0
const LIMEZU_GROUND_GRASS_Z := -30
const LIMEZU_GROUND_PATH_Z := -24
const LIMEZU_GROUND_SOIL_Z := -22
const LIMEZU_PLAYABLE_AREA_BOUNDS := Rect2i(-8, -4, 42, 30)
const LIMEZU_CURATED_PATH_TILES: Array[Vector2i] = [
	Vector2i(7, 14),
	Vector2i(8, 14),
	Vector2i(9, 14),
	Vector2i(10, 14),
	Vector2i(11, 14),
	Vector2i(12, 14),
]
const LIMEZU_APPROACH_PATH_TILES: Array[Vector2i] = [
	Vector2i(12, 15),
	Vector2i(13, 16),
	Vector2i(14, 16),
	Vector2i(15, 16),
	Vector2i(16, 17),
	Vector2i(17, 17),
	Vector2i(18, 18),
	Vector2i(19, 18),
	Vector2i(20, 18),
]
const LIMEZU_TILLED_SOIL_RECT := Rect2i(2, 12, 3, 3)
const LIMEZU_BARN_VISUAL_FOOTPRINT := Rect2i(9, 4, 9, 10)
const LIMEZU_CRATE_VISUAL_FOOTPRINT := Rect2i(10, 13, 1, 1)
const LIMEZU_SIGN_VISUAL_FOOTPRINTS: Array[Rect2i] = [
	Rect2i(9, 11, 1, 2),
]
const LIMEZU_EDGE_TREE_TILES: Array[Vector2i] = [
	Vector2i(29, 8),
	Vector2i(31, 18),
	Vector2i(25, 23),
]
const LIMEZU_EDGE_SMALL_TREE_TILES: Array[Vector2i] = [
	Vector2i(27, 7),
	Vector2i(29, 20),
	Vector2i(18, 24),
	Vector2i(10, 24),
]
const LIMEZU_EDGE_FLOWER_TILES: Array[Vector2i] = [
	Vector2i(23, 12),
	Vector2i(25, 18),
	Vector2i(22, 22),
	Vector2i(28, 23),
	Vector2i(16, 24),
	Vector2i(12, 23),
	Vector2i(15, 25),
	Vector2i(20, 24),
]
const LIMEZU_EDGE_FENCE_TILES: Array[Vector2i] = [
	Vector2i(27, 15),
	Vector2i(28, 15),
	Vector2i(29, 15),
	Vector2i(30, 15),
	Vector2i(13, 25),
	Vector2i(14, 25),
	Vector2i(15, 25),
	Vector2i(16, 25),
]
const LIMEZU_EDGE_CRATE_TILES: Array[Vector2i] = [
	Vector2i(26, 17),
	Vector2i(18, 24),
]
const LIMEZU_PROP_VISUAL_FOOTPRINTS: Array[Rect2i] = [
	Rect2i(26, 17, 1, 1),
	Rect2i(27, 15, 4, 1),
	Rect2i(18, 24, 1, 1),
	Rect2i(13, 25, 4, 1),
]

func _ready() -> void:
	_build_overworld()

func get_camera_limits() -> Rect2i:
	# Framed to whatever the world actually contains (core + every homestead lot +
	# town + forest), so the camera always reveals the full large neighborhood
	# instead of a hand-tuned box. Grows as plots are added.
	var bounds: Rect2 = _content_bounds_world().grow(260.0)
	return Rect2i(bounds)

## Bounding box (world px) of a tile rect in the active visual projection.
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
	# In the curated demo slice the opening view is framed tighter on the composed
	# homestead so the first screenshot is a cozy designed scene, not far empty map.
	# Players can still adjust live with PageUp/PageDown/+/- and reset with R.
	var z: float = LiveVisualPolicy.CURATED_SLICE_ZOOM if LiveVisualPolicy.CURATED_SLICE else LiveVisualPolicy.OVERWORLD_WIDE_ZOOM
	return Vector2(z, z)

func _build_overworld() -> void:
	_configure_visual_layers()
	# LimeZu is the live visual direction: when its local assets resolve, the opening
	# view is a LimeZu Modern Farm composition over the same gameplay grid. Sprout's
	# core ground/props/curated cluster are suppressed (the gameplay colliders stay).
	var limezu: bool = LiveVisualPolicy.live_limezu_slice()
	_build_overworld_backdrop()
	_build_region_tints()
	_build_ground()                 # inherited: skipped in LimeZu live mode (LimeZu grass covers)
	# In LimeZu live mode the neighborhood plot grounds + access roads (Sprout meadow +
	# generated dirt/stone path tiles) are the biggest non-LimeZu source bleeding into
	# the opening (and the "broken road"). Suppress them; plots stay claimable (logical),
	# and the LimeZu grass covers the opening view. Village/forest decor is generated +
	# off-screen, so it is suppressed too.
	if not limezu:
		_build_neighborhood_ground()
		_scatter_core_detail()      # Sprout-only light flowers/grass/pebbles
	_build_natural_borders()
	# Far-reaching visual layers (the long road to the far regions + the broad
	# wilderness scatter) read as a worldgen test in the opening view. They are kept
	# for the full overworld but SUPPRESSED for the curated demo slice so the first
	# screenshot stays a composed, calm space. The gameplay world is unchanged.
	if not LiveVisualPolicy.CURATED_SLICE:
		_build_connecting_roads()
		_build_overworld_wilderness()
	if not limezu:
		_build_village_area()
		_build_forest_area()
	_ensure_terrain_override_layer()
	_build_homestead_colliders()    # inherited: cottage/trees/fence colliders (Sprout visuals skipped in LimeZu mode)
	if limezu:
		_build_limezu_slice()       # LimeZu Modern Farm opening composition
	else:
		_build_curated_slice()      # Sprout hand-composed cozy focal cluster
	_build_overworld_bounds()

func _configure_visual_layers() -> void:
	ground_layer.z_index = LIMEZU_GROUND_LAYER_Z
	ground_layer.y_sort_enabled = false
	ground_layer.set_meta("visual_role", "terrain_ground")
	gameplay_layer.z_index = LIMEZU_GAMEPLAY_LAYER_Z
	gameplay_layer.y_sort_enabled = true
	gameplay_layer.set_meta("visual_role", "props_actors_y_sorted")

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
	# Cozy dirt avenues through the gutters between the lots. In the primary
	# Sprout/top-down projection, draw them as tile-aligned road cells so they
	# match terrain paint and parcel previews.
	if WorldProjection.is_sprout_compatible(visual_projection_mode()):
		for road_tile_variant in road_sample_tiles():
			_add_road_tile(road_tile_variant as Vector2i)
	else:
		for corridor in road_corridors():
			var pts: PackedVector2Array = PackedVector2Array()
			for t in corridor:
				pts.append(grid_to_world(t as Vector2i))
			TerrainShapes.add_ribbon(ground_layer, pts, 20.0, 20.0, BiomeRegistry.path_color("dirt_path"))

func _add_road_tile(tile: Vector2i) -> void:
	var road_node := Node2D.new()
	road_node.name = "Road_%d_%d" % [tile.x, tile.y]
	road_node.position = grid_to_world(tile)
	ground_layer.add_child(road_node)
	# Skip the flat dirt fill when the top-down path sprite covers the cell.
	if not _add_terrain_sprite(road_node, "dirt_path", tile):
		var road := Polygon2D.new()
		road.polygon = _tile_diamond()
		road.color = _terrain_base_color("dirt_path", tile)
		road.z_index = -2
		road_node.add_child(road)

## Paint one plot's biome-tinted ground patch (a 1-tile skirt around the rect).
## Public so the in-game world-builder can draw a plot the moment it's created,
## not just at boot. Core homestead tiles are never repainted (they keep their
## detailed yard art). Returns the container node so callers can free it later.
func paint_plot_ground(plot: Dictionary) -> Node2D:
	# LimeZu live mode: skip the Sprout/biome plot ground tiles (the plots are off the
	# curated opening view and their meadow tiles are a large non-LimeZu source).
	if LiveVisualPolicy.live_limezu_slice():
		return null
	var rect_variant: Variant = plot.get("rect", null)
	if not (rect_variant is Rect2i):
		return null
	var orig: Rect2i = rect_variant as Rect2i
	var r: Rect2i = orig.grow(1)
	var biome_id: String = String(plot.get("biome", "meadow"))
	var patch := Node2D.new()
	patch.name = "PlotGround_%s" % String(plot.get("plot_id", "plot"))
	patch.z_index = -8
	ground_layer.add_child(patch)
	for ty in range(r.position.y, r.end.y):
		for tx in range(r.position.x, r.end.x):
			if tx >= 0 and tx < MAP_WIDTH and ty >= 0 and ty < MAP_HEIGHT:
				continue  # don't repaint the homestead core
			var tile := Vector2i(tx, ty)
			# The 1-tile skirt around the plot is painted as meadow grass so the
			# biome patch is framed by the common ground instead of meeting the
			# background as a hard-edged rectangle.
			var terrain_id: String = "meadow"
			if orig.has_point(tile):
				terrain_id = LiveVisualPolicy.terrain_for_plot_ground(biome_id, orig, tile)
			var tile_node := Node2D.new()
			tile_node.position = grid_to_world(tile)
			patch.add_child(tile_node)
			if not _add_terrain_sprite(tile_node, terrain_id, tile):
				var ground := Polygon2D.new()
				ground.polygon = _tile_diamond()
				ground.color = LandRegistry.biome_color(terrain_id)
				ground.z_index = -2
				tile_node.add_child(ground)
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
	var has_sprite: bool = _add_terrain_sprite(node, terrain_id, tile)
	if not has_sprite:
		var base := Polygon2D.new()
		base.polygon = _tile_diamond()
		base.color = _terrain_base_color(terrain_id, tile)
		base.z_index = -2
		node.add_child(base)
	if WorldProjection.is_sprout_compatible(visual_projection_mode()) and has_sprite:
		_terrain_override_nodes[key] = node
		return
	if terrain_id == "dirt_path" or terrain_id == "stone_path":
		var inset := Polygon2D.new()
		inset.polygon = _tile_inner_polygon(7.0)
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
		edge.points = _tile_inner_polygon(4.0)
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

func _bg_layer() -> Node2D:
	if _background_layer != null and is_instance_valid(_background_layer):
		return _background_layer
	_background_layer = Node2D.new()
	_background_layer.name = "BackgroundScenery"
	_background_layer.z_index = -10
	ground_layer.add_child(_background_layer)
	return _background_layer

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
	# Calm, uniform grass tone so the tiled patches blend into the background instead
	# of reading as bright rectangles on a different-colored field. In LimeZu live mode
	# this matches the LimeZu grass tile so the area beyond the LimeZu ground is seamless.
	bg.color = LIMEZU_BACKDROP_GRASS if LiveVisualPolicy.live_limezu_slice() else BACKDROP_GRASS
	_bg_layer().add_child(bg)

## Soft grass tone matching the top-down meadow tile (art/generated/hearthvale).
const BACKDROP_GRASS := Color("#7faf68")
## Mean colour of the LimeZu grass tile (modern_farm) so the backdrop is seamless.
const LIMEZU_BACKDROP_GRASS := Color(0.28, 0.59, 0.34)

func _build_region_tints() -> void:
	# Region differentiation now comes from the actual terrain tiles + props, and a
	# detailed biome readout is available on the admin/world-builder overlay (F7).
	# The old broad alpha-0.62 color discs read as ugly debug blocks in normal play,
	# so they are intentionally NOT drawn here anymore.
	pass

func _build_natural_borders() -> void:
	if not LiveVisualPolicy.should_draw_broad_procedural_scenery():
		return
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
		TerrainShapes.add_disc(_bg_layer(), Vector2(x, north_y), 280, 7, Color("#84899e"), 0.5)
		TerrainShapes.add_disc(_bg_layer(), Vector2(x + 130, north_y + 60), 200, 7, Color("#9aa1b4"), 0.5)
	# A clear blue river hugging the south edge, well past the south wall.
	var river_y: float = bounds.end.y + 180.0
	TerrainShapes.add_ribbon(
		_bg_layer(),
		PackedVector2Array([
			Vector2(bounds.position.x - 200, river_y - 30), Vector2(cx - 600, river_y + 30),
			Vector2(cx, river_y - 20), Vector2(cx + 700, river_y + 30), Vector2(bounds.end.x + 200, river_y - 10),
		]),
		64.0, 70.0, BiomeRegistry.water_color()
	)
	# Forest wall east, soft cliff west.
	TerrainShapes.add_disc(_bg_layer(), Vector2(bounds.end.x + 60, bounds.position.y + bounds.size.y * 0.4), 460, 12, Color("#3f6a3c"), 0.7)
	TerrainShapes.add_disc(_bg_layer(), Vector2(bounds.position.x - 40, bounds.position.y + bounds.size.y * 0.5), 320, 8, Color("#8b8780"), 0.62)

func _add_tile_path_between(start_world: Vector2, end_world: Vector2, terrain_id: String = "dirt_path") -> void:
	var a: Vector2i = world_to_grid(start_world)
	var b: Vector2i = world_to_grid(end_world)
	var steps: int = maxi(absi(b.x - a.x), absi(b.y - a.y))
	var seen: Dictionary = {}
	for s in range(steps + 1):
		var t: float = float(s) / float(maxi(steps, 1))
		var tile := Vector2i(roundi(lerpf(a.x, b.x, t)), roundi(lerpf(a.y, b.y, t)))
		for offset in [Vector2i.ZERO, Vector2i(0, 1)]:
			var road_tile: Vector2i = tile + offset
			var key: String = "%d,%d" % [road_tile.x, road_tile.y]
			if seen.has(key):
				continue
			seen[key] = true
			var road_node := Node2D.new()
			road_node.name = "CleanRoad_%s" % key
			road_node.position = grid_to_world(road_tile)
			ground_layer.add_child(road_node)
			_add_terrain_sprite(road_node, terrain_id, road_tile)

func _add_tile_plaza(center_world: Vector2, radius: int, terrain_id: String = "stone_path") -> void:
	var center: Vector2i = world_to_grid(center_world)
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var tile := Vector2i(x, y)
			if Vector2(tile.x - center.x, tile.y - center.y).length() > float(radius) + 0.25:
				continue
			var node := Node2D.new()
			node.name = "CleanPlaza_%d_%d" % [tile.x, tile.y]
			node.position = grid_to_world(tile)
			ground_layer.add_child(node)
			_add_terrain_sprite(node, terrain_id, tile)

func _build_connecting_roads() -> void:
	if WorldProjection.is_sprout_compatible(visual_projection_mode()):
		_add_tile_path_between(Vector2(-60, 300), Vector2(1596, 392), "dirt_path")
		_add_tile_path_between(Vector2(1596, 392), Vector2(3060, 326), "stone_path")
		return
	TerrainShapes.add_ribbon(
		_bg_layer(),
		PackedVector2Array([Vector2(-60, 300), Vector2(320, 420), Vector2(820, 440), Vector2(1300, 392), Vector2(1596, 392)]),
		30.0, 30.0, BiomeRegistry.path_color("dirt_path")
	)
	TerrainShapes.add_ribbon(
		_bg_layer(),
		PackedVector2Array([Vector2(1596, 392), Vector2(2100, 420), Vector2(2600, 360), Vector2(3060, 326)]),
		28.0, 24.0, BiomeRegistry.terrain_color("road", true)
	)

func _build_village_area() -> void:
	var c: Vector2 = VILLAGE_OFFSET
	if WorldProjection.is_sprout_compatible(visual_projection_mode()):
		_add_tile_plaza(c + Vector2(96, 290), 5, "stone_path")
		for off in [Vector2(-150, 110), Vector2(270, 140), Vector2(-90, 470), Vector2(310, 430)]:
			_add_decor_tree(gameplay_layer, c + off)
		return
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
	for i in range(18):
		var p: Vector2 = c + Vector2(rng.randf_range(-380, 540), rng.randf_range(-140, 470))
		if p.distance_to(shrine) < 96.0:
			continue
		_add_overworld_pine(gameplay_layer, p)
	for i in range(4):
		_add_rock(gameplay_layer, c + Vector2(rng.randf_range(-320, 500), rng.randf_range(20, 440)))
	for i in range(5):
		_add_mushroom(gameplay_layer, c + Vector2(rng.randf_range(-340, 520), rng.randf_range(0, 460)))

func _build_overworld_wilderness() -> void:
	# Sparse deterministic countryside between the anchors so the land never reads as
	# empty. Drawn in the ground layer (behind props/player), visual only.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = OW_SEED + 7
	for i in range(58):
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

## Light, deterministic meadow detailing over the OPEN starting core so the most-seen
## view reads as a tended cozy yard instead of one flat grass tile repeated. Small
## decor sprites only (Sprout flower patches + pebbles, a few generated grass tufts),
## drawn under the player in the ground layer; skips paths/town/forest tiles, the
## cottage footprint, the reserved spawn, and static props. No collision, no gameplay.
func _scatter_core_detail() -> void:
	if not WorldProjection.is_sprout_compatible(visual_projection_mode()):
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = OW_SEED + 23
	var blocked: Array[Vector2i] = get_static_blocked_tiles()
	for ty in range(MAP_HEIGHT):
		for tx in range(MAP_WIDTH):
			var tile := Vector2i(tx, ty)
			if _terrain_id_for_tile(tile) != "meadow":
				continue  # leave paths, the town pad, and the forest tiles clear
			if tile in blocked or tile == get_spawn_tile():
				continue
			if rng.randf() > 0.12:
				continue
			var world_pos: Vector2 = grid_to_world(tile) + Vector2(rng.randf_range(-9.0, 9.0), rng.randf_range(-7.0, 7.0))
			var roll: float = rng.randf()
			if roll < 0.55:
				_decor_sprite(ground_layer, world_pos, "flower_patch", rng.randf_range(0.28, 0.40))
			elif roll < 0.85:
				_decor_sprite(ground_layer, world_pos, "grass_tuft", rng.randf_range(0.30, 0.42))
			else:
				_decor_sprite(ground_layer, world_pos, "rock", rng.randf_range(0.24, 0.34))

## Hand-composed cozy focal cluster around the homestead core so the OPENING view
## reads as a designed yard (cottage + well + a small garden bed + flower beds +
## framing greenery) instead of a flat worldgen test. Sprout sprites only; everything
## here is decor (no collision) and is placed to avoid the cottage, the reserved
## spawn, the path rows, the fence line, and the existing trees/NPC markers.
func _build_curated_slice() -> void:
	if not LiveVisualPolicy.CURATED_SLICE or not WorldProjection.is_sprout_compatible(visual_projection_mode()):
		return
	set_meta("curated_slice", true)
	# Focal well just east of the cottage (Sprout object, decor only).
	_decor_sprite(gameplay_layer, grid_to_world(Vector2i(11, 7)), ContentIds.PLACEABLE_WELL, 0.72)
	# A small tended garden bed: a clean 3x2 tilled patch tucked to the south-west,
	# drawn in the ground layer (behind the player) so it reads as a kept plot.
	for ty in range(12, 14):
		for tx in range(2, 5):
			var tile := Vector2i(tx, ty)
			var cell := Node2D.new()
			cell.name = "CuratedBed_%d_%d" % [tx, ty]
			cell.position = grid_to_world(tile)
			ground_layer.add_child(cell)
			_add_terrain_sprite(cell, "tilled_soil", tile)
	# Flower beds: a soft border for the garden plus a couple by the cottage/path.
	for flower_tile in [Vector2i(1, 12), Vector2i(5, 12), Vector2i(2, 14), Vector2i(4, 14), Vector2i(8, 7), Vector2i(8, 8), Vector2i(4, 7)]:
		_decor_sprite(ground_layer, grid_to_world(flower_tile), "flower_patch", 0.46)
	# Framing greenery at the view edges (gameplay layer so it y-sorts with the player).
	for bush_tile in [Vector2i(1, 5), Vector2i(1, 13), Vector2i(13, 6), Vector2i(13, 12)]:
		_decor_sprite(gameplay_layer, grid_to_world(bush_tile), "bush", 0.5)
	for tree_tile in [Vector2i(1, 3), Vector2i(13, 3)]:
		_decor_sprite(gameplay_layer, grid_to_world(tree_tile), "tree", 0.6)

## LimeZu Modern Farm opening composition over the existing gameplay grid. All art is
## resolved through LimeZuArtRegistry by logical id (no hardcoded licensed paths) and
## drawn at LIMEZU_DISPLAY_SCALE (16px art -> 32px cells). Ground tiles go in the
## (non-y-sorted) ground layer; objects/animals are bottom-anchored Node2Ds in the
## y-sorted gameplay layer so they overlap the player correctly. Trees/fence sit on the
## existing tree/fence colliders; the barn/garden/animals are decor. The gameplay grid,
## placement bounds, spawn, and colliders are unchanged.
func _build_limezu_slice() -> void:
	set_meta("limezu_slice", true)
	# 1) LimeZu grass ground covering the small playable homestead area. This is
	# intentionally bounded; the full overworld remains deferred.
	for ty in range(LIMEZU_PLAYABLE_AREA_BOUNDS.position.y, LIMEZU_PLAYABLE_AREA_BOUNDS.end.y):
		for tx in range(LIMEZU_PLAYABLE_AREA_BOUNDS.position.x, LIMEZU_PLAYABLE_AREA_BOUNDS.end.x):
			_limezu_ground("terrain.grass", Vector2i(tx, ty), LIMEZU_GROUND_GRASS_Z)
	# 2) A short dirt path in front of the home, plus small east/south approaches
	# that stay on the ground layer and never paint through visual footprints.
	for tile in LIMEZU_CURATED_PATH_TILES + LIMEZU_APPROACH_PATH_TILES:
		if _limezu_should_draw_path(tile):
			_limezu_ground("terrain.dirt_path", tile, LIMEZU_GROUND_PATH_Z)
	for gy in range(LIMEZU_TILLED_SOIL_RECT.position.y, LIMEZU_TILLED_SOIL_RECT.end.y):
		for gx in range(LIMEZU_TILLED_SOIL_RECT.position.x, LIMEZU_TILLED_SOIL_RECT.end.x):
			var soil_tile := Vector2i(gx, gy)
			if _limezu_should_draw_soil(soil_tile):
				_limezu_ground("terrain.tilled_soil", soil_tile, LIMEZU_GROUND_SOIL_Z)
	# 3) Crops on the tilled bed.
	var crops: Array[String] = ["crop.carrot", "crop.cauliflower", "crop.watermelon", "crop.carrot_stage1"]
	var crop_i: int = 0
	for gy in range(12, 15):
		for gx in range(2, 5):
			_limezu_object(crops[crop_i % crops.size()], Vector2i(gx, gy))
			crop_i += 1
	# 4) Focal barn (decor, placed low so it is fully on-screen), framing trees on the
	#    existing tree colliders, and the garden fence on the existing fence colliders.
	_limezu_object("object.barn", Vector2i(13, 13))
	for tree_tile in TREE_TILES:
		_limezu_object("object.tree", tree_tile as Vector2i)
	for offset in range(FENCE_LENGTH):
		_limezu_object("object.fence_horizontal", FENCE_START_TILE + Vector2i(offset, 0))
	# 5) Cozy detail + livestock (decor, no collision; placed in open tiles).
	for flower_tile in [Vector2i(1, 12), Vector2i(5, 11), Vector2i(12, 15), Vector2i(2, 9), Vector2i(15, 12)]:
		_limezu_object("object.flower", flower_tile)
	_limezu_object("animal.chicken", Vector2i(6, 12))
	_limezu_object("animal.cow", Vector2i(11, 15))
	_limezu_object("object.crate", Vector2i(10, 13))
	# 6) Sparse LimeZu-only edge clusters so walking a few steps from spawn still
	# feels authored without turning this into a whole-world makeover.
	for edge_tree_tile in LIMEZU_EDGE_TREE_TILES:
		_limezu_object("object.tree", edge_tree_tile)
	for edge_small_tree_tile in LIMEZU_EDGE_SMALL_TREE_TILES:
		_limezu_object("object.tree_small", edge_small_tree_tile)
	var flower_variants: Array[String] = ["object.flower", "object.flower2", "object.flower3"]
	for i in range(LIMEZU_EDGE_FLOWER_TILES.size()):
		_limezu_object(flower_variants[i % flower_variants.size()], LIMEZU_EDGE_FLOWER_TILES[i])
	for fence_tile in LIMEZU_EDGE_FENCE_TILES:
		_limezu_object("object.fence_horizontal", fence_tile)
	for edge_crate_tile in LIMEZU_EDGE_CRATE_TILES:
		_limezu_object("object.crate", edge_crate_tile)

func _limezu_is_ground_blocked(tile: Vector2i) -> bool:
	if LIMEZU_BARN_VISUAL_FOOTPRINT.has_point(tile):
		return true
	if LIMEZU_CRATE_VISUAL_FOOTPRINT.has_point(tile):
		return true
	for sign_rect in LIMEZU_SIGN_VISUAL_FOOTPRINTS:
		if sign_rect.has_point(tile):
			return true
	for prop_rect in LIMEZU_PROP_VISUAL_FOOTPRINTS:
		if prop_rect.has_point(tile):
			return true
	for tree_tile in TREE_TILES:
		if tile == (tree_tile as Vector2i):
			return true
	for edge_tree_tile in LIMEZU_EDGE_TREE_TILES:
		if tile == edge_tree_tile:
			return true
	for edge_small_tree_tile in LIMEZU_EDGE_SMALL_TREE_TILES:
		if tile == edge_small_tree_tile:
			return true
	return false

func _limezu_should_draw_path(tile: Vector2i) -> bool:
	return not _limezu_is_ground_blocked(tile)

func _limezu_should_draw_soil(tile: Vector2i) -> bool:
	return not _limezu_is_ground_blocked(tile)

## A LimeZu ground tile, centred on the cell, scaled to fill the 32px grid.
func _limezu_ground(logical_id: String, tile: Vector2i, z: int) -> void:
	if not LimeZuArtRegistry.has_asset(logical_id):
		return
	var s := Sprite2D.new()
	s.name = "LimeZuGround_%s_%d_%d" % [logical_id.replace(".", "_"), tile.x, tile.y]
	s.texture = LimeZuArtRegistry.resolve_texture(logical_id)
	s.centered = true
	s.position = grid_to_world(tile)
	s.scale = Vector2(LiveVisualPolicy.LIMEZU_DISPLAY_SCALE, LiveVisualPolicy.LIMEZU_DISPLAY_SCALE)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.z_index = z
	s.set_meta("ground_role", logical_id)
	s.set_meta("tile", tile)
	ground_layer.add_child(s)

## A LimeZu object/animal, bottom-anchored to base_tile and y-sorted via its feet.
func _limezu_object(logical_id: String, base_tile: Vector2i) -> void:
	if not LimeZuArtRegistry.has_asset(logical_id):
		return
	var tex: Texture2D = LimeZuArtRegistry.resolve_texture(logical_id)
	if tex == null:
		return
	var scale_f: float = LiveVisualPolicy.LIMEZU_DISPLAY_SCALE
	var holder := Node2D.new()
	holder.position = grid_to_world(base_tile) + Vector2(0, 16)
	holder.set_meta("limezu_logical_id", logical_id)
	holder.set_meta("tile", base_tile)
	gameplay_layer.add_child(holder)
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.position = Vector2(-tex.get_width() * scale_f * 0.5, -tex.get_height() * scale_f)
	s.scale = Vector2(scale_f, scale_f)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.set_meta("limezu_logical_id", logical_id)
	s.set_meta("tile", base_tile)
	holder.add_child(s)

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
	if _decor_sprite(parent, world_pos, "pine", 0.55):
		return
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
