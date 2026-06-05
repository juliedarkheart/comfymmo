extends Node2D
class_name SimpleVillager

@export var villager_name: String = "Villager"
@export var first_visit_text: String = "Hello."
@export var repeat_visit_text: String = "Good to see you again."
@export var repeat_visit_lines: PackedStringArray = PackedStringArray()

var _idle_timer: float = 0.0
var _body_node: Node2D = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_idle_timer = _rng.randf_range(0.0, TAU)
	_build_visual()

func _process(delta: float) -> void:
	_idle_timer += delta * 0.9
	if _body_node != null:
		_body_node.position.y = sin(_idle_timer) * 2.5

func get_repeat_line(visit_count: int) -> String:
	if repeat_visit_lines.size() > 0:
		return repeat_visit_lines[visit_count % repeat_visit_lines.size()]
	return repeat_visit_text

func _build_visual() -> void:
	var root: Node2D = Node2D.new()
	root.name = "Body"
	add_child(root)
	_body_node = root

	var shadow: Polygon2D = Polygon2D.new()
	shadow.position = Vector2(0, 18)
	shadow.polygon = PackedVector2Array([
		Vector2(-14, 0), Vector2(14, 0), Vector2(10, 4), Vector2(-10, 4),
	])
	shadow.color = Color(0.1, 0.08, 0.06, 0.14)
	root.add_child(shadow)

	# Hair drawn before head so head face renders on top
	var hair: Polygon2D = Polygon2D.new()
	hair.position = Vector2(0, -36)
	hair.polygon = PackedVector2Array([
		Vector2(0, -6), Vector2(8, -2), Vector2(10, 5),
		Vector2(8, 11), Vector2(-8, 11), Vector2(-10, 5), Vector2(-8, -2),
	])
	hair.color = Color("#6b3f28")
	root.add_child(hair)

	var bun: Polygon2D = Polygon2D.new()
	bun.position = Vector2(7, -44)
	bun.polygon = PackedVector2Array([
		Vector2(0, -4), Vector2(4, 0), Vector2(0, 4), Vector2(-4, 0),
	])
	bun.color = Color("#7a4a30")
	root.add_child(bun)

	var dress: Polygon2D = Polygon2D.new()
	dress.polygon = PackedVector2Array([
		Vector2(0, -10), Vector2(11, -4), Vector2(13, 5),
		Vector2(10, 16), Vector2(0, 18), Vector2(-10, 16),
		Vector2(-13, 5), Vector2(-11, -4),
	])
	dress.color = Color("#c07048")
	root.add_child(dress)

	var apron: Polygon2D = Polygon2D.new()
	apron.polygon = PackedVector2Array([
		Vector2(0, -4), Vector2(6, 0), Vector2(7, 10),
		Vector2(0, 14), Vector2(-7, 10), Vector2(-6, 0),
	])
	apron.color = Color("#e8c47a")
	root.add_child(apron)

	# Clock brooch — small golden diamond with a tick mark
	var brooch: Polygon2D = Polygon2D.new()
	brooch.position = Vector2(4, -6)
	brooch.polygon = PackedVector2Array([
		Vector2(0, -3), Vector2(3, 0), Vector2(0, 3), Vector2(-3, 0),
	])
	brooch.color = Color("#d4a84a")
	root.add_child(brooch)

	var brooch_mark: Polygon2D = Polygon2D.new()
	brooch_mark.position = Vector2(4, -8)
	brooch_mark.polygon = PackedVector2Array([
		Vector2(-0.5, 0), Vector2(0.5, 0), Vector2(0.5, 2), Vector2(-0.5, 2),
	])
	brooch_mark.color = Color("#8a6020")
	root.add_child(brooch_mark)

	var neck: Polygon2D = Polygon2D.new()
	neck.position = Vector2(0, -14)
	neck.polygon = PackedVector2Array([
		Vector2(-4, -4), Vector2(4, -4), Vector2(4, 4), Vector2(-4, 4),
	])
	neck.color = Color("#e8c8a8")
	root.add_child(neck)

	var head: Polygon2D = Polygon2D.new()
	head.position = Vector2(0, -26)
	head.polygon = PackedVector2Array([
		Vector2(0, -11), Vector2(8, -7), Vector2(11, 0),
		Vector2(8, 7), Vector2(0, 11),
		Vector2(-8, 7), Vector2(-11, 0), Vector2(-8, -7),
	])
	head.color = Color("#e8c8a8")
	root.add_child(head)

	# Half-frame glasses — thin upper rim bars
	for gx: int in [-4, 4]:
		var rim: Polygon2D = Polygon2D.new()
		rim.position = Vector2(gx, -29)
		rim.polygon = PackedVector2Array([
			Vector2(-4, 0), Vector2(4, 0), Vector2(4, 1), Vector2(-4, 1),
		])
		rim.color = Color("#5a4030")
		root.add_child(rim)

	var bridge: Polygon2D = Polygon2D.new()
	bridge.position = Vector2(0, -28)
	bridge.polygon = PackedVector2Array([
		Vector2(-1, 0), Vector2(1, 0), Vector2(1, 1), Vector2(-1, 1),
	])
	bridge.color = Color("#5a4030")
	root.add_child(bridge)

	for ex: int in [-4, 4]:
		var eye: Polygon2D = Polygon2D.new()
		eye.position = Vector2(ex, -26)
		eye.polygon = PackedVector2Array([
			Vector2(0, -2), Vector2(2, 0), Vector2(0, 2), Vector2(-2, 0),
		])
		eye.color = Color("#3e2c1e")
		root.add_child(eye)

	# Smile corners
	for sx: int in [-3, 3]:
		var dot: Polygon2D = Polygon2D.new()
		dot.position = Vector2(sx, -19)
		dot.polygon = PackedVector2Array([
			Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0),
		])
		dot.color = Color("#b87868")
		root.add_child(dot)
