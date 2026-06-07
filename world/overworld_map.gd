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

func _ready() -> void:
	_build_overworld()

func get_camera_limits() -> Rect2i:
	# Broad MMO-style framing spanning the whole strip; the backdrop is sized to it.
	return Rect2i(-760, -460, 4560, 1640)

func get_camera_zoom() -> Vector2:
	# Slightly closer than 1.0 for readable detail on high-DPI / 4K monitors. Players
	# can adjust live with PageUp/PageDown/+/- and reset with R.
	return Vector2(1.3, 1.3)

func _build_overworld() -> void:
	_build_overworld_backdrop()
	_build_region_tints()
	_build_ground()                 # inherited: detailed homestead yard tiles at origin
	_build_natural_borders()
	_build_connecting_roads()
	_build_village_area()
	_build_forest_area()
	_build_overworld_wilderness()
	_build_homestead_colliders()    # inherited: cottage, trees, fence (homestead area)
	_build_overworld_bounds()

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
	bg.color = Color("#6a9760")
	ground_layer.add_child(bg)

func _build_region_tints() -> void:
	# Broad terrain color forms so the three areas read as distinct land without hard
	# seams (homestead meadow, village outskirts, forest floor).
	TerrainShapes.add_disc(ground_layer, Vector2(60, 300), 760, 16, Color("#6f9d63"), 0.62)
	TerrainShapes.add_disc(ground_layer, VILLAGE_OFFSET + Vector2(96, 272), 720, 16, Color("#7c9b5d"), 0.62)
	TerrainShapes.add_disc(ground_layer, FOREST_OFFSET + Vector2(40, 260), 840, 16, Color("#557f4d"), 0.62)

func _build_natural_borders() -> void:
	# Distant mountain range along the north, a river along the south, a dense forest
	# wall to the east, and a cliff to the west — all drawn flat in the ground layer.
	for i in range(9):
		var x: float = -700.0 + i * 560.0
		TerrainShapes.add_disc(ground_layer, Vector2(x, -360), 270, 7, Color("#8a8a93"), 0.5)
		TerrainShapes.add_disc(ground_layer, Vector2(x + 130, -300), 190, 7, Color("#9a9aa2"), 0.5)
	TerrainShapes.add_ribbon(
		ground_layer,
		PackedVector2Array([Vector2(-760, 980), Vector2(700, 940), Vector2(1700, 1010), Vector2(2700, 950), Vector2(3800, 1010)]),
		48.0, 54.0, Color(0.4, 0.55, 0.62, 0.85)
	)
	TerrainShapes.add_disc(ground_layer, Vector2(3780, 320), 440, 12, Color("#3f6a3c"), 0.7)
	TerrainShapes.add_disc(ground_layer, Vector2(-760, 320), 300, 8, Color("#8b8780"), 0.62)

func _build_connecting_roads() -> void:
	TerrainShapes.add_ribbon(
		ground_layer,
		PackedVector2Array([Vector2(-60, 300), Vector2(320, 420), Vector2(820, 440), Vector2(1300, 392), Vector2(1596, 392)]),
		30.0, 30.0, Color("#b59872")
	)
	TerrainShapes.add_ribbon(
		ground_layer,
		PackedVector2Array([Vector2(1596, 392), Vector2(2100, 420), Vector2(2600, 360), Vector2(3060, 326)]),
		28.0, 24.0, Color("#ad8a64")
	)

func _build_village_area() -> void:
	var c: Vector2 = VILLAGE_OFFSET
	TerrainShapes.add_disc(ground_layer, c + Vector2(96, 286), 100, 8, Color("#c4b79a"), 0.5)
	TerrainShapes.add_disc(ground_layer, c + Vector2(96, 282), 68, 8, Color("#d2c6ab"), 0.5)
	_add_overworld_fountain(c + Vector2(96, 272))
	for off in [Vector2(-150, 110), Vector2(270, 140), Vector2(-90, 470), Vector2(310, 430)]:
		_add_decor_tree(gameplay_layer, c + off)

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

func _build_overworld_wilderness() -> void:
	# Sparse deterministic countryside between the anchors so the land never reads as
	# empty. Drawn in the ground layer (behind props/player), visual only.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = OW_SEED + 7
	for i in range(190):
		var p: Vector2 = Vector2(rng.randf_range(-700, 3760), rng.randf_range(-180, 880))
		var roll: float = rng.randf()
		if roll < 0.42:
			_add_grass_tuft(rng, ground_layer, p)
		elif roll < 0.70:
			_add_shrub(ground_layer, p)
		elif roll < 0.88:
			_add_flowers(rng, ground_layer, p)
		else:
			_add_decor_tree(ground_layer, p)

func _build_overworld_bounds() -> void:
	_add_boundary("OW_North", Vector2(1500, -120), Vector2(5000, 80))
	_add_boundary("OW_South", Vector2(1500, 900), Vector2(5000, 80))
	_add_boundary("OW_West", Vector2(-720, 390), Vector2(80, 1120))
	_add_boundary("OW_East", Vector2(3760, 390), Vector2(80, 1120))

func _add_overworld_fountain(world_pos: Vector2) -> void:
	var fountain: Node2D = Node2D.new()
	fountain.position = world_pos
	gameplay_layer.add_child(fountain)
	var base: Polygon2D = Polygon2D.new()
	base.position = Vector2(0, 8)
	base.color = Color("#c9c7d1")
	base.polygon = PackedVector2Array([Vector2(0, -20), Vector2(34, 0), Vector2(0, 20), Vector2(-34, 0)])
	fountain.add_child(base)
	var basin: Polygon2D = Polygon2D.new()
	basin.position = Vector2(0, -6)
	basin.color = Color("#8db8c9")
	basin.polygon = PackedVector2Array([Vector2(0, -16), Vector2(18, 0), Vector2(0, 12), Vector2(-18, 0)])
	fountain.add_child(basin)
	var post: Polygon2D = Polygon2D.new()
	post.position = Vector2(0, -26)
	post.color = Color("#b5aa9a")
	post.polygon = PackedVector2Array([Vector2(-5, -18), Vector2(5, -18), Vector2(5, 14), Vector2(-5, 14)])
	fountain.add_child(post)

func _add_overworld_pine(parent: Node2D, world_pos: Vector2) -> void:
	var pine: Node2D = Node2D.new()
	pine.position = world_pos
	parent.add_child(pine)
	var trunk: Polygon2D = Polygon2D.new()
	trunk.color = Color("#704f35")
	trunk.polygon = PackedVector2Array([Vector2(-5, 0), Vector2(5, 0), Vector2(7, -28), Vector2(-7, -28)])
	pine.add_child(trunk)
	var low: Polygon2D = Polygon2D.new()
	low.position = Vector2(0, -26)
	low.color = Color("#4f7d44")
	low.polygon = PackedVector2Array([Vector2(0, -22), Vector2(22, -2), Vector2(0, 18), Vector2(-22, -2)])
	pine.add_child(low)
	var up: Polygon2D = Polygon2D.new()
	up.position = Vector2(0, -46)
	up.color = Color("#6a9a5a")
	up.polygon = PackedVector2Array([Vector2(0, -18), Vector2(16, -1), Vector2(0, 13), Vector2(-16, -1)])
	pine.add_child(up)
