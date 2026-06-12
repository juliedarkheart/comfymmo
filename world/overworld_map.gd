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
	bg.color = Color("#709c5d")
	ground_layer.add_child(bg)

func _build_region_tints() -> void:
	# Broad terrain color forms so the three areas read as distinct land without hard
	# seams (homestead meadow, village outskirts, forest floor).
	TerrainShapes.add_disc(ground_layer, Vector2(60, 300), 760, 16, Color("#76a463"), 0.62)
	TerrainShapes.add_disc(ground_layer, VILLAGE_OFFSET + Vector2(96, 272), 720, 16, Color("#87a55e"), 0.62)
	TerrainShapes.add_disc(ground_layer, FOREST_OFFSET + Vector2(40, 260), 840, 16, Color("#4e7a4a"), 0.62)

func _build_natural_borders() -> void:
	# Distant mountain range along the north, a river along the south, a dense forest
	# wall to the east, and a cliff to the west — all drawn flat in the ground layer.
	for i in range(9):
		var x: float = -700.0 + i * 560.0
		TerrainShapes.add_disc(ground_layer, Vector2(x, -360), 270, 7, Color("#84899e"), 0.5)
		TerrainShapes.add_disc(ground_layer, Vector2(x + 130, -300), 190, 7, Color("#9aa1b4"), 0.5)
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
		30.0, 30.0, Color("#c2a071")
	)
	TerrainShapes.add_ribbon(
		ground_layer,
		PackedVector2Array([Vector2(1596, 392), Vector2(2100, 420), Vector2(2600, 360), Vector2(3060, 326)]),
		28.0, 24.0, Color("#b6915f")
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
	_add_boundary("OW_North", Vector2(1500, -120), Vector2(5000, 80))
	_add_boundary("OW_South", Vector2(1500, 900), Vector2(5000, 80))
	_add_boundary("OW_West", Vector2(-720, 390), Vector2(80, 1120))
	_add_boundary("OW_East", Vector2(3760, 390), Vector2(80, 1120))

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
