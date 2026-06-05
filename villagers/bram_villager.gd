extends SimpleVillager
class_name BramVillager

func _build_visual() -> void:
	var root: Node2D = Node2D.new()
	root.name = "Body"
	add_child(root)
	_body_node = root

	var shadow: Polygon2D = Polygon2D.new()
	shadow.position = Vector2(0, 18)
	shadow.polygon = PackedVector2Array([
		Vector2(-15, 0), Vector2(15, 0), Vector2(11, 4), Vector2(-11, 4),
	])
	shadow.color = Color(0.1, 0.08, 0.06, 0.14)
	root.add_child(shadow)

	# Trousers drawn first (behind jacket)
	var trousers: Polygon2D = Polygon2D.new()
	trousers.polygon = PackedVector2Array([
		Vector2(0, 2), Vector2(12, 6), Vector2(13, 18),
		Vector2(0, 20), Vector2(-13, 18), Vector2(-12, 6),
	])
	trousers.color = Color("#5a4a30")
	root.add_child(trousers)

	# Work jacket / shirt
	var jacket: Polygon2D = Polygon2D.new()
	jacket.polygon = PackedVector2Array([
		Vector2(0, -10), Vector2(13, -3), Vector2(14, 6),
		Vector2(10, 8), Vector2(0, 8), Vector2(-10, 8),
		Vector2(-14, 6), Vector2(-13, -3),
	])
	jacket.color = Color("#6a7f44")
	root.add_child(jacket)

	# Belt line
	var belt: Polygon2D = Polygon2D.new()
	belt.polygon = PackedVector2Array([
		Vector2(-13, 4), Vector2(13, 4), Vector2(13, 7), Vector2(-13, 7),
	])
	belt.color = Color("#3e2e18")
	root.add_child(belt)

	# Belt buckle
	var buckle: Polygon2D = Polygon2D.new()
	buckle.position = Vector2(0, 5)
	buckle.polygon = PackedVector2Array([
		Vector2(-3, -2), Vector2(3, -2), Vector2(3, 2), Vector2(-3, 2),
	])
	buckle.color = Color("#c8a040")
	root.add_child(buckle)

	var neck: Polygon2D = Polygon2D.new()
	neck.position = Vector2(0, -14)
	neck.polygon = PackedVector2Array([
		Vector2(-4, -4), Vector2(4, -4), Vector2(5, 4), Vector2(-5, 4),
	])
	neck.color = Color("#d4a878")
	root.add_child(neck)

	# Head drawn before hat brim so brim overlaps the top of head
	var head: Polygon2D = Polygon2D.new()
	head.position = Vector2(0, -26)
	head.polygon = PackedVector2Array([
		Vector2(0, -10), Vector2(9, -7), Vector2(12, 0),
		Vector2(9, 7), Vector2(0, 10),
		Vector2(-9, 7), Vector2(-12, 0), Vector2(-9, -7),
	])
	head.color = Color("#d4a878")
	root.add_child(head)

	# Hat brim — wide flat oval, overlaps top of head
	var brim: Polygon2D = Polygon2D.new()
	brim.position = Vector2(0, -36)
	brim.polygon = PackedVector2Array([
		Vector2(-18, -2), Vector2(-10, -6), Vector2(0, -7),
		Vector2(10, -6), Vector2(18, -2),
		Vector2(14, 4), Vector2(0, 5), Vector2(-14, 4),
	])
	brim.color = Color("#7a5e3a")
	root.add_child(brim)

	# Hat crown
	var crown: Polygon2D = Polygon2D.new()
	crown.position = Vector2(0, -46)
	crown.polygon = PackedVector2Array([
		Vector2(0, -9), Vector2(7, -5), Vector2(9, 0),
		Vector2(7, 5), Vector2(0, 7),
		Vector2(-7, 5), Vector2(-9, 0), Vector2(-7, -5),
	])
	crown.color = Color("#8a6a45")
	root.add_child(crown)

	# Hat band
	var band: Polygon2D = Polygon2D.new()
	band.position = Vector2(0, -37)
	band.polygon = PackedVector2Array([
		Vector2(-9, 0), Vector2(9, 0), Vector2(9, 2), Vector2(-9, 2),
	])
	band.color = Color("#5a3e22")
	root.add_child(band)

	# Eyes — drawn after hat so they are always visible
	for ex: int in [-4, 4]:
		var eye: Polygon2D = Polygon2D.new()
		eye.position = Vector2(ex, -26)
		eye.polygon = PackedVector2Array([
			Vector2(0, -2), Vector2(2, 0), Vector2(0, 2), Vector2(-2, 0),
		])
		eye.color = Color("#3e2c1e")
		root.add_child(eye)

	# Stubble dots (two small dots on lower face)
	for sx: int in [-3, 3]:
		var stubble: Polygon2D = Polygon2D.new()
		stubble.position = Vector2(sx, -19)
		stubble.polygon = PackedVector2Array([
			Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0),
		])
		stubble.color = Color("#9a7858")
		root.add_child(stubble)
