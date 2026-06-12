extends AmbientCreature
class_name MossRabbit

const OBSERVE_TEXTS: Array[String] = [
	"The moss rabbit twitches its ears.",
	"A small nose wiggles curiously.",
	"Its fluffy tail bobs as it hops.",
	"The rabbit pauses and looks around.",
]

var _hop_timer: float = 0.0
var _hop_offset: float = 0.0
var _rng_text: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	super._ready()
	_rng_text.randomize()
	_hop_timer = _rng.randf_range(0.0, TAU)
	_build_visual()

func get_display_name() -> String:
	return "Moss Rabbit"

func get_observe_text() -> String:
	return OBSERVE_TEXTS[_rng_text.randi() % OBSERVE_TEXTS.size()]

func _build_visual() -> void:
	var root: Node2D = Node2D.new()
	root.name = "Body"
	add_child(root)
	_body_node = root

	var shadow: Polygon2D = Polygon2D.new()
	shadow.position = Vector2(0, 10)
	shadow.polygon = PackedVector2Array([
		Vector2(-13, 0), Vector2(13, 0), Vector2(10, 4), Vector2(-10, 4),
	])
	shadow.color = Color(0.1, 0.08, 0.06, 0.14)
	root.add_child(shadow)

	var body: Polygon2D = Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(0, -12), Vector2(11, -5), Vector2(13, 2),
		Vector2(10, 9), Vector2(0, 12), Vector2(-10, 9),
		Vector2(-13, 2), Vector2(-11, -5),
	])
	body.color = Color("#b4a485")
	root.add_child(body)

	var belly: Polygon2D = Polygon2D.new()
	belly.polygon = PackedVector2Array([
		Vector2(0, -4), Vector2(6, 1), Vector2(5, 7),
		Vector2(0, 9), Vector2(-5, 7), Vector2(-6, 1),
	])
	belly.color = Color("#d6cdb0")
	root.add_child(belly)

	var ear_l: Polygon2D = Polygon2D.new()
	ear_l.position = Vector2(-5, -16)
	ear_l.polygon = PackedVector2Array([
		Vector2(0, -10), Vector2(4, -4), Vector2(3, 4), Vector2(-3, 4), Vector2(-4, -4),
	])
	ear_l.color = Color("#c2a07a")
	root.add_child(ear_l)

	var ear_inner_l: Polygon2D = Polygon2D.new()
	ear_inner_l.position = Vector2(-5, -16)
	ear_inner_l.polygon = PackedVector2Array([
		Vector2(0, -7), Vector2(2, -2), Vector2(2, 2), Vector2(-2, 2), Vector2(-2, -2),
	])
	ear_inner_l.color = Color("#e8b4a0")
	root.add_child(ear_inner_l)

	var ear_r: Polygon2D = Polygon2D.new()
	ear_r.position = Vector2(5, -16)
	ear_r.polygon = ear_l.polygon
	ear_r.color = Color("#c2a07a")
	root.add_child(ear_r)

	var ear_inner_r: Polygon2D = Polygon2D.new()
	ear_inner_r.position = Vector2(5, -16)
	ear_inner_r.polygon = ear_inner_l.polygon
	ear_inner_r.color = Color("#e8b4a0")
	root.add_child(ear_inner_r)

	for ex: int in [-5, 5]:
		var eye: Polygon2D = Polygon2D.new()
		eye.position = Vector2(ex, -7)
		eye.polygon = PackedVector2Array([
			Vector2(0, -2), Vector2(2, 0), Vector2(0, 2), Vector2(-2, 0),
		])
		eye.color = Color("#3e2c1e")
		root.add_child(eye)

	for bx: int in [-8, 8]:
		var blush: Polygon2D = Polygon2D.new()
		blush.position = Vector2(bx, -4)
		blush.polygon = PackedVector2Array([
			Vector2(0, -1.5), Vector2(2, 0), Vector2(0, 1.5), Vector2(-2, 0),
		])
		blush.color = Color(0.93, 0.66, 0.62, 0.8)
		root.add_child(blush)

	var nose: Polygon2D = Polygon2D.new()
	nose.position = Vector2(0, -1)
	nose.polygon = PackedVector2Array([
		Vector2(0, -2), Vector2(2, 0), Vector2(0, 2), Vector2(-2, 0),
	])
	nose.color = Color("#c07070")
	root.add_child(nose)

	var tail: Polygon2D = Polygon2D.new()
	tail.position = Vector2(0, 10)
	tail.polygon = PackedVector2Array([
		Vector2(0, -4), Vector2(4, 0), Vector2(0, 4), Vector2(-4, 0),
	])
	tail.color = Color("#eae0d0")
	root.add_child(tail)

func _animate(delta: float) -> void:
	if _state == "wander":
		_hop_timer += delta * 7.0
		_hop_offset = absf(sin(_hop_timer)) * -5.0
	else:
		_hop_offset = move_toward(_hop_offset, 0.0, delta * 20.0)

	if _body_node != null:
		_body_node.position.y = _hop_offset
